# Android AICore and the ML Kit GenAI APIs

**Last verified: 2026-09-03.** See [How to refresh this page](#how-to-refresh-this-page) at the
bottom — an agent that checks the sources must update the date in **both** language versions in the
same commit, even when nothing else changed.

This page is a **project-independent reference**. It is written to be useful to any Flutter or
Android project in the MyApps series that is considering on-device generative AI, not only to
MyNihongo!!!!!. What *this* app does with it is in
[`features/ai-assist.md`](features/ai-assist.md); the platform facts are here.

## What AICore is

`com.google.android.aicore` is an Android system service that holds the on-device foundation models
and runs inference for other apps. An app never ships or loads a model itself: it asks AICore, which
owns the model files, the download, the memory and the scheduling. That is why on-device GenAI costs
an app a few hundred kilobytes of client library rather than a multi-gigabyte asset, and why the
privacy claim is precise — the text goes to a **system service on the same device**, not to a server.

**ML Kit GenAI** is the client library family over it (`com.google.mlkit:genai-*`). There is no
supported way to reach AICore without it.

Two consequences worth knowing before designing anything:

- **Availability is a runtime question, per feature.** Two features on the same phone can have
  different statuses. Ask before every use, not once.
- **The model download is a network operation the app triggers but does not perform.** AICore
  fetches it from Google. Any privacy policy has to say so, and no app should start one without the
  user asking for it.

## Requirements

| Requirement | Value |
|---|---|
| Android API | 26+ for the Prompt API; the feature APIs are similar, but check each |
| AICore app | Required, and must be a version that serves the requested feature |
| Bootloader | **Must be locked.** The APIs refuse to run on an unlocked bootloader |
| Play services | Present in practice; the libraries resolve through Google's Maven |
| Device | A published per-API list; see below |

The locked-bootloader rule is the one that surprises people: a rooted or custom-ROM development
phone cannot test these APIs at all, and the failure looks like "unavailable", not like a permission
error. Check `ro.boot.verifiedbootstate` (`green`) and `ro.boot.flash.locked` (`1`) before concluding
a device is unsupported for some other reason.

There is also a first-run caveat: immediately after device setup or an AICore reset, the service may
need internet access and, sometimes, a restart before it reports anything but `UNAVAILABLE`.

## The APIs

Six as of the verification date. The four "feature" APIs are task-shaped and return
`ListenableFuture`s; the Prompt API is free-form and is coroutine-based.

| API | Artifact | Purpose | Input limit |
|---|---|---|---|
| Prompt | `com.google.mlkit:genai-prompt:1.0.0-beta2` | Free-form text or image + text → text | < 4000 tokens |
| Summarization | `com.google.mlkit:genai-summarization` | Article or chat → bulleted summary | see docs |
| Proofreading | `com.google.mlkit:genai-proofreading:1.0.0-beta1` | Fix grammar and spelling in short text | < 256 tokens |
| Rewriting | `com.google.mlkit:genai-rewriting:1.0.0-beta1` | Restate in a tone or style | < 256 tokens |
| Image description | `com.google.mlkit:genai-image-description` | Image → one-line description | — |
| Speech recognition | `com.google.mlkit:genai-speech-recognition` | Audio → text; basic mode API 31+, advanced mode on Pixel 10/11 | — |

All of them depend on `com.google.mlkit:genai-common` (`1.0.0-beta3`), which is where
`FeatureStatus`, `DownloadCallback`, `DownloadStatus`, `StreamingCallback` and `GenAiException` live.

Everything is **beta**: no SLA, no deprecation policy. Pin exact versions.

### Languages

Proofreading and rewriting are documented for **English, Japanese, French, German, Italian, Spanish
and Korean**. The Prompt API publishes no such list — it is a general model, and the practical answer
for any given language is "try it on the device and read the output". Google's own note is that
"availability of specific language support may vary depending on the particular device's
configuration".

### Devices

The feature APIs list Pixel 9 and newer plus a set of Snapdragon, Tensor and Dimensity devices
(Samsung Galaxy S25 among them). The **Prompt API's list is narrower** and, as of the verification
date, names Pixel 10, 10 Pro, 10 Pro XL and 10 Pro Fold. Treat published device lists as a floor and
the runtime status as the truth.

## The two API shapes

Confirmed by `javap` against the published AARs, not only from the documentation.

### Prompt (coroutines)

```kotlin
val model: GenerativeModel = Generation.getClient()          // or getClient(GenerationConfig)

when (model.checkStatus()) {                                  // suspend, returns Int
    FeatureStatus.UNAVAILABLE -> {}
    FeatureStatus.DOWNLOADABLE -> model.download().collect { status ->
        when (status) {
            is DownloadStatus.DownloadStarted -> status.bytesToDownload
            is DownloadStatus.DownloadProgress -> status.totalBytesDownloaded
            is DownloadStatus.DownloadFailed -> status.e
            DownloadStatus.DownloadCompleted -> {}
        }
    }
    FeatureStatus.DOWNLOADING -> {}
    FeatureStatus.AVAILABLE -> {}
}

val response = model.generateContent(
    generateContentRequest(TextPart(prompt)) {
        temperature = 0.2f
        topK = 16
        candidateCount = 1
        maxOutputTokens = 256
    }
)
val text = response.candidates.firstOrNull()?.text

model.close()
```

`generateContentStream(request)` returns a `Flow<GenerateContentResponse>` for streaming. There is a
`GenerativeModelFutures` wrapper in `com.google.mlkit.genai.prompt.java` for Java callers.

**Structured output and tool calling are not available on Android.** Ask for text and parse it.

### Feature APIs (ListenableFuture), proofreading as the example

```kotlin
val proofreader: Proofreader = Proofreading.getClient(
    ProofreaderOptions.builder(context)
        .setLanguage(ProofreaderOptions.Language.JAPANESE)
        .setInputType(ProofreaderOptions.InputType.KEYBOARD)
        .build()
)

proofreader.checkFeatureStatus()                    // ListenableFuture<Integer>
proofreader.downloadFeature(callback)               // ListenableFuture<Void>, DownloadCallback
proofreader.runInference(request)                   // ListenableFuture<ProofreadingResult>
proofreader.close()
```

`ProofreadingResult.getResults()` yields `ProofreadingSuggestion`s, each with `getText()`.
`runInference(request, StreamingCallback)` streams.

Mixing the two shapes in one Kotlin file needs a `ListenableFuture.await()`. Writing the ten-line
`suspendCancellableCoroutine` version is preferable to adding `kotlinx-coroutines-guava`, which pulls
all of Guava into the APK for that one function.

## Quotas and concurrency

AICore serves **one inference at a time per app** and enforces an app-level inference quota. Design
for it: refuse a second concurrent request with a "busy" answer of your own rather than letting the
service produce an error that is much harder to explain. Close clients when the hosting component
goes away — an open client holds a session other apps could be using.

## Using it from Flutter

There are several 0.x plugins (`google_mlkit_genai_prompt`, `flutter_local_ai`, `edge_gen_ai`,
`gemini_nano_android`). They wrap the Prompt API only, and each one is another plugin that may apply
the Kotlin Gradle Plugin — which matters to any project running Flutter's `android.builtInKotlin=false`
compatibility mode, where every KGP-applying plugin constrains the whole build.

For a small surface, **a method channel in the app's own Kotlin is less risk than a dependency**:
two clients and five methods, no plugin, no version to track. MyNihongo does this in
`android/app/src/main/kotlin/com/yuanzhe/my_nihongo/GenAiChannel.kt`; the shape is worth copying.

Set `minSdk = 26` explicitly in `android/app/build.gradle.kts` — Flutter's default is 24.

```kotlin
implementation("com.google.mlkit:genai-prompt:1.0.0-beta2")
implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
```

No manifest permission is needed: the network use is AICore's, not the app's.

Keep the policy — the opt-in switch, the prompt text, the parsing of the answer — on the Dart side.
Everything there is testable on a machine with no Android device; nothing in the Kotlin is.

## Checking a device with adb

```bash
adb shell pm list packages | grep aicore
adb shell dumpsys package com.google.android.aicore | grep versionName
adb shell getprop ro.boot.verifiedbootstate     # want: green
adb shell getprop ro.boot.flash.locked          # want: 1
adb shell getprop ro.build.version.sdk          # want: >= 26
adb logcat | grep -i aicore
```

A device may report two AICore entries — a `/product/priv-app` prebuilt stub and an updated version
installed over it. The updated one is what serves requests, so read the higher `versionName`.

### Diagnosing "not available on this device"

This is the failure that needs a procedure, because it is what the app reports for at least four
unrelated causes. Work down the list; the first two need no cable.

1. **Read the app's own status rows.** Each carries the raw answer under it — `FeatureStatus=0` when
   AICore was asked and said no, or an exception class and message when the call could not be made
   at all. A version line under the section names the installed AICore build and the device. Those
   three facts separate every case below.
2. **Compare the two features.** They have separate device lists. Explanations use the Prompt API,
   whose list is the narrower one; correction suggestions use Proofreading, whose list is much wider.
   *One row ready and the other unavailable is the expected answer on most non-Pixel hardware*, not a
   bug — and it is why the app never treats "AI" as one switchable thing.
3. **Check the bootloader.** `verifiedbootstate` must be `green` and `flash.locked` must be `1`. An
   unlocked bootloader fails as "unavailable", with no hint that this is the reason.
4. **Give provisioning time and network.** Right after setup, an AICore reset, or an OS update, the
   service can answer `UNAVAILABLE` until it has fetched what it needs, sometimes only after a
   restart. Re-check rather than concluding — this is what the **Check again** button in Settings is
   for.
5. **Check the AICore version against the device.** A manufacturer ships AICore through its own
   update channel, so a phone can be new and its AICore old.
6. **Only then suspect the build.** `logcat -s MyNihongoGenAi` prints every status answer and every
   failure with its exception class. If the failure appears in a release build but not a debug one,
   read [the R8 field note](#field-notes) before anything else.

The app is instrumented for exactly this: `GenAiChannel.status` catches its own exceptions and
answers `unreachable` with the exception class rather than letting them collapse into `unavailable`,
and it reads the AICore package version through the manifest's `<queries>` entry. Without that entry
the package is invisible on API 30+ and every device looks like it has no AICore at all.

## Privacy, honestly stated

Worth being precise, because "on-device AI" is easy to overclaim:

- Inference happens on the device. Prompts and answers do not leave it.
- **The model download does use the network**, performed by AICore, fetching from Google. It should
  be user-initiated and disclosed.
- The output is generated text. It can be wrong, and it should be labelled wherever it is shown.
- Nothing obliges an app to store what was generated, and an app that teaches something should not:
  a wrong answer kept is a wrong answer re-read.

## Field notes

Observations from real use, added as they are found. Each says which device and date, because none
of it is guaranteed to generalise.

- **Pixel 10 (`frankel`), Android 17, 2026-09-03.** AICore present as both a `/product` prebuilt
  stub (`aicore_20260302.01_RC00`) and an updated build (`aicore_20260723.00_RC11`); the updated one
  is what answers. `verifiedbootstate=green`, `flash.locked=1`, so the locked-bootloader rule is
  satisfied on a stock device.
- **R8 breaks it, and the failure looks like an unsupported device.** This is the one worth carrying
  to another project. A release build with default shrinking threw `NullPointerException` from
  `Objects.requireNonNull` deep inside ML Kit on the very first call, while the same code in a debug
  build answered correctly — so the app reported "not available on this device" on a phone that
  supports it perfectly. The AARs' own consumer rules cover their generated protos only. Keeping
  `com.google.mlkit.genai.**` is **not enough**: R8's `mapping.txt` named the failing frame as
  `com.google.mlkit.common.sdkinternal.LazyInstanceMap`, so the shared ML Kit SDK internals have to
  survive too. What works:

  ```proguard
  -keep class com.google.mlkit.** { *; }
  -keep class com.google.android.gms.internal.mlkit_** { *; }
  -dontwarn com.google.mlkit.**
  ```

  The technique generalises: when a release build fails inside obfuscated code, read the frame out of
  `build/app/intermediates/mapping/release/*/mapping.txt` rather than guessing which package to keep.
- **Both features were `DOWNLOADABLE` (1) out of the box** and became `AVAILABLE` (3) within seconds
  of tapping Download — on a Pixel 10 the base model is already present, so what is fetched is small
  and the multi-gigabyte first download some devices need did not happen here.
- **Latency: roughly 20–30 seconds** for a first Prompt API answer of a few sentences, and similar
  for proofreading. Slow enough that the UI must show a spinner and disable the other actions; not
  so slow that a timeout under a minute is safe. The app allows 45 seconds.
- **Both English and Simplified Chinese output were correct and idiomatic** when the prompt asked for
  them, on `nano-v3`. The Prompt API publishes no language list; this is one data point, not a
  guarantee.
- **Samsung Galaxy Z Fold 8, reported 2026-09-03: AICore installed, both features "not available".**
  Not reproduced here — there is no Samsung device on this host — and recorded because the *shape* of
  the report is the useful part. The two most likely causes are ordinary rather than broken: the
  Prompt API's published device list named only the Pixel 10 family at the verification date above,
  and AICore on a manufacturer's own update channel can lag the phone. What made it undiagnosable was
  the app, not the device: every failure path answered with the same sentence, so "AICore said no",
  "the call threw" and "the package is invisible to this build" were indistinguishable. The
  instrumentation described under [Diagnosing](#diagnosing-not-available-on-this-device) was added
  for this report; **treat a published device list as a floor and the runtime status as the truth**,
  and expect proofreading to be available on hardware where the Prompt API is not.
- The Proofreading API handed a **correct** sentence returns that sentence unchanged, so a client
  has to compare and say "nothing to change" itself — otherwise it tells the learner their correct
  sentence was wrong.

## How to refresh this page

The APIs are beta and move. An agent picking up work that touches on-device AI should re-check these
sources, update anything that changed — versions, limits, language lists, device lists, method
signatures — and **change the `Last verified` date at the top of both the English and the Chinese
version in the same commit**, even if nothing else needed changing. A date that is not moved is worse
than no date, because it makes stale facts look checked.

Sources, in the order worth reading them:

- Overview and the API list — <https://developers.google.com/ml-kit/genai>
- Prompt API and its get-started guide — <https://developers.google.com/ml-kit/genai/prompt/android>
- Proofreading — <https://developers.google.com/ml-kit/genai/proofreading/android>
- Rewriting — <https://developers.google.com/ml-kit/genai/rewriting/android>
- Gemini Nano on Android — <https://developer.android.com/ai/gemini-nano>

When a signature matters, **do not trust the documentation alone**: download the AAR from
`https://dl.google.com/dl/android/maven2/com/google/mlkit/<artifact>/<version>/<artifact>-<version>.aar`,
unzip `classes.jar`, and run `javap -public` over the classes under `com/google/mlkit/`. The
reference site does not always serve the class pages, and the AAR cannot be out of date with itself.

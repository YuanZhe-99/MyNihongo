# Android AICore and the ML Kit GenAI APIs

**Last verified: 2026-09-04**, on a Pixel 10 (Android 17) and, through a user report, a Galaxy Z Fold 8. See [How to refresh this page](#how-to-refresh-this-page) at the
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
| Prompt | `com.google.mlkit:genai-prompt:1.0.0-beta4` | Free-form text or image + text → text | < 4000 tokens |
| Summarization | `com.google.mlkit:genai-summarization` | Article or chat → bulleted summary | see docs |
| Proofreading | `com.google.mlkit:genai-proofreading:1.0.0-beta1` | Fix grammar and spelling in short text | < 256 tokens |
| Rewriting | `com.google.mlkit:genai-rewriting:1.0.0-beta1` | Restate in a tone or style | < 256 tokens |
| Image description | `com.google.mlkit:genai-image-description` | Image → one-line description | — |
| Speech recognition | `com.google.mlkit:genai-speech-recognition` | Audio → text; basic mode API 31+, advanced mode on Pixel 10/11 | — |
| Schema | `com.google.mlkit:genai-schema:1.0.0-alpha1` | Structured output: a schema the Prompt API decodes into | — |

All of them depend on `com.google.mlkit:genai-common` (`1.0.0-beta4`), which is where
`FeatureStatus`, `DownloadCallback`, `DownloadStatus`, `StreamingCallback` and `GenAiException` live.
The Prompt API's POM pulls the matching `genai-common` itself, so pinning `genai-prompt` is enough.

Everything is **beta**: no SLA, no deprecation policy. Pin exact versions — and read the
[release notes](https://developers.google.com/ml-kit/release-notes) when you do, because a beta
bump here has already fixed a device-visible bug rather than only adding features. `genai-prompt`
`1.0.0-beta4` (2026-07-21) is the floor for any app that wants the Prompt API to work on non-Pixel
hardware: see [Devices](#devices).

### Languages

Proofreading and rewriting are documented for **English, Japanese, French, German, Italian, Spanish
and Korean**. The Prompt API publishes no such list — it is a general model, and the practical answer
for any given language is "try it on the device and read the output". Google's own note is that
"availability of specific language support may vary depending on the particular device's
configuration".

### Devices

The feature APIs (summarization, proofreading, rewriting, image description) list Pixel 9 and newer
plus a wide set of Snapdragon, Tensor and Dimensity devices — Samsung's Galaxy S25 and S26 families,
the Galaxy Z Flip8, Z Fold8 and Z Fold8 Ultra, and phones from Honor, iQOO, Lenovo, Motorola,
OnePlus, OPPO, POCO, realme, Sharp, Sony, vivo and Xiaomi.

The **Prompt API's list is narrower and is split by Gemini Nano version**, which is the part that
matters when a call fails:

| Nano | Devices, abbreviated |
|---|---|
| nano-v2 | Honor, iQOO, Motorola, OnePlus, OPPO, POCO, realme, Samsung Z Fold7 and Z TriFold, vivo, Xiaomi |
| nano-v3 | Pixel 10 family, Honor, iQOO, Lenovo, Motorola, OnePlus, OPPO, realme, Samsung S26 family, Sharp, Sony, vivo |
| nano-v4 | Pixel 11 family; **Samsung Galaxy Z Flip8, Z Fold8, Z Fold8 Ultra** |

**A nano-v4 device needs `genai-prompt` 1.0.0-beta4 or newer.** Earlier clients throw
`FEATURE_NOT_FOUND` from `checkStatus()` on one — the release note for beta4 is precisely "fixed
compatibility with Gemini Nano v4 … a `GenAiException` when `checkStatus()` is used". The failure
looks exactly like an unsupported device, and it is not one. See the Z Fold 8 field note below.

That bump is **necessary and not sufficient**. A current client can ask; it still asks for only one
of four model variants unless it is told otherwise, and a Z Fold 8 running `beta4` refused that one.
See [Choosing a model](#choosing-a-model-release-stage-and-size-preference) and the Z Fold 8 field
notes below.

Treat published device lists as a floor and the runtime status as the truth — but check the client
version, and which variant you actually asked for, before believing a refusal.

## Choosing a model: release stage and size preference

`Generation.getClient()` with no argument is not "the model this device has". It is one specific
request — the **stable** release stage at the **full** size preference — and a device that does not
serve that exact combination answers `UNAVAILABLE`, which is indistinguishable from having no
on-device model at all.

Confirmed with `javap -public` against `genai-prompt:1.0.0-beta4`:

```kotlin
Generation.getClient(
    GenerationConfig.Builder().apply {
        modelConfig = ModelConfig.builder().apply {
            releaseStage = ModelReleaseStage.PREVIEW   // STABLE = 0, PREVIEW = 1
            preference = ModelPreference.FAST          // FAST = 1, FULL = 2
        }.build()
    }.build(),
)
```

Four combinations, and **no API asks which of them a device serves**. The only way to find out is to
build a client for each and call `checkStatus()` on it. Google's own guidance says as much in one
line: not every device supports every stage and preference, an `UNAVAILABLE` is that variant's
answer rather than the device's, and an app should always implement a fallback strategy.

So the shape that works is a probe, not a configuration:

1. Try **every** variant, not only those before the first success.
2. Keep the first whose `checkStatus()` is anything but `UNAVAILABLE`; close the rest at once, since
   an open client holds an AICore session.
3. **Report which variant answered, which ones served, and which ones refused.**

Step 1 is why the loop does not stop early: **whether the user has a choice of model size is itself
a fact**, and a loop that returns at the first success cannot know it. Step 3 is not a nicety —
without it, "not available on this device" is one sentence covering four different requests, and no
field report can tell them apart. This app prints
`FeatureStatus=0 · refused: stable/full, stable/fast, preview/full, preview/fast` under a refused
row, and `stable/fast · nano-v4-fast · 4096 tok` under a working one.

Re-probing all four costs one round trip each, so it is done on a deliberate refresh — the switch
going on, Settings opening, **Check again** — while a generation trusts the variant already serving.

### Who owns the downloaded model

AICore does, and this is worth being exact about because the obvious next question after a download
is how to remove it.

The model file belongs to the `com.google.android.aicore` system service and is **shared with every
app that asks for the same model**: a second app requesting it does not download it again. An app's
own storage does not grow. And **neither ML Kit client exposes any way to delete one** — `javap` over
`genai-prompt` and `genai-proofreading` shows `download`, `close`, `clearImplicitCaches` and nothing
else; `close()` releases the inference session, not the file.

So an app must not offer a Remove button. It would either do nothing or, if it somehow succeeded,
take away a model another app is using. Point the user at Android's own settings for AICore instead.

`ModelReleaseStage.PREVIEW` is worth trying and worth understanding. It reaches a model only on a
device enrolled in the **AICore developer preview**, and an app cannot enrol a device: nothing it
does will make a preview model appear for an ordinary user. Asking for it costs one status call and
occasionally answers on a developer's own phone, which is why it is last in the order rather than
absent.

Support is therefore best stated as a rule rather than a list: **every variant the installed client
can name, in the order the app prefers them.** A published device list is a dated snapshot; a
`FeatureStatus` answered a second ago is not.

### What a device can be asked once a model is serving

| Call | Shape | Use |
|---|---|---|
| `getBaseModelName()` | `suspend`, `String` | Which model is actually behind the client |
| `getTokenLimit()` | `suspend`, `Int` | The real input budget, rather than the documented one |
| `isThinkingModeAvailable()`, `isSystemPromptAvailable()`, `isStructuredOutputFeatureAvailable()`, `isCachingFeatureAvailable()` | `suspend`, `Boolean` | Per-capability probes added in the beta3/beta4 clients |
| `warmup()` | `suspend` | Pay the load cost before the learner is waiting |

All of them are meaningful only once a variant is serving; on a refusing device they throw. Treat
them as diagnostics to display, never as gates to depend on.

### Reading a failure

`GenAiException.getErrorCode()` returns one of the `GenAiException.ErrorCode` constants, which is a
far better thing to branch on than the English text of `message`:

| Code | Constant | Means |
|---|---|---|
| 8 | `NOT_AVAILABLE` | The feature is not served here |
| 16 | `NOT_SUPPORTED` | The request is not supported by this model |
| -101 | `AICORE_INCOMPATIBLE` | AICore itself cannot serve this device |
| 604 | `NEEDS_SYSTEM_UPDATE` | The system, not the app, is out of date |
| 12 | `REQUEST_TOO_LARGE` | Over the token limit |
| 9 | `BUSY` | Another inference is running |
| 7 | `CANCELLED` | The caller cancelled it |

There is also `com.google.mlkit.genai.common.internal.GenAiUtils.isAiCoreCompatible(context)`. It is
an **internal** API, so guard the call and treat a missing class as "unknown" — but on a device that
refuses every model variant it is the only thing that separates "AICore is absent or too old here"
from "AICore is fine, this model is simply not offered". That distinction is worth an internal call
that is allowed to disappear.

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
implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
```

`genai-prompt` beta4 depends on `kotlin-stdlib` 2.3.21. A project on an older Kotlin Gradle Plugin
(this app is on 2.2.20) still builds, because Kotlin reads metadata from one minor version ahead;
verified by building the app rather than assumed.

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
   at all. A working row instead names the variant and the model serving it. A version line under
   the section names the installed AICore build, the device, and whether AICore reports itself able
   to serve models here. Those facts separate every case below.
2. **Read which model variants were refused.** The Prompt API serves four combinations of release
   stage and size preference, and a device may serve none, one or all of them. The refusal line
   names every one that was tried. Four refusals with `compatible` reported true is a device that
   has AICore and is offered no Prompt model; four refusals with `compatible` false is an AICore
   problem, not a model one. See
   [Choosing a model](#choosing-a-model-release-stage-and-size-preference).
3. **Check the client library version when the message is `FEATURE_NOT_FOUND`.** On a Gemini Nano v4
   device — the Galaxy Z Fold8 family, the Pixel 11 family — any `genai-prompt` older than
   `1.0.0-beta4` throws exactly that from `checkStatus()`. It reads as "this device does not have the
   feature" and means "this client cannot ask this device". Necessary, and — as the Z Fold 8 notes
   below record — not sufficient on its own.
4. **Compare the two features.** They have separate device lists. Explanations use the Prompt API,
   whose list is the narrower one; correction suggestions use Proofreading, whose list is much wider.
   One row ready and the other unavailable is an ordinary answer on hardware that is on one list and
   not the other — and it is why the app never treats "AI" as one switchable thing.
5. **Check the bootloader.** `verifiedbootstate` must be `green` and `flash.locked` must be `1`. An
   unlocked bootloader fails as "unavailable", with no hint that this is the reason.
6. **Give provisioning time and network.** Right after setup, an AICore reset, or an OS update, the
   service can answer `UNAVAILABLE` until it has fetched what it needs, sometimes only after a
   restart. Re-check rather than concluding — this is what the **Check again** button in Settings is
   for, and it re-runs the whole probe.
7. **Check the AICore version against the device.** A manufacturer ships AICore through its own
   update channel, so a phone can be new and its AICore old.
8. **Only then suspect the build.** `logcat -s MyNihongoGenAi` prints every variant tried, every
   status answer and every failure with its exception class. If the failure appears in a release
   build but not a debug one, read [the R8 field note](#field-notes) before anything else.

The app is instrumented for exactly this. `GenAiChannel.status` catches its own exceptions and
answers `unreachable` with the exception class rather than letting them collapse into
`unavailable`; `GenAiChannel.probePrompt` records every variant it tried; and the AICore package
version is read through the manifest's `<queries>` entry. Without that entry the package is
invisible on API 30+ and every device looks like it has no AICore at all.

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
- **Samsung Galaxy Z Fold 8, 2026-09-04: the instrumentation answered the question.** The device
  reports `AICore 0.release.qc.prod_aicore_20260723.00_RC11 · samsung SM-F971U1` — note the `qc`,
  a Qualcomm build — and the two rows now differ:

  | Feature | Status |
  |---|---|
  | Explanations (Prompt) | `GenAiException: [ErrorCode 606] AICore failed with error type 3-PREPARATION_ERROR and error code 606-FEATURE_NOT_FOUND: Feature 636 is not available.` |
  | Correction suggestions (Proofreading) | Ready |

  **This was read wrongly at first, and the correction is the useful part of this note.** The
  original conclusion here was that `FEATURE_NOT_FOUND` is AICore saying the Prompt feature does not
  exist on this device, and that a refusal is the expected answer on non-Pixel hardware. That was
  wrong on both counts.

  The Z Fold 8 **is** a supported Prompt API device: it is on the published nano-v4 list, alongside
  the Z Flip8, the Z Fold8 Ultra and the Pixel 11 family. What the error actually meant is that the
  **client library was too old to talk to a nano-v4 device**. `genai-prompt` `1.0.0-beta4`
  (2026-07-21) is released with the note "fixed compatibility with Gemini Nano v4", naming a
  `GenAiException` from `checkStatus()` as the symptom. The app was pinned to `1.0.0-beta2`.

  Fixed in `v0.3.2` by bumping that one dependency. The Kotlin needed no change, which was checked by
  running `javap` over both AARs rather than assumed. **Not yet confirmed on the device:** this host
  has no Samsung hardware, so what has been verified is that the app builds, not that the row turned
  green.

  Two things worth carrying to another project. **A published device list is evidence about the
  device, not about your client** — the runtime status is the truth, but only once the library is
  current enough to ask the question. And **the plausible explanation is the dangerous one**: "this
  hardware is off the list" fitted every fact available, was written down here as settled, and closed
  the investigation for a day.

- **Pixel 10, `v0.4.1` release build, 2026-09-04: the two devices serve opposite variants, which is
  the whole argument for probing.** The probe reports:

  | Variant | Pixel 10 | Galaxy Z Fold 8 |
  |---|---|---|
  | `stable/full` | **serves** (`nano-v3`) | refused |
  | `stable/fast` | refused | **serves** (`nano-v4-fast`) |
  | `preview/full` | refused | refused |
  | `preview/fast` | refused | refused |

  No fixed choice of variant could have served both phones, and either one alone would have made the
  other look unsupported. That is exactly what happened for two releases.

  Neither device is offered the size switch, because neither serves two sizes.

- **The model outlives the app, which is how you can tell whose it is.** Uninstalling and reinstalling
  the app — which wipes its data and reset the AI switch to off — left the Prompt model
  `AVAILABLE`. AICore had kept it. This is the observation behind the app refusing to offer a Remove
  button.

- **R8 removed a coroutines bridge ML Kit needs, and only the release build noticed.** Tapping
  Download on the Pixel 10 threw

  ```
  java.lang.NoSuchMethodError: No static method cancel$default(
      Lkotlinx/coroutines/Job;Ljava/util/concurrent/CancellationException;
      ILjava/lang/Object;)V in class Lkotlinx/coroutines/Job;
  ```

  from inside `mlkit_genai_prompt`. Kotlin compiles a call that omits a default argument into a
  synthetic static `…$default` bridge; ML Kit's dexed code calls the one on `Job`, this app never
  does, so R8 dropped it. The download still completed — AICore does that work — but the app was told
  it had failed.

  This is the **second** R8 failure in this one feature, after the `LazyInstanceMap` one above, and
  the same lesson applies: keep what the library calls, not what your own code calls. The rule is
  `-keep class kotlinx.coroutines.** { *; }`, kept whole because these bridges are generated and
  there is no published list to enumerate. It costs about 0.2 MB of APK.

- **Samsung Galaxy Z Fold 8, `v0.3.2` installed, 2026-09-04: beta4 was not the fix either.** The
  bump changed the symptom and not the outcome. `checkStatus()` no longer throws; it returns `0`,
  and the row reads "Not available on this device · `FeatureStatus=0`". Proofreading is still Ready.

  **So the second plausible explanation was also wrong.** "The client is too old to ask" fitted the
  `FEATURE_NOT_FOUND` exception exactly, was confirmed by Google's own release note for beta4, and
  was written into this page and into `build.gradle.kts` as settled. It was true and it was not
  sufficient: an old client cannot ask at all, and a current client still asks for only **one** of
  four model variants. `Generation.getClient()` with no configuration requests the stable, full-size
  model, and this device does not serve it.

  What `v0.4.0` does about that is deliberately not a third guess. The app probes every variant,
  keeps the first that answers, and prints the ones that refused — so the next report from this
  device says *which* four requests were made rather than that something was unavailable. If all
  four refuse, that is the honest result and the app names the refusals instead of naming a cause.

  The rule this note exists for: **two wrong diagnoses in a row means the instrumentation is the
  bug.** Both explanations were plausible, evidence-backed, and closed the investigation. Neither
  was falsifiable from the app's own output, and that is the property worth fixing before the next
  theory.

- **Samsung Galaxy Z Fold 8, reported 2026-09-03: AICore installed, both features "not available".**
  Not reproduced here — there is no Samsung device on this host — and recorded because the *shape* of
  the report is the useful part. The causes guessed at here — an unlisted device, or an AICore build
  lagging the phone — were both wrong; the entry above has the measured cause and the fix. What made
  it undiagnosable was
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

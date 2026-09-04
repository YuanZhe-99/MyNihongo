# Pronunciation

Everything in the app that makes or hears sound. Phase 2 of `PLAN.md`. The device's own speech
engines do all the work: **nothing recorded, typed or spoken leaves the device.**

## Text to speech

`flutter_tts` over the platform engine — Android `TextToSpeech`, Apple `AVSpeechSynthesizer`, the
Windows speech platform. The app owns three pieces of engine state and nothing else: the language
(always `ja-JP`), the speaking rate, and the selected voice.

### What speaks

| Where | Button | Text spoken |
|---|---|---|
| Vocabulary detail sheet | beside the level chip | the entry's kana `reading` |
| Kana detail sheet | beside the romaji | the hiragana |
| Kana chart cell and search result | **long-press**, no button | the kana in the script currently shown |
| Every example sentence, in both detail sheets | at the end of the row | the sentence's kana `reading`, falling back to its surface |

**The kana reading is always preferred over the kanji surface.** An engine handed 一日 has to guess
between ついたち and いちにち; handed ついたち it has nothing to guess. Every catalog entry carries a
reading, and every grammar example does, so the fallback to the surface is rare.

### One voice, one utterance

`TtsService.speaking` is a single `ValueNotifier<String?>` holding the text currently playing. Every
button watches it, so the one that is playing shows a stop icon and the rest stay idle. Tapping the
playing button stops it; tapping a different one interrupts and starts the new utterance. There is
one voice on the device, and the UI never implies otherwise.

### Keeping the engine in Japanese

The hardest part of this feature is not choosing a voice. It is that **the Android engine does not
keep the language it was given**, and says nothing when it drops it. `flutter_tts`'s plugin
overwrites the language with the system default in two places:

1. **After its own initialization.** While the platform engine is starting, the plugin queues method
   calls; its init callback replays them and *then* sets the language to the system default voice's
   locale. A `setLanguage('ja-JP')` sent before that point is applied and immediately discarded.
2. **After a silent rebuild.** When the engine's service connection has dropped — routine once the
   app has been in the background — the next `speak` rebuilds the `TextToSpeech` instance, re-queues
   the utterance, and speaks it on a fresh engine that is back on the system default.

Both are invisible from Dart: `isLanguageAvailable` and the voice list still report Japanese, so the
app believed everything was fine while the engine read kana aloud as if it were English. It showed up
as words being mispronounced while grammar example sentences were fine — the difference was only
which screen had been opened first — and it went away after visiting Settings, because choosing a
voice there set one explicitly.

Three things fix it, all in `TtsService`:

- **A probe before the first write.** `init` awaits `isLanguageAvailable` and throws the answer away.
  Any queued call would do; the point is that awaiting one means the plugin's overwrite has already
  happened, so the `setLanguage` after it sticks.
- **Re-applying before every utterance.** `speak` sets the language, the voice and the rate again
  each time. Three engine calls cost milliseconds, and there is no event to listen for instead.
- **Selecting a voice, not only a language.** The app always names a specific Japanese voice — the
  one chosen in Settings, or the best available — so the engine cannot fall back to whatever voice it
  was last left on.

If Japanese is refused anyway and it worked earlier in the same run, `speak` rebuilds the engine once
through `setEngine` and re-applies everything. A device that never had Japanese never pays for that.

### Speed, voice and engine

Settings → Speech. The speed slider runs 0.6x to 1.2x in steps of 0.1 with a preview button that
speaks a fixed greeting.

The **Japanese voice** row opens a picker sheet, shown when the engine offers more than one Japanese
voice. Engine voice names are identifiers — `ja-jp-x-jab#male_1-local` — that say nothing about how a
voice sounds and differ between engines, so the sheet numbers them instead: "Japanese voice 1, 2,
3", ordered installed before missing, offline before network, then by the quality the engine claims,
then by name so the order is total and the numbers do not move between runs. Each row says what is
different about that voice, shows its raw name in a smaller line for a bug report, and carries a play
button. **Listening is not choosing:** the sample plays through `TtsService.preview`, which restores
the learner's own voice in a `finally`.

The **Speech engine** row appears only when the device has more than one engine installed, which is
common on Android — the Google engine and the manufacturer's, with different voices. Known engines
show a brand name; anything else shows its package name, which is still the truth. Switching engines
rebuilds the platform engine and discards the chosen voice, because a voice name from one engine
names nothing on another.

All three are device-local preferences in `storage_config.json` (`ttsRate`, `ttsVoice`, `ttsEngine`):
a phone speaker and a desktop speaker want different speeds, and neither a voice name nor an engine
package means anything on another device.

`flutter_tts` treats **0.5 as normal speed on every platform it supports**, so `TtsService.engineRate`
multiplies the user-facing value by 0.5 and there is no platform branch. A voice name that no longer
resolves — the voice was uninstalled, or the engine was switched — falls back to the best available
Japanese voice rather than to the engine default, which may not be Japanese at all.

### When there is no Japanese voice

Common, and not an error: a stock Windows install has none, and an Android device may have an engine
without the Japanese data. Then

- every speak button is **disabled rather than hidden**, with the reason in its tooltip — a button
  that vanished would look like a feature that does not exist, and this is a device state the user
  can fix;
- Settings → Speech replaces the speed, voice and engine rows with an explanation, plus a button that opens
  the system speech settings on Android (the `com.android.settings.TTS_SETTINGS` intent, through the
  app's one method channel) and Windows (`ms-settings:speech`). Apple platforms have no documented
  deep link, so the text names the settings pane instead.

Android 11+ package visibility means the manifest has to declare an `android.intent.action.TTS_SERVICE`
query, or the engine is invisible and the app reports no voices at all.

## Speech recognition

`speech_to_text` over the platform recognizer — Android's `SpeechRecognizer`, Apple's
`SFSpeechRecognizer`, the Windows speech platform. Linux has none behind the plugin, so
`platformMayRecognizeSpeech` refuses there before anything asks for a microphone.

### On the device, by default

Every listening request is made with `onDevice: true` unless the learner has turned on
**Settings › Speech › Allow network recognition**. On Android that maps to `EXTRA_PREFER_OFFLINE`,
which is offline-**only**: on a device with no Japanese model downloaded the attempt fails rather
than quietly going to a server. That failure is reported as `languageUnavailable`, and the practice
sheet turns it into a message naming both fixes — install the Japanese speech data, or turn the
fallback on knowingly.

The switch is the only setting in the app besides WebDAV sync that lets anything leave the device,
and its subtitle says exactly that. It is off by default and stored as an absent key
(`speechNetworkFallback`), so a device that never touched it never sends audio anywhere.

### The microphone

`RECORD_AUDIO` is declared in the manifest but requested at **first use**, never at install: the
practice sheet shows its own rationale dialog before the first `initialize()` when the permission is
not already granted, so the system prompt never arrives unexplained.

That promise had a hole until it was tried on a real phone. Settings → Speech asked the recognizer
whether it was available as soon as the page was built, and asking means `initialize()`, which is
what raises the system prompt — so **opening Settings produced a microphone dialog out of nowhere**.
It now checks the permission first and only initializes when it has already been granted; without
it, the status line says the check happens the first time you practise, which is true and is not the
same claim as "this device has no recognizer". `test/speech_settings_tiles_test.dart` holds it,
asserting that the backend is never initialized while the permission is absent. iOS and macOS carry
`NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`; the macOS sandbox needs
`com.apple.security.device.audio-input` in both entitlement files. Android 11+ package visibility
needs an `android.speech.RecognitionService` query, alongside the text-to-speech one.

No audio is recorded to a file, and nothing is stored. The recognizer's text is compared and then
forgotten when the sheet closes.

### The practice sheet

Opened from the microphone button on the vocabulary and kana detail sheets, and from **Practise** in
each example row's overflow menu. One column at every window size; it holds a target line with a
speak button, a record button, the mora chips and a legend.

| State | What is shown |
|---|---|
| idle | "Tap to speak" |
| listening | a stop button and the partial transcript, live |
| processing | the button disabled while the recognizer settles |
| done | the mora diff, then the score, then what was heard |
| failed | one sentence naming the cause and what to do about it |

The **diff is the primary output** and the score is a summary of the same alignment; a perfect
attempt gets a sentence rather than "100 of 100". Colour never carries meaning alone — the legend
names all four states, a missing mora is struck through, and a substitution shows both what the item
says and what was heard. The algorithm is in
[`../algorithms/pronunciation-scoring.md`](../algorithms/pronunciation-scoring.md).

The sheet states plainly that it judges whether you were **recognisable**, not your accent or pitch.

### Not built

Own-voice recording and playback (`record` + `just_audio`) are deferred: they need the microphone at
the same time as the recognizer, which cannot be verified without a device. See `PLAN.md` M2.2.

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

### Speed and voice

Settings → Speech. The speed slider runs 0.6x to 1.2x in steps of 0.1 with a preview button that
speaks a fixed greeting, and the voice dropdown lists the installed Japanese voices (it is hidden
when the engine offers fewer than two). Both are device-local preferences in `storage_config.json`
(`ttsRate`, `ttsVoice`), because a phone speaker and a desktop speaker want different speeds and a
voice name means nothing on another device's engine.

`flutter_tts` treats **0.5 as normal speed on every platform it supports**, so `TtsService.engineRate`
multiplies the user-facing value by 0.5 and there is no platform branch. A voice name that no longer
resolves — the voice was uninstalled between runs — falls back to the engine default rather than
failing.

### When there is no Japanese voice

Common, and not an error: a stock Windows install has none, and an Android device may have an engine
without the Japanese data. Then

- every speak button is **disabled rather than hidden**, with the reason in its tooltip — a button
  that vanished would look like a feature that does not exist, and this is a device state the user
  can fix;
- Settings → Speech replaces the speed and voice rows with an explanation, plus a button that opens
  the system speech settings on Android (the `com.android.settings.TTS_SETTINGS` intent, through the
  app's one method channel) and Windows (`ms-settings:speech`). Apple platforms have no documented
  deep link, so the text names the settings pane instead.

Android 11+ package visibility means the manifest has to declare an `android.intent.action.TTS_SERVICE`
query, or the engine is invisible and the app reports no voices at all.

## Speech recognition

Not built yet — `PLAN.md` M2.2. This page grows a section when it lands, and the privacy policy is
updated in the same change.

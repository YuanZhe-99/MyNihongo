import 'package:flutter/foundation.dart';

import 'tts_backend.dart';

/// Speaks Japanese through the device's own text-to-speech engine.
///
/// One instance for the whole app ([instance]), so there is a single answer to
/// "what is speaking right now" and a single place that owns the engine's
/// language, rate and voice. Nothing here leaves the device: the platform
/// engine renders the audio locally. See
/// `doc/en-us/features/pronunciation.md`.
class TtsService {
  TtsService(this._backend);

  /// The app-wide instance.
  static TtsService instance = TtsService(FlutterTtsBackend());

  /// Purpose: Replace the app-wide instance in a test.
  /// Inputs: `service`.
  /// Returns: None.
  /// Side effects: Rebinds [instance].
  /// Notes: Only tests call this; a real build constructs the engine-backed
  /// instance once at startup.
  @visibleForTesting
  static void setInstanceForTesting(TtsService service) => instance = service;

  /// The language every utterance is spoken in.
  static const languageTag = 'ja-JP';

  /// The slowest and fastest speaking rates the user can choose.
  static const minRate = 0.6;
  static const maxRate = 1.2;

  final TtsBackend _backend;

  /// The text currently being spoken, or null. Buttons watch this so exactly
  /// one of them can show its stop icon.
  final ValueNotifier<String?> speaking = ValueNotifier<String?>(null);

  bool _initialized = false;
  bool _hasJapaneseVoice = false;
  List<Map<String, String>> _japaneseVoices = const [];
  double _rate = 1.0;
  String? _voiceName;

  /// Whether the engine reported a Japanese voice. False until [init] runs.
  bool get hasJapaneseVoice => _hasJapaneseVoice;

  /// The Japanese voices the engine offers, newest query first.
  List<Map<String, String>> get japaneseVoices => _japaneseVoices;

  /// The user-facing rate multiple: 1.0 is the engine's normal speed.
  double get rate => _rate;

  /// The selected voice's name, or null for the engine default.
  String? get voiceName => _voiceName;

  /// Purpose: Convert a user-facing rate multiple to the engine's units.
  /// Inputs: `userRate` — 1.0 meaning normal speed.
  /// Returns: `double` for [TtsBackend.setSpeechRate].
  /// Side effects: None.
  /// Notes: `flutter_tts` treats **0.5 as normal on every platform** it
  /// supports — Android doubles the value before handing it to
  /// `TextToSpeech`, Apple's `AVSpeechSynthesizer` default is 0.5, and the
  /// Windows backend adds 0.5 to reach a WinRT `SpeakingRate` of 1.0. One
  /// mapping therefore serves all of them, and a platform branch here would be
  /// wrong rather than merely unnecessary.
  static double engineRate(double userRate) => userRate * 0.5;

  /// Purpose: Prepare the engine and learn what it can do.
  /// Inputs: `rate`, `voiceName` — the persisted preferences, if any.
  /// Returns: None.
  /// Side effects: Sets the engine language, rate and voice; queries voices.
  /// Notes: Runs at most once; later calls only apply preferences. Every call
  /// is guarded, because a device without a speech engine throws from the
  /// platform channel rather than answering false, and a failure here must not
  /// stop the app from starting.
  Future<void> init({double? rate, String? voiceName}) async {
    if (rate != null) _rate = rate.clamp(minRate, maxRate);
    if (!_initialized) {
      _initialized = true;
      try {
        await _backend.setLanguage(languageTag);
        _hasJapaneseVoice = await _backend.isLanguageAvailable(languageTag);
        final all = await _backend.voices();
        _japaneseVoices = [
          for (final voice in all)
            if (_isJapanese(voice)) voice,
        ];
        if (_japaneseVoices.isNotEmpty) _hasJapaneseVoice = true;
      } catch (_) {
        _hasJapaneseVoice = false;
        _japaneseVoices = const [];
      }
    }
    await setRate(_rate);
    if (voiceName != null) await setVoiceByName(voiceName);
  }

  /// Purpose: Change the speaking rate.
  /// Inputs: `userRate` — clamped to [minRate]…[maxRate].
  /// Returns: None.
  /// Side effects: Changes engine state.
  /// Notes: Persisting the choice is the caller's job; this only applies it.
  Future<void> setRate(double userRate) async {
    _rate = userRate.clamp(minRate, maxRate);
    try {
      await _backend.setSpeechRate(engineRate(_rate));
    } catch (_) {}
  }

  /// Purpose: Select a Japanese voice by its engine name.
  /// Inputs: `name` — null or an unknown name resets to the engine default.
  /// Returns: None.
  /// Side effects: Changes engine state.
  /// Notes: An unknown name is not an error: a voice can be uninstalled
  /// between runs, and the engine default is always a valid answer.
  Future<void> setVoiceByName(String? name) async {
    if (name == null) {
      _voiceName = null;
      return;
    }
    final match = _japaneseVoices
        .where((voice) => voice['name'] == name)
        .firstOrNull;
    if (match == null) {
      _voiceName = null;
      return;
    }
    _voiceName = name;
    try {
      await _backend.setVoice({
        'name': match['name'] ?? '',
        'locale': match['locale'] ?? languageTag,
      });
    } catch (_) {}
  }

  /// Purpose: Speak one piece of Japanese.
  /// Inputs: `text` — kana where the caller has it; see the note.
  /// Returns: None.
  /// Side effects: Stops any current utterance, produces audio, and updates
  /// [speaking] while the audio plays.
  /// Notes: Callers pass the kana `reading` rather than the kanji surface
  /// wherever the catalog has one, so the engine cannot pick the wrong reading
  /// of a kanji. Tapping the same button twice stops rather than repeats, and
  /// tapping a second button interrupts the first — one voice, one utterance.
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final wasSpeaking = speaking.value;
    await stop();
    if (wasSpeaking == trimmed) return;
    speaking.value = trimmed;
    try {
      await _backend.speak(trimmed);
    } catch (_) {
    } finally {
      if (speaking.value == trimmed) speaking.value = null;
    }
  }

  /// Purpose: Stop the current utterance.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Silences the engine and clears [speaking].
  /// Notes: Safe when nothing is speaking.
  Future<void> stop() async {
    if (speaking.value == null) return;
    speaking.value = null;
    try {
      await _backend.stop();
    } catch (_) {}
  }

  /// Purpose: Decide whether a voice map describes a Japanese voice.
  /// Inputs: `voice`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Locales arrive in
  /// several shapes — `ja-JP`, `ja_JP`, plain `ja` — so the test is on the
  /// language subtag rather than on the whole string.
  static bool _isJapanese(Map<String, String> voice) {
    final locale = voice['locale'] ?? '';
    return locale == 'ja' ||
        locale.startsWith('ja-') ||
        locale.startsWith('ja_');
  }
}

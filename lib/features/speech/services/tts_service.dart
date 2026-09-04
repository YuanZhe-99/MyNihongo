import 'package:flutter/foundation.dart';

import '../models/voice_ordering.dart';
import 'tts_backend.dart';

/// Speaks Japanese through the device's own text-to-speech engine.
///
/// One instance for the whole app ([instance]), so there is a single answer to
/// "what is speaking right now" and a single place that owns the engine
/// choice, language, rate and voice. Nothing here leaves the device: the
/// platform engine renders the audio locally. See
/// `doc/en-us/features/pronunciation.md`.
///
/// **The engine does not keep the language it was given.** `flutter_tts`'s
/// Android plugin overwrites it with the system default in two places — after
/// its own initialization, and again whenever it silently rebuilds the
/// `TextToSpeech` instance because the service connection dropped. Both are
/// invisible from Dart. Everything about how this class applies state exists
/// for that: see [init] for the ordering and [speak] for the repair.
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
  bool _japaneseSeen = false;
  bool _recovering = false;
  List<Map<String, String>> _japaneseVoices = const [];
  List<String> _engines = const [];
  String? _engineId;
  Map<String, String>? _defaultVoice;
  double _rate = 1.0;
  String? _voiceName;

  /// Whether Japanese is actually reachable on this engine. False until [init]
  /// runs, and re-evaluated before every utterance.
  bool get hasJapaneseVoice => _hasJapaneseVoice;

  /// The Japanese voices the engine offers, best first.
  List<Map<String, String>> get japaneseVoices => _japaneseVoices;

  /// The speech engines installed on the device; empty off Android.
  List<String> get engines => _engines;

  /// The chosen engine's package name, or null for the system default.
  String? get engineId => _engineId;

  /// The user-facing rate multiple: 1.0 is the engine's normal speed.
  double get rate => _rate;

  /// The selected voice's name, or null when the best voice is chosen for the
  /// user.
  String? get voiceName => _voiceName;

  /// The voice used when the user has not chosen one, so the UI can name it.
  Map<String, String>? get defaultJapaneseVoice => _defaultVoice;

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
  /// Inputs: `rate`, `voiceName`, `engineId` — the persisted preferences.
  /// Returns: None.
  /// Side effects: May switch engines; queries voices; sets language, voice and
  /// rate.
  /// Notes: The **order is load-bearing.** `isLanguageAvailable` is awaited
  /// before anything is set, purely as a probe: while the platform engine is
  /// still starting, the plugin queues method calls and replays them from its
  /// init callback — and then overwrites the language with the system default.
  /// A `setLanguage` sent before that point is therefore applied and
  /// immediately discarded, which left the engine reading Japanese aloud in the
  /// device's own language. Awaiting any queued call first means the overwrite
  /// has already happened. Every call is guarded, because a device without a
  /// speech engine throws from the platform channel rather than answering
  /// false, and a failure here must not stop the app from starting.
  Future<void> init({double? rate, String? voiceName, String? engineId}) async {
    if (rate != null) _rate = rate.clamp(minRate, maxRate);
    if (!_initialized) {
      _initialized = true;
      try {
        _engines = await _backend.engines();
        if (engineId != null && _engines.contains(engineId)) {
          _engineId = engineId;
          await _backend.setEngine(engineId);
        }
        // The probe. Its value is not used; awaiting it is the point.
        await _backend.isLanguageAvailable(languageTag);
        await _loadVoices();
      } catch (_) {
        _japaneseVoices = const [];
        _defaultVoice = null;
      }
    }
    if (voiceName != null) _voiceName = _resolveVoiceName(voiceName);
    await _applyEngineState();
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
  /// Inputs: `name` — null or an unknown name returns to the best voice.
  /// Returns: None.
  /// Side effects: Changes engine state.
  /// Notes: An unknown name is not an error: a voice can be uninstalled
  /// between runs, or belong to an engine the user has since switched away
  /// from. Falling back to the best Japanese voice is a better answer than the
  /// engine default, which may not be Japanese at all.
  Future<void> setVoiceByName(String? name) async {
    _voiceName = name == null ? null : _resolveVoiceName(name);
    await _applyEngineState();
  }

  /// Purpose: Switch to another speech engine.
  /// Inputs: `engine` — a package name from [engines], or null for the system
  /// default.
  /// Returns: None.
  /// Side effects: Rebuilds the platform engine, re-reads its voices, and
  /// clears the chosen voice.
  /// Notes: Voice names belong to an engine, so the choice cannot survive the
  /// switch; the best voice of the new engine is used until the user picks
  /// again. Persisting is the caller's job.
  Future<void> setEngine(String? engine) async {
    _engineId = engine;
    _voiceName = null;
    try {
      final target = engine ?? await _backend.defaultEngine();
      if (target != null) await _backend.setEngine(target);
      await _loadVoices();
    } catch (_) {}
    await _applyEngineState();
  }

  /// Purpose: Speak one piece of Japanese.
  /// Inputs: `text` — kana where the caller has it; see the note.
  /// Returns: None.
  /// Side effects: Stops any current utterance, re-applies the engine state,
  /// produces audio, and updates [speaking] while the audio plays.
  /// Notes: Callers pass the kana `reading` rather than the kanji surface
  /// wherever the catalog has one, so the engine cannot pick the wrong reading
  /// of a kanji. Tapping the same button twice stops rather than repeats, and
  /// tapping a second button interrupts the first — one voice, one utterance.
  /// The language, voice and rate are re-applied **before every utterance**,
  /// because the plugin rebuilds its `TextToSpeech` instance behind our back
  /// when the service connection drops — after which the engine is back on the
  /// system default language and reads Japanese as if it were English. Three
  /// engine calls cost milliseconds; the alternative is a wrong voice with no
  /// symptom the app can see.
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final wasSpeaking = speaking.value;
    await stop();
    if (wasSpeaking == trimmed) return;

    final ready = await _applyEngineState();
    if (!ready && _japaneseSeen) await _recoverEngine();

    speaking.value = trimmed;
    try {
      await _backend.speak(trimmed);
    } catch (_) {
    } finally {
      if (speaking.value == trimmed) speaking.value = null;
    }
  }

  /// Purpose: Speak a sample with one voice without selecting it.
  /// Inputs: `voice` — a map from [japaneseVoices]; `text` — the sample.
  /// Returns: None.
  /// Side effects: Produces audio, then restores the user's own engine state.
  /// Notes: The restore is in a `finally`, so a voice that fails mid-sample
  /// cannot leave the app speaking with it. This is what makes the picker
  /// auditionable: hearing a voice must not be the same act as choosing it.
  Future<void> preview(Map<String, String> voice, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await stop();
    try {
      await _backend.setLanguage(languageTag);
      await _backend.setVoice({
        'name': voice['name'] ?? '',
        'locale': voice['locale'] ?? languageTag,
      });
      await _backend.setSpeechRate(engineRate(_rate));
      speaking.value = trimmed;
      await _backend.speak(trimmed);
    } catch (_) {
    } finally {
      if (speaking.value == trimmed) speaking.value = null;
      await _applyEngineState();
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

  /// Purpose: Read the engine's voice list and keep the Japanese ones.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Replaces [japaneseVoices] and the default voice.
  /// Notes: Internal helper used within this file only. Sorted best-first so
  /// the picker can number them and the default is simply the first installed
  /// one.
  Future<void> _loadVoices() async {
    final all = await _backend.voices();
    _japaneseVoices = sortJapaneseVoices([
      for (final voice in all)
        if (_isJapanese(voice)) voice,
    ]);
    _defaultVoice = _japaneseVoices
        .where((voice) => !voiceIsNotInstalled(voice))
        .firstOrNull;
  }

  /// Purpose: Push the language, voice and rate the app wants onto the engine.
  /// Inputs: None.
  /// Returns: `Future<bool>` — whether Japanese was actually accepted.
  /// Side effects: Changes engine state; updates [hasJapaneseVoice].
  /// Notes: Internal helper used within this file only. Either the language or
  /// a Japanese voice being accepted is enough: an engine can refuse `ja-JP` as
  /// a locale and still hold a Japanese voice, and the reverse happens on
  /// desktop engines that enumerate no voices at all. Selecting the best voice
  /// explicitly — not only the language — is what stops the engine from
  /// falling back to whatever voice it was last left on.
  Future<bool> _applyEngineState() async {
    var reachable = false;
    try {
      reachable = await _backend.setLanguage(languageTag);
    } catch (_) {}
    final voice = _chosenVoice() ?? _defaultVoice;
    if (voice != null) {
      try {
        final accepted = await _backend.setVoice({
          'name': voice['name'] ?? '',
          'locale': voice['locale'] ?? languageTag,
        });
        if (accepted) reachable = true;
      } catch (_) {}
    }
    try {
      await _backend.setSpeechRate(engineRate(_rate));
    } catch (_) {}
    _hasJapaneseVoice = reachable;
    if (reachable) _japaneseSeen = true;
    return reachable;
  }

  /// Purpose: Rebuild an engine that has stopped accepting Japanese.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds the platform engine and re-applies every setting.
  /// Notes: Internal helper used within this file only. Only reached when
  /// Japanese worked earlier in this run, so a device that simply has none
  /// never pays for an engine rebuild. Re-entrancy is blocked, so one utterance
  /// triggers at most one rebuild.
  Future<void> _recoverEngine() async {
    if (_recovering) return;
    _recovering = true;
    try {
      final engine = _engineId ?? await _backend.defaultEngine();
      if (engine == null) return;
      if (!await _backend.setEngine(engine)) return;
      await _loadVoices();
      await _applyEngineState();
    } catch (_) {
    } finally {
      _recovering = false;
    }
  }

  /// Purpose: Find the voice map behind the chosen voice name.
  /// Inputs: None.
  /// Returns: `Map<String, String>?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Map<String, String>? _chosenVoice() {
    final name = _voiceName;
    if (name == null) return null;
    return _japaneseVoices.where((voice) => voice['name'] == name).firstOrNull;
  }

  /// Purpose: Keep a voice name only when this engine still offers it.
  /// Inputs: `name`.
  /// Returns: `String?` — the name, or null when it no longer resolves.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String? _resolveVoiceName(String name) =>
      _japaneseVoices.any((voice) => voice['name'] == name) ? name : null;

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

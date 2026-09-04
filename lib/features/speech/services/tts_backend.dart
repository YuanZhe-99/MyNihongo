import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// The seam between [TtsService] and the platform speech engine.
///
/// Only the calls this app makes are declared. The interface exists so tests
/// can drive the service without a platform channel: a `flutter_test` run has
/// no TTS engine, and the interesting behaviour (preferring the kana reading,
/// stopping before speaking again, filtering voices to Japanese) is all on
/// this side of the seam.
abstract class TtsBackend {
  /// Purpose: Set the language every later utterance is spoken in.
  /// Inputs: `language` — a BCP-47 tag such as `ja-JP`.
  /// Returns: `Future<bool>` — false when the engine rejects the language.
  /// Side effects: Changes engine state.
  /// Notes: None.
  Future<bool> setLanguage(String language);

  /// Purpose: Report whether the engine can speak a language.
  /// Inputs: `language`.
  /// Returns: `Future<bool>`.
  /// Side effects: None.
  /// Notes: On Android this answers for an installed voice; on Windows it
  /// answers for a voice the speech platform knows about.
  Future<bool> isLanguageAvailable(String language);

  /// Purpose: Set the engine speaking rate.
  /// Inputs: `rate` — in the engine's own units, not the user-facing multiple.
  /// Returns: None.
  /// Side effects: Changes engine state.
  /// Notes: [TtsService.engineRate] does the conversion.
  Future<void> setSpeechRate(double rate);

  /// Purpose: List the voices the engine offers.
  /// Inputs: None.
  /// Returns: `Future<List<Map<String, String>>>` — each with at least `name`
  /// and `locale`; an empty list when the engine cannot enumerate voices.
  /// Side effects: None.
  /// Notes: The plugin returns loosely typed maps; the implementation
  /// normalises them so the rest of the app never sees `dynamic`.
  Future<List<Map<String, String>>> voices();

  /// Purpose: Select a voice by name and locale.
  /// Inputs: `voice` — a map from [voices].
  /// Returns: `Future<bool>` — whether the engine accepted the voice.
  /// Side effects: Changes engine state.
  /// Notes: The answer is load-bearing: an engine that rejects the voice keeps
  /// speaking in whatever language it was left in, and [TtsService] uses this
  /// to decide whether Japanese is actually reachable.
  Future<bool> setVoice(Map<String, String> voice);

  /// Purpose: List the speech engines installed on the device.
  /// Inputs: None.
  /// Returns: `Future<List<String>>` — engine package names; empty where the
  /// platform has no concept of selectable engines.
  /// Side effects: None.
  /// Notes: Android only in practice. A phone often has two — the Google
  /// engine and the manufacturer's — and they do not have the same voices.
  Future<List<String>> engines();

  /// Purpose: Name the engine the system would use by default.
  /// Inputs: None.
  /// Returns: `Future<String?>` — a package name, or null when unknown.
  /// Side effects: None.
  /// Notes: None.
  Future<String?> defaultEngine();

  /// Purpose: Switch to another speech engine.
  /// Inputs: `engine` — a package name from [engines].
  /// Returns: `Future<bool>` — whether the engine initialized.
  /// Side effects: Rebuilds the platform engine; every piece of engine state
  /// (language, voice, rate) is lost and must be re-applied.
  /// Notes: The plugin resolves this only after the new engine's init callback
  /// has run, which is why awaiting it is what makes re-applying safe.
  Future<bool> setEngine(String engine);

  /// Purpose: Speak a string and complete when the utterance finishes.
  /// Inputs: `text`.
  /// Returns: None.
  /// Side effects: Produces audio.
  /// Notes: The implementation turns on `awaitSpeakCompletion` so a caller can
  /// tell when the audio stopped; without it the future returns immediately
  /// and the UI would clear its speaking state while sound is still playing.
  Future<void> speak(String text);

  /// Purpose: Stop whatever is currently being spoken.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Silences the engine.
  /// Notes: Safe to call when nothing is speaking.
  Future<void> stop();
}

/// The real backend, wrapping `flutter_tts`.
class FlutterTtsBackend implements TtsBackend {
  FlutterTtsBackend([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    // Fire and forget, and deliberately swallow the failure: a `flutter_test`
    // run has no plugin behind the channel and answers
    // `MissingPluginException`, which would otherwise surface as an unhandled
    // asynchronous error in every test that happens to build the app.
    unawaited(_tts.awaitSpeakCompletion(true).catchError((Object _) => null));
  }

  final FlutterTts _tts;

  /// Purpose: Set the engine language.
  /// Inputs: `language`.
  /// Returns: `Future<bool>` — the engine's own answer, or false when it
  /// returns something that is not a boolean.
  /// Side effects: Changes engine state.
  /// Notes: The plugin returns `dynamic`; Android answers `1`/`0` and the
  /// desktop backends answer a bool, so both shapes are accepted.
  @override
  Future<bool> setLanguage(String language) async =>
      _asBool(await _tts.setLanguage(language));

  /// Purpose: Ask whether a language can be spoken.
  /// Inputs: `language`.
  /// Returns: `Future<bool>`.
  /// Side effects: None.
  /// Notes: Same loose return typing as [setLanguage].
  @override
  Future<bool> isLanguageAvailable(String language) async =>
      _asBool(await _tts.isLanguageAvailable(language));

  /// Purpose: Set the engine rate.
  /// Inputs: `rate` in engine units.
  /// Returns: None.
  /// Side effects: Changes engine state.
  /// Notes: None.
  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  /// Purpose: List the engine's voices as string maps.
  /// Inputs: None.
  /// Returns: `Future<List<Map<String, String>>>`; empty when unsupported.
  /// Side effects: None.
  /// Notes: Every value is stringified, because Android returns booleans for
  /// `network_required` and Windows returns a gender enum.
  @override
  Future<List<Map<String, String>>> voices() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    return [
      for (final voice in raw)
        if (voice is Map)
          {
            for (final entry in voice.entries)
              entry.key.toString(): entry.value.toString(),
          },
    ];
  }

  /// Purpose: Select a voice.
  /// Inputs: `voice`.
  /// Returns: `Future<bool>` — the engine's own answer.
  /// Side effects: Changes engine state.
  /// Notes: Android answers `1` when it found a voice with that exact name and
  /// locale, `0` when it did not; the same loose typing as [setLanguage].
  @override
  Future<bool> setVoice(Map<String, String> voice) async =>
      _asBool(await _tts.setVoice(voice));

  /// Purpose: List the installed speech engines.
  /// Inputs: None.
  /// Returns: `Future<List<String>>`; empty on a platform without engines or
  /// when the query fails.
  /// Side effects: None.
  /// Notes: `getEngines` exists only on the Android side of the plugin and
  /// throws elsewhere, so the failure is swallowed rather than branched on
  /// `defaultTargetPlatform` — the empty list is the same answer either way.
  @override
  Future<List<String>> engines() async {
    try {
      final raw = await _tts.getEngines;
      if (raw is! List) return const [];
      return [for (final engine in raw) engine.toString()];
    } catch (_) {
      return const [];
    }
  }

  /// Purpose: Name the system's default speech engine.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: Same platform caveat as [engines].
  @override
  Future<String?> defaultEngine() async {
    try {
      final raw = await _tts.getDefaultEngine;
      return raw is String && raw.isNotEmpty ? raw : null;
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Switch the platform engine.
  /// Inputs: `engine`.
  /// Returns: `Future<bool>`.
  /// Side effects: Rebuilds the platform engine.
  /// Notes: The plugin's `setEngine` completes from the new engine's init
  /// callback, so a caller that awaits it knows the engine is ready — and
  /// knows its own language and voice were discarded.
  @override
  Future<bool> setEngine(String engine) async {
    try {
      await _tts.setEngine(engine);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Purpose: Speak text, completing when the audio ends.
  /// Inputs: `text`.
  /// Returns: None.
  /// Side effects: Produces audio.
  /// Notes: None.
  @override
  Future<void> speak(String text) => _tts.speak(text);

  /// Purpose: Stop the engine.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Silences the engine.
  /// Notes: None.
  @override
  Future<void> stop() => _tts.stop();

  /// Purpose: Read the plugin's loosely typed truthy answers.
  /// Inputs: `value` — whatever the platform channel returned.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Android answers with
  /// `1`/`0`, the desktop backends with a bool, and a failed call with null.
  static bool _asBool(Object? value) =>
      value == true || value == 1 || value == '1' || value == 'true';
}

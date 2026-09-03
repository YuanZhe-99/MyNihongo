import 'package:speech_to_text/speech_to_text.dart';

/// One recognition result handed back to the service.
class SpeechHeard {
  const SpeechHeard({required this.text, required this.isFinal});

  /// What the recognizer believes it heard, in its own script.
  final String text;

  /// Whether this is the recognizer's final answer for this session.
  final bool isFinal;
}

/// Why a listening session ended badly.
enum SpeechFailure {
  /// The recognizer exists but heard nothing it could transcribe.
  noMatch,

  /// The device has no offline Japanese model and offline was required.
  languageUnavailable,

  /// The user declined the microphone, or the system did.
  permissionDenied,

  /// No recognizer on this device, or it failed to start.
  unavailable,
}

/// The seam between [SpeechRecognitionService] and the platform recognizer.
///
/// It exists for the same reason the text-to-speech seam does: a
/// `flutter_test` run has no recognizer, and the parts worth testing — the
/// state machine, the on-device policy, the permission gate — are all on the
/// service's side of it.
abstract class SpeechBackend {
  /// Purpose: Start the recognizer and report whether it can be used.
  /// Inputs: `onFailure` — called for errors that arrive asynchronously.
  /// Returns: `Future<bool>`.
  /// Side effects: May prompt for the microphone permission.
  /// Notes: Called once per app run; a false answer is remembered.
  Future<bool> initialize({required void Function(SpeechFailure) onFailure});

  /// Purpose: Report whether the microphone permission is already granted.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: None.
  /// Notes: Used to decide whether the first-use rationale is still needed.
  Future<bool> hasPermission();

  /// Purpose: List the locale ids the recognizer supports.
  /// Inputs: None.
  /// Returns: `Future<List<String>>` — ids as the platform spells them
  /// (`ja_JP` on Android, `ja-JP` on Apple).
  /// Side effects: None.
  /// Notes: None.
  Future<List<String>> localeIds();

  /// Purpose: Listen for one utterance.
  /// Inputs: `localeId`, `onDevice`, and `onHeard` for partial and final
  /// results.
  /// Returns: None.
  /// Side effects: Opens the microphone.
  /// Notes: `onDevice` true means offline-only: where the device has no
  /// offline model the attempt fails rather than quietly going to a server.
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(SpeechHeard) onHeard,
  });

  /// Purpose: Stop listening and keep whatever was recognized.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: None.
  Future<void> stop();

  /// Purpose: Stop listening and discard the result.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: None.
  Future<void> cancel();
}

/// The real backend, wrapping `speech_to_text`.
class SpeechToTextBackend implements SpeechBackend {
  SpeechToTextBackend([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  /// Purpose: Start the recognizer.
  /// Inputs: `onFailure`.
  /// Returns: `Future<bool>`.
  /// Side effects: May prompt for the microphone permission.
  /// Notes: The plugin reports errors through a callback rather than by
  /// throwing, so the mapping from its error ids to [SpeechFailure] lives
  /// here, next to the plugin that produces them.
  @override
  Future<bool> initialize({
    required void Function(SpeechFailure) onFailure,
  }) async {
    try {
      return await _speech.initialize(
        onError: (error) => onFailure(_mapError(error.errorMsg)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Purpose: Report whether the microphone permission is granted.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: None.
  /// Notes: False on a platform that does not gate the microphone.
  @override
  Future<bool> hasPermission() async {
    try {
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// Purpose: List supported locale ids.
  /// Inputs: None.
  /// Returns: `Future<List<String>>`; empty when the recognizer cannot answer.
  /// Side effects: None.
  /// Notes: None.
  @override
  Future<List<String>> localeIds() async {
    try {
      final locales = await _speech.locales();
      return [for (final locale in locales) locale.localeId];
    } catch (_) {
      return const [];
    }
  }

  /// Purpose: Listen for one utterance.
  /// Inputs: `localeId`, `onDevice`, `onHeard`.
  /// Returns: None.
  /// Side effects: Opens the microphone.
  /// Notes: `listenFor` bounds a session at eight seconds and `pauseFor` ends
  /// it two seconds after the learner stops — a single word or sentence is
  /// what is being practised, not dictation.
  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(SpeechHeard) onHeard,
  }) async {
    await _speech.listen(
      onResult: (result) => onHeard(
        SpeechHeard(text: result.recognizedWords, isFinal: result.finalResult),
      ),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        onDevice: onDevice,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  /// Purpose: Stop listening, keeping the result.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: None.
  @override
  Future<void> stop() => _speech.stop();

  /// Purpose: Stop listening, discarding the result.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: None.
  @override
  Future<void> cancel() => _speech.cancel();

  /// Purpose: Translate a plugin error id into a failure this app handles.
  /// Inputs: `errorMsg`.
  /// Returns: `SpeechFailure`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The ids come from
  /// Android's `SpeechRecognizer` and are passed through by the plugin;
  /// `error_language_unavailable` is the one that matters, because it is what
  /// an offline-only request answers on a device with no Japanese model
  /// downloaded, and the UI turns it into a link to the system settings.
  static SpeechFailure _mapError(String errorMsg) {
    if (errorMsg.contains('permission')) return SpeechFailure.permissionDenied;
    if (errorMsg.contains('no_match') || errorMsg.contains('speech_timeout')) {
      return SpeechFailure.noMatch;
    }
    if (errorMsg.contains('language')) {
      return SpeechFailure.languageUnavailable;
    }
    return SpeechFailure.unavailable;
  }
}

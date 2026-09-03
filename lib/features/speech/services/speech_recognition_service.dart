import 'package:flutter/foundation.dart';

import '../../../shared/utils/platform_capabilities.dart';
import 'speech_backend.dart';

/// Where a listening session is.
enum SpeechPhase {
  /// Nothing is happening.
  idle,

  /// The microphone is open.
  listening,

  /// The recognizer has stopped and is settling on an answer.
  processing,

  /// The session ended without a usable answer; see
  /// [SpeechRecognitionService.failure].
  failed,

  /// A final answer arrived.
  done,
}

/// Listens for one spoken Japanese utterance, on the device.
///
/// One instance for the whole app, over an injectable [SpeechBackend]. The
/// recognizer belongs to the platform — Android's `SpeechRecognizer`, Apple's
/// `SFSpeechRecognizer`, the Windows speech platform — and this class owns the
/// policy around it: Japanese only, on-device unless the user opted into a
/// network fallback, one session at a time, and the microphone asked for at
/// first use rather than at install.
class SpeechRecognitionService extends ChangeNotifier {
  SpeechRecognitionService(this._backend);

  /// The app-wide instance.
  static SpeechRecognitionService instance = SpeechRecognitionService(
    SpeechToTextBackend(),
  );

  /// Purpose: Replace the app-wide instance in a test.
  /// Inputs: `service`.
  /// Returns: None.
  /// Side effects: Rebinds [instance].
  /// Notes: Only tests call this.
  @visibleForTesting
  static void setInstanceForTesting(SpeechRecognitionService service) =>
      instance = service;

  final SpeechBackend _backend;

  bool _initialized = false;
  bool _available = false;
  String? _localeId;
  SpeechPhase _phase = SpeechPhase.idle;
  String _heard = '';
  SpeechFailure? _failure;

  /// Whether a Japanese recognizer was found. False until [ensureAvailable].
  bool get isAvailable => _available;

  /// The Japanese locale id the recognizer offered, or null.
  String? get localeId => _localeId;

  /// Where the current session is.
  SpeechPhase get phase => _phase;

  /// The latest text from the recognizer, partial or final.
  String get heard => _heard;

  /// Why the last session failed, or null.
  SpeechFailure? get failure => _failure;

  /// Whether the user allowed a fallback to network recognition. Off by
  /// default; the app never sets it on its own.
  bool networkFallbackAllowed = false;

  /// Purpose: Start the recognizer once and find the Japanese locale.
  /// Inputs: None.
  /// Returns: `Future<bool>` — whether Japanese recognition can be attempted.
  /// Side effects: On the first call, initializes the recognizer, which is
  /// where the platform asks for the microphone permission.
  /// Notes: Gated on [platformMayRecognizeSpeech] first, so a platform with no
  /// recognizer behind the plugin never prompts for a microphone it will not
  /// use. The locale id is whatever the platform spells Japanese as — `ja_JP`
  /// on Android, `ja-JP` on Apple — so it is matched on the `ja` prefix rather
  /// than compared to a constant.
  Future<bool> ensureAvailable() async {
    if (_initialized) return _available;
    _initialized = true;
    if (!platformMayRecognizeSpeech) return false;
    _available = await _backend.initialize(onFailure: _onFailure);
    if (_available) {
      final ids = await _backend.localeIds();
      for (final id in ids) {
        if (id.toLowerCase().startsWith('ja')) {
          _localeId = id;
          break;
        }
      }
      if (_localeId == null) _available = false;
    }
    notifyListeners();
    return _available;
  }

  /// Purpose: Report whether the microphone has already been granted.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: None.
  /// Notes: The UI shows its rationale before the first [ensureAvailable] when
  /// this is false, so the system prompt never arrives unexplained.
  Future<bool> hasPermission() => _backend.hasPermission();

  /// Purpose: Listen for one utterance.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Opens the microphone and publishes state changes.
  /// Notes: `onDevice` is the inverse of [networkFallbackAllowed], so the
  /// default request is offline-only. On Android that maps to
  /// `EXTRA_PREFER_OFFLINE`, which **fails** rather than falling back when no
  /// offline Japanese model is installed — that failure is the honest answer,
  /// and the UI turns it into a link to the system settings. Only a user who
  /// has explicitly turned the fallback on ever sends audio to a server.
  Future<void> listen() async {
    if (!await ensureAvailable()) {
      _fail(SpeechFailure.unavailable);
      return;
    }
    _heard = '';
    _failure = null;
    _phase = SpeechPhase.listening;
    notifyListeners();
    try {
      await _backend.listen(
        localeId: _localeId!,
        onDevice: !networkFallbackAllowed,
        onHeard: _onHeard,
      );
    } catch (_) {
      _fail(SpeechFailure.unavailable);
    }
  }

  /// Purpose: End the session and keep what was recognized.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: The recognizer may still deliver a final result afterwards, which
  /// is why the phase becomes `processing` rather than `done`.
  Future<void> stop() async {
    if (_phase != SpeechPhase.listening) return;
    _phase = SpeechPhase.processing;
    notifyListeners();
    await _backend.stop();
  }

  /// Purpose: Abandon the session and discard the result.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Closes the microphone.
  /// Notes: Used when the practice sheet is dismissed mid-session.
  Future<void> cancel() async {
    if (_phase == SpeechPhase.listening || _phase == SpeechPhase.processing) {
      await _backend.cancel();
    }
    _phase = SpeechPhase.idle;
    _heard = '';
    _failure = null;
    notifyListeners();
  }

  /// Purpose: Return to the idle state, ready for another attempt.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Publishes a state change.
  /// Notes: Called by the retry button, so the previous result disappears
  /// before the microphone opens again.
  void reset() {
    _phase = SpeechPhase.idle;
    _heard = '';
    _failure = null;
    notifyListeners();
  }

  /// Purpose: Record a partial or final result.
  /// Inputs: `result`.
  /// Returns: None.
  /// Side effects: Publishes a state change.
  /// Notes: Internal helper used within this file only. A final result with no
  /// text is a `noMatch`: the session ended and nothing was understood, which
  /// the learner should see as "not heard" rather than as an empty attempt
  /// scored at zero.
  void _onHeard(SpeechHeard result) {
    _heard = result.text;
    if (result.isFinal) {
      if (result.text.trim().isEmpty) {
        _fail(SpeechFailure.noMatch);
        return;
      }
      _phase = SpeechPhase.done;
    }
    notifyListeners();
  }

  /// Purpose: Record an asynchronous recognizer error.
  /// Inputs: `failure`.
  /// Returns: None.
  /// Side effects: Publishes a state change.
  /// Notes: Internal helper used within this file only. An error that arrives
  /// after a final result is ignored: some Android builds report `no_match`
  /// after a session that already produced an answer.
  void _onFailure(SpeechFailure failure) {
    if (_phase == SpeechPhase.done) return;
    _fail(failure);
  }

  /// Purpose: Move to the failed state.
  /// Inputs: `failure`.
  /// Returns: None.
  /// Side effects: Publishes a state change.
  /// Notes: Internal helper used within this file only.
  void _fail(SpeechFailure failure) {
    _failure = failure;
    _phase = SpeechPhase.failed;
    notifyListeners();
  }
}

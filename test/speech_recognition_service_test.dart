import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/speech_backend.dart';
import 'package:my_nihongo/features/speech/services/speech_recognition_service.dart';

/// Purpose: Test the recognition service's state machine and its on-device
/// policy against a scripted fake recognizer.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The load-bearing assertion is the on-device one: the default request
/// must be offline-only, and only a user who turned the network fallback on
/// may ever produce a request that could send audio to a server. Everything
/// else here is the state machine the practice sheet renders.
class _FakeSpeechBackend implements SpeechBackend {
  _FakeSpeechBackend({
    this.initializes = true,
    this.locales = const ['en_US', 'ja_JP'],
  });

  final bool initializes;
  final List<String> locales;

  void Function(SpeechFailure)? failureSink;
  final List<bool> onDeviceRequests = [];
  final List<String> localeRequests = [];
  int stops = 0;
  int cancels = 0;
  void Function(SpeechHeard)? _onHeard;

  /// Purpose: Deliver a result as the platform recognizer would.
  /// Inputs: `text`, `isFinal`.
  /// Returns: None.
  /// Side effects: Calls back into the service.
  /// Notes: Test-only.
  void deliver(String text, {bool isFinal = false}) =>
      _onHeard?.call(SpeechHeard(text: text, isFinal: isFinal));

  /// Purpose: Raise an asynchronous recognizer error.
  /// Inputs: `failure`.
  /// Returns: None.
  /// Side effects: Calls back into the service.
  /// Notes: Test-only.
  void raise(SpeechFailure failure) => failureSink?.call(failure);

  @override
  Future<bool> initialize({
    required void Function(SpeechFailure) onFailure,
  }) async {
    failureSink = onFailure;
    return initializes;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<String>> localeIds() async => locales;

  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(SpeechHeard) onHeard,
  }) async {
    localeRequests.add(localeId);
    onDeviceRequests.add(onDevice);
    _onHeard = onHeard;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

  test(
    'the Japanese locale is chosen however the platform spells it',
    () async {
      final backend = _FakeSpeechBackend(locales: const ['en_US', 'ja-JP']);
      final service = SpeechRecognitionService(backend);
      expect(await service.ensureAvailable(), isTrue);
      expect(service.localeId, 'ja-JP');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test('a recognizer with no Japanese is not available', () async {
    final service = SpeechRecognitionService(
      _FakeSpeechBackend(locales: const ['en_US']),
    );
    expect(await service.ensureAvailable(), isFalse);
    expect(service.isAvailable, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  test('the default request is offline only', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend);
    await service.listen();
    expect(backend.onDeviceRequests, [true]);
    expect(backend.localeRequests, ['ja_JP']);
    debugDefaultTargetPlatformOverride = null;
  });

  test('the network fallback is the only way onDevice is relaxed', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend)
      ..networkFallbackAllowed = true;
    await service.listen();
    expect(backend.onDeviceRequests, [false]);
    debugDefaultTargetPlatformOverride = null;
  });

  test('a partial result is published without ending the session', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend);
    await service.listen();
    backend.deliver('こん');
    expect(service.phase, SpeechPhase.listening);
    expect(service.heard, 'こん');
    backend.deliver('こんにちは', isFinal: true);
    expect(service.phase, SpeechPhase.done);
    expect(service.heard, 'こんにちは');
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'a final result with no text is a no-match, not an empty attempt',
    () async {
      final backend = _FakeSpeechBackend();
      final service = SpeechRecognitionService(backend);
      await service.listen();
      backend.deliver('  ', isFinal: true);
      expect(service.phase, SpeechPhase.failed);
      expect(service.failure, SpeechFailure.noMatch);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test('an error after a final result is ignored', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend);
    await service.listen();
    backend.deliver('ねこ', isFinal: true);
    backend.raise(SpeechFailure.noMatch);
    expect(service.phase, SpeechPhase.done);
    debugDefaultTargetPlatformOverride = null;
  });

  test('a missing offline model surfaces as languageUnavailable', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend);
    await service.listen();
    backend.raise(SpeechFailure.languageUnavailable);
    expect(service.phase, SpeechPhase.failed);
    expect(service.failure, SpeechFailure.languageUnavailable);
    debugDefaultTargetPlatformOverride = null;
  });

  test('stop moves to processing and cancel returns to idle', () async {
    final backend = _FakeSpeechBackend();
    final service = SpeechRecognitionService(backend);
    await service.listen();
    await service.stop();
    expect(service.phase, SpeechPhase.processing);
    expect(backend.stops, 1);
    await service.cancel();
    expect(service.phase, SpeechPhase.idle);
    expect(backend.cancels, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'a recognizer that refuses to start fails rather than throwing',
    () async {
      final service = SpeechRecognitionService(
        _FakeSpeechBackend(initializes: false),
      );
      await service.listen();
      expect(service.phase, SpeechPhase.failed);
      expect(service.failure, SpeechFailure.unavailable);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test(
    'a platform with no recognizer is never asked for a microphone',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final backend = _FakeSpeechBackend();
      final service = SpeechRecognitionService(backend);
      expect(await service.ensureAvailable(), isFalse);
      expect(backend.failureSink, isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

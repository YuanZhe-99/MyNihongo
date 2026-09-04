import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/ai_assist_service.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';

/// Purpose: Test the on-device AI policy against a scripted fake backend.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The load-bearing assertion is the first one: while the learner has
/// the feature switched off, **the backend is never called at all**. Everything
/// else here is the state the Settings rows and the sentence lab render — the
/// per-feature statuses, the one-at-a-time rule, and the timeout that stops a
/// wedged model leaving a spinner on the screen.
class _FakeGenAiBackend extends GenAiBackend {
  _FakeGenAiBackend({
    this.promptStatus = GenAiStatus.available,
    this.proofreadStatus = GenAiStatus.available,
    this.answer = 'because it is unusual',
    this.suggestions = const ['これは本です。'],
    this.failure,
    this.hang = false,
  });

  GenAiStatus promptStatus;
  GenAiStatus proofreadStatus;
  String answer;
  List<String> suggestions;
  GenAiFailure? failure;

  /// When true, `explain` waits on [release] instead of answering.
  bool hang;

  /// Completed by a test to let a hanging `explain` finish.
  final release = Completer<String>();

  /// Every call that reached the platform, in order. Empty is a passing test.
  final List<String> calls = [];

  /// Progress events to emit during a download.
  List<(int, int)> progress = const [(1024, 4096), (4096, 4096)];

  /// The diagnostic line the platform sends back with a failing status.
  String? detail;

  /// What the device says about its AICore installation.
  GenAiCoreInfo? core;

  int cancels = 0;

  @override
  Future<GenAiStatus> status(GenAiFeature feature) async {
    calls.add('status:${feature.name}');
    return feature == GenAiFeature.prompt ? promptStatus : proofreadStatus;
  }

  @override
  Future<GenAiStatusReport> statusReport(GenAiFeature feature) async =>
      GenAiStatusReport(await status(feature), detail: detail);

  @override
  Future<GenAiCoreInfo?> coreInfo() async {
    calls.add('coreInfo');
    return core;
  }

  @override
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    calls.add('download:${feature.name}');
    for (final (bytes, total) in progress) {
      onProgress?.call(bytes, total);
    }
    return true;
  }

  @override
  Future<String> explain(String prompt, {int maxOutputTokens = 256}) async {
    calls.add('explain');
    if (hang) return release.future;
    if (failure != null) throw GenAiException(failure!);
    return answer;
  }

  @override
  Future<List<String>> proofread(String text) async {
    calls.add('proofread');
    if (failure != null) throw GenAiException(failure!);
    return suggestions;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a service that was never switched on calls nothing', () async {
    final backend = _FakeGenAiBackend();
    final service = AiAssistService(backend: backend);

    expect(service.enabled, isFalse);
    expect(service.canExplain, isFalse);
    await expectLater(
      service.explain('anything'),
      throwsA(isA<GenAiException>()),
      reason: 'the switch is the gate, not a filter on the answer',
    );
    await expectLater(
      service.proofread('これは本'),
      throwsA(isA<GenAiException>()),
    );
    expect(backend.calls, isEmpty);
  });

  test('switching on asks the device what each feature can do', () async {
    final backend = _FakeGenAiBackend(
      proofreadStatus: GenAiStatus.downloadable,
    );
    final service = AiAssistService(backend: backend);

    await service.setEnabled(true);

    expect(service.statusOf(GenAiFeature.prompt), GenAiStatus.available);
    expect(service.statusOf(GenAiFeature.proofread), GenAiStatus.downloadable);
    expect(service.canExplain, isTrue);
    expect(service.canProofread, isFalse, reason: 'nothing downloaded yet');
    expect(service.needsDownload, isFalse, reason: 'explaining already works');
  });

  test('switching off forgets the statuses and stops the model', () async {
    final backend = _FakeGenAiBackend();
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);
    expect(service.canExplain, isTrue);

    await service.setEnabled(false);

    expect(service.canExplain, isFalse);
    expect(service.statusOf(GenAiFeature.prompt), GenAiStatus.unsupported);
    expect(backend.cancels, 1);
  });

  test('an explanation reaches the backend once the switch is on', () async {
    final backend = _FakeGenAiBackend(answer: 'the verb is in the past');
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    final answer = await service.explain('prompt text');

    expect(answer, 'the verb is in the past');
    expect(
      backend.calls,
      contains('status:prompt'),
      reason: 'the status is re-asked before every use',
    );
    expect(backend.calls.last, 'explain');
    expect(service.busy, isFalse);
  });

  test('a model that went away is reported, not called', () async {
    final backend = _FakeGenAiBackend();
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);
    backend.promptStatus = GenAiStatus.downloadable;

    await expectLater(
      service.explain('prompt text'),
      throwsA(
        isA<GenAiException>().having(
          (e) => e.failure,
          'failure',
          GenAiFailure.unavailable,
        ),
      ),
    );
    expect(backend.calls, isNot(contains('explain')));
  });

  test('a download reports progress and refreshes the status', () async {
    final backend = _FakeGenAiBackend(
      proofreadStatus: GenAiStatus.downloadable,
    );
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    final seen = <int>[];
    service.addListener(() {
      final progress = service.downloadProgress;
      if (progress != null && progress.bytes > 0) seen.add(progress.bytes);
    });
    backend.proofreadStatus = GenAiStatus.available;
    final ok = await service.download(GenAiFeature.proofread);

    expect(ok, isTrue);
    expect(seen, [1024, 4096]);
    expect(service.statusOf(GenAiFeature.proofread), GenAiStatus.available);
    expect(service.downloadProgress, isNull, reason: 'cleared when finished');
    expect(service.busy, isFalse);
  });

  test('a download is refused while the switch is off', () async {
    final backend = _FakeGenAiBackend();
    final service = AiAssistService(backend: backend);

    expect(await service.download(GenAiFeature.prompt), isFalse);
    expect(backend.calls, isEmpty);
  });

  test('a second request while one is running is refused as busy', () async {
    final backend = _FakeGenAiBackend(hang: true);
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    final first = service.explain('first');
    await Future<void>.delayed(Duration.zero);
    expect(service.busy, isTrue);

    await expectLater(
      service.explain('second'),
      throwsA(
        isA<GenAiException>().having(
          (e) => e.failure,
          'failure',
          GenAiFailure.busy,
        ),
      ),
    );
    expect(backend.calls.where((c) => c == 'explain').length, 1);

    backend.release.complete('done');
    await first;
  });

  test('proofreading returns what the model suggested', () async {
    final backend = _FakeGenAiBackend(suggestions: const ['これは本です。', 'これは本だ。']);
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    expect(await service.proofread('これは本'), ['これは本です。', 'これは本だ。']);
    expect(backend.calls, contains('status:proofread'));
    expect(backend.calls.last, 'proofread');
  });

  test('a backend failure keeps its reason', () async {
    final backend = _FakeGenAiBackend(failure: GenAiFailure.tooLong);
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    await expectLater(
      service.explain('a very long prompt'),
      throwsA(
        isA<GenAiException>().having(
          (e) => e.failure,
          'failure',
          GenAiFailure.tooLong,
        ),
      ),
    );
    expect(service.busy, isFalse, reason: 'the spinner clears on failure too');
  });

  test('needsDownload is what the lab shows its hint for', () async {
    final backend = _FakeGenAiBackend(
      promptStatus: GenAiStatus.downloadable,
      proofreadStatus: GenAiStatus.downloadable,
    );
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    expect(service.canExplain, isFalse);
    expect(service.needsDownload, isTrue);
  });

  test('a device that cannot run them at all needs no download', () async {
    final backend = _FakeGenAiBackend(
      promptStatus: GenAiStatus.unavailable,
      proofreadStatus: GenAiStatus.unavailable,
    );
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    expect(service.canExplain, isFalse);
    expect(
      service.needsDownload,
      isFalse,
      reason: 'offering a download that cannot help would be a false promise',
    );
  });

  test('a status the device could not be asked for is not "unavailable"', () async {
    final backend = _FakeGenAiBackend(
      promptStatus: GenAiStatus.unreachable,
      proofreadStatus: GenAiStatus.available,
    )..detail = 'GenAiException: AICore is out of date';
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);

    // The two used to share one answer, and a phone with AICore installed then
    // reported that it had no on-device model at all.
    expect(service.statusOf(GenAiFeature.prompt), GenAiStatus.unreachable);
    expect(service.statusOf(GenAiFeature.proofread), GenAiStatus.available);
    expect(
      service.reportOf(GenAiFeature.prompt).detail,
      'GenAiException: AICore is out of date',
    );
  });

  test('one feature can be unavailable while the other is ready', () async {
    final backend = _FakeGenAiBackend(
      promptStatus: GenAiStatus.unavailable,
      proofreadStatus: GenAiStatus.downloadable,
    );
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);
    expect(service.canExplain, isFalse);
    expect(service.statusOf(GenAiFeature.proofread), GenAiStatus.downloadable);
  });

  test('the AICore version is read when the statuses are refreshed', () async {
    final backend = _FakeGenAiBackend()
      ..core = const GenAiCoreInfo(
        installed: true,
        versionName: 'aicore_20260723.00_RC11',
        sdk: 36,
        device: 'samsung SM-F978B',
      );
    final service = AiAssistService(backend: backend);
    await service.setEnabled(true);
    expect(service.coreInfo?.versionName, 'aicore_20260723.00_RC11');
    expect(service.coreInfo?.device, 'samsung SM-F978B');
  });

  test('a device that reports no AICore info does not break the page', () async {
    final service = AiAssistService(backend: _FakeGenAiBackend());
    await service.setEnabled(true);
    expect(service.coreInfo, isNull);
  });

  test('turning the switch off asks the device nothing, diagnostics included',
      () async {
    final backend = _FakeGenAiBackend();
    final service = AiAssistService(backend: backend);
    expect(backend.calls, isEmpty);
    expect(service.reportOf(GenAiFeature.prompt).status,
        GenAiStatus.unsupported);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';

/// Purpose: Test how the platform channel's answers become statuses.
/// Inputs: None.
/// Returns: None.
/// Side effects: Installs a mock handler on the GenAI method channel.
/// Notes: This is the layer the Z Fold 8 report landed on. Every failure used
/// to become `unavailable`, so "AICore said no", "AICore threw" and "this build
/// of the app cannot reach AICore" all rendered as the one sentence "not
/// available on this device" — on a phone that has AICore installed. The
/// mapping below is what makes those three separable, so each case is asserted
/// rather than left to a device nobody here has.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelGenAiBackend.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Purpose: Answer the GenAI channel with a canned reply.
  /// Inputs: `reply` — called with the method name.
  /// Returns: None.
  /// Side effects: Installs a handler, removed on tear-down.
  /// Notes: Internal helper used within this file only.
  void mock(Object? Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(channel, (call) async => reply(call));
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('an available feature is reported with no diagnostic line', () async {
    mock((_) => {'status': 'available', 'code': 3, 'detail': null});
    final report = await MethodChannelGenAiBackend(
      channel,
    ).statusReport(GenAiFeature.prompt);
    expect(report.status, GenAiStatus.available);
    expect(report.detail, isNull);
  });

  test('a feature AICore refused carries the raw status code', () async {
    mock(
      (_) => {'status': 'unavailable', 'code': 0, 'detail': 'FeatureStatus=0'},
    );
    final report = await MethodChannelGenAiBackend(
      channel,
    ).statusReport(GenAiFeature.prompt);
    expect(report.status, GenAiStatus.unavailable);
    expect(report.code, 0);
    expect(report.detail, 'FeatureStatus=0');
  });

  test(
    'a call that threw on the device is unreachable, not unavailable',
    () async {
      mock(
        (_) => {
          'status': 'unreachable',
          'code': -1,
          'detail': 'GenAiException: AICore is out of date',
        },
      );
      final report = await MethodChannelGenAiBackend(
        channel,
      ).statusReport(GenAiFeature.prompt);
      expect(report.status, GenAiStatus.unreachable);
      expect(report.detail, contains('GenAiException'));
    },
  );

  test('a platform exception is unreachable and keeps its code', () async {
    mock((_) => throw PlatformException(code: 'failed', message: 'boom'));
    final report = await MethodChannelGenAiBackend(
      channel,
    ).statusReport(GenAiFeature.prompt);
    expect(report.status, GenAiStatus.unreachable);
    expect(report.detail, 'failed: boom');
  });

  test('the AICore package version is read back', () async {
    mock(
      (call) => call.method == 'aicore'
          ? {
              'installed': true,
              'versionName': 'aicore_20260723.00_RC11',
              'sdk': 36,
              'device': 'samsung SM-F978B',
            }
          : null,
    );
    final info = await MethodChannelGenAiBackend(channel).coreInfo();
    expect(info?.installed, isTrue);
    expect(info?.versionName, 'aicore_20260723.00_RC11');
    expect(info?.device, 'samsung SM-F978B');
  });

  test(
    'a device without AICore says so rather than answering nothing',
    () async {
      mock((_) => {'installed': false, 'sdk': 34, 'device': 'Pixel 6'});
      final info = await MethodChannelGenAiBackend(channel).coreInfo();
      expect(info?.installed, isFalse);
      expect(info?.device, 'Pixel 6');
    },
  );

  test('no platform call is made where no on-device model can exist', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var called = false;
    mock((_) {
      called = true;
      return null;
    });
    final backend = MethodChannelGenAiBackend(channel);
    expect(
      (await backend.statusReport(GenAiFeature.prompt)).status,
      GenAiStatus.unsupported,
    );
    expect(await backend.coreInfo(), isNull);
    expect(called, isFalse);
  });
  test(
    'the variant that answered and the model serving it are reported',
    () async {
      mock(
        (_) => {
          'status': 'available',
          'code': 3,
          'variant': 'preview/fast',
          'refused': 'stable/full, stable/fast, preview/full',
          'baseModelName': 'gemini-nano-v4',
          'tokenLimit': 4096,
          'detail': null,
        },
      );
      final report = await MethodChannelGenAiBackend(
        channel,
      ).statusReport(GenAiFeature.prompt);
      expect(report.status, GenAiStatus.available);
      expect(report.variant, 'preview/fast');
      expect(report.baseModelName, 'gemini-nano-v4');
      expect(report.tokenLimit, 4096);
      expect(report.refused, contains('stable/full'));
    },
  );

  test('a refusal names every variant that was tried', () async {
    mock(
      (_) => {
        'status': 'unavailable',
        'code': 0,
        'variant': null,
        'refused': 'stable/full, stable/fast, preview/full, preview/fast',
        'detail':
            'FeatureStatus=0 · refused: stable/full, stable/fast, '
            'preview/full, preview/fast',
      },
    );
    final report = await MethodChannelGenAiBackend(
      channel,
    ).statusReport(GenAiFeature.prompt);
    expect(report.status, GenAiStatus.unavailable);
    expect(report.variant, isNull);
    expect(report.refused, contains('preview/fast'));
    expect(report.detail, contains('refused:'));
  });

  test(
    'a status this build does not know is unknown, never unavailable',
    () async {
      mock(
        (_) => {'status': 'unknown', 'code': 7, 'detail': 'FeatureStatus=7'},
      );
      final report = await MethodChannelGenAiBackend(
        channel,
      ).statusReport(GenAiFeature.prompt);
      expect(report.status, GenAiStatus.unknown);
      expect(report.status, isNot(GenAiStatus.unavailable));
      expect(report.code, 7);
    },
  );

  test(
    'a platform side that sends none of the new fields still decodes',
    () async {
      mock((_) => {'status': 'unavailable', 'code': 0});
      final report = await MethodChannelGenAiBackend(
        channel,
      ).statusReport(GenAiFeature.prompt);
      expect(report.status, GenAiStatus.unavailable);
      expect(report.variant, isNull);
      expect(report.refused, isNull);
      expect(report.baseModelName, isNull);
      expect(report.tokenLimit, isNull);
    },
  );

  test('whether AICore can serve models here is read back', () async {
    mock(
      (call) => call.method == 'aicore'
          ? {
              'installed': true,
              'versionName': 'aicore_20260723.00_RC11',
              'sdk': 36,
              'device': 'samsung SM-F978B',
              'compatible': false,
            }
          : null,
    );
    final info = await MethodChannelGenAiBackend(channel).coreInfo();
    expect(info?.compatible, isFalse);
  });

  test(
    'an AICore reply with no compatibility answer leaves it unknown',
    () async {
      mock((_) => {'installed': true, 'sdk': 36, 'device': 'Pixel 10'});
      final info = await MethodChannelGenAiBackend(channel).coreInfo();
      expect(info?.compatible, isNull);
    },
  );

  test('the answer length asked for travels to the platform', () async {
    int? sent;
    mock((call) {
      if (call.method == 'explain') {
        sent = (call.arguments as Map)['maxOutputTokens'] as int?;
        return 'ok';
      }
      return null;
    });
    await MethodChannelGenAiBackend(
      channel,
    ).explain('why', maxOutputTokens: 320);
    expect(sent, 320);
  });
}

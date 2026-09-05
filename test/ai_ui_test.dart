import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/ai_assist_service.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';
import 'package:my_nihongo/features/ai/widgets/ai_explanation_card.dart';
import 'package:my_nihongo/features/ai/widgets/ai_settings_tiles.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/views/sentence_lab_page.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test what the learner can see and reach, with and without an
/// on-device model.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets; replaces the AI singleton.
/// Notes: The properties worth holding are visibility ones. While the switch is
/// off **nothing AI-related appears anywhere**, so a learner who never opted in
/// never meets the feature. When it is on, every generated answer is inside a
/// card carrying the generated label, and it is rendered below the
/// deterministic finding rather than in place of it. Driven in English, unlike
/// the layout tests: what is asserted here is the wording of controls and
/// labels, not how wide anything measures.
class _FakeGenAiBackend extends GenAiBackend {
  _FakeGenAiBackend({
    this.status_ = GenAiStatus.available,
    this.answer = 'これは説明です。',
    this.detail,
    this.core,
    this.perFeature = const {},
    this.variant,
    this.fastVariant,
    this.served,
    this.refused,
    this.baseModelName,
    this.tokenLimit,
  });

  GenAiStatus status_;

  /// Overrides [status_] for the features named, so a test can describe a
  /// device that has one model and not the other — which is what most non-Pixel
  /// hardware actually is.
  final Map<GenAiFeature, GenAiStatus> perFeature;
  String answer;
  String? detail;
  GenAiCoreInfo? core;

  /// What the probe found: the variant serving, the ones refused, and the
  /// model behind the one that answered.
  final String? variant;

  /// What the probe reports when the faster model is asked for instead.
  final String? fastVariant;
  final String? served;
  final String? refused;
  final String? baseModelName;
  final int? tokenLimit;
  final List<String> calls = [];

  @override
  Future<GenAiStatus> status(GenAiFeature feature) async {
    calls.add('status');
    return perFeature[feature] ?? status_;
  }

  @override
  Future<GenAiStatusReport> statusReport(
    GenAiFeature feature, {
    bool force = false,
    bool preferFast = false,
  }) async => GenAiStatusReport(
    await status(feature),
    detail: detail,
    variant: preferFast ? fastVariant ?? variant : variant,
    served: served,
    refused: refused,
    baseModelName: baseModelName,
    tokenLimit: tokenLimit,
  );

  @override
  Future<GenAiCoreInfo?> coreInfo() async => core;

  @override
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    calls.add('download');
    onProgress?.call(2048, 4096);
    status_ = GenAiStatus.available;
    return true;
  }

  @override
  Future<String> explain(String prompt, {int maxOutputTokens = 256}) async {
    calls.add('explain');
    return answer;
  }

  @override
  Future<List<String>> proofread(String text) async {
    calls.add('proofread');
    return ['$text です'];
  }

  @override
  Future<void> cancel() async => calls.add('cancel');
}

/// A documents directory the test owns, so a written preference does not
/// escape into the developer's own config file.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Only the tests that unlock developer options need real storage. Giving
  // every test a path provider made the settings notifier load a config that
  // said AI was off, which switched the service back off underneath the lab
  // tests that had just turned it on.
  Directory? temp;

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() {
    ContentRepository.parseInIsolate = true;
    AiAssistService.setInstanceForTest(AiAssistService());
  });

  tearDown(() async {
    if (temp != null && temp!.existsSync()) {
      await temp!.delete(recursive: true);
    }
    temp = null;
  });

  /// Install a service the test controls, and put the singleton back after.
  Future<AiAssistService> useService(
    _FakeGenAiBackend backend, {
    required bool enabled,
  }) async {
    final service = AiAssistService(backend: backend);
    AiAssistService.setInstanceForTest(service);
    addTearDown(() => AiAssistService.setInstanceForTest(AiAssistService()));
    if (enabled) await service.setEnabled(true);
    return service;
  }

  /// Purpose: Show the AI settings section, optionally with developer options
  /// already unlocked.
  /// Inputs: The `tester`, a `locale`, and `debug`.
  /// Returns: None.
  /// Side effects: Writes `storage_config.json` in a temporary directory when
  /// `debug` is set; pumps the widget.
  /// Notes: The preference is written to the real config file rather than
  /// injected, so what these tests exercise is the path the eight-tap unlock
  /// actually takes. Writing it needs `runAsync`, because `testWidgets` runs
  /// its body in a fake-async zone where a `dart:io` write never completes.
  Future<void> pumpSettings(
    WidgetTester tester, {
    Locale? locale,
    bool debug = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    if (debug) {
      await tester.runAsync(() async {
        temp = await Directory.systemTemp.createTemp('mynihongo_aiui_');
        PathProviderPlatform.instance = _FakePathProvider(temp!.path);
        await NihongoStorage.setDebugMode(true);
      });
    }
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale ?? const Locale('en'),
            home: const Scaffold(
              body: SingleChildScrollView(child: AiSettingsTiles()),
            ),
          ),
        ),
      );
      // The settings notifier reads the config file on construction, so the
      // first frame is drawn before the preference has arrived.
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  // A phone-width but very tall viewport, so the whole result — including the
  // issues section and anything under it — is laid out without scrolling.
  // What is being checked here is which controls exist, not where they fall on
  // a real screen; the geometry tests live in `sentence_lab_ui_test.dart`.
  Future<void> pumpLab(WidgetTester tester, String sentence) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 2400);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SentenceLabPage(initialSentence: sentence),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('the settings section offers a switch that starts off', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(_FakeGenAiBackend(), enabled: false);

    await pumpSettings(tester);

    expect(find.text('On-device AI assistance'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(
      find.text('Download'),
      findsNothing,
      reason: 'nothing is offered before the switch is on',
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a switched-on device shows one status row per feature', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(_FakeGenAiBackend(), enabled: true);

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Explanations and extra questions'), findsOneWidget);
    expect(find.text('Correction suggestions'), findsOneWidget);
    expect(find.text('Ready'), findsNWidgets(2));
    expect(
      find.textContaining('Android downloads the model, not this app'),
      findsOneWidget,
      reason: 'who performs the download is stated where the button is',
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a downloadable feature offers a Download button', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final backend = _FakeGenAiBackend(status_: GenAiStatus.downloadable);
    await useService(backend, enabled: true);

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Needs a one-time download'), findsNWidgets(2));
    expect(find.text('Download'), findsNWidgets(2));

    await tester.tap(find.text('Download').first);
    await tester.pumpAndSettle();

    expect(backend.calls, contains('download'));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a platform with no on-device model shows no switch', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await useService(_FakeGenAiBackend(), enabled: false);

    await pumpSettings(tester);

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('This platform has no on-device model.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the lab shows nothing AI-related while the switch is off', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final backend = _FakeGenAiBackend();
    await useService(backend, enabled: false);

    await pumpLab(tester, '私は昨日映画を見ます。');

    expect(find.text('Possible issues'), findsOneWidget);
    expect(find.text('Explain'), findsNothing);
    expect(find.text('Explain this sentence'), findsNothing);
    expect(find.text('Suggest a correction'), findsNothing);
    expect(
      backend.calls,
      isEmpty,
      reason: 'a learner who never opted in never reaches the device',
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a switched-on lab explains an issue below its row', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(answer: 'The verb is in the non-past.'),
      enabled: true,
    );

    await pumpLab(tester, '私は昨日映画を見ます。');

    expect(find.text('Explain'), findsWidgets);
    expect(find.text('Explain this sentence'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Explain').first);
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('The verb is in the non-past.'), findsOneWidget);
    expect(
      find.text('Generated on this device — may be wrong'),
      findsOneWidget,
      reason: 'every generated answer says so',
    );
    // The deterministic finding is still above its explanation.
    final issueRow = tester.getTopLeft(find.text('Possible issues'));
    final card = tester.getTopLeft(find.byType(AiExplanationCard));
    expect(issueRow.dy, lessThan(card.dy));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the lab points at Settings when no model is downloaded', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(status_: GenAiStatus.downloadable),
      enabled: true,
    );

    await pumpLab(tester, 'これは本です。');

    expect(find.text('Explain this sentence'), findsNothing);
    expect(find.textContaining('not downloaded yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a device that cannot run a model is not nagged', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(status_: GenAiStatus.unavailable),
      enabled: true,
    );

    await pumpLab(tester, 'これは本です。');

    expect(find.text('Explain this sentence'), findsNothing);
    expect(find.textContaining('not downloaded yet'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a proofreading-only device still offers the rewrite', (
    tester,
  ) async {
    // The Galaxy Z Fold 8's actual shape: the Prompt API is unreachable and
    // Proofreading is ready. Until v0.3.2 both buttons were gated on
    // explanations, so this device saw no AI at all while Settings correctly
    // reported one feature as usable.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        perFeature: const {
          GenAiFeature.prompt: GenAiStatus.unreachable,
          GenAiFeature.proofread: GenAiStatus.available,
        },
      ),
      enabled: true,
    );

    await pumpLab(tester, 'これは本です。');

    expect(find.text('Suggest a correction'), findsOneWidget);
    expect(find.text('Explain this sentence'), findsNothing);
    expect(find.text('Explain'), findsNothing);
    expect(
      find.textContaining('not downloaded yet'),
      findsNothing,
      reason: 'a hint under a usable button reads as if it will fail',
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the rewrite runs on a proofreading-only device', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final backend = _FakeGenAiBackend(
      perFeature: const {
        GenAiFeature.prompt: GenAiStatus.unreachable,
        GenAiFeature.proofread: GenAiStatus.available,
      },
    );
    await useService(backend, enabled: true);

    await pumpLab(tester, 'これは本です。');
    await tester.runAsync(() async {
      await tester.tap(find.text('Suggest a correction'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(backend.calls, contains('proofread'));
    expect(
      backend.calls,
      isNot(contains('explain')),
      reason: 'the Prompt API is not on this device',
    );
    expect(find.text('One possible rewrite'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('an explanation-only device still offers the explanation', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        perFeature: const {
          GenAiFeature.prompt: GenAiStatus.available,
          GenAiFeature.proofread: GenAiStatus.unavailable,
        },
      ),
      enabled: true,
    );

    await pumpLab(tester, 'これは本です。');

    expect(find.text('Explain this sentence'), findsOneWidget);
    expect(find.text('Suggest a correction'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a refusing device shows what it said and offers a re-check', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final backend = _FakeGenAiBackend(
      status_: GenAiStatus.unavailable,
      detail: 'FeatureStatus=0',
      core: const GenAiCoreInfo(
        installed: true,
        versionName: 'aicore_20260723.00_RC11',
        sdk: 36,
        device: 'samsung SM-F978B',
      ),
    );
    await useService(backend, enabled: true);

    await pumpSettings(tester, debug: true);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Without these three lines the learner is told "not available on this
    // device" and has nothing to act on or report.
    expect(find.text('FeatureStatus=0'), findsNWidgets(2));
    expect(
      find.text('AICore aicore_20260723.00_RC11 · samsung SM-F978B'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.refresh), findsNWidgets(2));

    backend.calls.clear();
    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pumpAndSettle();
    expect(backend.calls, contains('status'));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a device AICore could not be asked says so in its own words', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        status_: GenAiStatus.unreachable,
        detail: 'GenAiException: AICore is out of date',
        core: const GenAiCoreInfo(installed: false, sdk: 34, device: 'Pixel 6'),
      ),
      enabled: true,
    );

    await pumpSettings(tester, debug: true);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('The AI service could not be reached'), findsNWidgets(2));
    expect(
      find.text('AICore is not installed on this device.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a working feature is not cluttered with diagnostics', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(_FakeGenAiBackend(), enabled: true);

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsNWidgets(2));
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('a refusal names every model variant that was tried', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        status_: GenAiStatus.unavailable,
        detail:
            'FeatureStatus=0 · refused: stable/full, stable/fast, '
            'preview/full, preview/fast',
        refused: 'stable/full, stable/fast, preview/full, preview/fast',
        core: const GenAiCoreInfo(
          installed: true,
          versionName: 'aicore_20260723.00_RC11',
          sdk: 36,
          device: 'samsung SM-F978B',
          compatible: true,
        ),
      ),
      enabled: true,
    );

    await pumpSettings(tester, debug: true);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // This is what M4.0 is for. "Not available on this device" was true for
    // two releases and never said which of four model variants had been asked
    // for, nor whether AICore itself was the problem.
    expect(find.textContaining('preview/fast'), findsNWidgets(2));
    expect(
      find.text(
        'AICore aicore_20260723.00_RC11 · samsung SM-F978B · '
        'AICore can serve models on this device',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a served feature names the variant and the model behind it', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        variant: 'preview/fast',
        baseModelName: 'gemini-nano-v4',
        tokenLimit: 4096,
      ),
      enabled: true,
    );

    await pumpSettings(tester, debug: true);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      find.text('preview/fast · gemini-nano-v4 · 4096 tok'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'a status this build does not know says so and can be rechecked',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(
        _FakeGenAiBackend(
          status_: GenAiStatus.unknown,
          detail: 'FeatureStatus=7',
        ),
        enabled: true,
      );

      await pumpSettings(tester, debug: true);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The device reported a status this version does not recognise',
        ),
        findsNWidgets(2),
      );
      expect(find.text('FeatureStatus=7'), findsNWidgets(2));
      expect(find.byIcon(Icons.refresh), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('a device serving both sizes offers the choice, and uses it', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(
      _FakeGenAiBackend(
        variant: 'stable/full',
        fastVariant: 'stable/fast',
        served: 'stable/full, stable/fast',
        baseModelName: 'nano-v4',
      ),
      enabled: true,
    );

    await pumpSettings(tester, debug: true);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Use the faster model'), findsOneWidget);
    expect(find.textContaining('stable/full · nano-v4'), findsNWidgets(2));

    await tester.tap(find.text('Use the faster model'));
    await tester.pumpAndSettle();

    // The switch is not a note for next launch: the row names the model that
    // is serving now.
    expect(find.textContaining('stable/fast · nano-v4'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a device serving one size is offered no choice', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // The Galaxy Z Fold 8: the larger model is refused, the faster one serves.
    await useService(
      _FakeGenAiBackend(
        variant: 'stable/fast',
        served: 'stable/fast',
        refused: 'stable/full',
        baseModelName: 'nano-v4-fast',
      ),
      enabled: true,
    );

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      find.text('Use the faster model'),
      findsNothing,
      reason: 'a switch that cannot change what is serving is worse than none',
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the page says where the model lives and that it stays there', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await useService(_FakeGenAiBackend(), enabled: true);

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // No Remove button anywhere: neither ML Kit client exposes a way to delete
    // a model, and the file is AICore's, shared with every app that uses it.
    expect(find.textContaining('cannot be removed from here'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Remove'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('a downloadable feature is not decorated with a refusal line', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // The Pixel 10 on first run: the model is not fetched yet, and three
    // variants were refused on the way to finding the one that serves. Saying
    // so under "Needs a one-time download" reads as a fault beside a perfectly normal
    // state, so the platform sends no detail for it and none is shown.
    await useService(
      _FakeGenAiBackend(status_: GenAiStatus.downloadable),
      enabled: true,
    );

    await pumpSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Needs a one-time download'), findsNWidgets(2));
    expect(find.textContaining('refused'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Download'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  group('developer options', () {
    // The report that produced this: the AI rows were long, written from the
    // implementation's point of view, and full of things a learner has no way
    // to act on. Every one of them was there for a reason — two wrong
    // diagnoses came from a Settings page that could not say why a device said
    // no — but that audience is one person with a cable, not the learner.

    testWidgets('a working feature says only that it is ready', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(
        _FakeGenAiBackend(
          variant: 'stable/full',
          served: 'stable/full',
          baseModelName: 'nano-v4',
          tokenLimit: 4096,
        ),
        enabled: true,
      );

      await pumpSettings(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Ready'), findsNWidgets(2));
      expect(
        find.textContaining('stable/full'),
        findsNothing,
        reason: 'a learner cannot act on a model variant',
      );
      expect(find.textContaining('nano-v4'), findsNothing);
      expect(find.textContaining('4096 tok'), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a refused feature does not show the raw status either', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(
        _FakeGenAiBackend(
          status_: GenAiStatus.unavailable,
          detail: 'FeatureStatus=0 · refused: stable/full, stable/fast',
          core: const GenAiCoreInfo(
            installed: true,
            versionName: 'aicore_20260723.00_RC11',
            sdk: 36,
            device: 'Pixel 10',
          ),
        ),
        enabled: true,
      );

      await pumpSettings(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Not available on this device'), findsNWidgets(2));
      expect(find.textContaining('FeatureStatus'), findsNothing);
      expect(find.textContaining('aicore_'), findsNothing);
      // The re-check button stays. Availability changes without the app doing
      // anything, and that is something a learner can act on.
      expect(find.byIcon(Icons.refresh), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('an unrecognised status reads as unavailable to a learner', (
      tester,
    ) async {
      // The distinction is real and worth keeping — reading an unknown status
      // as a refusal is exactly the mistake that produced two wrong diagnoses
      // — but it is not a distinction a learner can act on.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(
        _FakeGenAiBackend(status_: GenAiStatus.unknown, detail: 'raw=7'),
        enabled: true,
      );

      await pumpSettings(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Not available on this device'), findsNWidgets(2));
      expect(
        find.textContaining('does not recognise'),
        findsNothing,
        reason: 'that sentence is for whoever has to work out why',
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('unlocked, the same device shows the whole diagnosis', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(
        _FakeGenAiBackend(status_: GenAiStatus.unknown, detail: 'raw=7'),
        enabled: true,
      );

      await pumpSettings(tester, debug: true);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The device reported a status this version does not '
          'recognise',
        ),
        findsNWidgets(2),
      );
      expect(find.text('raw=7'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the plain copy names no internal machinery', (tester) async {
      // The specific complaint. "AICore", "system service" and "model variant"
      // are words the app knows and the learner does not.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await useService(_FakeGenAiBackend(), enabled: true);

      await pumpSettings(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      for (final jargon in const ['AICore', 'system service', 'variant']) {
        expect(
          find.textContaining(jargon),
          findsNothing,
          reason: '"$jargon" is a word the app knows, not the learner',
        );
      }
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

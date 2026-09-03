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
import 'package:my_nihongo/l10n/app_localizations.dart';

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
class _FakeGenAiBackend implements GenAiBackend {
  _FakeGenAiBackend({
    this.status_ = GenAiStatus.available,
    this.answer = 'これは説明です。',
  });

  GenAiStatus status_;
  String answer;
  final List<String> calls = [];

  @override
  Future<GenAiStatus> status(GenAiFeature feature) async {
    calls.add('status');
    return status_;
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() {
    ContentRepository.parseInIsolate = true;
    AiAssistService.setInstanceForTest(AiAssistService());
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

  Future<void> pumpSettings(WidgetTester tester, {Locale? locale}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
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

    expect(find.text('Explanations'), findsOneWidget);
    expect(find.text('Correction suggestions'), findsOneWidget);
    expect(find.text('Ready'), findsNWidgets(2));
    expect(
      find.textContaining('AICore system service'),
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

    expect(find.text('Not downloaded yet'), findsNWidgets(2));
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
}

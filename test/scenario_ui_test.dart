import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/lessons/models/scenario.dart';
import 'package:my_nihongo/features/lessons/views/scenario_page.dart';
import 'package:my_nihongo/features/ai/services/ai_assist_service.dart';
import 'package:my_nihongo/features/ai/services/ai_practice_service.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';
import 'package:my_nihongo/features/ai/widgets/ai_explanation_card.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test the scripted-conversation page at the geometries the app
/// supports, and the one rule that makes it a lesson rather than a quiz.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; the page reads no files.
/// Notes: Driven in Simplified Chinese like the other layout tests, because
/// square CJK glyphs measure the real layout while the test font inflates
/// Latin and reports overflows a device would never show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  Map<String, Object?> line(String ja, String zh) => {
    'speaker': 'A',
    'ja': ja,
    'reading': ja,
    'en': 'x',
    'zh': zh,
  };

  final scenario = Scenario.fromJson({
    'title': {'en': 'At the station', 'zh': '在车站'},
    'dialogue': [
      line('こんにちは。', '你好。'),
      line('はい、どうぞ。', '好的，请。'),
      line('ありがとう。', '谢谢。'),
      line('さようなら。', '再见。'),
    ],
    'branches': [
      {
        'after': 2,
        'choices': [
          {
            'ja': 'はい、そうです。',
            'reading': 'はい、そうです。',
            'en': 'Yes',
            'zh': '是的。',
            'correct': true,
          },
          {
            'ja': 'いいえ。',
            'reading': 'いいえ。',
            'en': 'No',
            'zh': '不是。',
          },
        ],
      },
    ],
  })!;

  final unit = LessonUnit.fromJson({
    'id': 'unit:n5-1',
    'title': {'en': 'One', 'zh': '第一单元'},
  })!;

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: ScenarioPage(
            args: ScenarioArgs(scenario: scenario, unit: unit),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final geometry in const [
    (412.0, 915.0, 'a phone in portrait'),
    (915.0, 412.0, 'a phone in landscape'),
    (933.0, 704.0, 'a Z Fold 8 unfolded'),
    (704.0, 933.0, 'a Z Fold 8 folded'),
    (791.0, 820.0, 'a Pixel 10 Pro Fold'),
    (659.0, 791.0, 'a Z Fold 5'),
    (1024.0, 768.0, 'a tablet in landscape'),
    (768.0, 1024.0, 'a tablet in portrait'),
  ]) {
    testWidgets('${geometry.$3} shows the first line without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('在车站'), findsOneWidget);
      expect(find.text('你好。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the script advances one line at a time', (tester) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('好的，请。'), findsNothing);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('好的，请。'), findsOneWidget);
  });

  testWidgets('a wrong reply does not end the conversation', (tester) async {
    await pumpAt(tester, 412, 915);
    // Two lines in, the branch is asked.
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('你要说什么？'), findsOneWidget);

    // Pick the wrong one. The script carries on regardless, and the reply
    // stays in the transcript where it was said.
    await tester.tap(find.byType(OutlinedButton).last);
    await tester.pump();
    expect(find.text('你要说什么？'), findsNothing);
    expect(find.text('不是。'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('谢谢。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tally at the end counts the right replies', (tester) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton).first); // the correct one
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      final next = find.byType(FilledButton);
      if (next.evaluate().isEmpty) break;
      await tester.tap(next.first);
      await tester.pump();
    }
    expect(find.textContaining('1 次'), findsOneWidget);
  });

  group('the conversation goes on past the script', () {
    /// Install a controlled AI, and put both singletons back afterwards.
    ///
    /// **Both**: `AiPracticeService.instance` captures the assist service at
    /// its own construction, so a test that replaces only the assist singleton
    /// is still talking to the real, disabled practice service and sees a
    /// device with no model.
    Future<_FakeGenAi> useAi({
      bool proofread = false,
      String answer = 'Japanese: いらっしゃいませ。\nMeaning: 欢迎光临。',
    }) async {
      final backend = _FakeGenAi(
        answer: answer,
        perFeature: {
          if (!proofread) GenAiFeature.proofread: GenAiStatus.unavailable,
        },
      );
      // No path provider on purpose, as in `ai_ui_test`: turning the switch on
      // persists the preference, and a real `dart:io` write started inside a
      // widget test's zone never completes there. Without one the write fails
      // at once, the service is on in memory, and that is all these tests need.
      final service = AiAssistService(backend: backend);
      AiAssistService.setInstanceForTest(service);
      AiPracticeService.setInstanceForTest(
        AiPracticeService(assist: service),
      );
      addTearDown(() {
        AiAssistService.setInstanceForTest(AiAssistService());
        AiPracticeService.setInstanceForTest(AiPracticeService());
      });
      await service.setEnabled(true);
      return backend;
    }

    /// Pump a fixed number of frames rather than settling.
    ///
    /// `pumpAndSettle` cannot be used here: while a reply is being written the
    /// page shows a `CircularProgressIndicator`, which schedules a frame
    /// forever, so settling is a thing that never happens. A bounded pump is
    /// what the exam tests use for the same reason.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    /// Run the script to its end, so the conversation is what is left.
    Future<void> finishScript(WidgetTester tester) async {
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        final next = find.byType(FilledButton);
        if (next.evaluate().isEmpty) break;
        await tester.tap(next.first);
        await tester.pump();
      }
    }

    testWidgets('nothing is offered while the switch is off', (tester) async {
      // The scripted conversation and its tally are the lesson. A device
      // without a model has not lost anything it was promised.
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      expect(find.textContaining('1 次'), findsOneWidget);
      expect(find.text('继续对话'), findsNothing);
      expect(find.text('结束对话'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a model, the script ends in an invitation', (
      tester,
    ) async {
      await useAi();
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      expect(find.text('继续对话'), findsOneWidget);
      expect(find.text('结束对话'), findsOneWidget);
      expect(find.textContaining('会以角色身份回答'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a typed turn is answered in character and labelled', (
      tester,
    ) async {
      await useAi();
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      await tester.enterText(find.byType(TextField), 'すみません、お願いします。');
      await tester.tap(find.byIcon(Icons.send));
      await settle(tester);

      expect(find.text('すみません、お願いします。'), findsOneWidget);
      expect(find.textContaining('いらっしゃいませ。'), findsOneWidget);
      expect(find.textContaining('欢迎光临。'), findsOneWidget);
      expect(
        find.text('在本设备上生成——可能有误'),
        findsOneWidget,
        reason: 'a reply written by a model says so, above itself',
      );
      expect(find.textContaining('第 1 轮'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a reply with no Japanese in it is refused', (tester) async {
      // A model answering the instruction rather than the learner writes a
      // well-formed line that is not a reply.
      await useAi(answer: "Japanese: Sorry, I can't continue this.");
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      await tester.enterText(find.byType(TextField), 'すみません、お願いします。');
      await tester.tap(find.byIcon(Icons.send));
      await settle(tester);

      expect(find.textContaining("Sorry, I can't"), findsNothing);
      expect(find.byType(AiExplanationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the learner can end it whenever they like', (tester) async {
      await useAi();
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, '结束对话'));
      await tester.pump();
      expect(find.text('对话已结束。'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('继续对话'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the proofreader speaks under the learner’s own line', (
      tester,
    ) async {
      await useAi(proofread: true);
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      await tester.enterText(find.byType(TextField), 'すみません');
      // Inside `runAsync`, because proofreading is the one path that needs the
      // sentence analyser, and loading its lexicon is real `dart:io` that
      // never completes inside the binding's fake-async zone.
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.send));
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pump();
      expect(find.textContaining('校对：すみません です'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each turn is counted towards the cap', (tester) async {
      // What the cap itself does is `ScenarioChat`'s to prove, in
      // `scenario_chat_test.dart`: driving eight model round-trips through the
      // widget tester tests the tester. What is worth checking here is that
      // the page is counting real turns and saying so.
      await useAi();
      await pumpAt(tester, 412, 915);
      await finishScript(tester);
      expect(find.textContaining('第 0 轮，共 8 轮'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ありがとうございます。');
      await tester.tap(find.byIcon(Icons.send));
      await settle(tester);
      expect(find.textContaining('第 1 轮，共 8 轮'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final geometry in const [
      (412.0, 915.0, 'a phone in portrait'),
      (915.0, 412.0, 'a phone in landscape'),
      (933.0, 704.0, 'a Z Fold 8 unfolded'),
      (704.0, 933.0, 'a Z Fold 8 folded'),
      (791.0, 820.0, 'a Pixel 10 Pro Fold'),
      (659.0, 791.0, 'a Z Fold 5'),
      (1024.0, 768.0, 'a tablet in landscape'),
      (768.0, 1024.0, 'a tablet in portrait'),
    ]) {
      testWidgets('${geometry.$3} composes a turn over the keyboard', (
        tester,
      ) async {
        // The composer sits outside the scrolling transcript for exactly this
        // reason: a field at the bottom of a list is under the IME.
        await useAi();
        await pumpAt(tester, geometry.$1, geometry.$2);
        await finishScript(tester);
        // The keyboard comes up when the field is focused, which is after the
        // script has run — raising it first would leave a landscape phone 112
        // pixels tall, which is not a state the app is ever in.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.reset);
        await tester.pump();
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// A backend the test answers for.
///
/// Small on purpose: what these tests are about is the page, so the model is
/// reduced to one canned reply and a proofreader that appends です.
class _FakeGenAi extends GenAiBackend {
  _FakeGenAi({required this.answer, this.perFeature = const {}});

  final String answer;

  /// Lets a test describe a device serving one model and not the other, which
  /// is what most non-Pixel hardware actually is.
  final Map<GenAiFeature, GenAiStatus> perFeature;

  @override
  Future<GenAiStatus> status(GenAiFeature feature) async =>
      perFeature[feature] ?? GenAiStatus.available;

  @override
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  }) async => true;

  @override
  Future<String> explain(String prompt, {int maxOutputTokens = 256}) async =>
      answer;

  @override
  Future<List<String>> proofread(String text) async => ['$text です'];

  @override
  Future<void> cancel() async {}
}

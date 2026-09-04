import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/question_bank.dart';
import 'package:my_nihongo/features/quiz/services/question_generator.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

/// Purpose: Test that a unit's question pool is built whole and drawn from
/// fairly.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Against the shipped N5 units, because whether a topic can actually
/// fill a twelve-question session is a fact about the content. The old
/// level-wide quiz shuffled items and took twenty; a unit is small enough to
/// build every question it can ask and then choose, which is what makes a rare
/// mode as likely as a common one rather than as likely as its items are.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late QuestionGenerator generator;
  late LessonPath n5;
  const en = Locale('en');

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    generator = QuestionGenerator(
      catalog: catalog,
      analyzer: SentenceAnalyzer(
        lexicon: Lexicon.build(
          catalog,
          functionWords: await loadFunctionWords(),
        ),
        catalog: catalog,
      ),
      random: Random(20260904),
    );
    n5 = LessonPath.fromJson(
      jsonDecode(File('assets/content/lessons/n5.json').readAsStringSync()),
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  QuestionBank bankFor(LessonUnit unit) => QuestionBank.build(
    unit: unit,
    catalog: catalog,
    generator: generator,
    modes: QuizMode.values.toSet(),
    locale: en,
  );

  test('every shipped unit can fill a session', () {
    for (final unit in n5.units) {
      final bank = bankFor(unit);
      expect(
        bank.questions.length,
        greaterThanOrEqualTo(20),
        reason: '${unit.id} could only build ${bank.questions.length}',
      );
    }
  });

  test('a hand-written question keeps its explanation and its order', () {
    final unit = n5.units.firstWhere((u) => u.questions.isNotEmpty);
    final authored = unit.questions.first;
    final built = bankFor(unit).questions.firstWhere(
      (q) => q.explanation != null && q.options.length == 4,
    );
    expect(built.explanation, isNotEmpty);
    expect(
      bankFor(unit).questions.any((q) => q.options.join() ==
          authored.options.join()),
      isTrue,
      reason: "a hand-written question's options are often an ordered set",
    );
  });

  test('the same question is never in the pool twice', () {
    for (final unit in n5.units) {
      final keys = [
        for (final q in bankFor(unit).questions)
          '${q.itemId}/${q.mode.name}/${q.prompt}',
      ];
      expect(keys.toSet(), hasLength(keys.length), reason: unit.id);
    }
  });

  test('a draw asks about each item at most once', () {
    final bank = bankFor(n5.units.first);
    final drawn = bank.draw(
      12,
      progress: const ProgressData(),
      random: Random(1),
    );
    expect(drawn, hasLength(12));
    expect(
      drawn.map((q) => q.itemId).toSet(),
      hasLength(drawn.length),
      reason: 'twelve questions should be twelve different things',
    );
  });

  test('the same seed draws the same session', () {
    final bank = bankFor(n5.units.first);
    String render(List<QuizQuestion> qs) =>
        qs.map((q) => '${q.itemId}/${q.mode.name}').join('|');
    expect(
      render(bank.draw(12, progress: const ProgressData(), random: Random(7))),
      render(bank.draw(12, progress: const ProgressData(), random: Random(7))),
    );
  });

  test('a draw prefers what the learner has not got right', () {
    final unit = n5.units.first;
    final bank = bankFor(unit);
    // Everything answered right except one item.
    final unseen = unit.items.first;
    final progress = ProgressData(
      records: [
        for (final item in unit.items.skip(1))
          StudyRecord.create(item).copyWith(correct: 5),
      ],
    );
    var appearances = 0;
    for (var seed = 0; seed < 40; seed++) {
      final drawn = bank.draw(3, progress: progress, random: Random(seed));
      if (drawn.any((q) => q.itemId == unseen)) appearances++;
    }
    expect(
      appearances,
      greaterThan(10),
      reason: 'an item with no record weighs three times an answered one',
    );
  });

  test('a draw never returns more than the pool holds', () {
    final bank = bankFor(n5.units.first);
    final drawn = bank.draw(
      1000,
      progress: const ProgressData(),
      random: Random(3),
    );
    expect(drawn.length, lessThanOrEqualTo(bank.questions.length));
    expect(drawn, isNotEmpty);
  });
}

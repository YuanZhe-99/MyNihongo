import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/drills/services/drill_sampler.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';

/// Purpose: Test that two papers from one pool are not the same paper, and
/// that a question the learner has just seen is not the first one back.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Sampling is the part of an exam most likely to be wrong in a way
/// nobody notices: a paper that quietly asks the same six questions every
/// time still looks exactly like a paper. So the randomness is injected and
/// every rule here is asserted on a seeded draw rather than eyeballed.
void main() {
  DrillQuestion q(
    String id, {
    DrillType type = DrillType.kanjiReading,
    String? passage,
  }) => DrillQuestion(
    id: id,
    type: type,
    items: const ['vocab:one'],
    kind: AnswerKind.choice,
    prompt: const LocalizedStrings({
      'en': ['?'],
    }),
    options: const ['a', 'b', 'c', 'd'],
    answer: 0,
    passageId: passage,
  );

  DrillFile fileOf(List<DrillQuestion> questions) => DrillFile(
    level: JlptLevel.n5,
    section: DrillSection.vocab,
    questions: questions,
  );

  final ten = fileOf([for (var i = 1; i <= 10; i++) q('q:n5-v-00$i')]);

  test('a draw takes what the composition asks for', () {
    final drawn = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 4},
      random: Random(1),
    );
    expect(drawn, hasLength(4));
    expect(drawn.map((d) => d.id).toSet(), hasLength(4));
  });

  test('a type with no questions yields none rather than another type', () {
    final drawn = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 2, DrillType.usage: 5},
      random: Random(1),
    );
    expect(drawn, hasLength(2));
    expect(drawn.every((d) => d.type == DrillType.kanjiReading), isTrue);
  });

  test('a pool shorter than the ask yields what it has', () {
    final drawn = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 40},
      random: Random(1),
    );
    expect(
      drawn,
      hasLength(10),
      reason:
          'the results screen says how many were asked, so a short '
          'section is visible rather than padded',
    );
  });

  test('never-asked questions come before asked ones', () {
    final drawn = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 3},
      asked: {for (var i = 1; i <= 7; i++) 'q:n5-v-00$i'},
      random: Random(3),
    );
    expect(
      drawn.map((d) => d.id).toSet(),
      {'q:n5-v-008', 'q:n5-v-009', 'q:n5-v-0010'},
      reason: 'seven were already seen and exactly three were not',
    );
  });

  test('once every question is asked, the oldest comes first', () {
    final asked = {for (var i = 1; i <= 10; i++) 'q:n5-v-00$i'};
    final drawn = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 2},
      asked: asked,
      lastAsked: {for (var i = 1; i <= 10; i++) 'q:n5-v-00$i': i * 1000},
      random: Random(5),
    );
    expect(drawn.map((d) => d.id), ['q:n5-v-001', 'q:n5-v-002']);
  });

  test('two draws from one fresh pool are not the same paper', () {
    final first = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 4},
      random: Random(1),
    ).map((d) => d.id).toList();
    final second = DrillSampler.draw(
      ten,
      counts: {DrillType.kanjiReading: 4},
      random: Random(2),
    ).map((d) => d.id).toList();
    expect(first, isNot(second));
  });

  test('the paper asks its 大問 in the order the paper asks them', () {
    final mixed = fileOf([
      q('q:n5-v-020', type: DrillType.paraphrase),
      q('q:n5-v-001'),
      q('q:n5-v-010', type: DrillType.context),
    ]);
    final drawn = DrillSampler.draw(
      mixed,
      counts: {
        DrillType.paraphrase: 1,
        DrillType.kanjiReading: 1,
        DrillType.context: 1,
      },
      random: Random(1),
    );
    expect(
      drawn.map((d) => d.type),
      [DrillType.kanjiReading, DrillType.context, DrillType.paraphrase],
      reason: 'the counts map is written in whatever order the JSON was',
    );
  });

  group('drawing by passage', () {
    final reading = DrillFile(
      level: JlptLevel.n5,
      section: DrillSection.reading,
      questions: [
        for (var p = 1; p <= 3; p++)
          for (var i = 1; i <= 3; i++)
            q('q:n5-r-${p}0$i', type: DrillType.mid, passage: 'p:n5-r-00$p'),
      ],
    );

    test('a passage comes whole, not one question from each of three', () {
      final drawn = DrillSampler.drawByPassage(
        reading,
        counts: {DrillType.mid: 3},
        random: Random(1),
      );
      expect(drawn, hasLength(3));
      expect(
        drawn.map((d) => d.passageId).toSet(),
        hasLength(1),
        reason: 'three texts read for three marks is three times the work',
      );
    });

    test('passages are taken until the count is met or passed', () {
      final drawn = DrillSampler.drawByPassage(
        reading,
        counts: {DrillType.mid: 4},
        random: Random(1),
      );
      expect(drawn, hasLength(6));
      expect(drawn.map((d) => d.passageId).toSet(), hasLength(2));
    });

    test('a passage every question of which is asked comes last', () {
      final drawn = DrillSampler.drawByPassage(
        reading,
        counts: {DrillType.mid: 3},
        asked: {'q:n5-r-101', 'q:n5-r-102', 'q:n5-r-103'},
        random: Random(7),
      );
      expect(drawn.first.passageId, isNot('p:n5-r-001'));
    });

    test('a section with no passages still draws its loose questions', () {
      // 文の文法1 has no passage and 文章の文法 does, and both live in the
      // grammar file, so the passage-aware draw has to serve both.
      final drawn = DrillSampler.drawByPassage(
        ten,
        counts: {DrillType.kanjiReading: 3},
        random: Random(1),
      );
      expect(drawn, hasLength(3));
      expect(drawn.every((d) => d.passageId == null), isTrue);
    });
  });

  test('a section with no questions is not offered', () {
    expect(
      DrillSampler.sectionsWithContent({
        DrillSection.vocab: ten,
        DrillSection.grammar: const DrillFile(
          level: JlptLevel.n5,
          section: DrillSection.grammar,
        ),
      }),
      {DrillSection.vocab},
    );
  });
}

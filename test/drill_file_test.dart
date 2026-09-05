import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';

/// Purpose: Test what a drill file can say and what the app refuses to read
/// from one.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The refusals matter more than the acceptances. These files are
/// written by a model, merged by a script and edited by hand, and a question
/// the app half-understands is worse than one it drops: a paper that quietly
/// marks the wrong option right teaches the wrong answer and looks exactly
/// like a paper that does not.
void main() {
  const locale = Locale('en');

  Map<String, Object?> question({
    String id = 'q:n5-v-001',
    String type = 'kanji-reading',
    Object? items = const ['vocab:jm1578850'],
    String kind = 'choice',
    Object? options = const ['こうえん', 'こえん', 'きょうえん', 'こうげん'],
    Object? answer = 0,
    Object? extra,
  }) => {
    'id': id,
    'type': type,
    'items': items,
    'kind': kind,
    'options': options,
    'answer': answer,
    'prompt': {'en': 'How is it read?', 'zh': '怎么读？'},
    ...?(extra as Map<String, Object?>?),
  };

  group('parsing one question', () {
    test('a well-formed question becomes one', () {
      final parsed = DrillQuestion.fromJson(
        question(
          extra: {
            'ja': '毎朝、公園を歩きます。',
            'reading': 'まいあさ、こうえんをあるきます。',
            'blank': '公園',
            'explanation': {'en': 'Kouen.', 'zh': '公园。'},
          },
        ),
      );
      expect(parsed, isNotNull);
      expect(parsed!.id, 'q:n5-v-001');
      expect(parsed.type, DrillType.kanjiReading);
      expect(parsed.type.section, DrillSection.vocab);
      expect(parsed.itemId, 'vocab:jm1578850');
      expect(parsed.kind, AnswerKind.choice);
      expect(parsed.answer, 0);
    });

    test('a question about nothing cannot be recorded, so it is dropped', () {
      expect(DrillQuestion.fromJson(question(items: const [])), isNull);
      expect(DrillQuestion.fromJson(question(items: null)), isNull);
    });

    test('an unknown 大問 is dropped rather than filed under a guess', () {
      // Filing it under vocabulary would score a listening question in the
      // wrong group, which is the one error a results screen cannot show.
      expect(DrillQuestion.fromJson(question(type: 'crossword')), isNull);
    });

    test('an answer that is not one of the options is dropped', () {
      expect(DrillQuestion.fromJson(question(answer: 4)), isNull);
      expect(DrillQuestion.fromJson(question(answer: -1)), isNull);
      expect(DrillQuestion.fromJson(question(answer: 'A')), isNull);
      expect(DrillQuestion.fromJson(question(answer: null)), isNull);
    });

    test('an empty option would be shown blank, so it is refused', () {
      expect(
        DrillQuestion.fromJson(
          question(options: const ['こうえん', '', 'きょうえん', 'こうげん']),
        ),
        isNull,
      );
    });

    test('fewer than two options is not a choice', () {
      expect(DrillQuestion.fromJson(question(options: const ['こうえん'])), isNull);
    });
  });

  group('an ordering question', () {
    Map<String, Object?> order({Object? answerOrder = const [1, 0, 2, 3]}) =>
        question(
          id: 'q:n5-g-020',
          type: 'sentence-composition',
          kind: 'order',
          items: const ['grammar:kara-reason'],
          answer: null,
          options: const ['から', '降っている', '出かけ', 'ませんでした'],
          extra: {
            'answerOrder': answerOrder,
            'frame': {'before': '雨が', 'after': '。'},
            'ja': '雨が降っているから出かけませんでした。',
          },
        );

    test('the fragments carry their order', () {
      final parsed = DrillQuestion.fromJson(order());
      expect(parsed, isNotNull);
      expect(parsed!.kind, AnswerKind.order);
      expect(parsed.answerOrder, [1, 0, 2, 3]);
      expect(parsed.frameBefore, '雨が');
      expect(parsed.frameAfter, '。');
    });

    test('an order that is not a permutation cannot be marked', () {
      // Two fragments claiming one position, or a position claimed by none:
      // either way the sentence cannot be rebuilt, so there is nothing to
      // mark the learner's ordering against.
      expect(
        DrillQuestion.fromJson(order(answerOrder: const [0, 0, 2, 3])),
        isNull,
      );
      expect(
        DrillQuestion.fromJson(order(answerOrder: const [1, 0, 2])),
        isNull,
      );
      expect(
        DrillQuestion.fromJson(order(answerOrder: const [1, 0, 2, 4])),
        isNull,
      );
      expect(DrillQuestion.fromJson(order(answerOrder: null)), isNull);
    });

    test('an ordering question needs no answer index', () {
      final parsed = DrillQuestion.fromJson(order())!;
      final quiz = parsed.toQuizQuestion(locale);
      expect(quiz.kind, AnswerKind.order);
      expect(quiz.answerOrder, [1, 0, 2, 3]);
    });
  });

  group('the adapter', () {
    QuizQuestion adapt(Map<String, Object?> json) =>
        DrillQuestion.fromJson(json)!.toQuizQuestion(locale);

    test('a gap type shows the gap, not the answer', () {
      final quiz = adapt(
        question(
          id: 'q:n5-g-001',
          type: 'form-selection',
          items: const ['grammar:tara'],
          extra: {
            'ja': '雨が降ったら行きません。',
            'reading': 'あめがふったらいきません。',
            'blank': '降ったら',
          },
        ),
      );
      expect(quiz.prompt, '雨が（　　）行きません。');
    });

    test('a marked type shows the word it is asking about', () {
      // 漢字読み asks how a word is read. Blanking it out would leave nothing
      // to read.
      final quiz = adapt(
        question(
          extra: {
            'ja': '毎朝、公園を歩きます。',
            'reading': 'まいあさ、こうえんをあるきます。',
            'blank': '公園',
          },
        ),
      );
      expect(quiz.prompt, '毎朝、【公園】を歩きます。');
    });

    test('the reading is withheld where the reading is the answer', () {
      final reading = adapt(
        question(
          extra: {
            'ja': '毎朝、公園を歩きます。',
            'reading': 'まいあさ、こうえんをあるきます。',
            'blank': '公園',
          },
        ),
      );
      expect(
        reading.promptReading,
        isNull,
        reason: 'furigana over 公園 would answer a 漢字読み question',
      );

      final gap = adapt(
        question(
          id: 'q:n5-g-001',
          type: 'form-selection',
          items: const ['grammar:tara'],
          extra: {'ja': '雨が降ったら行きません。', 'reading': 'あめがふったらいきません。'},
        ),
      );
      expect(gap.promptReading, 'あめがふったらいきません。');
    });

    test('a reading question asks its question, not an empty prompt', () {
      final quiz = adapt(
        question(
          id: 'q:n5-r-001',
          type: 'short',
          items: const ['grammar:te-kara'],
          options: const ['起きます', '朝ご飯を食べます', '学校へ行きます', '寝ます'],
          answer: 1,
          extra: {'passage': 'p:n5-r-001'},
        ),
      );
      expect(quiz.prompt, 'How is it read?');
      expect(quiz.instruction, isNull);
      expect(quiz.passageId, 'p:n5-r-001');
      expect(
        quiz.speakText,
        isNull,
        reason: 'the script player speaks a listening drill, not a button',
      );
    });

    test(
      'a written question keeps the paper instruction as the small line',
      () {
        final quiz = adapt(
          question(extra: {'ja': '毎朝、公園を歩きます。', 'reading': 'まいあさ、こうえんをあるきます。'}),
        );
        expect(quiz.instruction, 'How is it read?');
        expect(quiz.prompt, '毎朝、公園を歩きます。');
      },
    );

    test('a drill question is scored by its own id', () {
      // A paper asks several questions about one word. Scored by item they
      // would be one question asked once, and the rest would never count.
      final quiz = adapt(question());
      expect(quiz.questionId, 'q:n5-v-001');
      expect(quiz.mode, QuizMode.drill);
    });
  });

  group('the file', () {
    Map<String, Object?> file({
      String level = 'N5',
      String section = 'vocab',
      Object? questions,
    }) => {
      'level': level,
      'section': section,
      'questions': questions ?? [question()],
    };

    test('a file loads its questions', () {
      final parsed = DrillFile.fromJson(
        file(),
        level: JlptLevel.n5,
        section: DrillSection.vocab,
      );
      expect(parsed.questions, hasLength(1));
      expect(parsed.isEmpty, isFalse);
    });

    test('a file that disagrees with its own name loads nothing', () {
      // A merge run against the wrong section is exactly how this arrives,
      // and loading it anyway would score N4 grammar as N5 vocabulary.
      final parsed = DrillFile.fromJson(
        file(level: 'N4'),
        level: JlptLevel.n5,
        section: DrillSection.vocab,
      );
      expect(parsed.isEmpty, isTrue);

      final crossed = DrillFile.fromJson(
        file(section: 'grammar'),
        level: JlptLevel.n5,
        section: DrillSection.vocab,
      );
      expect(crossed.isEmpty, isTrue);
    });

    test('one bad question costs the question, not the file', () {
      final parsed = DrillFile.fromJson(
        file(
          questions: [
            question(),
            question(id: 'q:n5-v-002', answer: 9),
          ],
        ),
        level: JlptLevel.n5,
        section: DrillSection.vocab,
      );
      expect(parsed.questions, hasLength(1));
      expect(parsed.questions.single.id, 'q:n5-v-001');
    });

    test('a passage is found by id and only by an id there is', () {
      final parsed = DrillFile.fromJson(
        {
          'level': 'N5',
          'section': 'reading',
          'passages': [
            {
              'id': 'p:n5-r-001',
              'type': 'short',
              'lines': [
                {'ja': '私は毎朝七時に起きます。', 'reading': 'わたしはまいあさしちじにおきます。'},
              ],
              'en': 'I get up at seven.',
            },
          ],
          'questions': const [],
        },
        level: JlptLevel.n5,
        section: DrillSection.reading,
      );

      expect(parsed.passages, hasLength(1));
      expect(parsed.passageById('p:n5-r-001')?.lines, hasLength(1));
      expect(parsed.passageById('p:n5-r-999'), isNull);
      expect(parsed.passageById(null), isNull);
    });
  });

  group('the structure', () {
    final structure = JlptStructure.fromJson({
      'source': 'jlpt.jp',
      'levels': {
        'N5': {
          'blocks': [
            {
              'sections': ['vocab'],
              'minutes': 20,
            },
            {
              'sections': ['grammar', 'reading'],
              'minutes': 40,
            },
          ],
          'scoring': [
            {
              'id': 'languageReading',
              'sections': ['vocab', 'grammar', 'reading'],
              'max': 120,
              'pass': 38,
            },
          ],
          'types': {'kanji-reading': 7, 'info': 1, 'crossword': 4},
          'overallMax': 180,
          'overallPass': 80,
        },
      },
    });

    test('the levels and their blocks are read', () {
      final level = structure.forLevel(JlptLevel.n5)!;
      expect(structure.source, 'jlpt.jp');
      expect(level.blocks, hasLength(2));
      expect(level.blocks[1].sections, [
        DrillSection.grammar,
        DrillSection.reading,
      ]);
      expect(level.overallPass, 80);
    });

    test('a 大問 this build has no enum for is dropped, not fatal', () {
      final level = structure.forLevel(JlptLevel.n5)!;
      expect(level.types.keys, [DrillType.kanjiReading, DrillType.info]);
      expect(level.fullCount, 8);
    });

    test('a short paper is a third, rounded up, never below one', () {
      final level = structure.forLevel(JlptLevel.n5)!;
      final short = level.composition(ExamScale.short);
      expect(short[DrillType.kanjiReading], 3);
      expect(
        short[DrillType.info],
        1,
        reason: 'a third of one question is still a 大問 on the paper',
      );
      expect(level.composition(ExamScale.full)[DrillType.kanjiReading], 7);
    });

    test('the block minutes scale with the paper', () {
      final level = structure.forLevel(JlptLevel.n5)!;
      expect(level.minutes(ExamScale.full), [20, 40]);
      expect(level.minutes(ExamScale.short), [7, 14]);
    });

    test('a section knows which group it is scored in', () {
      final level = structure.forLevel(JlptLevel.n5)!;
      expect(level.groupFor(DrillSection.reading)?.id, 'languageReading');
      expect(level.groupFor(DrillSection.listening), isNull);
    });

    test('a structure file that will not load is empty, not a crash', () {
      expect(JlptStructure.fromJson(null).levels, isEmpty);
      expect(JlptStructure.fromJson({'levels': 3}).levels, isEmpty);
      expect(
        JlptStructure.fromJson({
          'levels': {'N5': {}},
        }).forLevel(JlptLevel.n5),
        isNull,
      );
    });
  });
}

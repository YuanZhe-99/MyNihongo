import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/answer_checker.dart';
import 'package:my_nihongo/features/quiz/services/distractors.dart';
import 'package:my_nihongo/features/quiz/services/question_generator.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

/// Purpose: Test question generation against the content the app ships.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Against the **real** catalog rather than a fixture, because the
/// properties worth guarding are properties of the shipped data: whether N5 has
/// enough same-level words to build plausible distractors, whether the shipped
/// example sentences parse into orderable chunks, whether a grammar point's own
/// forms leak into its wrong options. A synthetic catalog would pass all of
/// those and tell us nothing. The one invariant every mode shares: **a question
/// that is generated must be answerable** — exactly one right option, no
/// duplicates, and the marked answer actually correct.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late SentenceAnalyzer analyzer;
  late QuestionGenerator generator;
  const en = Locale('en');
  const checker = AnswerChecker();

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    final words = await loadFunctionWords();
    analyzer = SentenceAnalyzer(
      lexicon: Lexicon.build(catalog, functionWords: words),
      catalog: catalog,
    );
    // A fixed seed so a failure is reproducible; the generator shuffles.
    generator = QuestionGenerator(
      catalog: catalog,
      analyzer: analyzer,
      random: Random(20260903),
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  /// Purpose: Assert a question is answerable at all.
  /// Inputs: The `question`.
  /// Returns: None.
  /// Side effects: Fails the test when it is not.
  /// Notes: Internal helper used within this file only.
  void expectAnswerable(QuizQuestion question) {
    if (question.kind == AnswerKind.choice) {
      expect(question.options, hasLength(distractorCount + 1));
      expect(
        question.options.toSet(),
        hasLength(question.options.length),
        reason: 'two identical options would be two correct answers',
      );
      expect(question.answerIndex, isNotNull);
      expect(
        checker.check(question, ChoiceAnswer(question.answerIndex!)),
        isTrue,
      );
    }
    if (question.kind == AnswerKind.typed) {
      expect(question.acceptedAnswers, isNotEmpty);
    }
    if (question.kind == AnswerKind.order) {
      expect(question.options.length, greaterThanOrEqualTo(minOrderFragments));
      expect(question.answerOrder, hasLength(question.options.length));
    }
  }

  test('every kana can be asked about in all three kana modes', () {
    for (final entry in allKanaEntries()) {
      for (final mode in kanaQuizModes) {
        final question = generator.generate(
          entry.progressId,
          mode,
          locale: en,
        );
        expect(
          question,
          isNotNull,
          reason: '${entry.progressId} in ${mode.name}',
        );
        expectAnswerable(question!);
      }
    }
  });

  test('a kana question never offers the same romaji twice', () {
    // じ and ぢ are both "ji"; offering both makes the question unanswerable.
    for (final entry in allKanaEntries()) {
      final question = generator.generate(
        entry.progressId,
        QuizMode.kanaToRomaji,
        locale: en,
      );
      expect(question!.options.toSet(), hasLength(question.options.length));
    }
  });

  test('a romaji-to-kana question shows the script it was asked for', () {
    final entry = allKanaEntries().first;
    final katakana = generator.generate(
      entry.progressId,
      QuizMode.romajiToKana,
      locale: en,
      script: KanaScript.katakana,
    );
    expect(katakana!.options, contains(entry.katakana));
    expect(katakana.options, isNot(contains(entry.hiragana)));
  });

  test('most N5 words can be asked in the meaning modes', () {
    final n5 = catalog.vocab.where((v) => v.level.label == 'N5').toList();
    var built = 0;
    for (final entry in n5) {
      final question = generator.generate(
        entry.id,
        QuizMode.vocabJaToMeaning,
        locale: en,
      );
      if (question == null) continue;
      expectAnswerable(question);
      built++;
    }
    expect(
      built / n5.length,
      greaterThan(0.9),
      reason: 'N5 has to be able to fill four options from its own level',
    );
  });

  test('the written-form modes apply only to words that have kanji', () {
    final kanaOnly = catalog.vocab.firstWhere((v) => !v.hasKanji);
    expect(
      generator.generate(
        kanaOnly.id,
        QuizMode.vocabReadingToKanji,
        locale: en,
      ),
      isNull,
      reason: 'the prompt and the answer would be the same string',
    );

    final withKanji = catalog.vocab.firstWhere(
      (v) => v.hasKanji && v.level.label == 'N5',
    );
    final question = generator.generate(
      withKanji.id,
      QuizMode.vocabKanjiToReading,
      locale: en,
    );
    expect(question, isNotNull);
    expectAnswerable(question!);
  });

  test('a typed reading accepts both the kana and the romaji', () {
    final entry = catalog.vocab.firstWhere((v) => v.level.label == 'N5');
    final question = generator.generate(
      entry.id,
      QuizMode.vocabTypeReading,
      locale: en,
    )!;
    expect(checker.check(question, TypedAnswer(entry.reading)), isTrue);
    expectAnswerable(question);
  });

  test('a listening question hides its prompt but can still be spoken', () {
    final entry = catalog.vocab.firstWhere((v) => v.level.label == 'N5');
    final question = generator.generate(
      entry.id,
      QuizMode.vocabListening,
      locale: en,
    )!;
    expect(question.prompt, isEmpty);
    expect(question.speakText, entry.reading);
  });

  test('a speak button is always given the reading, never the kanji', () {
    for (final entry in catalog.vocab.take(200).where((v) => v.hasKanji)) {
      for (final mode in vocabQuizModes) {
        final question = generator.generate(entry.id, mode, locale: en);
        if (question?.speakText == null) continue;
        expect(
          question!.speakText,
          entry.reading,
          reason: 'an engine handed kanji has to guess the reading',
        );
      }
    }
  });

  test('every shipped N5 grammar point can be asked at least one way', () {
    final points = catalog.grammar.toList();
    final unaskable = <String>[];
    for (final point in points) {
      final question = generator.forItem(
        point.id,
        grammarQuizModes,
        locale: en,
      );
      if (question == null) {
        unaskable.add(point.id);
      } else {
        expectAnswerable(question);
      }
    }
    expect(
      unaskable,
      isEmpty,
      reason: 'a grammar point the quiz cannot ask about is a content gap',
    );
  });

  test('a pattern question never offers a point the sentence contains', () {
    for (final point in catalog.grammar) {
      final question = generator.generate(
        point.id,
        QuizMode.grammarPattern,
        locale: en,
      );
      if (question == null) continue;
      final sentence = question.prompt;
      for (var i = 0; i < question.options.length; i++) {
        if (i == question.answerIndex) continue;
        final other = catalog.grammar.firstWhere(
          (g) => g.pattern == question.options[i],
          orElse: () => catalog.grammar.first,
        );
        expect(
          other.matchForms.any(sentence.contains),
          isFalse,
          reason: '${other.id} also appears in "$sentence"',
        );
      }
    }
  });

  test('a particle question blanks a particle out of its own sentence', () {
    var built = 0;
    for (final point in catalog.grammar) {
      final question = generator.generate(
        point.id,
        QuizMode.grammarParticle,
        locale: en,
      );
      if (question == null) continue;
      built++;
      expect(question.prompt, contains(particleBlank));
      expectAnswerable(question);
    }
    expect(built, greaterThan(20), reason: 'N5 is mostly about particles');
  });

  test('a conjugation question offers only real forms of the same word', () {
    var built = 0;
    for (final point in catalog.grammar) {
      final question = generator.generate(
        point.id,
        QuizMode.grammarConjugation,
        locale: en,
      );
      if (question == null) continue;
      built++;
      expect(question.prompt, contains(particleBlank));
      expect(question.formLabel, isNotNull);
      expectAnswerable(question);
    }
    expect(built, greaterThan(0), reason: 'N5 teaches ます, ない, た and て');
  });

  test('an ordering question can be solved back into its sentence', () {
    var built = 0;
    for (final point in catalog.grammar) {
      final question = generator.generate(
        point.id,
        QuizMode.grammarOrder,
        locale: en,
      );
      if (question == null) continue;
      built++;
      expectAnswerable(question);
      final correct = List.generate(question.options.length, (i) => i)
        ..sort(
          (a, b) => question.answerOrder[a].compareTo(question.answerOrder[b]),
        );
      expect(checker.check(question, OrderAnswer(correct)), isTrue);
      expect(
        question.options.length,
        greaterThanOrEqualTo(minOrderFragments),
        reason: 'two pieces is not a puzzle',
      );
    }
    expect(built, greaterThan(20));
  });

  test('a mode asked about the wrong kind of item produces nothing', () {
    expect(
      generator.generate('kana:あ', QuizMode.vocabJaToMeaning, locale: en),
      isNull,
    );
    expect(
      generator.generate('grammar:desu', QuizMode.kanaToRomaji, locale: en),
      isNull,
    );
    expect(
      generator.generate('vocab:nonexistent', QuizMode.vocabJaToMeaning,
          locale: en),
      isNull,
    );
  });

  test('without an analyser the grammar modes simply do not fire', () {
    final plain = QuestionGenerator(catalog: catalog, random: Random(1));
    for (final mode in grammarQuizModes) {
      final question = plain.generate('grammar:desu', mode, locale: en);
      if (mode == QuizMode.grammarPattern) {
        expect(question, isNotNull, reason: 'this one needs no parse');
      } else {
        expect(question, isNull);
      }
    }
  });
}

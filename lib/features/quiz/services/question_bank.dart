import 'dart:math';
import 'dart:ui';

import '../../content/models/content_catalog.dart';
import '../../lessons/models/lesson_path.dart';
import '../../progress/models/study_record.dart';
import '../models/quiz_question.dart';
import 'question_generator.dart';

/// Every question a unit can ask, and a weighted draw from them.
///
/// The quiz until now asked about a level: shuffle its items, take twenty.
/// A unit asks about a topic, and a topic is small enough that the pool can be
/// built whole — every enabled mode over every item, plus the sentences and
/// the questions written for that unit — and then drawn from. Building it
/// whole is what makes the draw fair: a rare mode is as likely as a common one
/// because both are in the same bag.
class QuestionBank {
  /// Purpose: Hold a unit's questions.
  /// Inputs: `questions`, already built.
  /// Returns: A new `QuestionBank` instance.
  /// Side effects: None.
  /// Notes: None.
  const QuestionBank(this.questions);

  /// Every question this unit can ask, in no particular order.
  final List<QuizQuestion> questions;

  /// Whether the unit could produce nothing at all.
  bool get isEmpty => questions.isEmpty;

  /// Purpose: Build every question one unit can ask.
  /// Inputs: The `unit`, the `catalog`, a `generator`, the enabled `modes`,
  /// and the `locale` the prompts are written in.
  /// Returns: `QuestionBank`.
  /// Side effects: None.
  /// Notes: Three sources, in this order. The catalog items the unit teaches,
  /// asked every enabled way that works for them. The unit's own sentences,
  /// which the grammar modes can blank and shuffle exactly as they do a
  /// catalog example. And the questions somebody wrote for this unit, which
  /// are the only ones with an explanation attached.
  ///
  /// Duplicates are dropped by prompt, because the same sentence reaching the
  /// pool from two directions would be asked twice in one session.
  static QuestionBank build({
    required LessonUnit unit,
    required ContentCatalog catalog,
    required QuestionGenerator generator,
    required Set<QuizMode> modes,
    required Locale locale,
  }) {
    final out = <QuizQuestion>[];
    final seen = <String>{};

    void add(QuizQuestion? question) {
      if (question == null) return;
      final key = '${question.itemId}/${question.mode.name}/${question.prompt}';
      if (!seen.add(key)) return;
      out.add(question);
    }

    for (final item in unit.items) {
      for (final mode in modes) {
        add(generator.generate(item, mode, locale: locale));
      }
    }

    for (final sentence in unit.sentences) {
      for (final item in sentence.items) {
        if (studyKindOf(item) != StudyKind.grammar) continue;
        for (final mode in modes) {
          add(
            generator.fromSentence(
              itemId: item,
              example: sentence.toExample(),
              mode: mode,
              locale: locale,
            ),
          );
        }
      }
    }

    for (final authored in unit.questions) {
      add(_authored(authored, locale));
    }

    return QuestionBank(out);
  }

  /// Purpose: Turn a hand-written question into a quiz question.
  /// Inputs: The `authored` question and the `locale`.
  /// Returns: `QuizQuestion?` — null when its prompt has no text.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The options are used
  /// exactly as written, in the order they were written: a hand-written
  /// question's options are often an ordered set — a conjugation table, a
  /// sequence of counters — and shuffling them would be a change to the
  /// question rather than to its presentation.
  static QuizQuestion? _authored(AuthoredQuestion authored, Locale locale) {
    final prompt = authored.prompt.resolveJoined(locale);
    if (prompt.isEmpty) return null;
    return QuizQuestion(
      itemId: authored.item,
      mode: QuizMode.grammarPattern,
      kind: AnswerKind.choice,
      prompt: prompt,
      options: authored.options,
      answerIndex: authored.answer,
      explanation: authored.explanation?.resolveJoined(locale),
    );
  }

  /// Purpose: Draw a session's worth of questions from the pool.
  /// Inputs: How many to draw (`count`), the learner's `progress`, and a
  /// `random` so a draw can be reproduced in a test.
  /// Returns: `List<QuizQuestion>`.
  /// Side effects: None.
  /// Notes: Weighted, and by exactly one thing: what the learner has not got
  /// right yet. An item with no record weighs three, one whose last answer was
  /// wrong weighs two, everything else one; a hand-written question weighs
  /// double, because somebody chose it. **At most one question per item**, so
  /// a twelve-question session is twelve different things rather than one word
  /// asked six ways.
  List<QuizQuestion> draw(
    int count, {
    required ProgressData progress,
    Random? random,
  }) {
    final rng = random ?? Random();
    final records = {for (final record in progress.records) record.id: record};
    final byItem = <String, List<QuizQuestion>>{};
    for (final question in questions) {
      (byItem[question.itemId] ??= []).add(question);
    }

    final weighted = <String>[];
    for (final item in byItem.keys) {
      final record = records[item];
      var weight = record == null
          ? 3
          : record.correct == 0
          ? 2
          : 1;
      if (byItem[item]!.any((q) => q.explanation != null)) weight *= 2;
      for (var i = 0; i < weight; i++) {
        weighted.add(item);
      }
    }

    final chosen = <QuizQuestion>[];
    final used = <String>{};
    while (chosen.length < count && used.length < byItem.length) {
      final item = weighted[rng.nextInt(weighted.length)];
      if (!used.add(item)) continue;
      final options = byItem[item]!;
      chosen.add(options[rng.nextInt(options.length)]);
    }
    return chosen;
  }
}

import 'dart:ui';

import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/practice_prompt_builder.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/grammar_point.dart';
import '../../content/models/vocab_entry.dart';
import '../../lessons/models/lesson_path.dart';
import '../models/quiz_question.dart';

/// How many generated questions a single session may receive.
const maxGeneratedQuestions = 3;

/// Asks the on-device model for extra questions about a unit.
///
/// Everything here is written so that a bad answer costs nothing. A generated
/// question is [QuizQuestion.generated], which keeps it out of the spaced
/// repetition scheduler; it arrives **after** the session has already started,
/// so waiting for a model never delays the first question; and every reply is
/// checked against the rules below before it becomes a question at all. A
/// reply that fails any of them is dropped in silence, because the session is
/// already complete without it.
class AiQuestionGenerator {
  /// Purpose: Build a generator for one unit.
  /// Inputs: The `unit`, the `catalog` its ids resolve through, the prompt
  /// `builder`, the `locale`, and the `service` that runs the model.
  /// Returns: A new `AiQuestionGenerator` instance.
  /// Side effects: None.
  /// Notes: The service is injected so a test can supply replies without a
  /// device; nothing here knows what backend is behind it.
  const AiQuestionGenerator({
    required this.unit,
    required this.catalog,
    required this.builder,
    required this.locale,
    required this.service,
  });

  /// The unit the questions are about.
  final LessonUnit unit;

  /// The catalog the unit's ids resolve through.
  final ContentCatalog catalog;

  /// Builds the prompt for one grammar point.
  final PracticePromptBuilder builder;

  /// Which language the model is asked to answer in.
  final Locale locale;

  /// Runs the model.
  final AiPracticeService service;

  /// Purpose: Generate questions one at a time, as they arrive.
  /// Inputs: `limit` — how many to ask for; `avoid` — prompts the session
  /// already has, so a generated question never repeats one.
  /// Returns: A stream of accepted `QuizQuestion`s.
  /// Side effects: Runs a model on the device, once per grammar point tried.
  /// Notes: A stream rather than a list because each question is useful the
  /// moment it exists: the session appends it and the learner may reach it
  /// while the next one is still being written.
  Stream<QuizQuestion> generate({
    int limit = maxGeneratedQuestions,
    Set<String> avoid = const {},
  }) async* {
    final seen = {...avoid};
    var made = 0;
    for (final id in unit.grammar) {
      if (made >= limit) return;
      final point = catalog.grammarById(id);
      if (point == null) continue;
      final prompt = builder.forQuiz(point, words: _words, locale: locale);
      if (prompt == null) continue;
      final raw = await service.runInBackground(prompt);
      if (raw == null) continue;
      final question = parse(raw, point: point);
      if (question == null || !seen.add(question.prompt)) continue;
      made++;
      yield question;
    }
  }

  /// The unit's words, for grounding the prompt.
  List<VocabEntry> get _words => [
    for (final id in unit.vocab) ?catalog.vocabById(id),
  ];

  /// Purpose: Turn one model reply into a question, or refuse it.
  /// Inputs: The `raw` reply and the `point` it was asked about.
  /// Returns: `QuizQuestion?` — null whenever anything is off.
  /// Side effects: None.
  /// Notes: The checks are deliberately strict, and every one of them has a
  /// failure it prevents: a missing line means the model answered in prose; a
  /// repeated option means one of the four is not a distractor; a blank left
  /// out of the sentence means nothing is being asked; an answer letter with
  /// no option behind it means the reply contradicts itself. None of those can
  /// be repaired by guessing, and a guessed question is worse than no question
  /// because it looks exactly like an authored one.
  static QuizQuestion? parse(String raw, {required GrammarPoint point}) {
    String? sentence;
    String? answer;
    String? why;
    final options = <String, String>{};
    for (final line in raw.split('\n')) {
      final text = line.trim();
      if (_after(text, 'Q') case final value? when sentence == null) {
        sentence = value;
        continue;
      }
      for (final letter in const ['A', 'B', 'C', 'D']) {
        if (_after(text, letter) case final value?) {
          options.putIfAbsent(letter, () => value);
        }
      }
      answer ??= _after(text, 'Answer');
      why ??= _after(text, 'Why');
    }

    if (sentence == null || sentence.isEmpty) return null;
    if (!sentence.contains('＿') && !sentence.contains('_')) return null;
    if (options.length != 4) return null;
    final letters = const ['A', 'B', 'C', 'D'];
    final values = [for (final letter in letters) options[letter]!];
    if (values.any((value) => value.isEmpty)) return null;
    if (values.toSet().length != 4) return null;
    final index = letters.indexOf((answer ?? '').toUpperCase());
    if (index < 0) return null;

    return QuizQuestion(
      itemId: point.id,
      mode: QuizMode.grammarPattern,
      kind: AnswerKind.choice,
      prompt: sentence,
      options: values,
      answerIndex: index,
      explanation: (why?.isEmpty ?? true) ? null : why,
      generated: true,
    );
  }

  /// Purpose: Take what follows a one-letter or word label.
  /// Inputs: `line`, `label`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Either kind of colon,
  /// because a model writing Chinese reaches for the full-width one about as
  /// often as the ASCII one.
  static String? _after(String line, String label) {
    final match = RegExp(
      '^${RegExp.escape(label)}\\s*[:：]\\s*',
      caseSensitive: false,
    ).firstMatch(line);
    return match == null ? null : line.substring(match.end).trim();
  }
}

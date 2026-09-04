import 'dart:ui';

import '../../content/models/content_catalog.dart';
import '../../content/models/localized_strings.dart';
import '../../content/models/vocab_entry.dart';
import 'prompt_builder.dart';

/// Where `assets/content/prompts/practice.json` lives.
const practicePromptAsset = 'assets/content/prompts/practice.json';

/// Builds the prompts for the practice tasks.
///
/// Every one of them is grounded in something the app already computed or
/// already shows — the learner's own text, the catalog's own explanation, the
/// question exactly as it was worded on screen. That is what keeps an answer
/// consistent with what the rest of the app says, and it is why the model is
/// never asked an open question about Japanese.
class PracticePromptBuilder {
  /// Purpose: Build prompts from a set of templates.
  /// Inputs: `templates`, loaded from the asset.
  /// Returns: A new `PracticePromptBuilder` instance.
  /// Side effects: None.
  /// Notes: Every method returns null when its template is missing, so a build
  /// whose asset failed to load simply offers no AI actions rather than
  /// sending the model an empty instruction.
  const PracticePromptBuilder(this.templates);

  /// The parsed templates.
  final PromptTemplates templates;

  /// Purpose: Ask for a rewrite of what the learner wrote.
  /// Inputs: The learner's `text`, the `unitWords` the exercise is built on,
  /// any `grammarNotes` the app matched, and the `locale`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Refuses text over `maxWritingChars` rather than truncating it. A
  /// rewrite of half a paragraph is not a rewrite, and a learner who cannot
  /// see where it was cut cannot tell why the feedback stops.
  String? forWriting(
    String text, {
    List<VocabEntry> unitWords = const [],
    List<String> grammarNotes = const [],
    required Locale locale,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > templates.limit('maxWritingChars', 600)) return null;
    return _build('writing', locale, (labels, out) {
      out.writeln('${labels['learner'] ?? 'Learner'}: $trimmed');
      if (unitWords.isNotEmpty) {
        final capped = unitWords.take(templates.limit('maxVocabInPrompt', 12));
        out.writeln(
          '${labels['vocabulary'] ?? 'Vocabulary'}: '
          '${capped.map((w) => w.headword).join('、')}',
        );
      }
      for (final note in grammarNotes) {
        out.writeln('${labels['grammar'] ?? 'Grammar'}: $note');
      }
    });
  }

  /// Purpose: Ask whether a free answer means the same as the model answer.
  /// Inputs: The learner's `answer`, the `expected` answer, and the `locale`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Both sides are capped, because a free answer this long is not the
  /// kind of question this grades.
  String? forGrading(
    String answer,
    String expected, {
    required Locale locale,
  }) {
    final limit = templates.limit('maxAnswerChars', 200);
    if (answer.trim().isEmpty || expected.trim().isEmpty) return null;
    if (answer.length > limit || expected.length > limit) return null;
    return _build('grade', locale, (labels, out) {
      out
        ..writeln('${labels['learner'] ?? 'Learner'}: ${answer.trim()}')
        ..writeln('${labels['expected'] ?? 'Expected'}: ${expected.trim()}');
    });
  }

  /// Purpose: Ask why the answer the learner chose was wrong.
  /// Inputs: The `question` as worded on screen, what they `chose`, the
  /// `correct` option, the catalog's own `grammarNote` where there is one, and
  /// the `locale`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: The question is passed **exactly as the app worded it**, the same
  /// rule the sentence lab follows: an answer to a differently worded question
  /// is worse than none.
  String? forWhyWrong({
    required String question,
    required String chosen,
    required String correct,
    String? grammarNote,
    required Locale locale,
  }) {
    if (question.trim().isEmpty || chosen.trim().isEmpty) return null;
    return _build('whyWrong', locale, (labels, out) {
      out
        ..writeln('${labels['question'] ?? 'Question'}: ${question.trim()}')
        ..writeln('${labels['chosen'] ?? 'Chosen'}: ${chosen.trim()}')
        ..writeln('${labels['correct'] ?? 'Correct'}: ${correct.trim()}');
      if (grammarNote != null && grammarNote.trim().isNotEmpty) {
        final capped = grammarNote.trim();
        final limit = templates.limit('maxGrammarExcerptChars', 300);
        out.writeln(
          '${labels['grammar'] ?? 'Grammar'}: '
          '${capped.length > limit ? capped.substring(0, limit) : capped}',
        );
      }
    });
  }

  /// Purpose: Ask for extra example sentences for one word.
  /// Inputs: The `entry`, the `catalog` for its level, and the `locale`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: The word's own meaning is included so the sentences show the sense
  /// the catalog teaches rather than whichever sense the model thought of.
  String? forExamples(
    VocabEntry entry, {
    ContentCatalog? catalog,
    required Locale locale,
  }) => _build('examples', locale, (labels, out) {
    out
      ..writeln('${labels['sentence'] ?? 'Word'}: ${entry.headword}'
          '（${entry.reading}）')
      ..writeln('${labels['expected'] ?? 'Meaning'}: '
          '${entry.meanings.resolveJoined(locale)}')
      ..writeln('JLPT: ${entry.level.label}');
  });

  /// Purpose: Assemble one prompt from a task template.
  /// Inputs: The `task` name, the `locale`, and a `body` writer.
  /// Returns: `String?` — null when the task has no template.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Same shape as
  /// `PromptBuilder._build`: instruction, blank line, the grounding the body
  /// writes, then the rules. The whole prompt is capped, and a prompt over the
  /// cap is refused rather than cut — a truncated rule list is a prompt with
  /// the rules missing.
  String? _build(
    String task,
    Locale locale,
    void Function(Map<String, String> labels, StringBuffer out) body,
  ) {
    final byLanguage = templates.tasks[task];
    if (byLanguage == null || byLanguage.isEmpty) return null;
    final keys = LocalizedStrings.lookupOrder(locale);
    final template = keys.map((key) => byLanguage[key]).nonNulls.firstOrNull;
    if (template == null) return null;
    final labels =
        keys.map((key) => templates.labels[key]).nonNulls.firstOrNull ??
        const <String, String>{};

    final out = StringBuffer()
      ..writeln(template.instruction)
      ..writeln();
    body(labels, out);
    out
      ..writeln()
      ..writeln('${labels['rules'] ?? 'Rules'}:');
    for (final rule in template.rules) {
      out.writeln('- $rule');
    }
    final prompt = out.toString();
    return prompt.length > templates.limit('maxPromptChars', 4000)
        ? null
        : prompt;
  }
}

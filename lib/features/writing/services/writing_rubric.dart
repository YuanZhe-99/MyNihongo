/// Purpose: Say what the app itself can measure about a piece of writing —
/// how much was written, how much of the unit was used, and how much of it
/// sits at the level the learner is aiming at.
/// Inputs: The analyses the deterministic pipeline already produced, the unit
/// the exercise belongs to, and the catalog.
/// Returns: An immutable value.
/// Side effects: None — pure, so the whole rubric is testable without a model
/// or a device.
/// Notes: **This runs whether or not there is a model on the device**, and it
/// is what the AI note is written on top of rather than a fallback for when
/// the model is missing. A learner is entitled to the same measurements on
/// every phone; what the model adds is a sentence about what to try next, and
/// that is the part it is allowed to add.
///
/// Nothing here is a mark. There is no total, no percentage and no pass line,
/// because 作文 is not on the JLPT and inventing a score for it would be the
/// app asserting something no examiner would.
library;

import '../../content/models/content_catalog.dart';
import '../../content/models/jlpt_level.dart';
import '../../lessons/models/lesson_path.dart';
import '../../sentence/models/sentence_analysis.dart';
import '../../sentence/models/token.dart';

/// How many of the unit's words a piece of writing aims to use.
///
/// The same number the writing page already shows, kept here so the rubric and
/// the line above it cannot disagree.
const writingRubricWordTarget = 3;

/// What the app measured about one piece of writing.
class WritingRubric {
  /// Purpose: Hold one set of measurements.
  /// Inputs: All fields.
  /// Returns: A new `WritingRubric` instance.
  /// Side effects: None.
  /// Notes: Built by [build]; nothing else constructs one outside tests.
  const WritingRubric({
    this.sentences = 0,
    this.wordsUsed = const {},
    this.wordsWanted = 0,
    this.grammarUsed = const {},
    this.tokensAtLevel = 0,
    this.tokensPlaced = 0,
    this.unreadable = 0,
  });

  /// How many sentences were written.
  final int sentences;

  /// Which of the unit's words were actually used, by catalog id.
  final Set<String> wordsUsed;

  /// How many the unit teaches.
  final int wordsWanted;

  /// Which taught grammar points the analyser found, by catalog id.
  final Set<String> grammarUsed;

  /// How many placed tokens are at the target level or easier.
  final int tokensAtLevel;

  /// How many tokens the catalog could place at all.
  final int tokensPlaced;

  /// How many tokens could not be read.
  final int unreadable;

  /// Whether there is anything to report.
  bool get isEmpty => sentences == 0;

  /// The share of placed tokens at the target level or easier, 0 to 1.
  ///
  /// One when nothing could be placed: a rubric that scolds a learner for
  /// words it could not look up is measuring the catalog, not the writing.
  double get levelShare =>
      tokensPlaced == 0 ? 1 : tokensAtLevel / tokensPlaced;

  /// Whether the unit's word target was met.
  bool get metWordTarget =>
      wordsWanted == 0 || wordsUsed.length >= writingRubricWordTarget;

  /// Purpose: Measure one piece of writing.
  /// Inputs: The `analyses`, one per sentence; the `unit` where there is one;
  /// the `catalog`; and the `level` the learner is aiming at.
  /// Returns: `WritingRubric`.
  /// Side effects: None.
  /// Notes: The words used are counted from the **parse**, not by searching
  /// the text, so an inflected form counts: somebody who wrote 食べました used
  /// 食べる. The same is true of the grammar, which comes from the analyser's
  /// own matches rather than from string matching — the app already has a
  /// better answer than a search would give.
  ///
  /// A token the catalog cannot place is counted as unreadable rather than as
  /// above the level. Not knowing what a word is and knowing it is too hard
  /// are different findings, and only the second is about the learner.
  static WritingRubric build({
    required List<SentenceAnalysis> analyses,
    LessonUnit? unit,
    ContentCatalog? catalog,
    required JlptLevel level,
  }) {
    if (analyses.isEmpty) return const WritingRubric();
    final wanted = unit?.vocab.toSet() ?? const <String>{};
    final used = <String>{};
    final grammar = <String>{};
    var placed = 0;
    var atLevel = 0;
    var unreadable = 0;

    for (final analysis in analyses) {
      for (final match in analysis.grammar) {
        grammar.add(match.pointId);
      }
      for (final token in analysis.tokens) {
        if (token.category == TokenCategory.unknown) {
          unreadable++;
          continue;
        }
        final id = token.refId;
        if (id == null) continue;
        if (wanted.contains(id)) used.add(id);
        final entry = catalog?.vocabById(id);
        if (entry == null) continue;
        placed++;
        if (entry.level.index <= level.index) atLevel++;
      }
    }

    return WritingRubric(
      sentences: analyses.length,
      wordsUsed: used,
      wordsWanted: wanted.length,
      grammarUsed: grammar,
      tokensAtLevel: atLevel,
      tokensPlaced: placed,
      unreadable: unreadable,
    );
  }

  /// Purpose: Say what was measured, in lines a prompt can carry.
  /// Inputs: `level` — named so the model knows what "at level" meant.
  /// Returns: `List<String>`; empty for an empty rubric.
  /// Side effects: None.
  /// Notes: English, and deliberately: these lines go into a prompt, never
  /// onto the screen. The screen renders the same numbers through the ARB
  /// catalogs in the learner's own language; this is the model's copy, and
  /// keeping the two apart is what stops a translation change from silently
  /// rewording a prompt.
  List<String> promptLines(String level) => [
    if (sentences > 0) '$sentences sentence(s) written.',
    if (wordsWanted > 0)
      '${wordsUsed.length} of the unit\'s $wordsWanted words used '
          '(the exercise asks for $writingRubricWordTarget).',
    if (grammarUsed.isNotEmpty)
      '${grammarUsed.length} taught grammar point(s) used.',
    if (tokensPlaced > 0)
      '${(levelShare * 100).round()}% of the words the catalog recognised '
          'are at $level or easier.',
    if (unreadable > 0) '$unreadable word(s) could not be read at all.',
  ];
}

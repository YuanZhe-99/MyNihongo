/// Purpose: Say what a quiz session should be about and how long it should run.
/// Inputs: Built at the point the learner starts a quiz.
/// Returns: An immutable value, passed to the quiz route as its `extra`.
/// Side effects: None.
/// Notes: The source is a sealed hierarchy because the ways in are genuinely
/// different questions — "what is due", "what is new", "these kana rows", "this
/// level", "these ids", "this unit", "this paper" — and a single
/// nullable-everything class would let two of them be set at once.
library;

import '../../content/models/jlpt_level.dart';
import '../../drills/models/drill_file.dart';
import '../../drills/models/drill_section.dart';
import '../../kana/models/kana.dart';
import '../../progress/models/study_record.dart';
import 'quiz_question.dart';

/// Where a session's items come from.
sealed class QuizSource {
  const QuizSource();
}

/// Everything due for review right now.
class DueReviews extends QuizSource {
  /// Purpose: Ask for the review queue's due items.
  /// Inputs: None.
  /// Returns: A new `DueReviews` instance.
  /// Side effects: None.
  /// Notes: None.
  const DueReviews();
}

/// Items the learner has not started yet, up to today's allowance.
class NewItems extends QuizSource {
  /// Purpose: Ask for today's new items.
  /// Inputs: None.
  /// Returns: A new `NewItems` instance.
  /// Side effects: None.
  /// Notes: None.
  const NewItems();
}

/// Selected rows of the kana chart.
class KanaRows extends QuizSource {
  /// Purpose: Ask about particular rows of the kana chart.
  /// Inputs: The row indices per table, and which script to show.
  /// Returns: A new `KanaRows` instance.
  /// Side effects: None.
  /// Notes: Rows are selected **by index**, not by label: `kanaBasicRows` has
  /// two rows labelled `n` — the な row and ん — so a label is not a key.
  const KanaRows({
    this.basic = const [],
    this.voiced = const [],
    this.yoon = const [],
    this.script = KanaScript.hiragana,
  });

  /// Indices into `kanaBasicRows`.
  final List<int> basic;

  /// Indices into `kanaVoicedRows`.
  final List<int> voiced;

  /// Indices into `kanaYoonRows`.
  final List<int> yoon;

  /// Which script the questions show.
  final KanaScript script;
}

/// Everything at one JLPT level, from one catalog.
class LevelSource extends QuizSource {
  /// Purpose: Ask about a whole level of one catalog.
  /// Inputs: `level`, and which `kind` of item.
  /// Returns: A new `LevelSource` instance.
  /// Side effects: None.
  /// Notes: None.
  const LevelSource(this.level, this.kind);

  /// The level to draw from.
  final JlptLevel level;

  /// Vocabulary or grammar.
  final StudyKind kind;
}

/// An explicit list of catalog ids.
class IdsSource extends QuizSource {
  /// Purpose: Ask about exactly these items.
  /// Inputs: `ids`.
  /// Returns: A new `IdsSource` instance.
  /// Side effects: None.
  /// Notes: What a lesson uses in M3.4.
  const IdsSource(this.ids);

  /// The catalog ids to ask about.
  final List<String> ids;
}

/// One unit of a level's path.
class UnitSource extends QuizSource {
  /// Purpose: Ask about one unit of the lesson path.
  /// Inputs: The `unitId`, the `level` its file belongs to, and whether this
  /// is the unit's `checkpoint`.
  /// Returns: A new `UnitSource` instance.
  /// Side effects: None.
  /// Notes: The only source whose questions come from a bank rather than from
  /// the catalog directly, because a unit ships sentences and questions of its
  /// own. A checkpoint asks more of them and writes a pass or a fail; ordinary
  /// practice does neither.
  const UnitSource(this.unitId, this.level, {this.checkpoint = false});

  /// The `unit:` id.
  final String unitId;

  /// The level whose file the unit is in.
  final JlptLevel level;

  /// Whether passing this session unlocks the next unit.
  final bool checkpoint;
}

/// A JLPT paper, or one section of one.
class DrillSource extends QuizSource {
  /// Purpose: Ask a paper's questions rather than the app's own.
  /// Inputs: The `level`; the `sections` to draw from, empty for all four;
  /// the `scale` of the paper.
  /// Returns: A new `DrillSource` instance.
  /// Side effects: None.
  /// Notes: The only source whose questions were written for a paper rather
  /// than derived from a catalog entry, which is why it carries a composition
  /// instead of a list of ids: what makes a paper a paper is how many of each
  /// 大問 it has, and that is a fact about the level, not about the learner.
  ///
  /// `maxQuestions` on the config does **not** apply — the composition decides
  /// the length, and truncating it would drop the last 大問 rather than
  /// shortening the paper evenly.
  const DrillSource(
    this.level, {
    this.sections = const {},
    this.scale = ExamScale.short,
  });

  /// Which level's paper.
  final JlptLevel level;

  /// The sections to ask about; empty means every section with content.
  final Set<DrillSection> sections;

  /// How much of the paper to ask.
  final ExamScale scale;
}

/// One session's settings.
class QuizConfig {
  /// Purpose: Describe a quiz session.
  /// Inputs: `source`; `modes` the learner has enabled; `maxQuestions`;
  /// `recordProgress`.
  /// Returns: A new `QuizConfig` instance.
  /// Side effects: None.
  /// Notes: `recordProgress` exists so a practice run can be offered later
  /// without touching the schedule. Everything shipped today records.
  const QuizConfig({
    required this.source,
    this.modes = const {},
    this.maxQuestions = 20,
    this.recordProgress = true,
  });

  /// Where the items come from.
  final QuizSource source;

  /// The modes the learner has left switched on; empty means all of them.
  final Set<QuizMode> modes;

  /// How many questions a session runs for.
  final int maxQuestions;

  /// Whether answers advance the spaced-repetition schedule.
  final bool recordProgress;
}

/// Purpose: Say what a learner is worst at, from the papers they have actually
/// sat.
/// Inputs: Their exam attempts, the shipped drill files, and the catalog.
/// Returns: An immutable value.
/// Side effects: None — a pure function of what is already on disk.
/// Notes: Pure on purpose, and derived rather than stored. A weakness recorded
/// once would be a verdict the learner could not shake off; recomputing it from
/// the last few attempts means practice actually moves it, which is the only
/// reason a report like this is worth showing.
library;

import '../../content/models/content_catalog.dart';
import '../../progress/models/exam_attempt.dart';
import '../models/drill_file.dart';
import '../models/drill_section.dart';

/// How many recent attempts the report looks at.
///
/// Five, not all of them. A report over every attempt ever sat is a report the
/// learner cannot change: forty old papers drown five recent good ones, and the
/// number stops responding to work. Five is enough to be more than one bad day.
const weaknessRecentAttempts = 5;

/// How many times something must have been asked before it is called a
/// weakness.
///
/// Below this a run of bad luck looks exactly like a gap. Three is low, and
/// deliberately: the point is to name something to go and look at, not to
/// publish a statistic.
const weaknessMinAsked = 3;

/// How many weak grammar points the report names.
const weaknessMaxPoints = 10;

/// One thing that was asked, and how it went.
class WeaknessTally {
  /// Purpose: Hold one tally.
  /// Inputs: `asked` and `right`.
  /// Returns: A new `WeaknessTally` instance.
  /// Side effects: None.
  /// Notes: None.
  const WeaknessTally({required this.asked, required this.right});

  /// How many times it was asked.
  final int asked;

  /// How many of those were right.
  final int right;

  /// Accuracy from 0 to 1; 0 when nothing was asked.
  double get accuracy => asked == 0 ? 0 : right / asked;

  /// Purpose: Add one result.
  /// Inputs: `correct`.
  /// Returns: A new tally.
  /// Side effects: None.
  /// Notes: None.
  WeaknessTally plus(bool correct) =>
      WeaknessTally(asked: asked + 1, right: right + (correct ? 1 : 0));
}

/// What the learner is worst at, over their recent attempts.
class WeaknessReport {
  /// Purpose: Hold one report.
  /// Inputs: The three tallies and the attempt count behind them.
  /// Returns: A new `WeaknessReport` instance.
  /// Side effects: None.
  /// Notes: `attempts` is carried so a screen can say how much the report is
  /// based on. "You are weak at 文法" from one paper and from five are
  /// different claims, and only one of them is worth acting on.
  const WeaknessReport({
    this.bySection = const {},
    this.byType = const {},
    this.byItem = const {},
    this.attempts = 0,
  });

  /// An empty report, for a learner who has sat nothing.
  static const empty = WeaknessReport();

  /// How each section went.
  final Map<DrillSection, WeaknessTally> bySection;

  /// How each 大問 went.
  final Map<DrillType, WeaknessTally> byType;

  /// How each catalog item went.
  final Map<String, WeaknessTally> byItem;

  /// How many attempts the report is built from.
  final int attempts;

  /// Whether there is anything to show.
  bool get isEmpty => bySection.isEmpty;

  /// The weakest catalog items, worst first.
  ///
  /// Only things asked at least [weaknessMinAsked] times, and only things got
  /// wrong at least once — a run of perfect answers is not a weakness however
  /// few of them there were. Ties break on the id so the order is total and two
  /// items with the same accuracy cannot swap places between builds.
  List<MapEntry<String, WeaknessTally>> get weakestItems {
    final weak = [
      for (final entry in byItem.entries)
        if (entry.value.asked >= weaknessMinAsked &&
            entry.value.right < entry.value.asked)
          entry,
    ]..sort((a, b) {
      final byAccuracy = a.value.accuracy.compareTo(b.value.accuracy);
      return byAccuracy != 0 ? byAccuracy : a.key.compareTo(b.key);
    });
    return weak.take(weaknessMaxPoints).toList();
  }

  /// The weakest 大問, worst first, under the same rules as [weakestItems].
  List<MapEntry<DrillType, WeaknessTally>> get weakestTypes {
    final weak = [
      for (final entry in byType.entries)
        if (entry.value.asked >= weaknessMinAsked &&
            entry.value.right < entry.value.asked)
          entry,
    ]..sort((a, b) {
      final byAccuracy = a.value.accuracy.compareTo(b.value.accuracy);
      return byAccuracy != 0 ? byAccuracy : a.key.key.compareTo(b.key.key);
    });
    return weak.take(weaknessMaxPoints).toList();
  }

  /// Purpose: Build the report from what the learner has sat.
  /// Inputs: `attempts` (newest first); the drill `files` by level and section;
  /// the `level` to report on, or null for every level; `recent` — how many
  /// attempts to look at.
  /// Returns: `WeaknessReport`.
  /// Side effects: None.
  /// Notes: The join is done here rather than stored, because an attempt keeps
  /// only which questions were asked and what was answered. Everything else —
  /// which section, which 大問, which catalog items — is read from the shipped
  /// files now, so a content correction reaches the report as well.
  ///
  /// A question the files no longer have is skipped rather than counted under
  /// nothing. It is one fewer data point, which is the honest cost; counting it
  /// would put a weakness against a 大問 the app can no longer name.
  ///
  /// **Unanswered questions do not count at all.** The clock took them away,
  /// and a report that read a time-out as a gap in the learner's Japanese would
  /// send them to study the wrong thing.
  static WeaknessReport build({
    required List<ExamAttempt> attempts,
    required Map<String, DrillQuestion> questions,
    String? level,
    int recent = weaknessRecentAttempts,
  }) {
    final considered = [
      for (final attempt in attempts)
        if (level == null || attempt.level == level) attempt,
    ].take(recent).toList();
    if (considered.isEmpty) return empty;

    final bySection = <DrillSection, WeaknessTally>{};
    final byType = <DrillType, WeaknessTally>{};
    final byItem = <String, WeaknessTally>{};

    for (final attempt in considered) {
      for (final entry in attempt.answers.entries) {
        if (entry.value == examUnanswered) continue;
        final question = questions[entry.key];
        if (question == null) continue;
        final correct = entry.value == 1;
        final section = question.type.section;
        bySection[section] = (bySection[section] ?? const WeaknessTally(
          asked: 0,
          right: 0,
        )).plus(correct);
        byType[question.type] = (byType[question.type] ?? const WeaknessTally(
          asked: 0,
          right: 0,
        )).plus(correct);
        for (final id in question.items) {
          byItem[id] = (byItem[id] ?? const WeaknessTally(asked: 0, right: 0))
              .plus(correct);
        }
      }
    }

    return WeaknessReport(
      bySection: bySection,
      byType: byType,
      byItem: byItem,
      attempts: considered.length,
    );
  }

  /// Purpose: Name the catalog ids worth pushing to the front of the review
  /// queue.
  /// Inputs: The `catalog`, so an id no longer shipped is not prioritized.
  /// Returns: `Set<String>`.
  /// Side effects: None.
  /// Notes: The queue orders by this before it orders by how overdue something
  /// is. A word the learner keeps getting wrong on a paper is a better use of
  /// the next five minutes than a word whose interval happens to have elapsed.
  Set<String> prioritizedIds(ContentCatalog? catalog) => {
    for (final entry in weakestItems)
      if (catalog == null ||
          catalog.vocabById(entry.key) != null ||
          catalog.grammarById(entry.key) != null)
        entry.key,
  };
}

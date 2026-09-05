/// Purpose: Turn a learner's recent papers into a band — not ready, close,
/// ready — for each scoring group and for the level as a whole.
/// Inputs: A weakness report, the level's structure, and how much of the
/// catalog the learner has actually met.
/// Returns: An immutable value.
/// Side effects: None.
/// Notes: **This is not a JLPT score and cannot be.** JEES does not publish the
/// raw-to-scaled equating, so no app can compute one. What is computable is
/// accuracy on questions this app wrote, and the honest way to report that is a
/// band with the caveat attached — which is why the band names are qualitative
/// and there is no number anywhere in this file's output.
library;

import '../models/drill_file.dart';
import '../models/drill_section.dart';
import 'weakness_report.dart';

/// The accuracy a group needs before it is called ready.
///
/// The same number as `checkpointPassAccuracy`, and deliberately: the app
/// already decided that seven in ten means "this has been learnt" when it
/// opens the next lesson unit, and having two different thresholds for the
/// same claim would be the app disagreeing with itself.
const readinessReady = 0.70;

/// The accuracy below which a group is not close yet.
const readinessClose = 0.55;

/// How many questions a group needs before a band is claimed at all.
///
/// Twenty over the recent attempts. Below that the band would move on one
/// lucky paper, and a readiness estimate that swings is worse than none.
const readinessMinAsked = 20;

/// How much of the level's catalog must have been met before the estimate is
/// allowed to say "ready".
///
/// Half. Answering the questions well says something about the questions asked;
/// it says much less about a level whose vocabulary the learner has not seen.
const readinessMinCoverage = 0.5;

/// How ready a learner looks.
enum ReadinessBand {
  /// Not enough has been sat to say anything.
  unknown,

  /// Measured, and not there yet.
  notYet,

  /// Measured, and within reach.
  close,

  /// Measured, and consistently over the line.
  ready,

  /// Cannot be measured on this device at all.
  ///
  /// Only listening, and only where there is no Japanese voice. It is not
  /// `unknown` — that means "sit more papers", which would be advice the
  /// learner cannot take.
  unmeasured,
}

/// What the app is willing to say about a learner's readiness.
class ReadinessEstimate {
  /// Purpose: Hold one estimate.
  /// Inputs: The band per scoring group, the `overall` band, and whether the
  /// estimate was `cappedByCoverage`.
  /// Returns: A new `ReadinessEstimate` instance.
  /// Side effects: None.
  /// Notes: `cappedByCoverage` is carried so the screen can say *why* it will
  /// not say ready. "Close" with no explanation, from a learner scoring nine in
  /// ten, reads as a bug rather than as a caveat.
  const ReadinessEstimate({
    this.byGroup = const {},
    this.overall = ReadinessBand.unknown,
    this.cappedByCoverage = false,
  });

  /// An estimate for a learner who has sat nothing.
  static const unknown = ReadinessEstimate();

  /// The band for each scoring group, by its id.
  final Map<String, ReadinessBand> byGroup;

  /// The band for the level as a whole.
  final ReadinessBand overall;

  /// Whether the overall band was held back because too little of the level's
  /// catalog has been met.
  final bool cappedByCoverage;

  /// Purpose: Work out the bands.
  /// Inputs: The `report`; the level's `structure`; `coverage` — the share of
  /// the level's catalog items the learner has a progress record for; and
  /// `hasJapaneseVoice`.
  /// Returns: `ReadinessEstimate`.
  /// Side effects: None.
  /// Notes: **The overall band is the worst group, not the average.** That
  /// mirrors the exam's own rule — fail one scoring group and you fail the
  /// level, however well the others went — and it is the one part of the real
  /// scoring the app can honestly reproduce, because it is a rule rather than a
  /// number.
  ///
  /// A group with too few questions is `unknown`, and one unknown group makes
  /// the whole estimate unknown: an overall band computed from two groups out
  /// of three would be a claim about a paper nobody has sat.
  ///
  /// Listening with no Japanese voice is `unmeasured`, and that does **not**
  /// drag the overall band down — the learner has not done badly at it, the
  /// device simply cannot ask. The overall band is then the worst of the
  /// groups that could be measured, and the screen says listening is missing
  /// from it.
  static ReadinessEstimate build({
    required WeaknessReport report,
    required LevelStructure structure,
    double coverage = 1,
    bool hasJapaneseVoice = true,
  }) {
    if (report.isEmpty) return unknown;

    final byGroup = <String, ReadinessBand>{};
    for (final group in structure.scoring) {
      var asked = 0;
      var right = 0;
      for (final section in group.sections) {
        final tally = report.bySection[section];
        if (tally == null) continue;
        asked += tally.asked;
        right += tally.right;
      }

      final onlyListening =
          group.sections.length == 1 &&
          group.sections.single == DrillSection.listening;
      if (onlyListening && !hasJapaneseVoice) {
        byGroup[group.id] = ReadinessBand.unmeasured;
        continue;
      }
      if (asked < readinessMinAsked) {
        byGroup[group.id] = ReadinessBand.unknown;
        continue;
      }
      final accuracy = right / asked;
      byGroup[group.id] = accuracy >= readinessReady
          ? ReadinessBand.ready
          : accuracy >= readinessClose
          ? ReadinessBand.close
          : ReadinessBand.notYet;
    }

    final measured = [
      for (final band in byGroup.values)
        if (band != ReadinessBand.unmeasured) band,
    ];
    if (measured.isEmpty || measured.contains(ReadinessBand.unknown)) {
      return ReadinessEstimate(
        byGroup: byGroup,
        overall: ReadinessBand.unknown,
      );
    }

    var overall = measured.reduce(
      (a, b) => a.index < b.index ? a : b,
    );
    // Answering well says something about the questions asked; it says much
    // less about a level whose vocabulary the learner has mostly not met. So
    // coverage can hold the estimate back, and the screen says it did.
    final capped = overall == ReadinessBand.ready &&
        coverage < readinessMinCoverage;
    if (capped) overall = ReadinessBand.close;

    return ReadinessEstimate(
      byGroup: byGroup,
      overall: overall,
      cappedByCoverage: capped,
    );
  }
}

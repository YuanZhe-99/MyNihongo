import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/drills/services/readiness_rules.dart';
import 'package:my_nihongo/features/drills/services/weakness_report.dart';

/// Purpose: Test the readiness estimate — the bands, the rule that the worst
/// group decides, and the two things that stop it claiming anything.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; every test here is pure.
/// Notes: The estimate is deliberately conservative, and these tests are
/// mostly about the ways it refuses to speak. **The overall band is the worst
/// group, not the average**, because that is the exam's own rule and the one
/// part of real JLPT scoring an app can honestly reproduce. **One unknown
/// group makes the whole thing unknown**, because a band computed from two
/// groups out of three is a claim about a paper nobody sat. And listening on a
/// device with no Japanese voice is `unmeasured` rather than bad — the learner
/// did not fail it, the device could not ask.

/// The two-group shape N5 and N4 use.
const _twoGroups = LevelStructure(
  blocks: [],
  scoring: [
    ScoringGroup(
      id: 'languageReading',
      sections: [DrillSection.vocab, DrillSection.grammar,
          DrillSection.reading],
      max: 120,
      pass: 38,
    ),
    ScoringGroup(
      id: 'listening',
      sections: [DrillSection.listening],
      max: 60,
      pass: 19,
    ),
  ],
  types: {},
  overallMax: 180,
  overallPass: 80,
);

/// Purpose: Build a report with a chosen tally per section.
/// Inputs: `sections` — how each section went.
/// Returns: `WeaknessReport`.
/// Side effects: None.
/// Notes: Internal helper used within this test file only. Built directly
/// rather than through `build`, because the bands are a function of the
/// tallies and going through attempts would test the join twice.
WeaknessReport report(Map<DrillSection, (int asked, int right)> sections) =>
    WeaknessReport(
      bySection: {
        for (final entry in sections.entries)
          entry.key: WeaknessTally(
            asked: entry.value.$1,
            right: entry.value.$2,
          ),
      },
      attempts: 1,
    );

void main() {
  test('a learner who has sat nothing gets no estimate', () {
    expect(
      ReadinessEstimate.build(
        report: WeaknessReport.empty,
        structure: _twoGroups,
      ).overall,
      ReadinessBand.unknown,
    );
  });

  test('too few questions in a group leaves the whole estimate unknown', () {
    final estimate = ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (40, 36),
        DrillSection.listening: (5, 5),
      }),
      structure: _twoGroups,
    );

    expect(estimate.byGroup['languageReading'], ReadinessBand.ready);
    expect(estimate.byGroup['listening'], ReadinessBand.unknown);
    expect(
      estimate.overall,
      ReadinessBand.unknown,
      reason: 'a band from one group out of two is a claim about no paper',
    );
  });

  test('the bands follow the two thresholds', () {
    ReadinessBand bandFor(int right) => ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (100, right),
        DrillSection.listening: (100, 100),
      }),
      structure: _twoGroups,
    ).byGroup['languageReading']!;

    expect(bandFor(70), ReadinessBand.ready);
    expect(bandFor(69), ReadinessBand.close);
    expect(bandFor(55), ReadinessBand.close);
    expect(bandFor(54), ReadinessBand.notYet);
  });

  test('the overall band is the worst group, not the average', () {
    final estimate = ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (100, 95),
        DrillSection.listening: (100, 20),
      }),
      structure: _twoGroups,
    );

    expect(estimate.byGroup['languageReading'], ReadinessBand.ready);
    expect(estimate.overall, ReadinessBand.notYet);
  });

  test('a group is the sum of its sections', () {
    final estimate = ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (10, 10),
        DrillSection.grammar: (10, 10),
        DrillSection.reading: (10, 0),
        DrillSection.listening: (20, 20),
      }),
      structure: _twoGroups,
    );

    expect(
      estimate.byGroup['languageReading'],
      ReadinessBand.close,
      reason: 'twenty of thirty is 0.67 — over close, under ready',
    );
  });

  test('thin catalog coverage holds ready back to close, and says so', () {
    final estimate = ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (100, 95),
        DrillSection.listening: (100, 95),
      }),
      structure: _twoGroups,
      coverage: 0.2,
    );

    expect(estimate.overall, ReadinessBand.close);
    expect(estimate.cappedByCoverage, isTrue);
  });

  test('coverage does not push a band up, only down', () {
    final estimate = ReadinessEstimate.build(
      report: report({
        DrillSection.vocab: (100, 40),
        DrillSection.listening: (100, 95),
      }),
      structure: _twoGroups,
      coverage: 0.1,
    );

    expect(estimate.overall, ReadinessBand.notYet);
    expect(estimate.cappedByCoverage, isFalse);
  });

  test('listening with no voice is unmeasured and does not drag the rest', () {
    final estimate = ReadinessEstimate.build(
      report: report({DrillSection.vocab: (100, 95)}),
      structure: _twoGroups,
      hasJapaneseVoice: false,
    );

    expect(estimate.byGroup['listening'], ReadinessBand.unmeasured);
    expect(
      estimate.overall,
      ReadinessBand.ready,
      reason: 'the learner did not fail listening; the device could not ask',
    );
  });
}

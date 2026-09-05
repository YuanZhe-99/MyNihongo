/// Purpose: Draw one paper's worth of questions from the shipped files without
/// asking the same thing twice.
/// Inputs: The files, the composition wanted, and what has already been asked.
/// Returns: A list of questions in paper order.
/// Side effects: None — the randomness is injected, so a test can pin it.
/// Notes: Pure on purpose. Sampling is the part of an exam most likely to be
/// wrong in a way nobody notices — a paper that quietly asks the same six
/// questions every time still looks like a paper — so it is testable in
/// isolation rather than reachable only through a page.
library;

import 'dart:math';

import '../models/drill_file.dart';
import '../models/drill_section.dart';

/// Draws questions for one paper.
class DrillSampler {
  /// Purpose: Prevent construction.
  /// Inputs: None.
  /// Returns: Never.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  DrillSampler._();

  /// Purpose: Draw the questions for one section.
  /// Inputs: The `file`; `counts` per type; `asked` — every question id the
  /// learner has already been given; `lastAsked` — when each was last asked,
  /// as milliseconds since the epoch; a `random` for the shuffle.
  /// Returns: `List<DrillQuestion>` in the order the paper asks them, which is
  /// the order the types are declared in `DrillType`.
  /// Side effects: None.
  /// Notes: **Never-asked first, then least recently asked, then whatever is
  /// left.** The three tiers matter in that order: a learner who has seen
  /// forty of a level's sixty questions should be shown the twenty they have
  /// not, and once the pool is exhausted the oldest is the one they are most
  /// likely to have forgotten.
  ///
  /// Within a tier the order is shuffled, so two papers drawn from the same
  /// tier are not the same paper.
  ///
  /// A type with fewer questions than asked for yields what it has. The
  /// results screen says how many were asked, so a short section is visible
  /// rather than silently padded from another type.
  static List<DrillQuestion> draw(
    DrillFile file, {
    required Map<DrillType, int> counts,
    Set<String> asked = const {},
    Map<String, int> lastAsked = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final byType = <DrillType, List<DrillQuestion>>{};
    for (final question in file.questions) {
      (byType[question.type] ??= []).add(question);
    }

    final drawn = <DrillQuestion>[];
    // `DrillType.values` order is the paper's order, so iterating it rather
    // than `counts.keys` puts 漢字読み before 文脈規定 whatever order the
    // structure file happened to write its type map in.
    for (final type in DrillType.values) {
      final want = counts[type] ?? 0;
      if (want <= 0) continue;
      final pool = byType[type];
      if (pool == null || pool.isEmpty) continue;
      drawn.addAll(_pick(pool, want, asked, lastAsked, rng));
    }
    return drawn;
  }

  /// Purpose: Draw whole passages rather than questions scattered across them.
  /// Inputs: The same as [draw].
  /// Returns: `List<DrillQuestion>`.
  /// Side effects: None.
  /// Notes: A reading or listening 大問 asks several questions about one text.
  /// Drawing questions independently would put one question from each of four
  /// passages on a short paper, which is four texts to read for four marks —
  /// four times the work of the paper it is imitating. So the unit drawn is
  /// the passage, and its questions come with it; the count is reached by
  /// taking passages until it is met or passed.
  ///
  /// A question with no passage is drawn singly, which is what makes this safe
  /// to use for every section: 文章の文法 has a passage, 文の文法1 does not,
  /// and both live in the grammar file.
  static List<DrillQuestion> drawByPassage(
    DrillFile file, {
    required Map<DrillType, int> counts,
    Set<String> asked = const {},
    Map<String, int> lastAsked = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final drawn = <DrillQuestion>[];
    for (final type in DrillType.values) {
      final want = counts[type] ?? 0;
      if (want <= 0) continue;
      final pool = [
        for (final question in file.questions)
          if (question.type == type) question,
      ];
      if (pool.isEmpty) continue;

      final loose = [
        for (final q in pool)
          if (q.passageId == null) q,
      ];
      final groups = <String, List<DrillQuestion>>{};
      for (final question in pool) {
        final id = question.passageId;
        if (id != null) (groups[id] ??= []).add(question);
      }
      if (groups.isEmpty) {
        drawn.addAll(_pick(loose, want, asked, lastAsked, rng));
        continue;
      }

      // A passage is "already asked" when every question on it is, and its
      // recency is that of its most recently asked question — the learner
      // remembers the text, not the individual questions about it.
      final keys = groups.keys.toList();
      final ordered = _order(
        keys,
        (id) => groups[id]!.every((q) => asked.contains(q.id)),
        (id) => groups[id]!
            .map((q) => lastAsked[q.id] ?? 0)
            .fold(0, (a, b) => a > b ? a : b),
        rng,
      );
      var taken = 0;
      for (final id in ordered) {
        if (taken >= want) break;
        final group = groups[id]!;
        drawn.addAll(group);
        taken += group.length;
      }
      if (taken < want && loose.isNotEmpty) {
        drawn.addAll(_pick(loose, want - taken, asked, lastAsked, rng));
      }
    }
    return drawn;
  }

  /// Purpose: Take the best `want` of a pool.
  /// Inputs: The `pool`, how many are wanted, the asked set, the recency map
  /// and the `rng`.
  /// Returns: `List<DrillQuestion>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static List<DrillQuestion> _pick(
    List<DrillQuestion> pool,
    int want,
    Set<String> asked,
    Map<String, int> lastAsked,
    Random rng,
  ) {
    final ordered = _order(
      pool,
      (question) => asked.contains(question.id),
      (question) => lastAsked[question.id] ?? 0,
      rng,
    );
    return ordered.take(want).toList();
  }

  /// Purpose: Put never-asked members first, then least recently asked.
  /// Inputs: The `pool`; `seen` and `when` read one member; the `rng`.
  /// Returns: A new list; the input is not touched.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The shuffle happens
  /// **within** each tier rather than across the whole pool, which is the
  /// whole point: a plain shuffle would show a question the learner saw
  /// yesterday as readily as one they have never seen.
  static List<T> _order<T>(
    List<T> pool,
    bool Function(T) seen,
    int Function(T) when,
    Random rng,
  ) {
    final fresh = <T>[];
    final used = <T>[];
    for (final member in pool) {
      (seen(member) ? used : fresh).add(member);
    }
    fresh.shuffle(rng);
    used.shuffle(rng);
    // A stable sort would keep the shuffle inside equal timestamps; Dart's
    // `sort` is not stable, so the shuffle above is what breaks ties and this
    // only has to get the order of distinct timestamps right.
    used.sort((a, b) => when(a).compareTo(when(b)));
    return [...fresh, ...used];
  }

  /// Purpose: Say which sections a paper at this level actually has content
  /// for.
  /// Inputs: The loaded `files` by section.
  /// Returns: `Set<DrillSection>`.
  /// Side effects: None.
  /// Notes: A section with no file is not offered, rather than offered and
  /// then found empty. The Learn card disables the button and says why.
  static Set<DrillSection> sectionsWithContent(
    Map<DrillSection, DrillFile> files,
  ) => {
    for (final entry in files.entries)
      if (entry.value.questions.isNotEmpty) entry.key,
  };
}

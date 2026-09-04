/// Purpose: Decide what to study now — which items are due, and which new ones
/// today's allowance still has room for.
/// Inputs: The progress file, the catalog, the learner profile, and the time.
/// Returns: An immutable queue.
/// Side effects: None — pure, so the whole policy is testable without a device.
/// Notes: "Due" is judged by **local calendar date**, not by the stored
/// instant. `dueAt` is a plain UTC instant so it compares identically on every
/// device, but a learner expects anything due today to be due all day, and
/// their "today" is their own. The two rules live apart on purpose: the
/// scheduler stores instants, the queue reads days.
library;

import '../../content/models/content_catalog.dart';
import '../../content/models/jlpt_level.dart';
import '../../kana/models/kana.dart';
import '../models/learner_profile.dart';
import '../models/study_record.dart';

/// The kinds the queue draws new items from, in the order it introduces them.
///
/// Kana first: they are the alphabet, and a vocabulary item whose reading
/// cannot be read is a memorized picture.
const _newItemOrder = [StudyKind.kana, StudyKind.vocab, StudyKind.grammar];

/// What to study now.
class ReviewQueue {
  /// Purpose: Hold one computed queue.
  /// Inputs: All fields.
  /// Returns: A new `ReviewQueue` instance.
  /// Side effects: None.
  /// Notes: Built by [build]; nothing else constructs one outside tests.
  const ReviewQueue({
    this.due = const [],
    this.newIds = const [],
    this.reviewsDoneToday = 0,
    this.newDoneToday = 0,
    this.reviewAllowance = 0,
    this.newAllowance = 0,
    this.overdueTotal = 0,
  });

  /// Items due for review, most overdue first, capped by today's allowance.
  final List<StudyRecord> due;

  /// Catalog ids not yet studied, capped by today's allowance.
  final List<String> newIds;

  /// Reviews already answered today.
  final int reviewsDoneToday;

  /// New items already started today.
  final int newDoneToday;

  /// Reviews still allowed today.
  final int reviewAllowance;

  /// New items still allowed today.
  final int newAllowance;

  /// How many items are due in total, ignoring the daily cap.
  ///
  /// Separate from `due.length` so the UI can say "40 due, 20 today" rather
  /// than pretending the backlog is smaller than it is.
  final int overdueTotal;

  /// Whether there is anything at all to do right now.
  bool get isEmpty => due.isEmpty && newIds.isEmpty;

  /// Whether the day's review allowance is used up while items remain due.
  bool get reviewLimitReached => due.isEmpty && overdueTotal > 0;

  /// Purpose: Decide whether a record is due.
  /// Inputs: `record`; `now` — local time.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: A record with no `dueAt` has never been reviewed and is not a
  /// review. The comparison is on the local calendar day, so an item due at
  /// 23:00 is available from midnight rather than only in the evening.
  static bool isDue(StudyRecord record, DateTime now) {
    final due = record.dueAt;
    if (due == null) return false;
    return !_dayOf(due.toLocal()).isAfter(_dayOf(now));
  }

  /// Purpose: Build the queue for right now.
  /// Inputs: `progress`, `catalog`, `profile`; `now` — local time; `kinds` —
  /// which catalogs new items may come from.
  /// Returns: `ReviewQueue`.
  /// Side effects: None.
  /// Notes: Today's counts are **derived from the records**, not stored: a
  /// review answered today is one whose `lastReviewedAt` falls on today's local
  /// date, and a new item started today is a record `createdAt` today. Nothing
  /// has to be reset at midnight, nothing extra is synced, and work done on
  /// another device and synced in counts too — which is what a synced daily
  /// goal has to mean. Scanning a few thousand records costs nothing next to
  /// the catalog lookups.
  static ReviewQueue build({
    required ProgressData progress,
    required ContentCatalog catalog,
    required LearnerProfile profile,
    required DateTime now,
    Set<StudyKind> kinds = studiedKinds,
  }) {
    final today = _dayOf(now);
    var reviewsDone = 0;
    var newDone = 0;
    final studied = <String>{};
    final due = <StudyRecord>[];

    for (final record in progress.studyRecords) {
      studied.add(record.id);
      final reviewed = record.lastReviewedAt?.toLocal();
      if (reviewed != null && _dayOf(reviewed) == today) reviewsDone++;
      if (_dayOf(record.createdAt.toLocal()) == today) newDone++;
      if (kinds.contains(record.kind) && isDue(record, now)) due.add(record);
    }

    // Most overdue first: the longest-forgotten item is the one whose recall
    // is decaying fastest, and a learner who stops halfway should have spent
    // the time on those.
    due.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    final reviewAllowance = (profile.dailyReviewLimit - reviewsDone)
        .clamp(0, profile.dailyReviewLimit);
    final newAllowance = (profile.dailyNewLimit - newDone).clamp(
      0,
      profile.dailyNewLimit,
    );

    return ReviewQueue(
      due: due.take(reviewAllowance).toList(),
      newIds: _newItems(
        catalog: catalog,
        studied: studied,
        kinds: kinds,
        level: profile.targetLevel,
        limit: newAllowance,
      ),
      reviewsDoneToday: reviewsDone,
      newDoneToday: newDone,
      reviewAllowance: reviewAllowance,
      newAllowance: newAllowance,
      overdueTotal: due.length,
    );
  }

  /// Purpose: Choose the next unstudied catalog items.
  /// Inputs: The `catalog`, the ids already `studied`, the allowed `kinds`, the
  /// learner's `level`, and how many to take.
  /// Returns: `List<String>` of catalog ids.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Kana come first and
  /// ignore the level — they are not levelled, and the rest of the catalog is
  /// unreadable without them. Vocabulary comes before grammar, and common words
  /// before rare ones, so the first hundred items a learner meets are the ones
  /// they will actually see again. Lesson order replaces this in M3.4; until
  /// then the catalog's own order is the best available answer.
  static List<String> _newItems({
    required ContentCatalog catalog,
    required Set<String> studied,
    required Set<StudyKind> kinds,
    required JlptLevel level,
    required int limit,
  }) {
    if (limit <= 0) return const [];
    final out = <String>[];

    void take(Iterable<String> ids) {
      for (final id in ids) {
        if (out.length >= limit) return;
        if (studied.contains(id)) continue;
        out.add(id);
      }
    }

    for (final kind in _newItemOrder) {
      if (out.length >= limit) break;
      if (!kinds.contains(kind)) continue;
      switch (kind) {
        case StudyKind.kana:
          take(allKanaEntries().map((entry) => entry.progressId));
        case StudyKind.vocab:
          final atLevel = catalog.vocab.where((v) => v.level == level);
          take(atLevel.where((v) => v.common).map((v) => v.id));
          take(atLevel.where((v) => !v.common).map((v) => v.id));
        case StudyKind.grammar:
          take(
            catalog.grammar.where((g) => g.level == level).map((g) => g.id),
          );
        case StudyKind.profile:
        case StudyKind.lesson:
        case StudyKind.history:
        case StudyKind.other:
          break;
      }
    }
    return out;
  }

  /// Purpose: Reduce an instant to its calendar day.
  /// Inputs: `time`.
  /// Returns: `DateTime` at midnight.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Callers pass local
  /// time; comparing days is the whole point.
  static DateTime _dayOf(DateTime time) =>
      DateTime(time.year, time.month, time.day);
}

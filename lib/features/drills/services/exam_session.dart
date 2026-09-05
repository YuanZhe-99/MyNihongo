/// Purpose: Run one timed JLPT paper — its blocks, its clock, and the save
/// that lets a learner put it down and come back.
/// Inputs: The blocks to sit, and a clock the caller can pin.
/// Returns: A `ChangeNotifier` the exam page listens to.
/// Side effects: Runs a one-second timer while a block is on screen; holds no
/// storage of its own.
/// Notes: The clock is injected for the reason `QuizSession`'s callback is: a
/// test that had to wait real minutes to watch a block expire would be a test
/// nobody runs. Persistence is the page's job, so this file imports no storage
/// and a test can read exactly what would have been written.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../quiz/services/answer_checker.dart';
import '../../quiz/services/quiz_session.dart';
import '../models/drill_file.dart';
import '../models/drill_section.dart';

/// The version written into a saved paper.
///
/// Bumped when the save's shape changes in a way this build could not read.
/// A save from a newer build is discarded rather than half-read: an exam
/// resumed from a file this build only partly understands would be scored
/// against questions it could not reconstruct.
const examSaveVersion = 1;

/// One timed block of a paper: the sections it examines, and its clock.
class ExamBlock {
  /// Purpose: Hold one block, its questions and how much of its time is gone.
  /// Inputs: `index` in the paper; the `sections` it examines; the `limit`;
  /// the `session` that runs its questions; `usedBefore` — time already spent
  /// in earlier sittings.
  /// Returns: A new `ExamBlock` instance.
  /// Side effects: None.
  /// Notes: `usedBefore` and `resumedAt` are two halves of the same number.
  /// Time is only counted while the block is actually on screen, so the clock
  /// is "what earlier sittings used" plus "how long this sitting has been
  /// running" — which is why leaving the page cannot cost the learner time and
  /// cannot give them any either.
  ExamBlock({
    required this.index,
    required this.sections,
    required this.limit,
    required this.session,
    this.usedBefore = Duration.zero,
    this.submitted = false,
    this.started = false,
  });

  /// Which block of the paper this is, from zero.
  final int index;

  /// The sections examined here, in the order the paper asks them.
  final List<DrillSection> sections;

  /// How long the block is allowed.
  final Duration limit;

  /// The questions, run by the same session the practice quiz uses.
  final QuizSession session;

  /// Time spent in earlier sittings of this block.
  Duration usedBefore;

  /// When this sitting started, or null while the block is not on screen.
  DateTime? resumedAt;

  /// Whether the learner has ever started this block.
  ///
  /// Distinct from "the clock is running", and the distinction matters: the
  /// clock stops every time the page shows a dialog or the app is
  /// backgrounded, and a block that fell back to its start card each time
  /// would look to the learner as though the paper had been thrown away.
  bool started;

  /// Whether the block has been handed in.
  bool submitted;

  /// Purpose: Say how much of the block's time has been used.
  /// Inputs: `now`.
  /// Returns: `Duration`.
  /// Side effects: None.
  /// Notes: The running sitting counts only while [resumedAt] is set, which is
  /// exactly while the block is on screen and the app is in the foreground.
  Duration used(DateTime now) {
    final started = resumedAt;
    if (started == null) return usedBefore;
    return usedBefore + now.difference(started);
  }

  /// Purpose: Say how much time is left.
  /// Inputs: `now`.
  /// Returns: `Duration` — never negative.
  /// Side effects: None.
  /// Notes: Clamped at zero so a block whose deadline passed while the app was
  /// being killed shows `00:00` rather than a negative countdown.
  Duration remaining(DateTime now) {
    final left = limit - used(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Whether the clock has run out.
  bool expired(DateTime now) => remaining(now) == Duration.zero;
}

/// Runs one timed paper.
class ExamSession extends ChangeNotifier {
  /// Purpose: Start a paper.
  /// Inputs: The `level` label; the `scale`; the `blocks`; `startedAt`; and a
  /// `clock` for tests.
  /// Returns: A new `ExamSession` instance.
  /// Side effects: None until a block is started.
  /// Notes: The timer is not started here. A paper exists as soon as it is
  /// drawn, but its clock must not run until the learner has seen the start
  /// card and said they are ready — an exam that began counting while the
  /// questions were still being read would be a worse exam than the real one.
  ExamSession({
    required this.level,
    required this.scale,
    required List<ExamBlock> blocks,
    DateTime? startedAt,
    DateTime Function()? clock,
  }) : _blocks = blocks,
       _clock = clock ?? DateTime.now,
       startedAt = startedAt ?? (clock ?? DateTime.now)().toUtc();

  /// Which level's paper this is, as its label.
  final String level;

  /// How much of the paper is being sat.
  final ExamScale scale;

  /// When the paper was first opened, UTC.
  final DateTime startedAt;

  final List<ExamBlock> _blocks;
  final DateTime Function() _clock;
  Timer? _timer;
  int _current = 0;

  /// The blocks, in the order the paper sits them.
  List<ExamBlock> get blocks => List.unmodifiable(_blocks);

  /// Which block is being sat, or the last one once the paper is over.
  int get currentIndex => _current;

  /// The block being sat, or null once every block is in.
  ExamBlock? get current =>
      _current < _blocks.length ? _blocks[_current] : null;

  /// Whether every block has been handed in.
  bool get isFinished => _blocks.every((block) => block.submitted);

  /// Whether the paper is between blocks — one handed in, the next not started.
  ///
  /// The state the start card is shown in. A paper does not roll straight from
  /// one timed block into the next: the real thing has a break, and starting a
  /// clock the learner has not looked at is not a test of Japanese.
  bool get betweenBlocks {
    final block = current;
    return block != null && !block.started && !block.submitted;
  }

  /// How much time is left in the block being sat.
  Duration get remaining => current?.remaining(_clock()) ?? Duration.zero;

  /// Purpose: Start or resume the clock on the current block.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts a one-second timer; notifies listeners.
  /// Notes: Called when the learner taps Start and again whenever the page
  /// comes back to the foreground. Idempotent: resuming a block whose clock is
  /// already running changes nothing, so a lifecycle callback that fires twice
  /// cannot make the paper shorter.
  void resumeClock() {
    final block = current;
    if (block == null || block.submitted || block.resumedAt != null) return;
    block.resumedAt = _clock();
    block.started = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  /// Purpose: Stop the clock without handing the block in.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the timer; notifies listeners.
  /// Notes: What leaving the page and backgrounding the app both do. The time
  /// spent so far is folded into `usedBefore`, so the paper can be picked up
  /// later with the same time left — the clock measures attention, not
  /// wall-clock hours.
  void pauseClock() {
    final block = current;
    _timer?.cancel();
    _timer = null;
    if (block == null || block.resumedAt == null) return;
    block.usedBefore = block.used(_clock());
    block.resumedAt = null;
    notifyListeners();
  }

  /// Purpose: Hand in the current block and move to the next.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Forfeits anything unanswered; stops the clock; notifies.
  /// Notes: Everything still unanswered is recorded as **unanswered**, not as
  /// wrong. Running out of time is a fact about the attempt: calling it wrong
  /// would make every timed score worse than the learner did, and dropping it
  /// would make every timed score better.
  void submitBlock() {
    final block = current;
    if (block == null || block.submitted) return;
    pauseClock();
    block.session.forfeit();
    block.submitted = true;
    if (_current < _blocks.length - 1) _current++;
    notifyListeners();
  }

  /// Purpose: Hand the block in if its clock has run out.
  /// Inputs: None.
  /// Returns: `bool` — whether it did.
  /// Side effects: As [submitBlock] when the deadline has passed.
  /// Notes: Checked on every tick and again whenever the page returns to the
  /// foreground, because a phone that slept through the deadline has to find
  /// out on waking rather than resume a block that ended twenty minutes ago.
  bool checkDeadline() {
    final block = current;
    if (block == null || block.submitted) return false;
    if (!block.expired(_clock())) return false;
    submitBlock();
    return true;
  }

  /// Purpose: Move the paper on when the current block runs out of questions.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: As [submitBlock].
  /// Notes: A block whose questions are all answered is finished early, which
  /// the real paper also allows. The clock stops at that moment rather than at
  /// the limit, so the recorded time is time actually spent.
  void finishBlockEarly() {
    final block = current;
    if (block == null || !block.session.isFinished) return;
    submitBlock();
  }

  /// Purpose: Report one tick of the clock.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Notifies listeners; may submit the block.
  /// Notes: Internal helper used within this file only. One notification a
  /// second is what redraws the countdown; the deadline check rides along
  /// rather than needing a timer of its own.
  void _tick() {
    if (checkDeadline()) return;
    notifyListeners();
  }

  /// Purpose: Write the paper down so it can be picked up later.
  /// Inputs: None.
  /// Returns: `Map<String, dynamic>`.
  /// Side effects: None.
  /// Notes: The questions are saved **by id**, not by content: they are in the
  /// shipped files, and a save that carried its own copy would resume a paper
  /// the app no longer agrees with. The answers are saved as what the learner
  /// chose, so resuming re-marks them against the files as they are now.
  ///
  /// The running sitting is folded into `usedSecs` first, so a save taken
  /// mid-block records the time actually spent rather than the time spent up
  /// to the last pause.
  Map<String, dynamic> toJson() {
    final now = _clock();
    return {
      'v': examSaveVersion,
      'level': level,
      'scale': scale.name,
      'startedAt': startedAt.toIso8601String(),
      'blockIndex': _current,
      'blocks': [
        for (final block in _blocks)
          {
            'sections': [for (final s in block.sections) s.name],
            'limitSecs': block.limit.inSeconds,
            'usedSecs': block.used(now).inSeconds,
            'submitted': block.submitted,
            'started': block.started,
            'questionIds': [
              for (final outcome in block.session.outcomes) outcome.key,
              ...block.session.remainingKeys,
            ],
            'answers': {
              for (final entry in block.session.chosen.entries)
                entry.key: ?encodeAnswer(entry.value),
            },
          },
      ],
    };
  }

  /// Purpose: Write one answer down.
  /// Inputs: The `answer`.
  /// Returns: `Map<String, dynamic>?` — null for a shape a paper cannot ask.
  /// Side effects: None.
  /// Notes: Only the two shapes a drill question uses. A typed answer is not
  /// encoded because no 大問 asks for one, and inventing a representation for
  /// a case that cannot arise is a way of being wrong later without noticing.
  static Map<String, dynamic>? encodeAnswer(QuizAnswer answer) =>
      switch (answer) {
        ChoiceAnswer(:final index) => {'index': index},
        OrderAnswer(:final order) => {'order': order},
        TypedAnswer() => null,
      };

  /// Purpose: Read one answer back.
  /// Inputs: The `json`.
  /// Returns: `QuizAnswer?` — null for anything unreadable.
  /// Side effects: None.
  /// Notes: Never throws. A save whose answers cannot be read resumes as a
  /// paper with those questions unanswered, which is worse for the learner
  /// than a clean resume and much better than a crash on the way back in.
  static QuizAnswer? decodeAnswer(Object? json) {
    if (json is! Map) return null;
    final index = json['index'];
    if (index is int) return ChoiceAnswer(index);
    final order = json['order'];
    if (order is List) {
      final indices = [
        for (final value in order)
          if (value is int) value,
      ];
      if (indices.length == order.length) return OrderAnswer(indices);
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// A paper written down, before its questions have been found again.
///
/// Read from the save file without touching the content files, so the Learn
/// card can say "N5 mock, block 2, 18 minutes left" without parsing four
/// drill files to do it.
class SavedExam {
  /// Purpose: Hold a saved paper.
  /// Inputs: All fields.
  /// Returns: A new `SavedExam` instance.
  /// Side effects: None.
  /// Notes: None.
  const SavedExam({
    required this.level,
    required this.scale,
    required this.startedAt,
    required this.blockIndex,
    required this.blocks,
  });

  /// The level's label.
  final String level;

  /// `short` or `full`.
  final String scale;

  /// When the paper was first opened, UTC.
  final DateTime startedAt;

  /// Which block was being sat.
  final int blockIndex;

  /// One entry per block.
  final List<SavedExamBlock> blocks;

  /// How much time is left in the block that was being sat.
  Duration get remaining =>
      blockIndex < blocks.length ? blocks[blockIndex].remaining : Duration.zero;

  /// Purpose: Read a saved paper.
  /// Inputs: `json`.
  /// Returns: `SavedExam?` — null for anything this build cannot resume.
  /// Side effects: None.
  /// Notes: A save whose version this build does not know is refused rather
  /// than half-read. An exam resumed from a file only partly understood would
  /// be scored against questions it could not reconstruct, which is worse than
  /// telling the learner the saved paper is gone.
  static SavedExam? fromJson(Object? json) {
    if (json is! Map) return null;
    if (json['v'] != examSaveVersion) return null;
    final level = '${json['level'] ?? ''}';
    final startedAt = DateTime.tryParse('${json['startedAt']}');
    if (level.isEmpty || startedAt == null) return null;
    final blocks = [
      for (final block in (json['blocks'] as List? ?? const []))
        ?SavedExamBlock.fromJson(block),
    ];
    if (blocks.isEmpty) return null;
    final index = json['blockIndex'];
    return SavedExam(
      level: level,
      scale: '${json['scale'] ?? 'short'}',
      startedAt: startedAt.toUtc(),
      blockIndex: index is int && index >= 0 && index < blocks.length
          ? index
          : 0,
      blocks: blocks,
    );
  }
}

/// One block of a saved paper.
class SavedExamBlock {
  /// Purpose: Hold one saved block.
  /// Inputs: All fields.
  /// Returns: A new `SavedExamBlock` instance.
  /// Side effects: None.
  /// Notes: None.
  const SavedExamBlock({
    required this.sections,
    required this.limit,
    required this.used,
    required this.submitted,
    required this.started,
    required this.questionIds,
    required this.answers,
  });

  /// The sections this block examines.
  final List<DrillSection> sections;

  /// How long the block is allowed.
  final Duration limit;

  /// How much of that has been used.
  final Duration used;

  /// Whether it was already handed in.
  final bool submitted;

  /// Whether the learner had already started it.
  final bool started;

  /// The questions it asks, in order.
  final List<String> questionIds;

  /// What was answered, by question id.
  final Map<String, QuizAnswer> answers;

  /// How much time is left.
  Duration get remaining {
    final left = limit - used;
    return left.isNegative ? Duration.zero : left;
  }

  /// Purpose: Read one saved block.
  /// Inputs: `json`.
  /// Returns: `SavedExamBlock?` — null without sections or questions.
  /// Side effects: None.
  /// Notes: An answer that cannot be read is dropped and its question resumes
  /// unanswered, rather than costing the whole block.
  static SavedExamBlock? fromJson(Object? json) {
    if (json is! Map) return null;
    final sections = [
      for (final name in (json['sections'] as List? ?? const []))
        ?DrillSection.parse(name),
    ];
    final questionIds = [
      for (final id in (json['questionIds'] as List? ?? const [])) '$id',
    ];
    if (sections.isEmpty || questionIds.isEmpty) return null;
    final raw = json['answers'];
    return SavedExamBlock(
      sections: sections,
      limit: Duration(seconds: _int(json['limitSecs']) ?? 0),
      used: Duration(seconds: _int(json['usedSecs']) ?? 0),
      submitted: json['submitted'] == true,
      started: json['started'] == true,
      questionIds: questionIds,
      answers: {
        if (raw is Map)
          for (final entry in raw.entries)
            '${entry.key}': ?ExamSession.decodeAnswer(entry.value),
      },
    );
  }
}

/// Purpose: Read a JSON value as an integer.
/// Inputs: `value`.
/// Returns: `int?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
int? _int(Object? value) => switch (value) {
  final int number => number,
  final String text => int.tryParse(text),
  _ => null,
};

/// Purpose: Run one quiz from its first question to its summary.
/// Inputs: The questions to ask, and a callback for the first answer to each
/// item.
/// Returns: A `ChangeNotifier` the page listens to.
/// Side effects: Calls back on each item's first answer; holds no storage of
/// its own.
/// Notes: The session owns the queue and the score and nothing else. Writing
/// progress is a callback rather than a dependency, so this file imports no
/// storage and a test can watch exactly what it would have written.
library;

import 'package:flutter/foundation.dart';

import '../models/quiz_question.dart';
import 'answer_checker.dart';

/// How many times a wrong item comes back within the same session.
const maxRequeues = 2;

/// What happened to one answer.
class QuizOutcome {
  /// Purpose: Report one marked answer.
  /// Inputs: `correct`; `expected` — what the right answer was.
  /// Returns: A new `QuizOutcome` instance.
  /// Side effects: None.
  /// Notes: `expected` is carried so the UI can show it without re-deriving it.
  const QuizOutcome({required this.correct, this.expected});

  /// Whether the answer was right.
  final bool correct;

  /// The right answer, for showing after a wrong one.
  final String? expected;
}

/// What happened to one question over the whole session.
class QuestionOutcome {
  /// Purpose: Report one question's first result.
  /// Inputs: `key` — the question's score key; `itemId`; `correct`;
  /// `answered`.
  /// Returns: A new `QuestionOutcome` instance.
  /// Side effects: None.
  /// Notes: One per question rather than per attempt, and per **question**
  /// rather than per item: a paper asks 会う four different ways and a results
  /// screen that collapsed those into one row would hide three of them.
  ///
  /// `answered: false` is what a timed block leaves behind when the clock runs
  /// out. It is not a wrong answer — nobody got it wrong — and the exam record
  /// stores it as its own value so the accuracy is over what was attempted.
  const QuestionOutcome({
    required this.key,
    required this.itemId,
    required this.correct,
    this.answered = true,
  });

  /// The question's own id where it has one, else its item id.
  final String key;

  /// The catalog id the question is about.
  final String itemId;

  /// Whether the first answer was right; false for an unanswered question.
  final bool correct;

  /// Whether the learner answered at all.
  final bool answered;
}

/// One finished session, as the summary screen reads it.
class QuizSummary {
  /// Purpose: Report a finished session.
  /// Inputs: `total`, `firstTryCorrect`, and the ids answered wrongly first.
  /// Returns: A new `QuizSummary` instance.
  /// Side effects: None.
  /// Notes: The accuracy is over **first** answers, not over every attempt: a
  /// re-queued item answered right on the third try was not known.
  const QuizSummary({
    required this.total,
    required this.firstTryCorrect,
    required this.wrongIds,
  });

  /// How many distinct items were asked about.
  final int total;

  /// How many were right the first time.
  final int firstTryCorrect;

  /// The items that were wrong the first time, in the order they were asked.
  final List<String> wrongIds;

  /// First-try accuracy from 0 to 1; 0 for an empty session.
  double get accuracy => total == 0 ? 0 : firstTryCorrect / total;
}

/// Runs one quiz.
class QuizSession extends ChangeNotifier {
  /// Purpose: Start a session over a fixed list of questions.
  /// Inputs: `questions`; `onFirstAnswer`, called once per item with whether
  /// the **first** answer was right; `requeue`.
  /// Returns: A new `QuizSession` instance.
  /// Side effects: None until answered.
  /// Notes: `onFirstAnswer` fires per answer rather than once at the end, so an
  /// app killed mid-session keeps what was already answered. Only the first
  /// answer to an item reaches it: SM-2 grades how well something was recalled,
  /// and an item answered right on the third attempt within one minute was not
  /// recalled at all.
  ///
  /// `requeue` is off for a timed paper. Asking a question again after the
  /// learner got it wrong is how practice teaches, and it is also exactly what
  /// an exam must not do: a mock whose length depended on how well it was
  /// going could not be scored against a fixed composition, and the clock
  /// would be measuring a different paper for every learner.
  QuizSession({
    required List<QuizQuestion> questions,
    this.onFirstAnswer,
    this.requeue = true,
  }) : _queue = List.of(questions),
       _all = List.of(questions),
       _total = questions.length;

  /// Called with an item id and whether its first answer was right.
  final void Function(String itemId, bool correct)? onFirstAnswer;

  /// Whether a wrong answer comes back later in the same session.
  final bool requeue;

  final List<QuizQuestion> _queue;
  final List<QuizQuestion> _all;
  int _total;
  final AnswerChecker _checker = const AnswerChecker();
  final Map<String, bool> _firstResults = {};
  final Map<String, int> _requeues = {};
  final List<String> _wrongOrder = [];
  final Set<String> _recordedItems = {};
  final List<QuestionOutcome> _outcomes = [];
  final Map<String, QuizAnswer> _answers = {};

  QuizOutcome? _lastOutcome;
  int _answered = 0;

  /// The question on screen, or null when the session has finished.
  QuizQuestion? get current => _queue.isEmpty ? null : _queue.first;

  /// The result of the answer just given, until the next question is shown.
  QuizOutcome? get lastOutcome => _lastOutcome;

  /// Whether every question has been answered.
  bool get isFinished => _queue.isEmpty;

  /// How many distinct items the session holds.
  int get total => _total;

  /// What happened to each question, in the order they were asked.
  ///
  /// The exam record is built from this. It is per question and per first
  /// answer, which is the only reading of "what happened" that survives
  /// re-queueing.
  List<QuestionOutcome> get outcomes => List.unmodifiable(_outcomes);

  /// What the learner actually chose, by [scoreKey].
  ///
  /// The **first** answer to each question, which is the one that scored. A
  /// saved paper is written from this and replayed through [restore], so what
  /// comes back is what was chosen rather than the verdict it was given — a
  /// content update that corrected an answer key then corrects the resumed
  /// paper too.
  Map<String, QuizAnswer> get chosen => Map.unmodifiable(_answers);

  /// Every question the session was built with, in the order it asked them.
  ///
  /// What a results screen needs: the outcomes say which questions went wrong
  /// but not what they were, and re-reading the content files to find out
  /// would be re-answering a question the session already knows.
  List<QuizQuestion> get allQuestions => List.unmodifiable(_all);

  /// The score keys still waiting to be asked, in order.
  ///
  /// What a save needs alongside [outcomes] to write down the whole paper: the
  /// questions already answered and the ones still to come.
  List<String> get remainingKeys => [
    for (final question in _queue) scoreKey(question),
  ];

  /// Purpose: Name the key a question is scored under.
  /// Inputs: The `question`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: A drill question has its own id because a paper asks several
  /// different questions about one word, and scoring them as one item would
  /// mean the second and third never counted. Everything else is scored by
  /// item, which is what it has always been: two generated questions about one
  /// grammar point are the same question asked twice.
  static String scoreKey(QuizQuestion question) =>
      question.questionId ?? question.itemId;

  /// Purpose: Add a question to a session already running.
  /// Inputs: The `question`.
  /// Returns: None.
  /// Side effects: Lengthens the queue; notifies listeners.
  /// Notes: For a question that arrives after the session started — today,
  /// one written by the on-device model, which takes seconds the learner
  /// should not spend staring at a spinner. It goes to the back rather than
  /// interrupting, and the total grows so the progress indicator stays
  /// honest about how much is left.
  void append(QuizQuestion question) {
    _queue.add(question);
    _all.add(question);
    _total++;
    notifyListeners();
  }

  /// Purpose: Drop the current question without answering it.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Shortens the queue and the total; notifies listeners.
  /// Notes: For a question the learner should not have been asked — today,
  /// one the on-device model wrote. It is removed rather than re-queued, and
  /// [total] comes down with it so the progress line keeps counting what the
  /// learner will actually be asked.
  ///
  /// **Nothing is recorded.** A skipped question was not got wrong: it never
  /// reaches `_firstResults`, never enters the wrong list, never appears in
  /// [outcomes], and never moves a review interval. A generated question could
  /// not move one anyway, but the rule is stated here rather than left to that
  /// coincidence.
  void skip() {
    if (_queue.isEmpty) return;
    _queue.removeAt(0);
    if (_total > 0) _total--;
    _lastOutcome = null;
    notifyListeners();
  }

  /// Purpose: End the session with whatever is left unanswered.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Empties the queue; notifies listeners.
  /// Notes: What a timed block does when the clock reaches zero. Unlike
  /// [skip], the remaining questions **are** recorded — as `answered: false`,
  /// which is neither right nor wrong. Running out of time is a fact about the
  /// attempt and hiding it would make every timed score look better than it
  /// was; calling it wrong would make the learner look worse than they are.
  ///
  /// Nothing reaches `onFirstAnswer`: an unanswered question says nothing
  /// about how well the item was recalled, so it must not move a schedule.
  void forfeit() {
    for (final question in _queue) {
      final key = scoreKey(question);
      if (_firstResults.containsKey(key)) continue;
      _firstResults[key] = false;
      _outcomes.add(
        QuestionOutcome(
          key: key,
          itemId: question.itemId,
          correct: false,
          answered: false,
        ),
      );
    }
    _queue.clear();
    _lastOutcome = null;
    notifyListeners();
  }

  /// Purpose: Replay answers saved from an earlier sitting.
  /// Inputs: `answers`, keyed by [scoreKey].
  /// Returns: None.
  /// Side effects: Marks each replayed question; may call `onFirstAnswer`;
  /// notifies listeners once at the end.
  /// Notes: What resuming a saved mock does. The answers are marked again
  /// rather than their verdicts restored, so a content update that corrected
  /// an answer key is applied to the resumed paper too — the alternative is
  /// carrying a score the shipped file no longer agrees with.
  ///
  /// Questions the save has no answer for are left in the queue, which is what
  /// "resume" means.
  void restore(Map<String, QuizAnswer> answers) {
    if (answers.isEmpty) return;
    while (_queue.isNotEmpty) {
      final question = _queue.first;
      final saved = answers[scoreKey(question)];
      if (saved == null) break;
      answer(saved);
      next();
    }
    notifyListeners();
  }

  /// How many items have been answered at least once.
  int get answeredCount => _firstResults.length;

  /// How many answers have been given, re-queued ones included.
  int get attempts => _answered;

  /// The finished session, for the summary screen.
  QuizSummary get summary => QuizSummary(
    total: _total,
    firstTryCorrect: _firstResults.values.where((c) => c).length,
    wrongIds: List.unmodifiable(_wrongOrder),
  );

  /// Purpose: Mark the current question and hold the result.
  /// Inputs: The learner's `answer`.
  /// Returns: `QuizOutcome`, also available as [lastOutcome].
  /// Side effects: Records the first answer through the callback; notifies
  /// listeners.
  /// Notes: The question stays on screen after this: the learner has to see
  /// what the right answer was, so [next] is a separate step.
  ///
  /// `acceptedAnyway` only ever raises the verdict, never lowers it.
  QuizOutcome answer(QuizAnswer answer, {bool? acceptedAnyway}) {
    final question = current;
    if (question == null) {
      return const QuizOutcome(correct: false);
    }
    // `acceptedAnyway` is the on-device model's second opinion on a typed
    // answer, and it can only ever **raise** a verdict. The deterministic
    // check owns "correct": if the answer matches what the catalog says, no
    // model is asked and none can take that away. What a model can do is
    // recognise that a different wording means the same thing, which a string
    // comparison cannot — see `ai-assist.md`.
    final correct =
        _checker.check(question, answer) || (acceptedAnyway ?? false);
    _answered++;

    final key = scoreKey(question);
    if (!_firstResults.containsKey(key)) {
      _firstResults[key] = correct;
      _answers[key] = answer;
      _outcomes.add(
        QuestionOutcome(key: key, itemId: question.itemId, correct: correct),
      );
      // Named once even when the paper asks about it four times: the list is
      // what the learner is told to go and review, and the same word four
      // times over is a worse list, not a more emphatic one.
      if (!correct && !_wrongOrder.contains(question.itemId)) {
        _wrongOrder.add(question.itemId);
      }
      // A generated question never reaches the scheduler. It may be wrong
      // about the word, and the spacing of a word's reviews must not depend
      // on that. It still counts towards the score the learner sees, because
      // they answered it.
      //
      // The scheduler hears about each **item** once, even where a paper asked
      // four questions about it: SM-2 grades one recall, and the first is the
      // one that was not primed by the three before it.
      if (!question.generated && _recordedItems.add(question.itemId)) {
        onFirstAnswer?.call(question.itemId, correct);
      }
    }

    _lastOutcome = QuizOutcome(
      correct: correct,
      expected: correct ? null : _expectedText(question),
    );
    notifyListeners();
    return _lastOutcome!;
  }

  /// Purpose: Move to the next question, re-queueing a wrong one.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Changes the queue; notifies listeners.
  /// Notes: A wrong answer sends the item to the back of the queue so it is
  /// asked again before the session ends — that repetition is where the
  /// learning happens — but at most [maxRequeues] times, or a session with one
  /// stubborn item would never finish. A session created with `requeue: false`
  /// never does this at all; see the constructor.
  void next() {
    final question = current;
    if (question == null) return;
    _queue.removeAt(0);

    final key = scoreKey(question);
    final wasWrong = _lastOutcome?.correct == false;
    final seen = _requeues[key] ?? 0;
    if (requeue && wasWrong && seen < maxRequeues) {
      _requeues[key] = seen + 1;
      _queue.add(question);
    }
    _lastOutcome = null;
    notifyListeners();
  }

  /// Purpose: Name the right answer for the UI.
  /// Inputs: `question`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. An ordering question's
  /// right answer is the fragments joined in order, which is the sentence.
  String? _expectedText(QuizQuestion question) {
    if (question.kind != AnswerKind.order) return question.answerText;
    final ordered = List.generate(question.options.length, (i) => i)
      ..sort(
        (a, b) => question.answerOrder[a].compareTo(question.answerOrder[b]),
      );
    return [for (final index in ordered) question.options[index]].join();
  }
}

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
  /// the **first** answer was right.
  /// Returns: A new `QuizSession` instance.
  /// Side effects: None until answered.
  /// Notes: `onFirstAnswer` fires per answer rather than once at the end, so an
  /// app killed mid-session keeps what was already answered. Only the first
  /// answer to an item reaches it: SM-2 grades how well something was recalled,
  /// and an item answered right on the third attempt within one minute was not
  /// recalled at all.
  QuizSession({
    required List<QuizQuestion> questions,
    this.onFirstAnswer,
  }) : _queue = List.of(questions),
       _total = questions.length;

  /// Called with an item id and whether its first answer was right.
  final void Function(String itemId, bool correct)? onFirstAnswer;

  final List<QuizQuestion> _queue;
  int _total;
  final AnswerChecker _checker = const AnswerChecker();
  final Map<String, bool> _firstResults = {};
  final Map<String, int> _requeues = {};
  final List<String> _wrongOrder = [];

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
    _total++;
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
  QuizOutcome answer(QuizAnswer answer) {
    final question = current;
    if (question == null) {
      return const QuizOutcome(correct: false);
    }
    final correct = _checker.check(question, answer);
    _answered++;

    if (!_firstResults.containsKey(question.itemId)) {
      _firstResults[question.itemId] = correct;
      if (!correct) _wrongOrder.add(question.itemId);
      // A generated question never reaches the scheduler. It may be wrong
      // about the word, and the spacing of a word's reviews must not depend
      // on that. It still counts towards the score the learner sees, because
      // they answered it.
      if (!question.generated) onFirstAnswer?.call(question.itemId, correct);
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
  /// stubborn item would never finish.
  void next() {
    final question = current;
    if (question == null) return;
    _queue.removeAt(0);

    final wasWrong = _lastOutcome?.correct == false;
    final seen = _requeues[question.itemId] ?? 0;
    if (wasWrong && seen < maxRequeues) {
      _requeues[question.itemId] = seen + 1;
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

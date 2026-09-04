/// Purpose: Decide whether an answer is right.
/// Inputs: A question and what the learner did.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Kept apart from the widgets because marking is not a rendering
/// concern and because a typed answer is more forgiving than string equality:
/// a learner typing on a Japanese keyboard produces kana, one without an IME
/// produces romaji, and neither is wrong. What is *not* forgiven is a different
/// reading — が and か are different words, and normalizing them together would
/// teach that they are the same.
library;

import '../../kana/models/kana_text.dart';
import '../models/quiz_question.dart';

/// What the learner did about one question.
sealed class QuizAnswer {
  const QuizAnswer();
}

/// They picked one of the options.
class ChoiceAnswer extends QuizAnswer {
  /// Purpose: Record a chosen option.
  /// Inputs: `index` into the question's options.
  /// Returns: A new `ChoiceAnswer` instance.
  /// Side effects: None.
  /// Notes: None.
  const ChoiceAnswer(this.index);

  /// Which option was chosen.
  final int index;
}

/// They typed something.
class TypedAnswer extends QuizAnswer {
  /// Purpose: Record typed text.
  /// Inputs: `text` exactly as typed.
  /// Returns: A new `TypedAnswer` instance.
  /// Side effects: None.
  /// Notes: Normalization happens when it is checked, not here, so the UI can
  /// show the learner what they actually wrote.
  const TypedAnswer(this.text);

  /// What was typed.
  final String text;
}

/// They put the fragments in an order.
class OrderAnswer extends QuizAnswer {
  /// Purpose: Record an ordering.
  /// Inputs: `order` — the option indices in the order chosen.
  /// Returns: A new `OrderAnswer` instance.
  /// Side effects: None.
  /// Notes: None.
  const OrderAnswer(this.order);

  /// The option indices, in the order the learner arranged them.
  final List<int> order;
}

/// Marks answers.
class AnswerChecker {
  /// Purpose: Create a checker.
  /// Inputs: None.
  /// Returns: A new `AnswerChecker` instance.
  /// Side effects: None.
  /// Notes: Stateless and `const`.
  const AnswerChecker();

  /// Purpose: Mark one answer.
  /// Inputs: The `question` and the `answer`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: An answer of the wrong shape for the question is wrong rather than
  /// an error — the UI cannot produce one, and crashing on it would be a worse
  /// failure than marking it.
  bool check(QuizQuestion question, QuizAnswer answer) => switch (answer) {
    ChoiceAnswer(:final index) => index == question.answerIndex,
    TypedAnswer(:final text) => _checkTyped(question, text),
    OrderAnswer(:final order) => _checkOrder(question, order),
  };

  /// Purpose: Mark a typed answer.
  /// Inputs: The `question` and the raw `text`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Two spellings are
  /// accepted, and both are compared against a pre-normalized set: the kana
  /// reading through `toHiragana`, which folds katakana, long vowels and
  /// full-width characters, and the romaji lowercased. Whitespace is stripped
  /// because an IME leaves it and it means nothing here.
  bool _checkTyped(QuizQuestion question, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final kana = toHiragana(trimmed);
    final latin = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return question.acceptedAnswers.contains(kana) ||
        question.acceptedAnswers.contains(latin);
  }

  /// Purpose: Mark an ordering.
  /// Inputs: The `question` and the `order` chosen.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The question's
  /// `answerOrder` says where each shuffled fragment belongs, so a correct
  /// arrangement is the one whose positions ascend.
  bool _checkOrder(QuizQuestion question, List<int> order) {
    if (order.length != question.options.length) return false;
    if (order.toSet().length != order.length) return false;
    var previous = -1;
    for (final index in order) {
      if (index < 0 || index >= question.answerOrder.length) return false;
      final position = question.answerOrder[index];
      if (position <= previous) return false;
      previous = position;
    }
    return true;
  }
}

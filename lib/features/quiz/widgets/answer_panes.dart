import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../models/quiz_question.dart';
import '../services/answer_checker.dart';

/// Purpose: List the ordering fragments not placed yet, in display order.
/// Inputs: The `question` and the learner's `pending` answer.
/// Returns: `List<int>` — option indices, left to right as the chips show them.
/// Side effects: None.
/// Notes: Shared by the pane that draws the chips and the keyboard shortcut
/// that picks one, so key `3` always means the third chip on screen.
List<int> remainingFragments(QuizQuestion question, QuizAnswer? pending) {
  final chosen = pending is OrderAnswer ? pending.order : const <int>[];
  return [
    for (var i = 0; i < question.options.length; i++)
      if (!chosen.contains(i)) i,
  ];
}

/// The controls a question is answered with.
///
/// One widget rather than three at the call site: the three answer shapes —
/// pick one, type it, order the pieces — are the only thing that varies, and
/// which of them applies is a property of the question.
class AnswerPane extends StatelessWidget {
  /// Purpose: Create the answer controls for a question.
  /// Inputs: The `question`; `pending`, the answer composed so far; `locked`
  /// once it has been answered; `onChanged` as the learner composes;
  /// `onSubmit` when they commit from the keyboard; `showKeyHints` to number
  /// the options for a keyboard.
  /// Returns: A new `AnswerPane` instance.
  /// Side effects: None.
  /// Notes: Composing and submitting are separate so a mis-tap is correctable:
  /// choosing an option selects it, and a second action commits it. The
  /// composed choice and ordering live in the caller, not here, so a tap and a
  /// keyboard shortcut change the same state through the same path.
  const AnswerPane({
    super.key,
    required this.question,
    required this.pending,
    required this.locked,
    required this.onChanged,
    required this.onSubmit,
    this.showKeyHints = false,
  });

  /// The question being answered.
  final QuizQuestion question;

  /// The answer composed so far, or null before anything is chosen.
  final QuizAnswer? pending;

  /// Whether the answer has been submitted and the controls are read-only.
  final bool locked;

  /// Called with the answer as it is composed.
  final ValueChanged<QuizAnswer> onChanged;

  /// Called when the learner commits from the keyboard.
  final VoidCallback onSubmit;

  /// Whether options and fragments carry the number their key selects.
  final bool showKeyHints;

  /// Purpose: Build whichever controls this question needs.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Keyed by
  /// the question's identity so a typed string is discarded when the question
  /// changes rather than carried into the next one.
  @override
  Widget build(BuildContext context) {
    // Keyed by the question's own identity, not its item's. A paper asks
    // several different questions about one word one after another, and
    // keying by the item alone carried the first one's selection into the
    // second — the same latent bug the re-speak check had.
    final key = ValueKey(
      '${question.questionId ?? question.itemId}/${question.mode.name}',
    );
    return switch (question.kind) {
      AnswerKind.choice => _ChoicePane(
        key: key,
        question: question,
        pending: pending,
        locked: locked,
        onChanged: onChanged,
        showKeyHints: showKeyHints,
      ),
      AnswerKind.typed => _TypedPane(
        key: key,
        locked: locked,
        onChanged: onChanged,
        onSubmit: onSubmit,
      ),
      AnswerKind.order => _OrderPane(
        key: key,
        question: question,
        pending: pending,
        locked: locked,
        onChanged: onChanged,
        showKeyHints: showKeyHints,
      ),
    };
  }
}

/// One option per row, the whole row tappable.
class _ChoicePane extends StatelessWidget {
  const _ChoicePane({
    super.key,
    required this.question,
    required this.pending,
    required this.locked,
    required this.onChanged,
    required this.showKeyHints,
  });

  final QuizQuestion question;
  final QuizAnswer? pending;
  final bool locked;
  final ValueChanged<QuizAnswer> onChanged;
  final bool showKeyHints;

  /// Purpose: Build the options.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Once
  /// locked, the correct option is outlined and a wrong choice is marked, so
  /// the learner sees both what they picked and what was right.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = pending;
    final selected = answer is ChoiceAnswer ? answer.index : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _option(theme, i, selected),
          ),
      ],
    );
  }

  /// Purpose: Build one option button.
  /// Inputs: `theme`, the option `index`, and the `selected` index.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: Internal helper used within this file only. With key hints on,
  /// the first nine options carry the digit that selects them.
  Widget _option(ThemeData theme, int index, int? selected) {
    final isAnswer = index == question.answerIndex;
    final chosen = index == selected;
    final showResult = locked;

    final background = switch ((showResult, isAnswer, chosen)) {
      (true, true, _) => theme.colorScheme.primaryContainer,
      (true, false, true) => theme.colorScheme.errorContainer,
      _ => chosen ? theme.colorScheme.secondaryContainer : null,
    };

    // An option gets its reading over it wherever the catalog knows one,
    // **except** when the reading is what the question is asking for.
    final label = FuriganaText(
      question.options[index],
      reading: index < question.optionReadings.length
          ? question.optionReadings[index]
          : null,
      forceOff:
          question.mode == QuizMode.vocabKanjiToReading ||
          question.mode == QuizMode.vocabReadingToKanji,
      style: theme.textTheme.titleMedium,
    );

    return OutlinedButton(
      onPressed: locked ? null : () => onChanged(ChoiceAnswer(index)),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: background,
        // Keep the label readable once the button is disabled: a locked pane is
        // showing the learner the answer, not refusing to talk to them.
        disabledForegroundColor: theme.colorScheme.onSurface,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: showKeyHints && index < 9
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _KeyNumber(index + 1),
                  const SizedBox(width: 12),
                  Flexible(child: label),
                ],
              )
            : label,
      ),
    );
  }
}

/// The digit that selects an option, drawn quietly beside it.
class _KeyNumber extends StatelessWidget {
  const _KeyNumber(this.number);

  final int number;

  /// Purpose: Draw the number.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: None.
  /// Notes: Excluded from semantics: a screen reader already announces the
  /// option, and reading "1" before every one of them is noise.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Text(
        '$number',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.outline,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A text field for a typed reading.
class _TypedPane extends StatefulWidget {
  const _TypedPane({
    super.key,
    required this.locked,
    required this.onChanged,
    required this.onSubmit,
  });

  final bool locked;
  final ValueChanged<QuizAnswer> onChanged;
  final VoidCallback onSubmit;

  @override
  State<_TypedPane> createState() => _TypedPaneState();
}

class _TypedPaneState extends State<_TypedPane> {
  final _controller = TextEditingController();
  final _focus = FocusNode(debugLabel: 'typed answer');

  /// Purpose: Put the cursor in the field as soon as the question appears.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Requests keyboard focus after the first frame.
  /// Notes: An explicit request rather than `autofocus`, because `autofocus`
  /// is ignored once anything else in the route holds focus — and after a
  /// choice question the quiz's own keyboard handler does.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.locked) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Purpose: Build the input field.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  /// Focused so a learner answering a run of these never reaches for the
  /// field, and submitting from the keyboard works because that is how anybody
  /// types a list of answers.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: !widget.locked,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.quizTypeReadingHint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) => widget.onChanged(TypedAnswer(text)),
      onSubmitted: (_) => widget.onSubmit(),
    );
  }
}

/// Fragments to tap into order.
class _OrderPane extends StatelessWidget {
  const _OrderPane({
    super.key,
    required this.question,
    required this.pending,
    required this.locked,
    required this.onChanged,
    required this.showKeyHints,
  });

  final QuizQuestion question;
  final QuizAnswer? pending;
  final bool locked;
  final ValueChanged<QuizAnswer> onChanged;
  final bool showKeyHints;

  /// Purpose: Build the sentence being assembled and the pieces left.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Tapping
  /// rather than dragging: a drag target the width of a fragment is a hard
  /// gesture on a phone, and tapping is reversible by tapping again. With key
  /// hints on, the remaining fragments carry the digit that places them.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final answer = pending;
    final chosen = answer is OrderAnswer ? answer.order : const <int>[];
    final remaining = remainingFragments(question, pending);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final index in chosen)
                ActionChip(
                  label: Text(question.options[index]),
                  onPressed: locked ? null : () => _remove(chosen, index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var n = 0; n < remaining.length; n++)
              ActionChip(
                avatar: showKeyHints && n < 9 && !locked
                    ? _KeyNumber(n + 1)
                    : null,
                label: Text(question.options[remaining[n]]),
                onPressed: locked
                    ? null
                    : () => onChanged(OrderAnswer([...chosen, remaining[n]])),
              ),
          ],
        ),
        if (chosen.isNotEmpty && !locked)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onChanged(const OrderAnswer([])),
              child: Text(l10n.quizOrderReset),
            ),
          ),
      ],
    );
  }

  /// Purpose: Take a fragment back out.
  /// Inputs: The current `chosen` order and the option `index` to remove.
  /// Returns: None.
  /// Side effects: Reports the new ordering.
  /// Notes: Internal helper used within this file only.
  void _remove(List<int> chosen, int index) {
    onChanged(
      OrderAnswer([
        for (final i in chosen)
          if (i != index) i,
      ]),
    );
  }
}

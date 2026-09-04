import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/quiz_question.dart';
import '../services/answer_checker.dart';

/// The controls a question is answered with.
///
/// One widget rather than three at the call site: the three answer shapes —
/// pick one, type it, order the pieces — are the only thing that varies, and
/// which of them applies is a property of the question.
class AnswerPane extends StatelessWidget {
  /// Purpose: Create the answer controls for a question.
  /// Inputs: The `question`; `locked` once it has been answered; `onChanged`
  /// as the learner composes; `onSubmit` when they commit from the keyboard.
  /// Returns: A new `AnswerPane` instance.
  /// Side effects: None.
  /// Notes: Composing and submitting are separate so a mis-tap is correctable:
  /// choosing an option selects it, and a second action commits it.
  const AnswerPane({
    super.key,
    required this.question,
    required this.locked,
    required this.onChanged,
    required this.onSubmit,
  });

  /// The question being answered.
  final QuizQuestion question;

  /// Whether the answer has been submitted and the controls are read-only.
  final bool locked;

  /// Called with the answer as it is composed.
  final ValueChanged<QuizAnswer> onChanged;

  /// Called when the learner commits from the keyboard.
  final VoidCallback onSubmit;

  /// Purpose: Build whichever controls this question needs.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Keyed by
  /// the question's identity so composing state — a typed string, a partial
  /// ordering — is discarded when the question changes rather than carried into
  /// the next one.
  @override
  Widget build(BuildContext context) {
    final key = ValueKey('${question.itemId}/${question.mode.name}');
    return switch (question.kind) {
      AnswerKind.choice => _ChoicePane(
        key: key,
        question: question,
        locked: locked,
        onChanged: onChanged,
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
        locked: locked,
        onChanged: onChanged,
      ),
    };
  }
}

/// One option per row, the whole row tappable.
class _ChoicePane extends StatefulWidget {
  const _ChoicePane({
    super.key,
    required this.question,
    required this.locked,
    required this.onChanged,
  });

  final QuizQuestion question;
  final bool locked;
  final ValueChanged<QuizAnswer> onChanged;

  @override
  State<_ChoicePane> createState() => _ChoicePaneState();
}

class _ChoicePaneState extends State<_ChoicePane> {
  int? _selected;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _option(theme, i),
          ),
      ],
    );
  }

  /// Purpose: Build one option button.
  /// Inputs: `theme`, the option `index`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: Internal helper used within this file only.
  Widget _option(ThemeData theme, int index) {
    final isAnswer = index == widget.question.answerIndex;
    final chosen = index == _selected;
    final showResult = widget.locked;

    final background = switch ((showResult, isAnswer, chosen)) {
      (true, true, _) => theme.colorScheme.primaryContainer,
      (true, false, true) => theme.colorScheme.errorContainer,
      _ => chosen ? theme.colorScheme.secondaryContainer : null,
    };

    return OutlinedButton(
      onPressed: widget.locked
          ? null
          : () {
              setState(() => _selected = index);
              widget.onChanged(ChoiceAnswer(index));
            },
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
        child: Text(
          widget.question.options[index],
          style: theme.textTheme.titleMedium,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Purpose: Build the input field.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  /// Autofocused so a learner answering a run of these never reaches for the
  /// field, and submitting from the keyboard works because that is how anybody
  /// types a list of answers.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      enabled: !widget.locked,
      autofocus: true,
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
class _OrderPane extends StatefulWidget {
  const _OrderPane({
    super.key,
    required this.question,
    required this.locked,
    required this.onChanged,
  });

  final QuizQuestion question;
  final bool locked;
  final ValueChanged<QuizAnswer> onChanged;

  @override
  State<_OrderPane> createState() => _OrderPaneState();
}

class _OrderPaneState extends State<_OrderPane> {
  final List<int> _chosen = [];

  /// Purpose: Build the sentence being assembled and the pieces left.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Tapping
  /// rather than dragging: a drag target the width of a fragment is a hard
  /// gesture on a phone, and tapping is reversible by tapping again.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final remaining = [
      for (var i = 0; i < widget.question.options.length; i++)
        if (!_chosen.contains(i)) i,
    ];

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
              for (final index in _chosen)
                ActionChip(
                  label: Text(widget.question.options[index]),
                  onPressed: widget.locked ? null : () => _remove(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final index in remaining)
              ActionChip(
                label: Text(widget.question.options[index]),
                onPressed: widget.locked ? null : () => _add(index),
              ),
          ],
        ),
        if (_chosen.isNotEmpty && !widget.locked)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _chosen.clear();
                widget.onChanged(const OrderAnswer([]));
              }),
              child: Text(l10n.quizOrderReset),
            ),
          ),
      ],
    );
  }

  /// Purpose: Append a fragment to the sentence being built.
  /// Inputs: The option `index`.
  /// Returns: None.
  /// Side effects: Rebuilds and reports the ordering.
  /// Notes: Internal helper used within this file only.
  void _add(int index) {
    setState(() => _chosen.add(index));
    widget.onChanged(OrderAnswer(List.of(_chosen)));
  }

  /// Purpose: Take a fragment back out.
  /// Inputs: The option `index`.
  /// Returns: None.
  /// Side effects: Rebuilds and reports the ordering.
  /// Notes: Internal helper used within this file only.
  void _remove(int index) {
    setState(() => _chosen.remove(index));
    widget.onChanged(OrderAnswer(List.of(_chosen)));
  }
}

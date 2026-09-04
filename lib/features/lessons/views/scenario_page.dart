import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../speech/widgets/speak_button.dart';
import '../models/lesson_path.dart';
import '../models/scenario.dart';

/// What a scenario page needs to run, passed as the route's `extra`.
class ScenarioArgs {
  /// Purpose: Carry a scenario and the unit it belongs to.
  /// Inputs: `scenario`, `unit`.
  /// Returns: A new `ScenarioArgs` instance.
  /// Side effects: None.
  /// Notes: The unit comes along so the page can name what is being practised
  /// without looking the path up again.
  const ScenarioArgs({required this.scenario, required this.unit});

  /// The conversation to play.
  final Scenario scenario;

  /// The unit it belongs to.
  final LessonUnit unit;
}

/// Play one scripted conversation, one line at a time.
///
/// The learner taps to advance, and at a branch picks what to say. Both the
/// script and the choices are read aloud on request, which is the point of a
/// conversation the app can speak.
///
/// **A wrong choice does not end the conversation.** The chosen line is shown
/// in the transcript where it was said, marked right or wrong, the script
/// carries on, and the tally at the end says how many were right. Nothing is
/// written to the scheduler: choosing one of three is not recall, and the
/// unit's practice session is where recall is measured.
class ScenarioPage extends ConsumerStatefulWidget {
  /// Purpose: Show one conversation.
  /// Inputs: The `args`.
  /// Returns: A new `ScenarioPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const ScenarioPage({super.key, required this.args});

  /// The conversation and its unit.
  final ScenarioArgs args;

  @override
  ConsumerState<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends ConsumerState<ScenarioPage> {
  /// How many script lines have been shown.
  int _shown = 1;

  /// The branch waiting for an answer, when one is.
  ScenarioBranch? _asking;

  /// What the learner said, keyed by the branch's `after` so the reply can be
  /// shown in the place in the conversation where it was said.
  final _said = <int, ScenarioChoice>{};

  Scenario get _scenario => widget.args.scenario;

  @override
  void initState() {
    super.initState();
    _asking = _scenario.branchAfter(1);
  }

  /// Whether the script has run to its end with nothing left to ask.
  bool get _finished => _asking == null && _shown >= _scenario.dialogue.length;

  /// Purpose: Show the next line, or the branch that comes before it.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only.
  void _advance() {
    if (_finished) return;
    setState(() {
      _shown++;
      _asking = _scenario.branchAfter(_shown);
    });
  }

  /// Purpose: Record the reply the learner picked and carry on.
  /// Inputs: The `choice`.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only. The conversation
  /// continues whether the choice was right or wrong; only the tally differs.
  void _choose(ScenarioChoice choice) {
    final branch = _asking;
    if (branch == null) return;
    setState(() {
      _said[branch.after] = choice;
      _asking = null;
    });
  }

  @override
  /// Purpose: Build the page.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One column of lines that grows downwards, because a conversation
  /// is read in order and the newest line is the one being read.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final lines = _scenario.dialogue.take(_shown).toList();
    final branch = _asking;

    return Scaffold(
      appBar: AppBar(title: Text(_scenario.title.resolveJoined(locale))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                _line(context, lines[i], locale),
                // The learner's own reply belongs in the conversation, at the
                // point they said it — a transcript that drops it reads as if
                // the other speaker simply carried on alone.
                if (_said[i + 1] case final choice?)
                  _saidLine(context, choice, locale),
              ],
              if (branch != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.scenarioChoose,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                for (final choice in branch.choices)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton(
                      onPressed: () => _choose(choice),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FuriganaText(choice.ja, reading: choice.reading),
                      ),
                    ),
                  ),
              ] else if (_finished) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.scenarioDone(_rightCount, _said.length),
                  style: theme.textTheme.titleMedium,
                ),
              ] else ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _advance,
                  child: Text(l10n.scenarioNext),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// How many of the learner's replies were the expected one.
  int get _rightCount => _said.values.where((choice) => choice.correct).length;

  /// Purpose: Render the line the learner chose to say.
  /// Inputs: `context`, the `choice`, the `locale`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Marked right or wrong
  /// where the speaker's name would be, and set apart from the script by its
  /// tinted background, because the learner needs to see at a glance which
  /// lines in the transcript were theirs. It is shown either way: the whole
  /// point of a wrong reply not ending the conversation is being able to read
  /// what it looked like in place.
  Widget _saidLine(
    BuildContext context,
    ScenarioChoice choice,
    Locale locale,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Icon(
                choice.correct ? Icons.check_circle : Icons.cancel_outlined,
                size: 20,
                color: choice.correct
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FuriganaText(choice.ja, reading: choice.reading),
                  Text(
                    choice.translations.resolveJoined(locale),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SpeakButton(text: choice.reading ?? choice.ja),
          ],
        ),
      ),
    );
  }

  /// Purpose: Render one spoken line.
  /// Inputs: `context`, the `line`, the `locale`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The speaker's label is
  /// shown as written, the Japanese carries its kana, and the translation sits
  /// underneath in the reader's own language.
  Widget _line(BuildContext context, DialogueLine line, Locale locale) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Chip(
                label: Text(line.speaker),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuriganaText(line.ja, reading: line.reading),
                Text(
                  line.translations.resolveJoined(locale),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SpeakButton(text: line.reading ?? line.ja),
        ],
      ),
    );
  }
}

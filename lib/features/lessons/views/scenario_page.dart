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
/// as said, the script carries on, and the tally at the end says how many were
/// right. Nothing is written to the scheduler: choosing a reply from four is
/// not recall, and the unit's practice session is where recall is measured.
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

  /// What the learner said, in the order they said it.
  final _said = <ScenarioChoice>[];

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
    setState(() {
      _said.add(choice);
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
              for (final line in lines) _line(context, line, locale),
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
  int get _rightCount => _said.where((choice) => choice.correct).length;

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

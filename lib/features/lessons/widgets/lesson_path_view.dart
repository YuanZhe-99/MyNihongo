import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../quiz/models/quiz_config.dart';
import '../../content/models/jlpt_level.dart';
import '../models/lesson_path.dart';
import '../views/scenario_page.dart';
import '../services/lesson_repository.dart';
import '../services/lesson_rules.dart';
import '../../writing/views/writing_practice_page.dart';

/// The target level's units, as a path.
///
/// A level with no unit file yet says so in one line rather than showing an
/// empty box: levels are written one at a time, and a build that has N5's
/// units and not N3's is the normal state.
class LessonPathView extends ConsumerWidget {
  /// Purpose: Show the units of the learner's target level.
  /// Inputs: None; reads the profile, the path and the progress.
  /// Returns: A new `LessonPathView` instance.
  /// Side effects: None.
  /// Notes: None.
  const LessonPathView({super.key});

  @override
  /// Purpose: Build the path.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The cards are packed by width like the rest of the Learn tab, so
  /// a folded phone shows one column and an unfolded one shows two without a
  /// second layout to maintain.
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = ref.watch(learnerProfileProvider);
    final path = ref.watch(lessonPathProvider(profile.targetLevel));
    final progress = ref.watch(progressDataProvider).value;

    final units = path.value?.units ?? const <LessonUnit>[];
    if (path.value == null) return const LinearProgressIndicator();
    if (units.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.pathNotWritten(profile.targetLevel.label),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final states = progress == null
        ? <String, UnitState>{}
        : unitStates(path.value!, progress);
    final width = referenceContentWidth(MediaQuery.sizeOf(context).width);
    final columns = columnCapacity(
      width,
      minItemWidth: ruleCardMinWidth,
      maxColumns: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            l10n.pathTitle(profile.targetLevel.label),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final unit in units)
              SizedBox(
                width: columns == 1 ? width : (width - 12) / 2,
                child: _UnitCard(
                  unit: unit,
                  level: profile.targetLevel,
                  state: states[unit.id] ?? UnitState.locked,
                  progress: progress == null ? 0 : unitProgress(unit, progress),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One unit's card: its topic, how much of it is done, and what it offers.
class _UnitCard extends ConsumerWidget {
  /// Purpose: Show one unit.
  /// Inputs: The `unit`, its `level`, its `state`, and how much of it is done.
  /// Returns: A new `_UnitCard` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _UnitCard({
    required this.unit,
    required this.level,
    required this.state,
    required this.progress,
  });

  final LessonUnit unit;
  final JlptLevel level;
  final UnitState state;
  final double progress;

  @override
  /// Purpose: Build the card.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **A locked unit's
  /// checkpoint is still offered.** Practice is closed until the unit before
  /// is passed, but a learner who already knows this material can take the
  /// checkpoint and open it — hiding that behind the units it would let them
  /// skip is circular.
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final locked = state == UnitState.locked;
    final passed = state == UnitState.passed;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  passed
                      ? Icons.check_circle
                      : locked
                      ? Icons.lock_outline
                      : Icons.play_circle_outline,
                  size: 20,
                  color: passed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unit.title.resolveJoined(locale),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 6),
            Text(
              l10n.pathUnitItems(unit.grammar.length, unit.vocab.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: locked
                      ? null
                      : () => _start(context, ref, checkpoint: false),
                  child: Text(l10n.pathPractise),
                ),
                TextButton(
                  onPressed: () => _start(context, ref, checkpoint: true),
                  child: Text(
                    passed ? l10n.pathCheckpointAgain : l10n.pathCheckpoint,
                  ),
                ),
                // Writing is offered on the same terms as practice: it is
                // about this unit's words, so it waits until the unit opens.
                if (unit.scenario case final scenario?)
                  TextButton(
                    onPressed: locked
                        ? null
                        : () => context.push(
                            '/scenario',
                            extra: ScenarioArgs(
                              scenario: scenario,
                              unit: unit,
                            ),
                          ),
                    child: Text(l10n.pathScenario),
                  ),
                if (unit.writingPrompt case final prompt?)
                  TextButton(
                    onPressed: locked
                        ? null
                        : () => context.push(
                            '/writing',
                            extra: WritingPrompt(
                              prompt: prompt.resolveJoined(locale),
                              unit: unit,
                            ),
                          ),
                    child: Text(l10n.pathWriting),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Open a session over this unit.
  /// Inputs: `context`, `ref`, and whether this is the `checkpoint`.
  /// Returns: None.
  /// Side effects: Pushes the quiz route.
  /// Notes: Internal helper used within this file only.
  void _start(BuildContext context, WidgetRef ref, {required bool checkpoint}) {
    context.push(
      '/quiz',
      extra: QuizConfig(
        source: UnitSource(unit.id, level, checkpoint: checkpoint),
        modes: ref.read(appSettingsProvider).quizModes,
        maxQuestions: checkpoint ? checkpointSize : unitSessionSize,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../content/models/jlpt_level.dart';

/// The Settings rows that configure what and how much to study.
///
/// Unlike every other section in Settings, these are **not** device-local: the
/// target level and the daily limits live in the synced learner profile, so a
/// goal set on a phone is the same goal on a tablet. That is why they are
/// written through `progressDataProvider` rather than `appSettingsProvider`.
class LearningSettingsTiles extends ConsumerWidget {
  /// Purpose: Create the learning settings rows.
  /// Inputs: None.
  /// Returns: A new `LearningSettingsTiles` instance.
  /// Side effects: None.
  /// Notes: None.
  const LearningSettingsTiles({super.key});

  /// The daily new-item counts offered. Beyond about thirty a day, reviews
  /// pile up faster than anyone clears them.
  static const newLimits = [5, 10, 15, 20, 30];

  /// The daily review counts offered.
  static const reviewLimits = [50, 100, 150, 200, 500];

  /// Purpose: Build the target-level and daily-limit rows.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Each
  /// control writes the whole profile back, because the profile is one record
  /// and a partial write would drop the other fields.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = ref.watch(learnerProfileProvider);
    final notifier = ref.read(progressDataProvider.notifier);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.settingsTargetLevel),
          subtitle: Text(
            l10n.settingsTargetLevelBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: DropdownButton<JlptLevel>(
            value: profile.targetLevel,
            items: [
              for (final level in JlptLevel.values)
                DropdownMenuItem(value: level, child: Text(level.label)),
            ],
            onChanged: (level) => level == null
                ? null
                : notifier.updateProfile(profile.copyWith(targetLevel: level)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.fiber_new_outlined),
          title: Text(l10n.settingsDailyNew),
          trailing: DropdownButton<int>(
            value: newLimits.contains(profile.dailyNewLimit)
                ? profile.dailyNewLimit
                : null,
            hint: Text('${profile.dailyNewLimit}'),
            items: [
              for (final limit in newLimits)
                DropdownMenuItem(value: limit, child: Text('$limit')),
            ],
            onChanged: (limit) => limit == null
                ? null
                : notifier.updateProfile(
                    profile.copyWith(dailyNewLimit: limit),
                  ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.repeat_outlined),
          title: Text(l10n.settingsDailyReviews),
          subtitle: Text(
            l10n.settingsDailyLimitsBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: DropdownButton<int>(
            value: reviewLimits.contains(profile.dailyReviewLimit)
                ? profile.dailyReviewLimit
                : null,
            hint: Text('${profile.dailyReviewLimit}'),
            items: [
              for (final limit in reviewLimits)
                DropdownMenuItem(value: limit, child: Text('$limit')),
            ],
            onChanged: (limit) => limit == null
                ? null
                : notifier.updateProfile(
                    profile.copyWith(dailyReviewLimit: limit),
                  ),
          ),
        ),
      ],
    );
  }
}

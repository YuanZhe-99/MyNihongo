import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/utils/platform_capabilities.dart';

/// The daily reminder switch and the time it fires.
///
/// Hidden entirely on a platform with no notifications, rather than shown
/// disabled: a switch that cannot do anything is worse than no switch.
class ReminderSettingsTiles extends ConsumerWidget {
  /// Purpose: Show the reminder settings.
  /// Inputs: None; reads the settings provider.
  /// Returns: A new `ReminderSettingsTiles` instance.
  /// Side effects: None.
  /// Notes: None.
  const ReminderSettingsTiles({super.key});

  @override
  /// Purpose: Build the switch and the time row.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: **Permission is requested by the switch, not at startup.** The
  /// notifier asks the platform when the learner turns it on, and leaves the
  /// switch off with a line of explanation when it is refused — a switch that
  /// says on while the system says no is a lie about what will happen.
  Widget build(BuildContext context, WidgetRef ref) {
    if (!platformSchedulesReminders && !platformRemindsFromInsideTheApp) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final time = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_none),
          title: Text(l10n.reminderEnable),
          subtitle: Text(l10n.reminderEnableSubtitle),
          value: settings.reminderEnabled,
          onChanged: (on) async {
            final granted = await notifier.setReminderEnabled(on, l10n);
            if (!context.mounted || granted || !on) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.reminderDenied)));
          },
        ),
        if (settings.reminderEnabled)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.reminderTime),
            trailing: Text(time.format(context)),
            onTap: () async {
              final chosen = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (chosen == null) return;
              if (!context.mounted) return;
              await notifier.setReminderTime(
                chosen.hour,
                chosen.minute,
                l10n,
              );
            },
          ),
      ],
    );
  }
}

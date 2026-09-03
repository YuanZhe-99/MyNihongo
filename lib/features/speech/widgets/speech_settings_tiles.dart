import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/services/system_settings_launcher.dart';
import '../../../shared/utils/platform_capabilities.dart';
import '../services/tts_service.dart';

/// The Settings rows that configure spoken Japanese.
///
/// Kept out of `settings_page.dart` because the section is self-contained and
/// the settings page is already long. It reads the speaking rate and voice
/// from `appSettingsProvider` — the same place every other preference lives —
/// and asks `TtsService` what the device can actually do.
class SpeechSettingsTiles extends ConsumerWidget {
  const SpeechSettingsTiles({super.key});

  /// The sentence the preview button speaks: a greeting every learner meets
  /// in the first lesson, short enough to judge the speed by.
  static const previewText = 'こんにちは。はじめまして。';

  /// Purpose: Build the speech settings rows.
  /// Inputs: The build `context` and the widget `ref`.
  /// Returns: `Widget` — a column of rows, or the missing-voice notice.
  /// Side effects: None until a control is used.
  /// Notes: When no Japanese voice is installed there is nothing to configure,
  /// so the rate and voice rows are replaced by an explanation and, where a
  /// deep link exists, a button that opens the system speech settings.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final tts = TtsService.instance;

    if (!tts.hasJapaneseVoice) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.voice_over_off_outlined),
            title: Text(l10n.speechNoVoiceTitle),
            subtitle: Text(
              canOpenSystemSpeechSettings
                  ? l10n.speechNoVoiceBody
                  : '${l10n.speechNoVoiceBody} ${l10n.speechSettingsHintApple}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            isThreeLine: true,
          ),
          if (canOpenSystemSpeechSettings)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.speechOpenSystemSettings),
                  onPressed: () => _openSettings(context, l10n),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.speed_outlined),
          title: Text(l10n.speechRate),
          subtitle: Slider(
            min: TtsService.minRate,
            max: TtsService.maxRate,
            divisions: 6,
            value: settings.ttsRate.clamp(
              TtsService.minRate,
              TtsService.maxRate,
            ),
            label: l10n.speechRateValue(settings.ttsRate.toStringAsFixed(1)),
            onChanged: notifier.setTtsRate,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: l10n.speechRatePreview,
            onPressed: () => TtsService.instance.speak(previewText),
          ),
        ),
        if (tts.japaneseVoices.length > 1)
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: Text(l10n.speechVoice),
            trailing: DropdownButton<String?>(
              value: settings.ttsVoice,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.speechVoiceDefault),
                ),
                for (final voice in tts.japaneseVoices)
                  DropdownMenuItem(
                    value: voice['name'],
                    child: Text(voice['name'] ?? ''),
                  ),
              ],
              onChanged: notifier.setTtsVoice,
            ),
          ),
      ],
    );
  }

  /// Purpose: Send the user to the platform's speech settings.
  /// Inputs: `context`, `l10n`.
  /// Returns: None.
  /// Side effects: Opens another app; shows a snack bar when it could not.
  /// Notes: Internal helper used within this file only. The launcher answers
  /// false rather than throwing, so a device without the settings screen shows
  /// a message instead of crashing.
  Future<void> _openSettings(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await SystemSettingsLauncher.openSpeechSettings();
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.speechOpenSystemSettingsFailed)),
      );
    }
  }
}

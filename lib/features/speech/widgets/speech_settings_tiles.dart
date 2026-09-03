import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/services/system_settings_launcher.dart';
import '../../../shared/utils/platform_capabilities.dart';
import '../services/speech_recognition_service.dart';
import '../services/tts_service.dart';

/// The Settings rows that configure spoken Japanese.
///
/// Kept out of `settings_page.dart` because the section is self-contained and
/// the settings page is already long. It reads its preferences from
/// `appSettingsProvider` — the same place every other preference lives — and
/// asks `TtsService` and `SpeechRecognitionService` what the device can
/// actually do.
class SpeechSettingsTiles extends ConsumerStatefulWidget {
  const SpeechSettingsTiles({super.key});

  /// The sentence the preview button speaks: a greeting every learner meets in
  /// the first lesson, short enough to judge the speed by.
  static const previewText = 'こんにちは。はじめまして。';

  @override
  ConsumerState<SpeechSettingsTiles> createState() =>
      _SpeechSettingsTilesState();
}

class _SpeechSettingsTilesState extends ConsumerState<SpeechSettingsTiles> {
  bool? _recognizerAvailable;

  /// Purpose: Ask the recognizer whether it can be used, once.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May initialize the platform recognizer.
  /// Notes: Only asked when the platform could have one at all, so opening
  /// Settings on a platform without a recognizer never prompts for a
  /// microphone. The answer is a status line, not a control.
  @override
  void initState() {
    super.initState();
    if (!platformMayRecognizeSpeech) {
      _recognizerAvailable = false;
      return;
    }
    SpeechRecognitionService.instance.ensureAvailable().then((available) {
      if (mounted) setState(() => _recognizerAvailable = available);
    });
  }

  /// Purpose: Build the speech settings rows.
  /// Inputs: The build `context`.
  /// Returns: `Widget` — the text-to-speech rows (or the missing-voice
  /// notice), then the recognition rows.
  /// Side effects: None until a control is used.
  /// Notes: The two halves are independent: a device can have a Japanese voice
  /// and no recognizer, or the reverse, so neither half hides the other.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [..._buildTtsRows(context), ..._buildRecognitionRows(context)],
    );
  }

  /// Purpose: Build the speaking-rate and voice rows, or the notice.
  /// Inputs: `context`.
  /// Returns: `List<Widget>`.
  /// Side effects: None until a control is used.
  /// Notes: Internal helper used within this file only. With no Japanese voice
  /// there is nothing to configure, so the rows are replaced by an explanation
  /// and, where a deep link exists, a button that opens the system settings.
  List<Widget> _buildTtsRows(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final tts = TtsService.instance;

    if (!tts.hasJapaneseVoice) {
      return [
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
      ];
    }

    return [
      ListTile(
        leading: const Icon(Icons.speed_outlined),
        title: Text(l10n.speechRate),
        subtitle: Slider(
          min: TtsService.minRate,
          max: TtsService.maxRate,
          divisions: 6,
          value: settings.ttsRate.clamp(TtsService.minRate, TtsService.maxRate),
          label: l10n.speechRateValue(settings.ttsRate.toStringAsFixed(1)),
          onChanged: notifier.setTtsRate,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline),
          tooltip: l10n.speechRatePreview,
          onPressed: () =>
              TtsService.instance.speak(SpeechSettingsTiles.previewText),
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
    ];
  }

  /// Purpose: Build the recognition status line and the network-fallback
  /// switch.
  /// Inputs: `context`.
  /// Returns: `List<Widget>`.
  /// Side effects: None until the switch is used.
  /// Notes: Internal helper used within this file only. The switch is offered
  /// even where a recognizer was not found, because that is exactly the device
  /// whose owner may want to turn it on: an offline-only request is what
  /// failed. Its subtitle says plainly what turning it on means, since it is
  /// the one setting in the app that lets anything leave the device besides
  /// WebDAV sync.
  List<Widget> _buildRecognitionRows(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final available = _recognizerAvailable ?? false;
    return [
      ListTile(
        leading: Icon(
          available ? Icons.mic_none_outlined : Icons.mic_off_outlined,
        ),
        title: Text(
          available ? l10n.speechRecognizerReady : l10n.speechRecognizerMissing,
          style: theme.textTheme.bodyMedium,
        ),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.cloud_off_outlined),
        title: Text(l10n.speechNetworkFallback),
        subtitle: Text(
          l10n.speechNetworkFallbackBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        isThreeLine: true,
        value: settings.speechNetworkFallback,
        onChanged: notifier.setSpeechNetworkFallback,
      ),
    ];
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

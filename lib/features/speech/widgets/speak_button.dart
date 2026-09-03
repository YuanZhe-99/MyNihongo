import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../services/tts_service.dart';

/// A button that reads one piece of Japanese aloud.
///
/// It watches [TtsService.speaking], so the button whose text is playing shows
/// a stop icon and every other one stays idle — there is one voice, and the UI
/// says so. Tapping the playing button stops it.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.tooltip,
    this.iconSize,
  });

  /// The Japanese to speak. Callers pass the kana reading where the catalog
  /// has one, so the engine cannot mis-read a kanji.
  final String text;

  /// Overrides the default "Speak" tooltip.
  final String? tooltip;

  /// Overrides the default icon size.
  final double? iconSize;

  /// Purpose: Build the speak/stop button for this text.
  /// Inputs: The build `context`.
  /// Returns: `Widget` — an `IconButton`, disabled when the engine has no
  /// Japanese voice.
  /// Side effects: None until tapped.
  /// Notes: Disabled rather than hidden: a missing Japanese voice is a device
  /// state the user can fix, and a button that vanished would look like a
  /// feature that does not exist. The tooltip says which it is.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = TtsService.instance;
    final enabled = tts.hasJapaneseVoice;
    return ValueListenableBuilder<String?>(
      valueListenable: tts.speaking,
      builder: (context, speaking, _) {
        final active = speaking == text.trim();
        return IconButton(
          iconSize: iconSize,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            active ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          ),
          tooltip: enabled
              ? (active ? l10n.speechStop : (tooltip ?? l10n.speechSpeak))
              : l10n.speechNoVoiceTitle,
          onPressed: enabled ? () => tts.speak(text) : null,
        );
      },
    );
  }
}

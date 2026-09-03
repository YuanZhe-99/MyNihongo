import 'package:flutter/material.dart';

import '../../features/content/models/localized_strings.dart';
import '../../features/speech/widgets/pronunciation_practice_sheet.dart';
import '../../features/speech/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';

/// The controls that sit beside one example sentence.
///
/// The speak button is inline because it is the one used constantly;
/// everything else lives behind an overflow menu, because a row of icon
/// buttons does not fit a phone-width example. Later per-example actions —
/// the sentence lab in `PLAN.md` M2.3 — join the menu.
class ExampleActions extends StatelessWidget {
  const ExampleActions({super.key, required this.example});

  /// The example these actions apply to.
  final ContentExample example;

  /// Purpose: Build the per-example controls.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None until used.
  /// Notes: The spoken and practised text is the sentence's kana `reading`
  /// when the content supplies one, so the engine cannot mis-read a kanji;
  /// the surface is the fallback.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reading = example.reading ?? example.ja;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpeakButton(text: reading, iconSize: 20),
        PopupMenuButton<void>(
          iconSize: 20,
          tooltip: l10n.practiceAction,
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              onTap: () => showPronunciationPracticeSheet(
                context,
                PracticeTarget(display: example.ja, reading: reading),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_none_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.practiceAction),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

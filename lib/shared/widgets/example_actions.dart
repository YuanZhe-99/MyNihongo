import 'package:flutter/material.dart';

import '../../features/content/models/localized_strings.dart';
import '../../features/speech/widgets/speak_button.dart';

/// The controls that sit beside one example sentence.
///
/// Today that is the speak button. It exists as its own widget because more
/// per-example actions arrive with the rest of Phase 2 — practise the sentence,
/// open it in the sentence lab — and a row of three icon buttons does not fit a
/// phone-width example. Extra actions go behind the overflow menu, and the
/// speak button stays inline because it is the one used constantly.
class ExampleActions extends StatelessWidget {
  const ExampleActions({super.key, required this.example});

  /// The example these actions apply to.
  final ContentExample example;

  /// Purpose: Build the per-example controls.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: The spoken text is the sentence's kana `reading` when the content
  /// supplies one, so the engine cannot mis-read a kanji; the surface is the
  /// fallback.
  @override
  Widget build(BuildContext context) {
    return SpeakButton(text: example.reading ?? example.ja, iconSize: 20);
  }
}

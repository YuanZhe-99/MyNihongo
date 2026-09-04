import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/content/services/furigana_aligner.dart';
import '../providers/app_settings.dart';

/// Japanese text with its reading printed over the characters that need it.
///
/// Falls back to plain [Text] whenever it cannot be certain — the switch is
/// off, no reading was supplied, or the reading does not align — because the
/// caller's other option is showing the reading on its own line, which is what
/// the app did before this widget and is never wrong.
class FuriganaText extends ConsumerWidget {
  /// Purpose: Show `text`, with `reading` above the kanji it belongs to.
  /// Inputs: `text` as written; `reading` in kana; the usual text styling;
  /// `rubyScale` as a fraction of the base font size; `forceOff` to render
  /// plainly regardless of the preference.
  /// Returns: A new `FuriganaText` instance.
  /// Side effects: None.
  /// Notes: `forceOff` exists for the places where the reading **is** the
  /// question — a quiz asking which reading a word has must not print the
  /// answer above it. `bracketFallback` is for the places whose plain form
  /// already showed the reading in brackets, so turning furigana off there
  /// gives back exactly what was there before rather than losing the reading.
  const FuriganaText(
    this.text, {
    super.key,
    this.reading,
    this.style,
    this.rubyScale = 0.5,
    this.forceOff = false,
    this.bracketFallback = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The Japanese text as written.
  final String text;

  /// Its reading in kana, when the content supplies one.
  final String? reading;

  /// The style of the base text; the ruby is derived from it.
  final TextStyle? style;

  /// The ruby's size as a fraction of the base font size.
  final double rubyScale;

  /// Render plainly even when the preference is on.
  final bool forceOff;

  /// When ruby cannot be printed, show the reading in brackets after the text
  /// instead of dropping it.
  final bool bracketFallback;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  /// Purpose: Build the ruby text, or plain text when it cannot be built.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The alignment is computed in the build because it is a pure
  /// function of two short strings and costs less than caching it would; the
  /// only long input is a sentence, and the search is bounded by the anchors
  /// inside it.
  Widget build(BuildContext context, WidgetRef ref) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final plain = Text(
      bracketFallback && reading != null && reading != text
          ? '$text ($reading)'
          : text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (forceOff || !ref.watch(appSettingsProvider).showFurigana) return plain;

    final segments = alignFurigana(text, reading);
    if (segments == null || !segments.any((s) => s.isRuby)) return plain;

    final size = base.fontSize ?? 14.0;
    final rubyStyle = base.copyWith(
      fontSize: size * rubyScale,
      height: 1.0,
      fontWeight: FontWeight.normal,
      color: base.color?.withValues(alpha: 0.85),
    );

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            for (final segment in segments)
              if (segment.isRuby)
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.ideographic,
                  child: _Ruby(
                    text: segment.text,
                    reading: segment.reading!,
                    style: base,
                    rubyStyle: rubyStyle,
                  ),
                )
              else
                TextSpan(text: segment.text),
          ],
        ),
        style: base,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
      ),
    );
  }
}

/// One kanji run with its kana above it.
class _Ruby extends StatelessWidget {
  /// Purpose: Stack one reading over one run of characters.
  /// Inputs: `text`, `reading`, and the two styles.
  /// Returns: A new `_Ruby` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _Ruby({
    required this.text,
    required this.reading,
    required this.style,
    required this.rubyStyle,
  });

  final String text;
  final String reading;
  final TextStyle style;
  final TextStyle rubyStyle;

  @override
  /// Purpose: Build the two-line stack.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The ruby sits in its
  /// own line box above the base text, so a run whose reading is wider than
  /// its kanji makes the run wider rather than overlapping its neighbour.
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(reading, style: rubyStyle, textHeightBehavior: _tight),
        Text(text, style: style.copyWith(height: 1.0)),
      ],
    );
  }
}

/// Purpose: Stop the ruby line adding its own leading above the text.
/// Notes: Internal helper used within this file only.
const _tight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

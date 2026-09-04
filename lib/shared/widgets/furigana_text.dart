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

    // Every piece is the same shape — a reserved ruby line over one run of
    // base text — so aligning their bottoms aligns their baselines. That is
    // the whole reason this is a `Wrap` of boxes rather than a `Text.rich` of
    // `WidgetSpan`s: a span holding a two-line column reports the **ruby**
    // line's baseline as its own, so the plain kana between the kanji were
    // laid out level with the furigana instead of with the word. It looks
    // like two rows of text that do not belong together, and it is invisible
    // to a test that only asserts no exception was thrown. Found on a Pixel.
    final rubyHeight = (size * rubyScale) * 1.15;
    final lineHeight = size * (base.height ?? 1.35);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        // **Top-aligned, not bottom.** Every box starts with a ruby line of the
        // same reserved height, so aligning tops puts every base character at
        // the same y whatever its glyphs measure. Bottom alignment made that
        // depend on the text height instead, and a kanji box and a kana box
        // do not measure the same.
        crossAxisAlignment: WrapCrossAlignment.start,
        alignment: textAlign == TextAlign.center
            ? WrapAlignment.center
            : WrapAlignment.start,
        children: [
          for (final piece in _pieces(segments))
            _RubyBox(
              text: piece.text,
              reading: piece.reading,
              style: base,
              rubyStyle: rubyStyle,
              rubyHeight: rubyHeight,
              lineHeight: lineHeight,
            ),
        ],
      ),
    );
  }
}

/// Purpose: Split the alignment into the boxes a line is laid out from.
/// Inputs: The aligned `segments`.
/// Returns: `List<FuriganaSegment>` — the same runs, with the anchor runs
/// broken into single characters.
/// Side effects: None.
/// Notes: Internal helper used within this file only. A kanji run has to stay
/// whole, because its reading covers all of it. An anchor run must not: a
/// sentence whose kana runs are long would otherwise be one unbreakable box
/// and would run off the screen instead of wrapping. Japanese wraps between
/// characters anyway, so splitting there is what the text wanted.
List<FuriganaSegment> _pieces(List<FuriganaSegment> segments) {
  final out = <FuriganaSegment>[];
  for (final segment in segments) {
    if (segment.isRuby) {
      out.add(segment);
      continue;
    }
    for (var i = 0; i < segment.text.length; i++) {
      out.add(
        FuriganaSegment(
          text: segment.text[i],
          surfaceStart: segment.surfaceStart + i,
          surfaceEnd: segment.surfaceStart + i + 1,
          readingStart: segment.readingStart + i,
          readingEnd: segment.readingStart + i + 1,
        ),
      );
    }
  }
  return out;
}

/// One run of characters with room above it for a reading.
class _RubyBox extends StatelessWidget {
  /// Purpose: Draw one run under a fixed-height ruby line.
  /// Inputs: `text`, its `reading` or null, the two styles, and the height
  /// reserved for the ruby.
  /// Returns: A new `_RubyBox` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _RubyBox({
    required this.text,
    required this.reading,
    required this.style,
    required this.rubyStyle,
    required this.rubyHeight,
    required this.lineHeight,
  });

  final String text;
  final String? reading;
  final TextStyle style;
  final TextStyle rubyStyle;
  final double rubyHeight;
  final double lineHeight;

  @override
  /// Purpose: Build the box.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **The ruby line is
  /// reserved even when there is nothing to put in it.** Every box is then
  /// the same height, so aligning the row's bottoms puts every base character
  /// on one line — which is what went wrong when this was a paragraph of
  /// placeholder spans.
  Widget build(BuildContext context) {
    // **Every box is exactly this tall**, whatever it holds. Both slots are
    // fixed, so the base character sits at the same height in every box and
    // the row reads as one line — rather than depending on whether a kanji
    // glyph measures the same as a kana one, which it does not.
    return SizedBox(
      height: rubyHeight + lineHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // **No `Center` here.** `Align` expands to fill whatever width it
          // is offered, and `Wrap` offers every child the whole line — so a
          // centred slot made each box full width, which put one character on
          // each line and centred it. The `Text` shrink-wraps on its own; the
          // column's cross alignment is what centres the narrower of the two.
          SizedBox(
            height: rubyHeight,
            child: reading == null
                ? null
                : Text(
                    reading!,
                    style: rubyStyle,
                    maxLines: 1,
                    textHeightBehavior: _tight,
                  ),
          ),
          SizedBox(
            height: lineHeight,
            child: Text(
              text,
              style: style,
              strutStyle: StrutStyle.fromTextStyle(
                style,
                forceStrutHeight: true,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Purpose: Stop the ruby line adding its own leading above the text.
/// Notes: Internal helper used within this file only.
const _tight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

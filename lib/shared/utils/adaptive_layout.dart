import 'package:flutter/widgets.dart';
import 'package:myapps_ui/myapps_ui.dart' show MyAppsShellLayout;
import 'package:myapps_adaptive/myapps_adaptive.dart';

export 'package:myapps_adaptive/myapps_adaptive.dart';

/// Widest, in logical pixels, a reference page's content column grows.
///
/// The kana tables and the vocabulary and grammar lists centre inside this so
/// a desktop window does not stretch a five-column table across 1600 pixels.
const pageMaxContentWidth = 1080.0;

/// Narrowest a kana table may be before the kana page stops putting two side
/// by side, in logical pixels.
///
/// A five-column table spends 44 on its row label, so 330 leaves about 57 per
/// cell — level with what the same table gets on a phone in one column. Below
/// this the unfolded screen would be showing more, smaller kana than a phone
/// does, which is the opposite of the point.
const kanaTableMinWidth = 330.0;

/// Narrowest a rule or explanation card may be before those cards stop flowing
/// two across, in logical pixels.
///
/// These are paragraphs; a third column would fall below a comfortable reading
/// measure, and below 320 a two-line title starts wrapping to three.
const ruleCardMinWidth = 320.0;

/// Minimum width, in logical pixels, one vocabulary or grammar tile may occupy.
///
/// A tile carries a headword line, a reading line, one meaning line and a
/// trailing level chip; narrower than this and the meaning truncates before
/// the chip on the longest seeded English glosses.
const referenceTileMinWidth = 320.0;

/// Smallest width, in logical pixels, the settings detail pane may be given.
const settingsRightPaneMinWidth = 280.0;

/// Purpose: Return the width a shell page's content actually receives.
/// Inputs: `screenWidth` — full window width; `context` — actual page context.
/// Returns: `double`, never negative.
/// Side effects: None.
/// Notes: Context reads measured shell width; outside a shell uses full width.
/// The context-free form retains the legacy width rule for compatibility. Pass the
/// result wherever a capacity is being computed; keep passing the untouched
/// screen size to [canSplitLayout], which asks about the window's shape rather
/// than about the room left over inside it.
double shellContentWidth(double screenWidth, {BuildContext? context}) {
  if (context != null) {
    return MyAppsShellLayout.maybeOf(context)?.contentWidth ?? screenWidth;
  }
  final width = useNavigationRail(screenWidth)
      ? screenWidth - navRailWidth
      : screenWidth;
  return width < 0 ? 0 : width;
}

/// Purpose: Return the bottom padding a shell page's scrolling list needs.
/// Inputs: `screenWidth` — full window width; optional page `context`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Pages reserve breathing room below a list's last rows. A navigation
/// rail takes width instead of height, and the reservation becomes dead space
/// at the very moment vertical room is scarcest — a Fold 8 in landscape is only
/// 704 logical pixels tall. Since 0.6.1 the Expressive bottom bar floats over the
/// page; its height is added on top of this value by [navBarAwarePadding],
/// which every caller wraps around it.
double shellListBottomInset(double screenWidth, {BuildContext? context}) =>
    (context == null
        ? useNavigationRail(screenWidth)
        : MyAppsShellLayout.maybeOf(context)?.hasRail ?? false)
    ? 16.0
    : 80.0;

/// Purpose: Return the width a reference page's content column gets.
/// Inputs: `screenWidth` — the whole screen width in logical pixels;
/// `horizontalPadding` — the page's own left-plus-right padding.
/// Returns: `double`, never negative and never above [pageMaxContentWidth].
/// Side effects: None.
/// Notes: [shellContentWidth] less the padding, capped. The kana, vocabulary
/// and grammar pages all size their columns from this so they agree on where
/// the second column appears.
double referenceContentWidth(
  double screenWidth, {
  double horizontalPadding = 32.0,
  BuildContext? context,
}) {
  final available =
      shellContentWidth(screenWidth, context: context) - horizontalPadding;
  if (available <= 0) return 0;
  return available > pageMaxContentWidth ? pageMaxContentWidth : available;
}

/// Purpose: Return the number of columns a vocabulary or grammar list renders.
/// Inputs: `screenWidth`, `screenHeight` — the whole screen, which decides
/// whether splitting is allowed at all; `contentWidth` — the width the list
/// itself gets.
/// Returns: `int`, at least 1 and at most [listMaxColumns].
/// Side effects: None.
/// Notes: The gate reads the screen while the capacity reads the list's own
/// width, deliberately. Measuring the split decision against the body would
/// subtract the app bar and read a Fold 8 in portrait as 0.80 rather than
/// 0.755, leaving almost no margin under [splitMinAspect].
///
/// A stored [preference] is clamped to what fits rather than rejected, so a
/// choice made on a tablet survives a folded phone and comes back when the
/// window grows again. [listColumnsAuto] means the width decides.
int referenceColumnCount({
  required double screenWidth,
  required double screenHeight,
  required double contentWidth,
  int preference = listColumnsAuto,
}) {
  return resolveLayoutColumns(
    allowSplit: canSplitLayout(screenWidth, screenHeight),
    contentWidth: contentWidth,
    minItemWidth: referenceTileMinWidth,
    preference: preference,
  );
}

/// The narrowest a quiz answer pane may be before splitting stops paying.
///
/// Four option buttons with Japanese on them need room to breathe; below this
/// the split makes both halves worse than one column would have been.
const quizAnswerPaneMinWidth = 280.0;

/// Purpose: Return the width of the quiz page's fixed question pane.
/// Inputs: `contentWidth` — the width the page has to lay out in.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Proportional and then clamped, the same shape as
/// [settingsLeftPaneWidth]. The question is the smaller half: it holds a word
/// or a sentence, while the answer half holds four options. The final cap keeps
/// the answer pane at [quizAnswerPaneMinWidth] on the narrowest window that
/// splits at all, so the split never makes the answers harder to read than
/// stacking them would have been.
double quizQuestionPaneWidth(double contentWidth) {
  final proportional = (contentWidth * 0.45).clamp(320.0, 520.0);
  final capped = contentWidth - quizAnswerPaneMinWidth;
  return capped < proportional ? capped : proportional;
}

/// Purpose: Return the width of the exam page's passage pane.
/// Inputs: `contentWidth` — the width the page has to lay out in.
/// Returns: `double`.
/// Side effects: None.
/// Notes: The mirror image of [quizQuestionPaneWidth], and deliberately so.
/// There the question is the smaller half because it holds a word; here it is
/// the larger half because it holds a passage the learner reads and re-reads
/// while answering. 0.55 rather than 0.5 gives the text the longer line
/// without letting it crowd the options, and the same final cap keeps the
/// answers at [quizAnswerPaneMinWidth] on the narrowest window that splits.
double drillPassagePaneWidth(double contentWidth) {
  final proportional = (contentWidth * 0.55).clamp(360.0, 640.0);
  final capped = contentWidth - quizAnswerPaneMinWidth;
  return capped < proportional ? capped : proportional;
}

/// Purpose: Return the width of the settings page's fixed left pane.
/// Inputs: `contentWidth` — the width both panes share, in logical pixels,
/// which is [shellContentWidth] rather than the screen width.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Proportional, then clamped, then capped so the detail pane can never
/// be squeezed below [settingsRightPaneMinWidth]. The left pane carries full
/// `ListTile`s with trailing dropdowns, so it needs more room than a plain
/// list would. The cap only binds on a hand-resized desktop window and on the
/// narrowest foldables, where it gives up left-pane width rather than let the
/// right pane become unusable.
double settingsLeftPaneWidth(double contentWidth) {
  final preferred = (contentWidth * 0.44).clamp(300.0, 440.0);
  final capped = contentWidth - settingsRightPaneMinWidth;
  if (preferred <= capped) return preferred;
  return capped.clamp(240.0, 440.0);
}

/// The narrowest the sentence lab's result pane may be before splitting stops
/// paying.
///
/// Wider than [settingsRightPaneMinWidth] because the content is different: a
/// settings detail pane holds rows of text, while this holds a wrapped row of
/// word chips with a reading over each, an indented dependency list, and issue
/// rows with a button on the end. Below this the chips wrap to one word a line,
/// which is worse than the single column the split replaced.
const labResultPaneMinWidth = 360.0;

/// Purpose: Return the width of the input-and-history pane on the sentence lab
/// and writing practice.
/// Inputs: `contentWidth` — the width both panes share, which is
/// [shellContentWidth] rather than the screen width.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Proportional, then clamped, then capped so the result pane can never
/// drop below [labResultPaneMinWidth] — the same shape as
/// [settingsLeftPaneWidth] and [quizQuestionPaneWidth]. The input is the
/// smaller half: it holds one text field and a list of past sentences, while
/// the result holds the whole analysis chain. The cap binds on the narrowest
/// window that splits at all, where it gives up input width rather than let the
/// analysis become the harder half to read.
double labInputPaneWidth(double contentWidth) {
  final preferred = (contentWidth * 0.40).clamp(320.0, 460.0);
  final capped = contentWidth - labResultPaneMinWidth;
  return capped < preferred ? capped : preferred;
}

/// Purpose: Add the floating navigation bar's height to a page's padding.
/// Inputs: `context` — inside a shell page; `padding` — the page's own padding.
/// Returns: `EdgeInsets` — [padding] with the bottom inset reported by the
/// enclosing Scaffold added to its bottom.
/// Side effects: None.
/// Notes: With the Expressive bottom bar the shell uses `extendBody`, so pages
/// draw behind the bar and the Scaffold reports the bar's height as
/// `MediaQuery.padding.bottom`. Scroll views with an explicit padding do not
/// apply that inset themselves; passing their padding through here leaves room
/// to scroll the last content above the bar. A page needs it only when it
/// lives in the shell navigator: the five tabs and the pages the Settings
/// detail pane hosts. Router routes registered outside the `ShellRoute`
/// (`/quiz`, `/lab`, `/exam` ...) sit above the bar and never see its inset.
/// Elsewhere (classic bar, rail) the inset is just the system's, so wrapping is
/// harmless.
EdgeInsets navBarAwarePadding(BuildContext context, EdgeInsets padding) =>
    padding.copyWith(
      bottom: padding.bottom + MediaQuery.paddingOf(context).bottom,
    );

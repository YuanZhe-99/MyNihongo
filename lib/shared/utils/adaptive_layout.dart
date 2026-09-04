/// Minimum viewport width, in logical pixels, before a layout may split.
///
/// Material's *medium* width class and Android's `sw600dp` tablet threshold.
const splitMinWidth = 600.0;

/// Minimum viewport height, in logical pixels, before a layout may split.
///
/// Matches the boundary between Android's compact and medium height classes.
/// Google's own guidance is that a window whose height is compact — a phone or
/// an open flippable held in landscape — cannot practically carry two panes.
const splitMinHeight = 480.0;

/// Minimum viewport width-to-height ratio before a layout may split.
///
/// Sits between a Galaxy Z Fold 8 held in portrait (0.755) and the near-square
/// Fold 7 / Fold 8 Ultra (0.90), so one device can answer differently in its
/// two orientations. Changing it is a whole-app behaviour change.
const splitMinAspect = 0.82;

/// Horizontal gap, in logical pixels, between columns of a multi-column list.
const listTileGap = 12.0;

/// Largest number of columns a list will use, however wide the window is.
const listMaxColumns = 4;

/// Column preference meaning "use whatever the width can fit".
const listColumnsAuto = 0;

/// Minimum viewport width, in logical pixels, before the shell shows its
/// navigation rail instead of a bottom navigation bar.
///
/// Material's *medium* width class, which is where Google's guidance moves
/// navigation to the side. This is a width-only threshold on purpose; see
/// [useNavigationRail].
const navRailMinWidth = 600.0;

/// Logical pixels the navigation rail takes from the content when it is shown.
///
/// An 80 dp `NavigationRail` plus the 1 dp `VerticalDivider` beside it.
const navRailWidth = 81.0;

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

/// Purpose: Report whether a layout may split into panes or columns.
/// Inputs: `width`, `height` — the viewport size in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Three independent conditions, because none of them alone is enough.
/// The aspect test is the load-bearing one: it keeps a viewport that is
/// meaningfully taller than it is wide on the original single-column layout, so
/// a Galaxy Z Fold 8 splits in landscape (4:3) but not in portrait (3:4), while
/// the near-square Fold 7 and Fold 8 Ultra split in both orientations. The width
/// floor is the usual `sw600dp` tablet threshold. The height floor exists
/// because the aspect test alone admits wide, short viewports — a folded cover
/// screen or an ordinary phone held in landscape would otherwise split into two
/// cramped panes. See `doc/en-us/adaptive-layout.md` for the full derivation.
bool canSplitLayout(double width, double height) {
  if (width < splitMinWidth) return false;
  if (height < splitMinHeight) return false;
  if (height <= 0) return false;
  return width / height >= splitMinAspect;
}

/// Purpose: Report whether the shell should show a navigation rail.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: **Width only, deliberately** — this is not [canSplitLayout] and must
/// not be routed through it. A rail is not a split; it trades width, which is
/// abundant whenever this returns true, for height, which is not. The case it
/// helps most is the one the split rule rejects on purpose: an ordinary phone
/// held in landscape at 915 x 412, where a bottom bar spends 19% of the height
/// on navigation while 915 logical pixels of width sit unused.
bool useNavigationRail(double screenWidth) => screenWidth >= navRailMinWidth;

/// Purpose: Return the width a shell page's content actually receives.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `double`, never negative.
/// Side effects: None.
/// Notes: Subtracts the navigation rail when the shell is showing one. Pass the
/// result wherever a capacity is being computed; keep passing the untouched
/// screen size to [canSplitLayout], which asks about the window's shape rather
/// than about the room left over inside it.
double shellContentWidth(double screenWidth) {
  final width = useNavigationRail(screenWidth)
      ? screenWidth - navRailWidth
      : screenWidth;
  return width < 0 ? 0 : width;
}

/// Purpose: Return the bottom padding a shell page's scrolling list needs.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: The shell's bottom navigation bar overlaps the last rows of a list,
/// so pages reserve room for it. A navigation rail takes width instead, and the
/// reservation becomes dead space at the very moment vertical room is scarcest
/// — a Fold 8 in landscape is only 704 logical pixels tall.
double shellListBottomInset(double screenWidth) =>
    useNavigationRail(screenWidth) ? 16.0 : 80.0;

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
}) {
  final available = shellContentWidth(screenWidth) - horizontalPadding;
  if (available <= 0) return 0;
  return available > pageMaxContentWidth ? pageMaxContentWidth : available;
}

/// Purpose: Return how many columns of a given minimum width fit a content box.
/// Inputs: `contentWidth` — the width available, in logical pixels;
/// `minItemWidth` — the narrowest one column may be; `gap` — spacing between
/// columns; `maxColumns` — a ceiling however wide the box is.
/// Returns: `int`, at least 1 and at most `maxColumns`.
/// Side effects: None.
/// Notes: The adaptive-minimum-width approach Google recommends for feeds and
/// grids, rather than a hardcoded count per breakpoint. One gap is added to the
/// numerator so the arithmetic pays for the gaps *between* columns rather than
/// one after every column. Non-positive widths return 1.
int columnCapacity(
  double contentWidth, {
  required double minItemWidth,
  double gap = listTileGap,
  int maxColumns = listMaxColumns,
}) {
  final ceiling = maxColumns < 1 ? 1 : maxColumns;
  if (contentWidth <= 0) return 1;
  if (minItemWidth <= 0) return ceiling;
  final fit = ((contentWidth + gap) / (minItemWidth + gap)).floor();
  return fit.clamp(1, ceiling);
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
  if (!canSplitLayout(screenWidth, screenHeight)) return 1;
  final capacity = columnCapacity(
    contentWidth,
    minItemWidth: referenceTileMinWidth,
  );
  if (preference == listColumnsAuto) return capacity;
  return preference.clamp(1, capacity);
}

/// Purpose: Return how many rows a list of items needs at a column count.
/// Inputs: `itemCount`, `columns`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: The last row may be short; callers pad it so the remaining tiles keep
/// their width instead of stretching across the row.
int listRowCount(int itemCount, int columns) {
  if (itemCount <= 0) return 0;
  final perRow = columns < 1 ? 1 : columns;
  return (itemCount + perRow - 1) ~/ perRow;
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

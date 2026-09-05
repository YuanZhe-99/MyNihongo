# lib/features/learn/widgets/jlpt_practice_card.dart

The Learn tab's way into JLPT practice: one row per section, plus the Mock button this release has
not built yet and the Results button, which now opens `/exam-history`.

Replaces the roadmap card that promised this. A card that says a feature is coming should be deleted
by the release that ships it, or the app is advertising to a learner who is already using the thing.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `JlptPracticeCard` | class | B | The Learn tab's way into JLPT practice. |
| [`build`](#build) | method | A | Build the four practise rows, the Mock button that is not ready, and the Results button. |
| [`_sectionRow`](#row) | method | A | Render one section's practise row. |
| `_icon` | method | B | Pick an icon for a section. |
| `DrillSectionLabel` | extension | B | Name a section in the learner's language. |
| `drillSectionName` | method | B | Name one section, exhaustively over `DrillSection`. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the four practise buttons, the Mock button that is not ready, and Results.
- **Inputs:** `context`, `ref`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state; pushes `/exam-history` from Results.
- **Algorithm:** Read the learner's target level, watch `drillLevelProvider` for that level, then
  render a row per `DrillSection` value, followed by the still-disabled Mock button and the Results
  button, which pushes `/exam-history`.
- **Usage:** `learn_page.dart`.
- **Notes:** Keep this method cheap because Flutter may call it often. The level comes from the
  learner's own target rather than from a picker on this card: it is already a setting, and two
  places to change one thing is how they come to disagree. A section with no shipped file is
  **disabled with the reason next to it**, not hidden — a learner who cannot find 読解 practice has
  no way to tell whether it does not exist or they have not found it. The same rule covers listening
  on a device with no Japanese voice, and the Mock button this release has not built yet. Results is
  no longer one of those: it opens the `/exam-history` route, which is empty rather than absent
  before the first paper has been sat.

### `Widget _sectionRow(BuildContext context, AppLocalizations l10n, ThemeData theme, {…})` <a id="row"></a>

- **Kind:** method
- **Purpose:** Render one section's practise row.
- **Inputs:** `context`, `l10n`, `theme`; the `level`, the `section`, its `file` if loaded, whether
  the card is still `loading`, and `hasVoice`.
- **Returns:** `Widget`.
- **Side effects:** Pushes the quiz route on tap.
- **Algorithm:** A section is ready when its file has questions and it is not listening on a silent
  device. A ready row shows its question count and pushes `/quiz` with a `DrillSource` for that level
  and section; an unready one is disabled and shows why.
- **Usage:** `build`, once per `DrillSection` value.
- **Notes:** Internal helper used within this file only. The count is shown because it is the honest
  measure of what a section can offer: "20 questions" is a different offer from "120 questions", and
  a learner choosing what to practise is entitled to know which they are getting. While the files are
  still loading there is no reason and no count, so the row does not flicker a "no content" line on
  its way to having content.

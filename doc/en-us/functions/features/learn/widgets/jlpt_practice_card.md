# lib/features/learn/widgets/jlpt_practice_card.dart

The Learn tab's way into JLPT practice: one row per section, the offer to continue a saved mock, and
the readiness band, and the Mock, Results and What-to-work-on buttons, going to `/exam`,
`/exam-history` and `/weakness`.

Replaces the roadmap card that promised this. A card that says a feature is coming should be deleted
by the release that ships it, or the app is advertising to a learner who is already using the thing.

The whole card is wrapped in a `ValueListenableBuilder` on `TtsService.instance.ready`. Reading
`hasJapaneseVoice` at first build says "no" on every device, because the probe has not run — and this
card would then tell a Pixel it cannot practise listening and never take it back. `build` is now just
that wrapper and `_card` is the card, split out only so the listenable can wrap it.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `JlptPracticeCard` | class | B | The Learn tab's way into JLPT practice. |
| [`build`](#build) | method | A | Wrap the card in the speech engine's readiness. |
| [`_card`](#card) | method | A | Build the practise rows, the readiness band, the saved-paper offer, and the three buttons. |
| [`_startMock`](#startmock) | method | A | Start a new mock, asking first if one is already saved. |
| `_discard` | method | B | Throw away the saved paper, after a dialog that says what survives. |
| [`_readiness`](#readiness) | method | A | Say how ready the learner looks, and what is holding it back. |
| `_bandName` | method | B | Name one readiness band in the learner's language. |
| [`_sectionRow`](#row) | method | A | Render one section's practise row. |
| `_icon` | method | B | Pick an icon for a section. |
| `DrillSectionLabel` | extension | B | Name a section in the learner's language. |
| `drillSectionName` | method | B | Name one section, exhaustively over `DrillSection`. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the card, once the speech engine's readiness is known.
- **Inputs:** `context`, `ref`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** Read the learner's target level and watch `drillLevelProvider` for it, then return a
  `ValueListenableBuilder` on `TtsService.instance.ready` whose builder is `_card`.
- **Usage:** `learn_page.dart`.
- **Notes:** Keep this method cheap because Flutter may call it often. The level comes from the
  learner's own target rather than from a picker on this card: it is already a setting, and two
  places to change one thing is how they come to disagree.

  The listenable is the fix for a bug the device found. `TtsService.hasJapaneseVoice` is false until
  the voice probe has finished, and false-because-not-asked is not the same answer as
  false-because-there-is-none. Reading it at first build told a Pixel it could not practise listening
  and left it saying so; watching `ready` means the card rebuilds when the engine has actually
  answered. See [`../../speech/services/tts_service.md`](../../speech/services/tts_service.md).

### `Widget _card(…, bool ready)` <a id="card"></a>

- **Kind:** method
- **Purpose:** Build the practise rows, the saved-paper offer, and the two buttons under them.
- **Inputs:** `context`, `ref`, `l10n`, `theme`, the `level`, its `files` if loaded, and whether the
  engine has been `ready` asked.
- **Returns:** `Widget`.
- **Side effects:** None until a control is used; the controls push routes, clear the save, or open a
  dialog.
- **Algorithm:** Treat `hasVoice` as true while `!ready`, then a `Card` holding the title, the body
  line, one `_sectionRow` per `DrillSection` value, a divider, `_readiness`, the continue/discard pair when
  `savedExamProvider` has a paper, and finally the Mock, Results and What-to-work-on buttons.
- **Usage:** `build`, through the `ValueListenableBuilder`.
- **Notes:** Internal helper used within this file only. Split out only so the listenable wraps it;
  the reasoning is all in `build`.

  A section with no shipped file is **disabled with the reason next to it**, not hidden: a learner who
  cannot find 読解 practice has no way to tell whether it does not exist or they have not found it. The
  same rule covers listening on a device with no Japanese voice — but listening counts as "still
  loading" until the probe has answered, so the row makes no claim it has not checked.

  A saved paper is offered **before** a new one. Starting a fresh mock is one tap away either way, but
  a learner who put one down half an hour ago should not have to remember it exists. The line names
  the level, the block and the minutes left, all read straight from the save without touching the
  content files.

  Results is no longer disabled either: it opens `/exam-history`, which is empty rather than absent
  before the first paper has been sat.

### `Future<void> _startMock(BuildContext context, WidgetRef ref, AppLocalizations l10n, JlptLevel level)` <a id="startmock"></a>

- **Kind:** method
- **Purpose:** Start a new mock, asking first if one is already saved.
- **Inputs:** `context`, `ref`, `l10n`, the `level`.
- **Returns:** None.
- **Side effects:** May clear the saved paper and refresh `savedExamProvider`; navigates to `/exam`.
- **Algorithm:** Capture the router first. With a saved paper, ask whether to replace it and return if
  the answer is no; otherwise clear the save and refresh the provider. Then push `/exam` with an
  `ExamConfig` for this level.
- **Usage:** The Mock button.
- **Notes:** Internal helper used within this file only. One saved paper per device, so starting a
  second has to replace the first. That is worth asking about: the learner may have forgotten a paper
  is half-sat, and it is the only thing here that cannot be recovered.

  **Through the router, not the local navigator.** `/exam` is registered outside the tab shell, and
  pushing a `MaterialPageRoute` here would put a running clock above a navigation bar inviting the
  learner to leave. The router is captured before the dialog rather than reached for across the await.

  `_discard` beside it takes the same shape without the navigation, and its dialog says what survives:
  every answer already given went through the scheduler as it happened, so discarding the paper loses
  the paper, not the study.

### `Widget _sectionRow(BuildContext context, AppLocalizations l10n, ThemeData theme, {…})` <a id="row"></a>

- **Kind:** method
- **Purpose:** Render one section's practise row.
- **Inputs:** `context`, `l10n`, `theme`; the `level`, the `section`, its `file` if loaded, whether
  the row is still `loading`, and `hasVoice`.
- **Returns:** `Widget`.
- **Side effects:** Pushes the quiz route on tap.
- **Algorithm:** A section is ready when its file has questions and it is not listening on a silent
  device. A ready row shows its question count and pushes `/quiz` with a `DrillSource` for that level
  and section; an unready one is disabled and shows why.
- **Usage:** `_card`, once per `DrillSection` value.
- **Notes:** Internal helper used within this file only. The count is shown because it is the honest
  measure of what a section can offer: "20 questions" is a different offer from "120 questions", and
  a learner choosing what to practise is entitled to know which they are getting. While the files are
  still loading there is no reason and no count, so the row does not flicker a "no content" line on
  its way to having content — and listening is loading until the speech probe has answered, for the
  same reason.

### `Widget _readiness(BuildContext context, WidgetRef ref, AppLocalizations l10n, ThemeData theme, bool hasVoice)` <a id="readiness"></a>

- **Kind:** method
- **Purpose:** Say how ready the learner looks, and what is holding it back.
- **Inputs:** `context`, `ref`, `l10n`, `theme`, and whether the device has a Japanese voice.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** Watch `readinessProvider` and `weaknessReportProvider`; render the band's name, the
  caveat, the two conditional lines, and up to three chips naming the weakest items.
- **Usage:** The Learn card, between the practise rows and the mock controls.
- **Notes:** **The caveat is not optional and is not a tooltip.** A band shown beside the letters
  JLPT will be read as a JLPT score unless the screen says, in the same paragraph, that it is not
  one — JEES does not publish the raw-to-scaled equating, so no app can compute the real thing.

  `cappedByCoverage` and a missing Japanese voice each add their own line, because a band with no
  explanation for why it will not go higher reads as a bug rather than as a caveat.

  The three weakest points are named here rather than only on their own page, because the whole value
  of a weakness report is that it is seen without being sought.

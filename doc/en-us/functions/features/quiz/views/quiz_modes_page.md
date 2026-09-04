# lib/features/quiz/views/quiz_modes_page.dart

The Settings page that switches ways of asking on and off, grouped by catalog.

A second-level page like the WebDAV and backup pages: pushed full-screen on a
narrow window, hosted in the detail pane on a wide one, by the same
`_SettingsDetail` mechanism.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `QuizModesPage` | class | B | The mode switches. |
| `build` | method | B | Build the three groups of switches. |
| [`_toggle`](#toggle) | method | A | Switch one mode on or off, refusing the last one. |

## Documentation

### `void _toggle(BuildContext context, AppSettingsNotifier notifier, Set<QuizMode> enabled, QuizMode mode, bool on)` <a id="toggle"></a>

- **Kind:** method
- **Purpose:** Switch one mode on or off, refusing to switch off the last one.
- **Inputs:** The currently enabled set, the mode, and whether it should be on.
- **Returns:** None.
- **Side effects:** Persists the set, or shows a message.
- **Algorithm:** Build the next set; if it would be empty, show the reason and change nothing.
- **Usage:** Every switch on the page.
- **Notes:** Refused with a reason rather than silently ignored. With every mode off there is nothing
  to ask, and a quiz that opens empty looks broken rather than configured — so the learner is told
  why the switch did not move. An empty **stored** set means the opposite, every mode, which is why
  the page draws its switches against the full set rather than against what was stored.

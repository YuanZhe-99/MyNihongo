# lib/app/router.dart

Declares `appRouter`, the app's `GoRouter`: `initialLocation: '/learn'` and one `ShellRoute` whose
builder wraps every tab in `ShellScaffold`, holding the five tab routes in display order — `/learn`,
`/kana`, `/vocab`, `/grammar`, `/settings`. `ShellScaffold.routes` holds the same list; the two are
kept in step by hand. The full-window routes sit outside that shell; see below. See
[../../architecture.md](../../architecture.md).

## Declarations

The file contains a single top-level `final` (`appRouter`) with an ordinary doc comment and no
functions, so it carries no Function Explanation Layer entries.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `appRouter` | top-level `final GoRouter` | — | The router configuration consumed by `MyNihongoApp`. |

`buildAppRouter({initialLocation})` replaced the top-level `appRouter` in `PLAN.md` M1.3. `main()`
reads the last tab from the device preferences **before** `runApp` and passes it here, so the app
opens where the user left it rather than showing Learn and jumping. The root widget builds the
router once and keeps it in its state: a `GoRouter` owns navigation history, so rebuilding one on a
theme or locale change would send the user back to the initial tab mid-session.

Full-window routes sit **outside** the shell beside it — `/quiz`, `/scenario`, `/writing`, `/lab`,
`/exam`, which builds `ExamPage` from an `ExamConfig` passed as `extra`, and `/exam-history`, which
builds `ExamHistoryPage` and takes no `extra`. Outside the shell for the reason the quiz is: the
JLPT results are entered with a purpose from the Learn tab and left when they are finished, so a tab
bar under them would be offering somewhere else to go rather than a way back. `/exam` has a sharper
version of the same reason — a navigation bar under a running exam clock is an invitation to leave —
which is why the Learn card pushes it through the router rather than through the shell's own
navigator.

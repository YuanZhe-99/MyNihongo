# lib/app/router.dart

Declares `appRouter`, the app's `GoRouter`: `initialLocation: '/learn'` and one `ShellRoute` whose
builder wraps every tab in `ShellScaffold`, holding the five tab routes in display order — `/learn`,
`/kana`, `/vocab`, `/grammar`, `/settings`. `ShellScaffold.routes` holds the same list; the two are
kept in step by hand. There are no non-tab routes yet. See
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

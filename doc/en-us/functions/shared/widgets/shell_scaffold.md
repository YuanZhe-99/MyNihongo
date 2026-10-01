# lib/shared/widgets/shell_scaffold.dart

`ShellScaffold` wraps every tab page with the app's navigation: a bottom bar on a narrow window (the floating island `_FloatingNavBar` when the interface style is Expressive, the classic full-width `NavigationBar` for Material 3), a `NavigationRail` down the left from 600 logical pixels up. Both are built from
one list of five destinations, in the order of `ShellScaffold.routes`. The file also defines the
private `_ShellDestination` value type and (0.6.0) `_FloatingNavBar`. See [../../../adaptive-layout.md](../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold.new` | constructor | B | Create a shell scaffold instance around a child page. |
| `ShellScaffold._currentIndex` | method | B | Find which tab the current `GoRouterState` location belongs to; 0 when none matches. |
| `ShellScaffold._destinations` | method | B | Describe the five destinations once, icons and labels, in route order. |
| [`ShellScaffold.build`](#build) | method (`ConsumerWidget` build) | A | Build the shell around the current tab's page: bottom bar or rail by `useNavigationRail`. |
| `_FloatingNavBar` | private class | B | The bottom bar drawn as a floating pill-shaped island: a stadium `Material` around a stock `NavigationBar`, keyed `floatingNavBarIsland`. |
| `_FloatingNavBar.build` | method (widget build) | B | Build the island: margins, rounded surface, inner bar; the bottom inset is applied once outside it. |
| `_ShellDestination.new` | constructor | B | Create a shell destination (icon, selected icon, label). |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method of `ShellScaffold` (widget build)
- **Purpose:** Render the navigation in the form the width calls for.
- **Inputs:** `context`, `ref` (watches `appSettingsProvider.uiStyle`).
- **Returns:** A `Scaffold` with `bottomNavigationBar` (`_FloatingNavBar` for Expressive, `NavigationBar` for Material 3), or a `Scaffold` whose body is a `Row` of rail,
  divider, and the page.
- **Side effects:** `context.go(route)` on selection.
- **Algorithm:** `useNavigationRail(MediaQuery.sizeOf(context).width)`; the rail sits inside a
  `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` so it scrolls rather than
  overflows at compact heights, with `groupAlignment: 0`.
- **Usage:** `ShellRoute(builder: (context, state, child) => ShellScaffold(child: child))` in
  `router.dart`.
- **Notes:** Which one appears is the width-only rail decision, deliberately not the app-wide split
  rule. Nothing here is stateful, so folding a device swaps one for the other on the next frame
  with no route change. The rail is centred because it has no leading menu button or FAB; five
  destinations pinned to the top of a tall rail would leave the lower half empty.

# lib/shared/widgets/shell_scaffold.dart

`ShellScaffold` wraps every tab page with the app's navigation: a bottom bar (the compact floating pill `_ExpressiveNavBar` when the interface style is Expressive, the classic full-width `NavigationBar` for Material 3), a `NavigationRail` — on the left, or on the right by setting. Since 0.6.1 the device-local navigation-position setting (`NavPlacement`, both styles) decides: the bottom bar on every window (the default), the rail on wide windows only, or the rail everywhere. Both forms are built from
one list of five destinations, in the order of `ShellScaffold.routes`. The file also defines the
private `_ShellDestination` value type, `_ExpressiveNavBar` and `_ExpressiveNavItem`. See [../../../adaptive-layout.md](../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold.new` | constructor | B | Create a shell scaffold instance around a child page. |
| `ShellScaffold._currentIndex` | method | B | Find which tab the current `GoRouterState` location belongs to; 0 when none matches. |
| `ShellScaffold._destinations` | method | B | Describe the five destinations once, icons and labels, in route order. |
| [`ShellScaffold.build`](#build) | method (`ConsumerWidget` build) | A | Build the shell around the current tab's page: bottom bar or rail by `useNavigationRail` and the three navigation settings. |
| `_ExpressiveNavBar` | private class | B | The Expressive bottom bar: a compact floating stadium pill that hugs its items, keyed `floatingNavBarIsland`. |
| `_ExpressiveNavBar.new` | constructor | B | Create the Expressive navigation bar. |
| `_ExpressiveNavBar.build` | method (widget build) | B | Build the island: margins, `surfaceContainer` stadium, a `Row` of items; scales down instead of overflowing. |
| `_ExpressiveNavItem` | private class | B | One destination of the bar: icon plus label while selected, icon only otherwise. |
| `_ExpressiveNavItem.new` | constructor | B | Create one Expressive navigation item. |
| `_ExpressiveNavItem.build` | method (widget build) | B | Build the item: an animated tonal pill with icon and (selected only) label; unselected items carry a tooltip and a semantic label. |
| `_ShellDestination.new` | constructor | B | Create a shell destination (icon, selected icon, label). |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method of `ShellScaffold` (widget build)
- **Purpose:** Render the navigation in the form the width and the settings call for.
- **Inputs:** `context`, `ref` (watches `appSettingsProvider` for `uiStyle`, `navPlacement` and `navRailOnRight`).
- **Returns:** For Expressive without a rail, a `Scaffold(extendBody: true)` with `_ExpressiveNavBar`; for Material 3 without a rail, a `Scaffold` with `NavigationBar`; with a rail, a `Scaffold` whose body is a `Row` of the rail, a `VerticalDivider` and the page — the rail first, or last when `navRailOnRight` is set.
- **Side effects:** `context.go(route)` on selection, plus `NihongoStorage.setLastTab`.
- **Algorithm:** `wide = useNavigationRail(MediaQuery.sizeOf(context).width)`;
  `showRail = switch (placement) { bottom => false, sideOnWide => wide, side => true }`. The rail sits inside a
  `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` so it scrolls rather than
  overflows at compact heights, with `groupAlignment: 0`. In the Expressive bottom-bar branch the
  body is wrapped in a `MediaQuery` whose `viewPadding.bottom` is raised to at least `padding.bottom`,
  because a page's own `Scaffold` places a floating action button from `viewPadding`, which
  `extendBody` leaves at the system inset.
- **Usage:** `ShellRoute(builder: (context, state, child) => ShellScaffold(child: child))` in
  `router.dart`.
- **Notes:** Which form appears is the width-only rail decision, deliberately not the app-wide split
  rule, then the settings. `extendBody` makes the pages draw behind the floating bar and reports its
  height as `MediaQuery.padding.bottom`; every shell page with an explicit scroll padding leaves that
  room with `navBarAwarePadding`. Nothing here is stateful, so folding a device swaps one form for the
  other on the next frame with no route change. The rail is centred because it has no leading menu
  button or FAB; five destinations pinned to the top of a tall rail would leave the lower half empty.

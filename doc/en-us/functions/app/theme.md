# lib/app/theme.dart

`AppTheme` builds the light and dark themes from one seed color, `AppTheme.seedColor` (`0xFFCE5B78`,
sakura pink, so this app is told apart from its siblings at a glance), with
`ColorScheme.fromSeed`, or from the platform's dynamic scheme when the caller passes one (Android
only; see `MyNihongoApp.build`). `AppUiStyle` is the interface style the user picks in Settings:
`expressive` (the default) layers a theme-level Material 3 Expressive approximation on top of stock
Material 3, `material3` is stock Material 3 with outlined text fields. Both styles share the same
colors; Expressive changes shape, type weight and component details only, never layout or color. See
[../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AppUiStyle` | enum | B | The two interface styles, `material3` and `expressive`. |
| `NavPlacement` | enum | B | Where the shell puts its navigation (0.6.1): `bottom` (the default), `sideOnWide` or `side`; both interface styles. |
| `AppTheme._` | private constructor | B | Prevent direct instantiation and expose only static members. |
| `AppTheme.seedColor` | static constant | B | The app's brand color and the only per-app knob of the visual system. |
| `AppTheme.scheme` | static method | B | Resolve the color scheme for one brightness: the dynamic scheme when given, else `fromSeed`. |
| `AppTheme.build` | static method | B | Build the theme for one brightness and style (stock Material 3, plus `_expressive` for Expressive). |
| `AppTheme._morphingButtonStyle` | static method | B | A button style that is a pill at rest and a 12-radius rounded square while pressed (200 ms). |
| `AppTheme._emphasized` | static method | B | Make display, headline and title styles heavier by weight only. |
| `AppTheme._expressive` | static method | B | Layer the Expressive approximation onto a theme: larger radii, morphing buttons, emphasized titles, 2024 indicators, fade-forward transitions. |
| `AppTheme.light` | static method | B | Return the light theme for an optional dynamic scheme and a style (default Expressive). |
| `AppTheme.dark` | static method | B | Return the dark theme for an optional dynamic scheme and a style (default Expressive). |

## Expressive, theme level only

Radii: card 20, dialog 32, bottom sheet top 32, menu 16, chip 12, text field 12, FAB 20, floating
snack bar 16. Buttons (filled, elevated, outlined, text, icon) are pills that morph to a 12-radius
square on press. Display styles are w500 and headline/title styles w600; sizes and line heights are
stock. Progress indicators and sliders use the 2024 design (`year2023: false`, deprecated but the
only switch, marked with `// ignore: deprecated_member_use`). Page transitions are fade-forward on
Android, Windows and Linux and Cupertino on iOS and macOS. Spring motion, wavy progress, button
groups, split buttons, FAB menus and floating toolbars have no Flutter 3.44 equivalent and are not
imitated.

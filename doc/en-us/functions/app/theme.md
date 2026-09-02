# lib/app/theme.dart

`AppTheme` builds the light and dark Material 3 themes through `flex_color_scheme`, seeded with
`FlexScheme.sakura` so this app is told apart from its siblings at a glance. Both use level-surface
blending, outline input borders, and a navigation bar that labels only the selected destination.
See [../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AppTheme._` | private constructor | B | Prevent direct instantiation and expose only static members. |
| `AppTheme.light` | static getter | B | Return the light Material theme used by the app. |
| `AppTheme.dark` | static getter | B | Return the dark Material theme used by the app. |

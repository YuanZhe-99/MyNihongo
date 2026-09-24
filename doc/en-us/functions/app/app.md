# lib/app/app.dart

`MyNihongoApp` is the root widget: a `MaterialApp.router` wired to `appRouter`, the light and dark
`AppTheme`s, the theme mode and locale from `appSettingsProvider`, the generated `AppLocalizations`
delegates, and `DevicePreview.appBuilder`. It sets **no** `scrollBehavior`: the SDK default
already scrolls with the mouse wheel and draws scrollbars on desktop, and it keeps stylus and
accessibility drags working on Android. A custom behaviour that replaced the drag devices with
touch, mouse and trackpad was removed in 0.5.1, because it dropped exactly those; see
[../../platform-notes.md](../../platform-notes.md). See
[../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `MyNihongoApp.new` | constructor (`MyNihongoApp`) | B | Create the root app widget. |
| `MyNihongoApp.build` | method (`ConsumerWidget` build) | B | Build the `MaterialApp.router` with theme, locale, and routes from the settings provider. |

The `localeListResolutionCallback` is `resolveAppLocale` from
[locale_resolution.md](locale_resolution.md), which is what decides between the two Chinese
languages for a device that has not been told which to use.

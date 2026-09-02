# lib/app/app.dart

`MyNihongoApp` is the root widget: a `MaterialApp.router` wired to `appRouter`, the light and dark
`AppTheme`s, the theme mode and locale from `appSettingsProvider`, the generated `AppLocalizations`
delegates, and `DevicePreview.appBuilder`. A private `_DesktopScrollBehavior` lets mouse wheels and
trackpads drag scrollables, for the planned desktop targets. See
[../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_DesktopScrollBehavior.dragDevices` | getter override | B | Report which pointer kinds may drag a scrollable: touch, mouse, trackpad. |
| `MyNihongoApp.new` | constructor (`MyNihongoApp`) | B | Create the root app widget. |
| `MyNihongoApp.build` | method (`ConsumerWidget` build) | B | Build the `MaterialApp.router` with theme, locale, and routes from the settings provider. |

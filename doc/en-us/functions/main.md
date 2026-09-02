# lib/main.dart

The app entry point. It initializes the Flutter binding, fires the once-per-day auto-backup check
(a no-op until the user enables auto-backup), starts the auto-sync lifecycle observer (a no-op until
WebDAV is configured), and runs `MyNihongoApp` inside a `ProviderScope`, wrapped in `DevicePreview`
that is enabled only in debug builds. See [../architecture.md](../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `main` | top-level function | B | Initialize startup services and launch the app entry point. |

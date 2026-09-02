# lib/shared/providers/app_settings.dart

Device-local UI preferences as Riverpod state: `AppSettings` (theme mode, locale) and
`AppSettingsNotifier`, a `StateNotifier` that loads both from `storage_config.json` through
`NihongoStorage` on construction and persists every change. `appSettingsProvider` exposes it;
`MyNihongoApp` watches it. Nothing here is synced. See
[../../../data-formats.md](../../../data-formats.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AppSettingsNotifier.new` | constructor | B | Create the notifier and start loading the persisted settings. |
| `AppSettingsNotifier._loadPersisted` | method | B | Load the persisted theme mode and locale from disk and replace the state. |
| `AppSettingsNotifier.setThemeMode` | method | B | Update and persist the theme mode; `system` is stored as an absent key. |
| `AppSettingsNotifier.setLocale` | method | B | Update and persist the locale as `language` or `language_COUNTRY`; null follows the system. |
| `AppSettings.new` | constructor | B | Create an app settings instance. |
| `AppSettings.copyWith` | method | B | Create a copy with selected fields replaced; `clearLocale` exists because null already means "keep". |

`appSettingsProvider` is a top-level `final StateNotifierProvider` with no doc comment; it is not
counted.

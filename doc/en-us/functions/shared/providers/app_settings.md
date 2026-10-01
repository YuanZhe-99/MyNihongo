# lib/shared/providers/app_settings.dart

Device-local UI preferences as Riverpod state: `AppSettings` (theme mode, locale) and
`AppSettingsNotifier`, a `StateNotifier` that loads both from `storage_config.json` through
`NihongoStorage` on construction and persists every change. `appSettingsProvider` exposes it;
`MyNihongoApp` watches it. Nothing here is synced. See
[../../../data-formats.md](../../../data-formats.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
$1| `AppSettingsNotifier.fixed` | constructor | B | Create a notifier holding fixed settings and doing no I/O, for tests that override `appSettingsProvider`. |
| `AppSettingsNotifier._loadPersisted` | method | B | Load the persisted theme mode and locale from disk and replace the state; the stored locale tag is parsed with `localeFromTag`. When reminders are on, it ends by re-planning them in the background (`_rescheduleReminders`), so the schedule is rebuilt at every start; this never asks for permission. |
| `AppSettingsNotifier._rescheduleReminders`, `_reminderL10n` | method | B | Re-plan the reminders without a `BuildContext`: the wording comes from `lookupAppLocalizations` for the chosen language, or for the device's list resolved with `resolveAppLocale`. Failures are swallowed. |
| `AppSettingsNotifier.setThemeMode` | method | B | Update and persist the theme mode; `system` is stored as an absent key. |
$1| `AppSettingsNotifier.setUiStyle` | method | B | Choose the interface style (0.6.0); persists it, and the app rebuilds its theme and the shell its bottom bar. |
| `AppSettingsNotifier.setAiAssistEnabled` | method | B | Turn on-device AI on or off; applies it to `AiAssistService` and persists it, off as an absent key. |
| `AppSettingsNotifier.setPreferFastModel` | method | B | Choose the larger or the faster on-device model; re-probes and persists it. |
| `AppSettingsNotifier.setDebugMode` | method | B | Unlock or re-hide developer options; persists the choice on this device only. |
| `AppSettings.uiStyle` | field | B | The interface style (0.6.0): Expressive (default, floating island bottom bar) or Material 3 (classic bar). Device-local; never synced. |
$1 | field | B | Whether the user turned on-device AI on. False unless they did. |
| `AppSettings.preferFastModel` | field | B | Whether the faster on-device model is preferred where a device serves both sizes. |
| `AppSettings.debugMode` | field | B | Whether developer options are unlocked on this device. False until somebody taps the version row eight times. |
| `AppSettings.new` | constructor | B | Create an app settings instance. |
| `AppSettings.copyWith` | method | B | Create a copy with selected fields replaced; `clearLocale` exists because null already means "keep". |

`appSettingsProvider` is a top-level `final StateNotifierProvider` with no doc comment; it is not
counted.

## Developer options (v0.4.6)

`debugMode` is a field like any other here — a constructor parameter defaulting to `false`, a
`copyWith` parameter, and a line in `_readPersisted` reading `NihongoStorage.getDebugMode()` — and
`setDebugMode` is the ordinary setter beside `setAiAssistEnabled` and `setPreferFastModel`, writing
through to `NihongoStorage.setDebugMode`. What is worth saying is why it belongs in *this* object
rather than in the synced profile: it is **device-local and not synced**, because what it reveals is
the diagnosis of *this* phone — which model variant it served, which AICore build it has — and
carrying it to another device would turn diagnostics on where nobody asked and where every number
would be about a different device. Off is stored as an absent key, so a device that never unlocked
it has no `debugMode` line in `storage_config.json` at all. It is set from exactly one place, the
version row's tap handler in
[`../../features/settings/views/settings_page.md`](../../features/settings/views/settings_page.md),
and read by
[`../../features/ai/widgets/ai_settings_tiles.md`](../../features/ai/widgets/ai_settings_tiles.md).

## Reference preferences (M1.3)

`AppSettings` also carries `vocabLevel`, `grammarLevel`, `kanaScript` and `referenceListColumns`,
with `setVocabLevel`, `setGrammarLevel`, `setKanaScript` and `setReferenceListColumns` on the
notifier. They live in one object so a page reads them synchronously from the provider rather than
starting its own async read and racing its own first frame — a filter tapped before the first load
has landed is not overwritten by it. See
[`../../../features/reference-preferences.md`](../../../features/reference-preferences.md).

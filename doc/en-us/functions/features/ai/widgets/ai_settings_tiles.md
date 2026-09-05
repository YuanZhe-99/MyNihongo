# lib/features/ai/widgets/ai_settings_tiles.dart

The Settings rows that configure on-device AI assistance: the master switch, one status row per
feature, and the note saying who performs the model download.

Built the same way the Speech section is, and kept out of `settings_page.dart` for the same reason.

Consumers: `settings_page.dart`, which includes the section on Android only.

Since M3.0 a row that cannot offer its feature also shows what the device said — the raw
`FeatureStatus` value, or the exception class when the call failed — and carries a **Check again**
button, because AICore provisions itself after setup and sometimes only after a restart. A line under
the section names the installed AICore build and the device. See
[`../../../../features/ai-assist.md`](../../../../features/ai-assist.md).

Since v0.4.6 every one of those diagnostic lines is behind developer options. What a learner sees is
the status sentence and nothing else: the untranslated `_diagnostic` line names a model variant and a
token limit, the AICore line names a package version, and a learner can act on none of it — "Ready"
is the whole of what they need. Behind the flag the lines are still the first thing a bug report
needs, which is why none of them were deleted. `_featureRow` takes the flag as a required `debug`
parameter and `_statusLabel` as an optional one, so a caller cannot leak a diagnostic line by
forgetting to pass it; the AICore line is gated on `settings.debugMode` at the call site. The flag
is `AppSettings.debugMode`, unlocked by tapping the version row eight times — see
[`../../../shared/providers/app_settings.md`](../../../shared/providers/app_settings.md) and
[`../../settings/views/settings_page.md`](../../settings/views/settings_page.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AiSettingsTiles` | class | B | The On-device AI section. |
| [`initState`](#initstate) | method | A | Follow the service, and ask what its models can do. |
| `dispose` | method | B | Stop following the service. |
| `_onServiceChanged` | method | B | Rebuild when a status or a download changes. |
| [`build`](#build) | method | A | Build the switch and the rows. |
| [`_featureRow`](#featurerow) | method | A | Build one feature's status row; the diagnostic line only when `debug` is set. |
| `_statusLabel` | static method | B | Name a status in the learner's language; `unknown` reads as unavailable unless `debug` is set. |
| `_diagnostic` | static method | B | The untranslated line under a row: what serves it, or what refused. |
| `_coreLine` | static method | B | Name the AICore installation behind these features — version, device, whether it can serve models. |
| `_progressLabel` | static method | B | Say how far a download has got. |
| `_iconFor` | static method | B | Pick the icon for a status. |

## Documentation

### `void initState()` <a id="initstate"></a>

- **Kind:** method
- **Purpose:** Subscribe to the service and refresh the statuses.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Adds a listener; queries AICore **only** when the feature is already on.
- **Algorithm:** Add the listener, then refresh after the first frame if enabled.
- **Usage:** The Settings page.
- **Notes:** Nothing is asked of the device while the switch is off, so opening Settings on a phone
  whose owner never turned this on touches no model at all. The service is listened to directly
  rather than watched through riverpod because it is an app-wide singleton — see
  `aiAssistServiceProvider` for why that is not a `ChangeNotifierProvider`.

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the section.
- **Inputs:** The build context.
- **Returns:** `Widget`.
- **Side effects:** None until a control is used.
- **Algorithm:** On a platform with no on-device model, one explanatory line; otherwise the switch,
  and when it is on, a row per feature plus the download note.
- **Usage:** `settings_page.dart`.
- **Notes:** `settings_page.dart` omits the whole section off Android, so the explanatory line is a
  safety net for any other caller rather than something a user normally sees. The download note under
  the buttons is not a footnote: downloading a model is the only thing this feature does over the
  network, it is done by the system rather than by the app, and it happens only on a tap. Saying all
  three where the button is is what makes the switch an informed choice. The AICore line under that
  note is built only `if (settings.debugMode)`: which AICore build is installed is the other half of
  the diagnosis — the feature APIs and the Prompt API are served by the same package at different
  versions — but it is diagnosis rather than information, so it waits behind developer options with
  the rest. `settings.debugMode` is also what each `_featureRow` is handed as its `debug`.

### `Widget _featureRow(BuildContext, AiAssistService, GenAiFeature, String label, {required bool debug})` <a id="featurerow"></a>

- **Kind:** method
- **Purpose:** Show one feature's status, and offer its download.
- **Inputs:** The context, service, feature and its label, plus `debug` — required, and passed
  `settings.debugMode` by both call sites.
- **Returns:** `Widget`.
- **Side effects:** None until Download is used.
- **Algorithm:** Icon and subtitle from the status or the running download; a Download button only
  when the system says the model can be fetched. `_diagnostic` is called **only** when `debug` is
  set, and the row is three-line only when that produced a line.
- **Usage:** `build`, twice.
- **Notes:** Internal helper used within this file only. `debug` is required rather than defaulted
  because forgetting it should be a compile error, not a diagnostic line shown to a learner. The
  line it gates is untranslated on purpose: it is an identifier to quote in a bug report, not prose.
  Without it "not available on this device" is the same sentence whether the device is off a
  published support list, one model variant was refused and three were never tried, or the call
  threw — and those have different fixes. Two rows rather than one because the two
  features have separate models and separate downloads — a device can end up with explanations and no
  proofreading, and a single "AI: ready" line would be a lie on that phone. The button is disabled
  while anything is downloading, because AICore serves one at a time and two spinners would imply
  otherwise. Progress is megabytes rather than a percentage: the system does not always report a
  total, and a percentage that has to vanish halfway through is worse than a number that only grows.

# lib/features/settings/views/settings_page.dart

`SettingsPage` is the fifth tab. It shows sections — General (theme segmented button,
language dropdown: system, English, 简体中文, 繁體中文), Data, About (version, privacy policy, license, open-source
licenses) — and lays itself out in one or two panes by `canSplitLayout`. Data now holds the WebDAV sync row (with a live status subtitle), the backup row, ZIP export and
import, and the storage location. The private `_SettingsDetail` enum names the four rows that lead
to a second-level page: `webdav`, `backup`, `privacy`, `license`. Export and import act in place. See [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

Since v0.4.6 the version row in About is tappable. Eight taps unlock developer options — the
top-level `_debugUnlockTaps` constant, eight because that is what Android itself asks for. Copying
the gesture exactly is the point: somebody who needs the diagnostics already knows how to do it, and
nobody else will find it by accident. `_versionTaps` counts the run; it lives in the state object,
so it resets when the page is rebuilt from scratch and the count is a deliberate run of taps rather
than something a learner accumulates over weeks. Once unlocked, a **Developer options**
`SwitchListTile` appears in About, below the version row — and only once it is on, because an "off"
row there would be an invitation, and the point of hiding diagnostics is that they are not for the
learner who has not gone looking for them. Turning it off through that switch also resets
`_versionTaps`. The flag itself lives in `AppSettings.debugMode`
([../../../shared/providers/app_settings.md](../../../shared/providers/app_settings.md)) and is read
by [../../ai/widgets/ai_settings_tiles.md](../../ai/widgets/ai_settings_tiles.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SettingsPage.new` | constructor | B | Create a settings page instance. |
| `SettingsPage.createState` | method | B | Create the mutable state object for this widget. |
| `_SettingsPageState.initState` | method | B | Kick off the version and storage-path loads. |
| `_SettingsPageState._loadVersion` | method | B | Read the app version from `PackageInfo.fromPlatform()` for the About section. |
| `_SettingsPageState._refreshSyncStatus` | method | B | Redraw the WebDAV row when background sync status changes. |
| `_SettingsPageState.dispose` | method | B | Drop the sync status listener. |
| [`_SettingsPageState._onVersionTapped`](#onversiontapped) | method | A | Count taps on the version row, and unlock developer options at eight. |
| `_SettingsPageState._debugCountdown` | method | B | Say how many taps are left, once the run is clearly deliberate; null while there is nothing to say. |
| `_SettingsPageState._loadStoragePath` | method | B | Read the active storage directory for display. |
| `_SettingsPageState._syncSubtitle` | method | B | Summarize sync health for the WebDAV row's subtitle. |
| `_SettingsPageState._exportZip` | method | B | Write every data module to a ZIP in a folder the user picks. |
| `_SettingsPageState._importZip` | method | B | Replace local data from a ZIP the user picks. |
| `_SettingsPageState._detailPage` | method (widget helper) | B | Build the second-level page a settings row leads to. |
| [`_SettingsPageState._open`](#open) | method | A | Open a second-level page the way the current layout calls for. |
| [`_SettingsPageState._buildDetailPane`](#builddetailpane) | method (widget helper) | A | Build the right-hand pane of the two-pane layout. |
| `_SettingsPageState._buildSection` | method (widget helper) | B | Render a section heading above a run of settings rows. |
| `_SettingsPageState.build` | method (widget build) | B | Build the settings page in one or two panes. |
| `_SettingsPageState._buildSettingsList` | method (widget helper) | B | Build the scrolling list of settings sections. |

## Documentation

### `void _onVersionTapped()` <a id="onversiontapped"></a>

- **Kind:** method of `_SettingsPageState`
- **Purpose:** Count taps on the version row, and unlock developer options at eight.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `setState` on the counter; at eight, `setDebugMode(true)` — which persists the
  preference — and a snack bar saying developer options are on.
- **Algorithm:** Return immediately when `debugMode` is already on, so a second run does nothing;
  otherwise increment `_versionTaps`, and on reaching `_debugUnlockTaps` (8) reset the counter, set
  the flag and show the snack bar.
- **Usage:** The version row's `onTap`.
- **Notes:** Eight taps on the version is Android's own gesture, and copying it exactly is the point:
  somebody who needs this already knows how to do it, and nobody else will find it by accident. The
  countdown is `_debugCountdown`, shown as the version row's **own subtitle** rather than as a snack
  bar — not a style choice: a snack bar sits at the bottom of the screen, About is at the bottom of a
  long list, and the countdown would have covered the row the next tap has to land on. It stays quiet
  until three taps out, so an accidental double-tap says nothing while a deliberate run tells the
  person doing it that it is working.

### `void _open(_SettingsDetail detail)` <a id="open"></a>

- **Kind:** method of `_SettingsPageState`
- **Purpose:** Open a second-level page in whichever mode the layout is in.
- **Inputs:** `detail`.
- **Returns:** None.
- **Side effects:** Either selects the detail pane's page (`setState`) or pushes a
  `MaterialPageRoute` on the **root** navigator.
- **Algorithm:** `if (_twoPane) select; else push`.
- **Usage:** Every second-level row's `onTap`.
- **Notes:** Every row goes through here, so the two modes cannot drift apart. The root navigator is
  used so the pushed page covers the shell's bottom bar.

### `Widget _buildDetailPane(AppLocalizations l10n)` <a id="builddetailpane"></a>

- **Kind:** method of `_SettingsPageState`
- **Purpose:** Build the right-hand pane.
- **Inputs:** `l10n`.
- **Returns:** A placeholder ("Select an item from the list") when nothing is selected; otherwise a
  nested `Navigator` keyed on the selection whose single route is the detail page.
- **Side effects:** None beyond building widgets.
- **Algorithm:** Null selection → centred icon and hint; else `Navigator(key: ValueKey(detail),
  onGenerateRoute: …)`.
- **Usage:** The right `Expanded` child in two-pane `build`.
- **Notes:** The nested `Navigator` gives the hosted page a real route, so a page that calls
  `Navigator.pop` still works, and a one-route navigator reports `canPop == false`, so the hosted
  page's app bar grows no back arrow. Keying on the selection disposes and rebuilds on every change.
  The selection is kept when the window narrows back to one pane, so folding a device shut and
  opening it again restores it.

# lib/features/settings/views/settings_page.dart

`SettingsPage` is the fifth tab. It shows three sections — General (theme segmented button,
language dropdown), Data (storage location), About (version, privacy policy, license, open-source
licenses) — and lays itself out in one or two panes by `canSplitLayout`. The private
`_SettingsDetail` enum names the rows that lead to a second-level page (`privacy`, `license`); WebDAV
and backup join it in `PLAN.md` M1.1. See [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SettingsPage.new` | constructor | B | Create a settings page instance. |
| `SettingsPage.createState` | method | B | Create the mutable state object for this widget. |
| `_SettingsPageState.initState` | method | B | Kick off the version and storage-path loads. |
| `_SettingsPageState._loadVersion` | method | B | Read the app version from `PackageInfo.fromPlatform()` for the About section. |
| `_SettingsPageState._loadStoragePath` | method | B | Read the active storage directory for display. |
| `_SettingsPageState._detailPage` | method (widget helper) | B | Build the second-level page a settings row leads to. |
| [`_SettingsPageState._open`](#open) | method | A | Open a second-level page the way the current layout calls for. |
| [`_SettingsPageState._buildDetailPane`](#builddetailpane) | method (widget helper) | A | Build the right-hand pane of the two-pane layout. |
| `_SettingsPageState._buildSection` | method (widget helper) | B | Render a section heading above a run of settings rows. |
| `_SettingsPageState.build` | method (widget build) | B | Build the settings page in one or two panes. |
| `_SettingsPageState._buildSettingsList` | method (widget helper) | B | Build the scrolling list of settings sections. |

## Documentation

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

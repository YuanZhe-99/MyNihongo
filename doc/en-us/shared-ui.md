# Shared UI foundations

MyApps-UI `v0.1.0` is embedded at `packages/myapps_ui`, with relative submodule
URL `../MyApps-UI.git`. Initialize submodules recursively after a fresh clone.

`lib/app/theme.dart` keeps the existing `AppTheme` API and original sakura-pink
seed, delegating to `myapps_ui`. It re-exports `AppUiStyle` and `NavPlacement`;
their serialized names and defaults are unchanged. Dynamic color remains Android-only.

`lib/shared/utils/adaptive_layout.dart` imports and re-exports the pure
`myapps_adaptive` thresholds, `canSplitLayout`, `useNavigationRail`,
`columnCapacity` and `listRowCount`. Reference-table widths, exercise panes,
settings widths and bottom-bar padding stay here. Existing caller APIs remain valid.

The legacy width-only `shellContentWidth` prediction is unchanged in this release.
Actual navigation-space measurement and shared navigation widgets are a later stage.
Profile data is still app-owned; no data formats or cross-app identity behavior change.

## Updating

Publish the library commit and tag to both remotes before updating this app's
submodule pointer. Pin to a tagged commit and run analysis plus the full test suite.
The library's authoritative function and behavior docs live under its `doc/en-us/`;
this app documents its brand, integration and business layout only.

Release check: Google Maven's ML Kit group index was inspected on 2026-10-04.
`genai-prompt:1.0.0-beta4` and `genai-proofreading:1.0.0-beta1` remain the latest
listed versions, matching the app; retain both in this release.

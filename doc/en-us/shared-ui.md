# Shared UI foundations

MyApps-UI `v0.1.1` is embedded at `packages/myapps_ui`, with relative submodule
URL `../MyApps-UI.git`. Initialize submodules recursively after a fresh clone.

`lib/app/theme.dart` keeps the existing `AppTheme` API and original sakura-pink
seed, delegating to `myapps_ui`. It re-exports `AppUiStyle` and `NavPlacement`;
their serialized names and defaults are unchanged. Dynamic color remains Android-only.

`lib/shared/utils/adaptive_layout.dart` imports and re-exports the pure
`myapps_adaptive` thresholds, `canSplitLayout`, `useNavigationRail`,
`columnCapacity` and `listRowCount`. Reference-table widths, exercise panes,
settings widths and bottom-bar padding stay here. Existing caller APIs remain valid.

Profile data is still app-owned; no data formats or cross-app identity behavior change.

## Updating

Publish the library commit and tag to both remotes before updating this app's
submodule pointer. Pin to a tagged commit and run analysis plus the full test suite.
The library's authoritative function and behavior docs live under its `doc/en-us/`;
this app documents its brand, integration and business layout only.

Release check: Google Maven's ML Kit group index was inspected on 2026-10-04.
`genai-prompt:1.0.0-beta4` and `genai-proofreading:1.0.0-beta1` remain the latest
listed versions, matching the app; retain both in this release.

## P2 navigation and actual space

The application now delegates navigation rendering to `MyAppsNavigationShell`.
App-side shells retain routes, destination filtering, selection persistence and reminder
callbacks. Each page passes `context` to its width and bottom-inset helpers: measured
shell content width is used once, and full-window routes subtract no rail. The legacy
context-free helper remains for callers that explicitly request the old calculation.
The stable content slot preserves page state across resize, style and rail-side changes.
MyVidComp retains classic navigation, extended rails and review badges.

Profile extraction remains P3; data formats are unchanged.

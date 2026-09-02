# Version history

Release-by-release summary of MyNihongo!!!!!. Useful for understanding *why* a behavior exists
before changing it.

## Repository caveat

The repository's branch is `main`. The `origin` remote existed before the first commit; the
`github` remote was added at initialization. The `myapps_data` submodule was first pinned to
`54fa8d7`, two documentation-only commits after the package's `v1.0.1` tag; pin to a tag before the
first release.

## Releases

- *Unreleased* `0.1.0`: Project skeleton (`PLAN.md` M1.0) — Android target, five-tab shell with the
  series' adaptive layout and navigation rail, kana chart ported from MyAnime!!!!! with its data
  extracted into a catalog model, bundled vocabulary and grammar seed content (24 N5 words, 8 N5
  grammar points, English and Simplified Chinese) with browser pages, the synced `StudyRecord`
  progress model with unknown-field preservation, the `nihongo_progress.json` data module and the
  four facades over `myapps_data`, settings with theme/language/storage/about in two panes on wide
  windows, English and Simplified Chinese UI, tests for layout rules, pages, JSON compatibility,
  the module contract and the content rules, bilingual documentation, an Android CI workflow that runs on every push to `main`, and the app icon
  with iOS default / dark / tinted variants (the `ios/` folder is scaffolded for the icon set only
  and is not built by CI).

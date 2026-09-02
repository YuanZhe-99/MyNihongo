# MyNihongo `lib/` Function Index

This is the top-level index of the hand-written Function Explanation Layer documentation for
`lib/` in the MyNihongo repo. Each row links to a per-source-file page under `doc/en-us/functions/`
mirroring the `lib/` tree (with `.dart` replaced by `.md`).

**Totals:** the repo's `/// Purpose:` comment count is **220** (per the Function Explanation Layer
convention in `AGENTS.md`, excluding generated `lib/l10n/` code — see [l10n/INDEX.md](l10n/INDEX.md)).
The rows below sum to **220** documented declarations.

| Tier | Count |
|---|---|
| Tier A (full entry: Purpose/Inputs/Returns/Side effects/Algorithm/Usage/Notes) | 25 |
| Tier B (index row only) | 195 |
| **Total** | **220** |

These totals were measured against the source tree at initialization (`PLAN.md` M1.0). If you
change these numbers, measure them rather than adjusting them by hand:

```bash
find lib -name "*.dart" -not -path "lib/l10n/*" | xargs grep -h '/// Purpose:' | wc -l
```

A library-level `/// Purpose:` header and a class-level one count as declarations here, as they do
in the sibling repos, so a file's count can exceed its function count by one or two.

## Root (`lib/`)

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/main.dart` | [main.md](main.md) | 1 | 0 |

## app/

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/app/app.dart` | [app/app.md](app/app.md) | 3 | 0 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 11 | 1 |
| `lib/app/flavor.dart` | [app/flavor.md](app/flavor.md) | 1 | 0 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 0 | 0 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 3 | 0 |

## features/

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/features/content/models/content_catalog.dart` | [features/content/models/content_catalog.md](features/content/models/content_catalog.md) | 4 | 0 |
| `lib/features/content/models/grammar_point.dart` | [features/content/models/grammar_point.md](features/content/models/grammar_point.md) | 3 | 0 |
| `lib/features/content/models/jlpt_level.dart` | [features/content/models/jlpt_level.md](features/content/models/jlpt_level.md) | 2 | 0 |
| `lib/features/content/models/localized_strings.dart` | [features/content/models/localized_strings.md](features/content/models/localized_strings.md) | 9 | 1 |
| `lib/features/content/models/vocab_entry.dart` | [features/content/models/vocab_entry.md](features/content/models/vocab_entry.md) | 4 | 0 |
| `lib/features/content/services/content_repository.dart` | [features/content/services/content_repository.md](features/content/services/content_repository.md) | 2 | 0 |
| `lib/features/grammar/views/grammar_page.dart` | [features/grammar/views/grammar_page.md](features/grammar/views/grammar_page.md) | 9 | 1 |
| `lib/features/kana/models/kana.dart` | [features/kana/models/kana.md](features/kana/models/kana.md) | 8 | 0 |
| `lib/features/kana/views/kana_page.dart` | [features/kana/views/kana_page.md](features/kana/views/kana_page.md) | 14 | 2 |
| `lib/features/learn/views/learn_page.dart` | [features/learn/views/learn_page.md](features/learn/views/learn_page.md) | 5 | 0 |
| `lib/features/progress/models/study_record.dart` | [features/progress/models/study_record.md](features/progress/models/study_record.md) | 23 | 5 |
| `lib/features/progress/services/nihongo_storage.dart` | [features/progress/services/nihongo_storage.md](features/progress/services/nihongo_storage.md) | 17 | 3 |
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 11 | 2 |
| `lib/features/vocab/views/vocab_page.dart` | [features/vocab/views/vocab_page.md](features/vocab/views/vocab_page.md) | 8 | 1 |

## shared/

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 6 | 0 |
| `lib/shared/providers/progress_provider.dart` | [shared/providers/progress_provider.md](shared/providers/progress_provider.md) | 0 | 0 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 18 | 0 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 11 | 0 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 3 | 0 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 4 | 2 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 15 | 2 |
| `lib/shared/utils/adaptive_layout.dart` | [shared/utils/adaptive_layout.md](shared/utils/adaptive_layout.md) | 9 | 4 |
| `lib/shared/widgets/adaptive_tile_grid.dart` | [shared/widgets/adaptive_tile_grid.md](shared/widgets/adaptive_tile_grid.md) | 2 | 0 |
| `lib/shared/widgets/reference_widgets.dart` | [shared/widgets/reference_widgets.md](shared/widgets/reference_widgets.md) | 4 | 0 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 5 | 1 |

## l10n/

Generated code; see [l10n/INDEX.md](l10n/INDEX.md). Not counted above.

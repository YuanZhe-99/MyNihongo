# MyNihongo `lib/` 函数索引

这是 MyNihongo 仓库中 `lib/` 手写函数解释层文档的顶层索引。每行链接到 `doc/zh-cn/functions/` 下镜像 `lib/` 树的逐源文件页面（`.dart` 换成 `.md`）。

**总计：** 仓库的 `/// Purpose:` 注释数为 **417**（按 `AGENTS.md` 中的函数解释层约定，排除生成的 `lib/l10n/` 代码——见 [l10n/INDEX.md](l10n/INDEX.md)）。下方各行合计 **422** 个已记录声明。两个数字分别测量，并不要求完全相等：匿名回调可能带有 `/// Purpose:` 行却没有索引行，而库级文档头有索引行却不带该注释。

| Tier | 计数 |
|---|---|
| Tier A（完整条目：Purpose/Inputs/Returns/Side effects/Algorithm/Usage/Notes） | 55 |
| Tier B（仅索引行） | 367 |
| **总计** | **422** |

这些总计在初始化时（`PLAN.md` M1.0）对照源码树测得。若要改动这些数字，请测量而不要手工调整：

```bash
find lib -name "*.dart" -not -path "lib/l10n/*" | xargs grep -h '/// Purpose:' | wc -l
```

库级的 `/// Purpose:` 头和类级的一条在这里都算作声明，与兄弟仓库一致，因此一个文件的计数可能比其函数数多一到两个。

## 根（`lib/`）

| 源文件 | 页面 | 声明数 | Tier A 计数 |
|---|---|---|---|
| `lib/main.dart` | [main.md](main.md) | 1 | 0 |

## app/

| 源文件 | 页面 | 声明数 | Tier A 计数 |
|---|---|---|---|
| `lib/app/app.dart` | [app/app.md](app/app.md) | 4 | 0 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 11 | 1 |
| `lib/app/flavor.dart` | [app/flavor.md](app/flavor.md) | 1 | 0 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 1 | 0 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 3 | 0 |

## features/

| 源文件 | 页面 | 声明数 | Tier A 计数 |
|---|---|---|---|
| `lib/features/content/models/content_catalog.dart` | [features/content/models/content_catalog.md](features/content/models/content_catalog.md) | 7 | 0 |
| `lib/features/content/models/grammar_point.dart` | [features/content/models/grammar_point.md](features/content/models/grammar_point.md) | 3 | 0 |
| `lib/features/content/models/jlpt_level.dart` | [features/content/models/jlpt_level.md](features/content/models/jlpt_level.md) | 2 | 0 |
| `lib/features/content/models/localized_strings.dart` | [features/content/models/localized_strings.md](features/content/models/localized_strings.md) | 9 | 1 |
| `lib/features/content/models/parts_of_speech.dart` | [features/content/models/parts_of_speech.md](features/content/models/parts_of_speech.md) | 1 | 0 |
| `lib/features/content/models/vocab_entry.dart` | [features/content/models/vocab_entry.md](features/content/models/vocab_entry.md) | 4 | 0 |
| `lib/features/content/services/content_repository.dart` | [features/content/services/content_repository.md](features/content/services/content_repository.md) | 5 | 0 |
| `lib/features/content/services/study_item_labels.dart` | [features/content/services/study_item_labels.md](features/content/services/study_item_labels.md) | 3 | 1 |
| `lib/features/content/services/content_links.dart` | [features/content/services/content_links.md](features/content/services/content_links.md) | 7 | 3 |
| `lib/features/grammar/views/grammar_page.dart` | [features/grammar/views/grammar_page.md](features/grammar/views/grammar_page.md) | 7 | 1 |
| `lib/features/kana/models/kana.dart` | [features/kana/models/kana.md](features/kana/models/kana.md) | 9 | 0 |
| `lib/features/kana/models/kana_note.dart` | [features/kana/models/kana_note.md](features/kana/models/kana_note.md) | 4 | 0 |
| `lib/features/kana/models/kana_text.dart` | [features/kana/models/kana_text.md](features/kana/models/kana_text.md) | 5 | 2 |
| `lib/features/kana/models/romaji.dart` | [features/kana/models/romaji.md](features/kana/models/romaji.md) | 3 | 1 |
| `lib/features/kana/views/kana_page.dart` | [features/kana/views/kana_page.md](features/kana/views/kana_page.md) | 15 | 2 |
| `lib/features/learn/views/learn_page.dart` | [features/learn/views/learn_page.md](features/learn/views/learn_page.md) | 5 | 0 |
| `lib/features/progress/models/study_record.dart` | [features/progress/models/study_record.md](features/progress/models/study_record.md) | 23 | 5 |
| `lib/features/progress/services/nihongo_storage.dart` | [features/progress/services/nihongo_storage.md](features/progress/services/nihongo_storage.md) | 41 | 3 |
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/sentence/services/lexicon.dart` | [features/sentence/services/lexicon.md](features/sentence/services/lexicon.md) | 4 | 1 |
| `lib/features/speech/services/pronunciation_scorer.dart` | [features/speech/services/pronunciation_scorer.md](features/speech/services/pronunciation_scorer.md) | 3 | 2 |
| `lib/features/speech/services/speech_backend.dart` | [features/speech/services/speech_backend.md](features/speech/services/speech_backend.md) | 13 | 1 |
| `lib/features/speech/services/speech_recognition_service.dart` | [features/speech/services/speech_recognition_service.md](features/speech/services/speech_recognition_service.md) | 10 | 2 |
| `lib/features/speech/services/tts_backend.dart` | [features/speech/services/tts_backend.md](features/speech/services/tts_backend.md) | 15 | 1 |
| `lib/features/speech/services/tts_service.dart` | [features/speech/services/tts_service.md](features/speech/services/tts_service.md) | 8 | 3 |
| `lib/features/speech/widgets/pronunciation_practice_sheet.dart` | [features/speech/widgets/pronunciation_practice_sheet.md](features/speech/widgets/pronunciation_practice_sheet.md) | 12 | 2 |
| `lib/features/speech/widgets/speak_button.dart` | [features/speech/widgets/speak_button.md](features/speech/widgets/speak_button.md) | 1 | 1 |
| `lib/features/speech/widgets/speech_settings_tiles.dart` | [features/speech/widgets/speech_settings_tiles.md](features/speech/widgets/speech_settings_tiles.md) | 5 | 1 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 16 | 2 |
| `lib/features/settings/views/backup_page.dart` | [features/settings/views/backup_page.md](features/settings/views/backup_page.md) | 17 | 1 |
| `lib/features/vocab/views/vocab_page.dart` | [features/vocab/views/vocab_page.md](features/vocab/views/vocab_page.md) | 7 | 1 |

## shared/

| 源文件 | 页面 | 声明数 | Tier A 计数 |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 13 | 0 |
| `lib/shared/providers/progress_provider.dart` | [shared/providers/progress_provider.md](shared/providers/progress_provider.md) | 5 | 0 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 18 | 0 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 11 | 0 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 3 | 0 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 4 | 2 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 15 | 2 |
| `lib/shared/views/webdav_config_page.dart` | [shared/views/webdav_config_page.md](shared/views/webdav_config_page.md) | 21 | 1 |
| `lib/shared/services/system_settings_launcher.dart` | [shared/services/system_settings_launcher.md](shared/services/system_settings_launcher.md) | 1 | 1 |
| `lib/shared/utils/adaptive_layout.dart` | [shared/utils/adaptive_layout.md](shared/utils/adaptive_layout.md) | 9 | 4 |
| `lib/shared/utils/platform_capabilities.dart` | [shared/utils/platform_capabilities.md](shared/utils/platform_capabilities.md) | 5 | 1 |
| `lib/shared/widgets/adaptive_tile_grid.dart` | [shared/widgets/adaptive_tile_grid.md](shared/widgets/adaptive_tile_grid.md) | 3 | 0 |
| `lib/shared/widgets/example_actions.dart` | [shared/widgets/example_actions.md](shared/widgets/example_actions.md) | 1 | 1 |
| `lib/shared/widgets/content_sheets.dart` | [shared/widgets/content_sheets.md](shared/widgets/content_sheets.md) | 8 | 3 |
| `lib/shared/widgets/reference_widgets.dart` | [shared/widgets/reference_widgets.md](shared/widgets/reference_widgets.md) | 4 | 0 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 5 | 1 |
| `lib/shared/widgets/study_conflict_dialog.dart` | [shared/widgets/study_conflict_dialog.md](shared/widgets/study_conflict_dialog.md) | 6 | 1 |

## l10n/

生成代码；见 [l10n/INDEX.md](l10n/INDEX.md)。不计入上表。

## tool/

离线构建脚本，位于 `lib/` 之外，不计入上方的总计。

| 源文件 | 页面 | 声明数 | Tier A 数 |
|---|---|---|---|
| `tool/import_vocab.dart` | [tool/import_vocab.md](tool/import_vocab.md) | 7 | 1 |
| `tool/src/vocab_import_core.dart` | [tool/src/vocab_import_core.md](tool/src/vocab_import_core.md) | 14 | 3 |
| `tool/generate_ios_icons.dart` | 未编写文档 | — | — |

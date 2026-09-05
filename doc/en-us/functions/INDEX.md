# MyNihongo `lib/` Function Index

This is the top-level index of the hand-written Function Explanation Layer documentation for
`lib/` in the MyNihongo repo. Each row links to a per-source-file page under `doc/en-us/functions/`
mirroring the `lib/` tree (with `.dart` replaced by `.md`).

**Totals:** the repo's `/// Purpose:` comment count is **922** (per the Function Explanation Layer
convention in `AGENTS.md`, excluding generated `lib/l10n/` code — see [l10n/INDEX.md](l10n/INDEX.md)).
The rows below sum to **895** documented declarations. The two counts are measured separately and
are not expected to match exactly: an anonymous callback can carry a `/// Purpose:` line without
earning an index row, and a library-level doc header earns a row without carrying one.

| Tier | Count |
|---|---|
| Tier A (full entry: Purpose/Inputs/Returns/Side effects/Algorithm/Usage/Notes) | 173 |
| Tier B (index row only) | 722 |
| **Total** | **895** |

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
| `lib/app/app.dart` | [app/app.md](app/app.md) | 4 | 0 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 11 | 1 |
| `lib/app/flavor.dart` | [app/flavor.md](app/flavor.md) | 1 | 0 |
| `lib/app/locale_resolution.dart` | [app/locale_resolution.md](app/locale_resolution.md) | 4 | 2 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 1 | 0 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 3 | 0 |

## features/

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/features/ai/services/ai_assist_service.dart` | [features/ai/services/ai_assist_service.md](features/ai/services/ai_assist_service.md) | 20 | 4 |
| `lib/features/ai/services/aicore_sentence_enhancer.dart` | [features/ai/services/aicore_sentence_enhancer.md](features/ai/services/aicore_sentence_enhancer.md) | 4 | 3 |
| `lib/features/ai/services/genai_backend.dart` | [features/ai/services/genai_backend.md](features/ai/services/genai_backend.md) | 26 | 2 |
| `lib/features/ai/services/prompt_builder.dart` | [features/ai/services/prompt_builder.md](features/ai/services/prompt_builder.md) | 15 | 4 |
| `lib/features/ai/services/response_parser.dart` | [features/ai/services/response_parser.md](features/ai/services/response_parser.md) | 9 | 2 |
| `lib/features/ai/services/writing_rewrite.dart` | [features/ai/services/writing_rewrite.md](features/ai/services/writing_rewrite.md) | 2 | 1 |
| `lib/features/ai/widgets/ai_explanation_card.dart` | [features/ai/widgets/ai_explanation_card.md](features/ai/widgets/ai_explanation_card.md) | 3 | 2 |
| `lib/features/ai/widgets/ai_settings_tiles.dart` | [features/ai/widgets/ai_settings_tiles.md](features/ai/widgets/ai_settings_tiles.md) | 10 | 3 |
| `lib/features/content/models/content_catalog.dart` | [features/content/models/content_catalog.md](features/content/models/content_catalog.md) | 7 | 0 |
| `lib/features/content/models/grammar_point.dart` | [features/content/models/grammar_point.md](features/content/models/grammar_point.md) | 3 | 0 |
| `lib/features/content/models/jlpt_level.dart` | [features/content/models/jlpt_level.md](features/content/models/jlpt_level.md) | 2 | 0 |
| `lib/features/content/models/localized_strings.dart` | [features/content/models/localized_strings.md](features/content/models/localized_strings.md) | 10 | 2 |
| `lib/features/content/models/parts_of_speech.dart` | [features/content/models/parts_of_speech.md](features/content/models/parts_of_speech.md) | 1 | 0 |
| `lib/features/content/models/vocab_entry.dart` | [features/content/models/vocab_entry.md](features/content/models/vocab_entry.md) | 4 | 0 |
| `lib/features/content/services/content_repository.dart` | [features/content/services/content_repository.md](features/content/services/content_repository.md) | 5 | 0 |
| `lib/features/content/services/study_item_labels.dart` | [features/content/services/study_item_labels.md](features/content/services/study_item_labels.md) | 3 | 1 |
| `lib/features/content/services/content_links.dart` | [features/content/services/content_links.md](features/content/services/content_links.md) | 7 | 3 |
| `lib/features/content/services/furigana_aligner.dart` | [features/content/services/furigana_aligner.md](features/content/services/furigana_aligner.md) | 10 | 4 |
| `lib/features/grammar/views/grammar_page.dart` | [features/grammar/views/grammar_page.md](features/grammar/views/grammar_page.md) | 7 | 1 |
| `lib/features/kana/models/kana.dart` | [features/kana/models/kana.md](features/kana/models/kana.md) | 9 | 0 |
| `lib/features/kana/models/kana_note.dart` | [features/kana/models/kana_note.md](features/kana/models/kana_note.md) | 4 | 0 |
| `lib/features/kana/models/kana_text.dart` | [features/kana/models/kana_text.md](features/kana/models/kana_text.md) | 5 | 2 |
| `lib/features/kana/models/romaji.dart` | [features/kana/models/romaji.md](features/kana/models/romaji.md) | 3 | 1 |
| `lib/features/kana/views/kana_page.dart` | [features/kana/views/kana_page.md](features/kana/views/kana_page.md) | 15 | 2 |
| `lib/features/learn/widgets/learning_settings_tiles.dart` | [features/learn/widgets/learning_settings_tiles.md](features/learn/widgets/learning_settings_tiles.md) | 2 | 0 |
| `lib/features/learn/widgets/today_card.dart` | [features/learn/widgets/today_card.md](features/learn/widgets/today_card.md) | 3 | 1 |
| `lib/features/learn/views/learn_page.dart` | [features/learn/views/learn_page.md](features/learn/views/learn_page.md) | 5 | 0 |
| `lib/features/progress/models/study_record.dart` | [features/progress/models/study_record.md](features/progress/models/study_record.md) | 23 | 5 |
| `lib/features/progress/models/learner_profile.dart` | [features/progress/models/learner_profile.md](features/progress/models/learner_profile.md) | 7 | 2 |
| `lib/features/progress/models/history_entry.dart` | [features/progress/models/history_entry.md](features/progress/models/history_entry.md) | 12 | 4 |
| `lib/features/progress/services/nihongo_storage.dart` | [features/progress/services/nihongo_storage.md](features/progress/services/nihongo_storage.md) | 45 | 3 |
| `lib/features/progress/services/review_queue.dart` | [features/progress/services/review_queue.md](features/progress/services/review_queue.md) | 7 | 2 |
| `lib/features/progress/services/sm2_scheduler.dart` | [features/progress/services/sm2_scheduler.md](features/progress/services/sm2_scheduler.md) | 5 | 2 |
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/quiz/models/quiz_config.dart` | [features/quiz/models/quiz_config.md](features/quiz/models/quiz_config.md) | 8 | 1 |
| `lib/features/quiz/models/quiz_question.dart` | [features/quiz/models/quiz_question.md](features/quiz/models/quiz_question.md) | 7 | 1 |
| `lib/features/quiz/services/answer_checker.dart` | [features/quiz/services/answer_checker.md](features/quiz/services/answer_checker.md) | 8 | 0 |
| `lib/features/quiz/services/distractors.dart` | [features/quiz/services/distractors.md](features/quiz/services/distractors.md) | 8 | 2 |
| `lib/features/quiz/services/question_generator.dart` | [features/quiz/services/question_generator.md](features/quiz/services/question_generator.md) | 15 | 3 |
| `lib/features/quiz/services/quiz_session.dart` | [features/quiz/services/quiz_session.md](features/quiz/services/quiz_session.md) | 10 | 2 |
| `lib/features/quiz/views/quiz_modes_page.dart` | [features/quiz/views/quiz_modes_page.md](features/quiz/views/quiz_modes_page.md) | 3 | 1 |
| `lib/features/quiz/views/quiz_page.dart` | [features/quiz/views/quiz_page.md](features/quiz/views/quiz_page.md) | 9 | 1 |
| `lib/features/quiz/widgets/answer_panes.dart` | [features/quiz/widgets/answer_panes.md](features/quiz/widgets/answer_panes.md) | 8 | 1 |
| `lib/features/quiz/widgets/quiz_runner.dart` | [features/quiz/widgets/quiz_runner.md](features/quiz/widgets/quiz_runner.md) | 8 | 1 |
| `lib/features/sentence/models/function_word.dart` | [features/sentence/models/function_word.md](features/sentence/models/function_word.md) | 7 | 1 |
| `lib/features/sentence/models/sentence_analysis.dart` | [features/sentence/models/sentence_analysis.md](features/sentence/models/sentence_analysis.md) | 12 | 2 |
| `lib/features/sentence/models/token.dart` | [features/sentence/models/token.md](features/sentence/models/token.md) | 1 | 1 |
| `lib/features/sentence/services/chunker.dart` | [features/sentence/services/chunker.md](features/sentence/services/chunker.md) | 6 | 3 |
| `lib/features/sentence/services/conjugator.dart` | [features/sentence/services/conjugator.md](features/sentence/services/conjugator.md) | 10 | 2 |
| `lib/features/sentence/services/godan_rows.dart` | [features/sentence/services/godan_rows.md](features/sentence/services/godan_rows.md) | 6 | 0 |
| `lib/features/sentence/services/deinflector.dart` | [features/sentence/services/deinflector.md](features/sentence/services/deinflector.md) | 5 | 3 |
| `lib/features/sentence/services/grammar_matcher.dart` | [features/sentence/services/grammar_matcher.md](features/sentence/services/grammar_matcher.md) | 2 | 1 |
| `lib/features/sentence/services/lexicon.dart` | [features/sentence/services/lexicon.md](features/sentence/services/lexicon.md) | 10 | 3 |
| `lib/features/sentence/services/sentence_analyzer.dart` | [features/sentence/services/sentence_analyzer.md](features/sentence/services/sentence_analyzer.md) | 7 | 2 |
| `lib/features/sentence/services/sentence_checks.dart` | [features/sentence/services/sentence_checks.md](features/sentence/services/sentence_checks.md) | 5 | 2 |
| `lib/features/sentence/services/tokenizer.dart` | [features/sentence/services/tokenizer.md](features/sentence/services/tokenizer.md) | 12 | 3 |
| `lib/features/sentence/views/sentence_lab_page.dart` | [features/sentence/views/sentence_lab_page.md](features/sentence/views/sentence_lab_page.md) | 14 | 3 |
| `lib/features/sentence/widgets/analysis_result_view.dart` | [features/sentence/widgets/analysis_result_view.md](features/sentence/widgets/analysis_result_view.md) | 3 | 1 |
| `lib/features/sentence/widgets/form_labels.dart` | [features/sentence/widgets/form_labels.md](features/sentence/widgets/form_labels.md) | 2 | 1 |
| `lib/features/sentence/widgets/bunsetsu_tree.dart` | [features/sentence/widgets/bunsetsu_tree.md](features/sentence/widgets/bunsetsu_tree.md) | 1 | 1 |
| `lib/features/sentence/widgets/grammar_used_list.dart` | [features/sentence/widgets/grammar_used_list.md](features/sentence/widgets/grammar_used_list.md) | 1 | 1 |
| `lib/features/sentence/widgets/issue_list.dart` | [features/sentence/widgets/issue_list.md](features/sentence/widgets/issue_list.md) | 6 | 1 |
| `lib/features/sentence/widgets/token_chips.dart` | [features/sentence/widgets/token_chips.md](features/sentence/widgets/token_chips.md) | 5 | 2 |
| `lib/features/speech/models/voice_ordering.dart` | [features/speech/models/voice_ordering.md](features/speech/models/voice_ordering.md) | 5 | 1 |
| `lib/features/speech/services/pronunciation_scorer.dart` | [features/speech/services/pronunciation_scorer.md](features/speech/services/pronunciation_scorer.md) | 3 | 2 |
| `lib/features/speech/services/speech_backend.dart` | [features/speech/services/speech_backend.md](features/speech/services/speech_backend.md) | 13 | 1 |
| `lib/features/speech/services/speech_recognition_service.dart` | [features/speech/services/speech_recognition_service.md](features/speech/services/speech_recognition_service.md) | 10 | 2 |
| `lib/features/speech/services/tts_backend.dart` | [features/speech/services/tts_backend.md](features/speech/services/tts_backend.md) | 15 | 1 |
| `lib/features/speech/services/tts_service.dart` | [features/speech/services/tts_service.md](features/speech/services/tts_service.md) | 8 | 3 |
| `lib/features/speech/widgets/pronunciation_practice_sheet.dart` | [features/speech/widgets/pronunciation_practice_sheet.md](features/speech/widgets/pronunciation_practice_sheet.md) | 12 | 2 |
| `lib/features/speech/widgets/speak_button.dart` | [features/speech/widgets/speak_button.md](features/speech/widgets/speak_button.md) | 1 | 1 |
| `lib/features/speech/widgets/speech_settings_tiles.dart` | [features/speech/widgets/speech_settings_tiles.md](features/speech/widgets/speech_settings_tiles.md) | 5 | 2 |
| `lib/features/speech/widgets/voice_labels.dart` | [features/speech/widgets/voice_labels.md](features/speech/widgets/voice_labels.md) | 4 | 1 |
| `lib/features/speech/widgets/voice_picker_sheet.dart` | [features/speech/widgets/voice_picker_sheet.md](features/speech/widgets/voice_picker_sheet.md) | 4 | 1 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 16 | 2 |
| `lib/features/settings/views/backup_page.dart` | [features/settings/views/backup_page.md](features/settings/views/backup_page.md) | 17 | 1 |
| `lib/features/vocab/views/vocab_page.dart` | [features/vocab/views/vocab_page.md](features/vocab/views/vocab_page.md) | 7 | 1 |

## shared/

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 10 | 0 |
| `lib/shared/providers/progress_provider.dart` | [shared/providers/progress_provider.md](shared/providers/progress_provider.md) | 5 | 0 |
| `lib/shared/providers/learner_profile_provider.dart` | [shared/providers/learner_profile_provider.md](shared/providers/learner_profile_provider.md) | 3 | 0 |
| `lib/shared/providers/history_provider.dart` | [shared/providers/history_provider.md](shared/providers/history_provider.md) | 3 | 2 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 18 | 0 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 11 | 0 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 3 | 0 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 4 | 2 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 15 | 2 |
| `lib/shared/views/webdav_config_page.dart` | [shared/views/webdav_config_page.md](shared/views/webdav_config_page.md) | 21 | 1 |
| `lib/shared/services/system_settings_launcher.dart` | [shared/services/system_settings_launcher.md](shared/services/system_settings_launcher.md) | 1 | 1 |
| `lib/shared/utils/adaptive_layout.dart` | [shared/utils/adaptive_layout.md](shared/utils/adaptive_layout.md) | 9 | 4 |
| `lib/shared/utils/platform_capabilities.dart` | [shared/utils/platform_capabilities.md](shared/utils/platform_capabilities.md) | 6 | 1 |
| `lib/shared/widgets/adaptive_tile_grid.dart` | [shared/widgets/adaptive_tile_grid.md](shared/widgets/adaptive_tile_grid.md) | 3 | 0 |
| `lib/shared/widgets/example_actions.dart` | [shared/widgets/example_actions.md](shared/widgets/example_actions.md) | 1 | 1 |
| `lib/shared/widgets/furigana_text.dart` | [shared/widgets/furigana_text.md](shared/widgets/furigana_text.md) | 5 | 1 |
| `lib/shared/widgets/history_list.dart` | [shared/widgets/history_list.md](shared/widgets/history_list.md) | 6 | 2 |
| `lib/shared/widgets/content_sheets.dart` | [shared/widgets/content_sheets.md](shared/widgets/content_sheets.md) | 8 | 3 |
| `lib/shared/widgets/reference_widgets.dart` | [shared/widgets/reference_widgets.md](shared/widgets/reference_widgets.md) | 4 | 0 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 5 | 1 |
| `lib/shared/widgets/study_conflict_dialog.dart` | [shared/widgets/study_conflict_dialog.md](shared/widgets/study_conflict_dialog.md) | 8 | 1 |

### Added in Phase 3

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `lib/features/lessons/models/lesson_path.dart` | [features/lessons/models/lesson_path.md](features/lessons/models/lesson_path.md) | 12 | 2 |
| `lib/features/lessons/services/lesson_repository.dart` | not documented | — | — |
| `lib/features/lessons/services/lesson_rules.dart` | [features/lessons/services/lesson_rules.md](features/lessons/services/lesson_rules.md) | 9 | 3 |
| `lib/features/lessons/widgets/lesson_path_view.dart` | not documented | — | — |
| `lib/features/quiz/services/question_bank.dart` | [features/quiz/services/question_bank.md](features/quiz/services/question_bank.md) | 5 | 2 |
| `lib/features/quiz/widgets/why_wrong.dart` | not documented | — | — |
| `lib/features/reminders/services/reminder_backend.dart` | not documented | — | — |
| `lib/features/reminders/services/reminder_planner.dart` | [features/reminders/services/reminder_planner.md](features/reminders/services/reminder_planner.md) | 3 | 1 |
| `lib/features/reminders/services/reminder_service.dart` | [features/reminders/services/reminder_service.md](features/reminders/services/reminder_service.md) | 12 | 3 |
| `lib/features/reminders/services/local_notifications_backend.dart` | not documented | — | — |
| `lib/features/reminders/services/desktop_reminder_backend.dart` | not documented | — | — |
| `lib/features/reminders/widgets/reminder_settings_tiles.dart` | not documented | — | — |
| `lib/features/ai/services/ai_practice_service.dart` | [features/ai/services/ai_practice_service.md](features/ai/services/ai_practice_service.md) | 7 | 2 |
| `lib/features/ai/services/practice_prompt_builder.dart` | not documented | — | — |
| `lib/features/ai/services/practice_response_parser.dart` | [features/ai/services/practice_response_parser.md](features/ai/services/practice_response_parser.md) | 9 | 3 |
| `lib/features/ai/widgets/generated_examples.dart` | not documented | — | — |
| `lib/features/lessons/models/scenario.dart` | [features/lessons/models/scenario.md](features/lessons/models/scenario.md) | 14 | 1 |
| `lib/features/lessons/views/scenario_page.dart` | [features/lessons/views/scenario_page.md](features/lessons/views/scenario_page.md) | 8 | 1 |
| `lib/features/quiz/services/ai_question_generator.dart` | [features/quiz/services/ai_question_generator.md](features/quiz/services/ai_question_generator.md) | 7 | 2 |
| `lib/features/writing/views/writing_practice_page.dart` | [features/writing/views/writing_practice_page.md](features/writing/views/writing_practice_page.md) | 18 | 5 |

## l10n/

Generated code; see [l10n/INDEX.md](l10n/INDEX.md). Not counted above.

## tool/

Offline build scripts, outside `lib/` and outside the totals above.

| Source file | Page | Declarations | Tier A count |
|---|---|---|---|
| `tool/import_vocab.dart` | [tool/import_vocab.md](tool/import_vocab.md) | 7 | 1 |
| `tool/src/vocab_import_core.dart` | [tool/src/vocab_import_core.md](tool/src/vocab_import_core.md) | 14 | 3 |
| `tool/convert_zh_tw.dart` | not documented | — | — |
| `tool/draft_inputs.dart` | not documented | — | — |
| `tool/merge_drafts.dart` | not documented | — | — |
| `tool/generate_ios_icons.dart` | not documented | — | — |

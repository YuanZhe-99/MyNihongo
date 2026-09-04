# lib/features/learn/widgets/learning_settings_tiles.dart

The Settings rows that configure what and how much to study: target level, new items a day, reviews
a day.

**Unlike every other section in Settings these are synced, not device-local.** They live in the
learner profile inside `nihongo_progress.json`, so a goal set on a phone is the same goal on a
tablet — which is why they are written through `progressDataProvider` rather than
`appSettingsProvider`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LearningSettingsTiles` | class | B | The Settings rows that configure study goals. |
| `newLimits`, `reviewLimits` | static constants | B | The daily counts offered. |
| `build` | method | B | Build the target-level and daily-limit rows. |

# lib/features/learn/widgets/learning_settings_tiles.dart

设置中用来配置学什么、学多少的几行：目标级别、每日新内容、每日复习量。

**与设置里其他每个分区不同，这几项是同步的，而不是设备本地的。** 它们存在 `nihongo_progress.json` 内的学习者档案里，因此在手机上设定的目标在平板上也是同一个目标——这也正是它们经由 `progressDataProvider` 而不是 `appSettingsProvider` 写入的原因。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `LearningSettingsTiles` | 类 | B | 设置中配置学习目标的那几行。 |
| `newLimits`、`reviewLimits` | 静态常量 | B | 可选的每日数量。 |
| `build` | 方法 | B | 构建目标级别与两个每日上限行。 |

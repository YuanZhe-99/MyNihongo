# MyNihongo!!!!! 文档（概念）

**MyNihongo!!!!!**（每个面向用户的名称中都有五个感叹号——应用标题、启动器标签，以及之后的安装包元数据和 bundle 名称）是一款隐私优先的日语学习应用。它结合了五十音图、带 JLPT 级别的单词与语法内容目录、同步的用户学习进度记录、通过共享 `myapps_data` 引擎实现的 WebDAV 同步、本地备份与 ZIP 传输，以及本系列面向折叠屏设备的自适应布局。发音练习、句子分析、间隔重复课程和 JLPT 练习题在计划中；见仓库根目录的 `PLAN.md`。

- **作者 / 包 id：** `yuanzhe`、`com.yuanzhe.my_nihongo`
- **许可证：** GPL-3.0
- **平台：** Android（Windows、iOS 和 macOS 在计划中；不面向 Web）
- **框架：** Flutter，Dart SDK `^3.11.3`；CI 使用 Flutter `3.44.2`

本树保存**概念**文档——架构、数据格式、布局规则和逐功能行为——为需要理解应用*为什么*这样行为的用户和代理而写。逐函数的 API 文档单独位于 [`functions/`](functions/)，翻译说明在 [`translation-guide.md`](translation-guide.md) 中。

**这些文档是代码的权威描述。** 仓库的 `AGENTS.md` 刻意只保留给代理的指令——工作流、编写规则、行为契约和发布流程——并在这里指向其余一切。代码变更时，这些页面先行更新；当文档与代码不一致时，以代码核实后修正页面。

共享的 WebDAV 同步、备份和 ZIP 引擎不在此仓库。它们位于嵌入在 `packages/myapps_data` 的 `myapps_data` 包中，文档在 `packages/myapps_data/doc/en-us/`。

## 目录

### 核心概念

- [`architecture.md`](architecture.md) — 应用外壳、状态管理、导航、l10n、仓库布局，以及整个代码库遵循的核心架构规则。
- [`data-formats.md`](data-formats.md) — 内容目录的 schema、`StudyRecord` 进度模型、磁盘 JSON 格式，以及完整持久化数据清单（哪些同步、哪些仅设备本地）。
- [`adaptive-layout.md`](adaptive-layout.md) — 布局何时可以分栏、导航放在哪里、能放几列，以及每个页面使用哪条规则。
- [`sync.md`](sync.md) — 共享 WebDAV 引擎在这里的配置方式：唯一的数据模块、它的合并，以及冲突如何呈现给用户。
- [`backup-restore.md`](backup-restore.md) — 本地备份和 ZIP 导出 / 导入在这里的配置方式。
- [`platform-notes.md`](platform-notes.md) — Android 构建状态和计划中的平台。
- [`ci-cd.md`](ci-cd.md) — CI 任务、构建 / 校验命令集，以及全新克隆（子模块）步骤。
- [`version-history.md`](version-history.md) — 逐版本摘要。

### 功能区域

- [`features/kana-reference.md`](features/kana-reference.md) — 五十音图页面及其背后的假名目录。
- [`features/content-catalog.md`](features/content-catalog.md) — 内置的单词和语法内容：schema、id、语言、许可，以及浏览页面。
- [`features/learning-progress.md`](features/learning-progress.md) — 同步的学习进度记录和学习仪表盘。
- [`features/sync-and-backup.md`](features/sync-and-backup.md) — “设置 › 数据”下的同步、备份与 ZIP 界面。
- [`features/reference-preferences.md`](features/reference-preferences.md) — 参考页面按设备记住的五个选择。

## 此处不涵盖

- `doc/zh-cn/functions/` — 逐源文件的函数索引页面。单独维护；从 [`functions/INDEX.md`](functions/INDEX.md) 开始。
- `PLAN.md` — 路线图，位于仓库根目录。

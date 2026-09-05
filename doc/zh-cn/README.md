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
- [`features/pronunciation.md`](features/pronunciation.md) — 一切发声与听声的部分：哪些内容会被朗读、速度与语音偏好，以及未安装日语语音时的表现。
- [`features/sentence-lab.md`](features/sentence-lab.md) — 句子实验室页面：它显示什么、从哪里进入，以及它写明的限制。
- [`features/content-authoring.md`](features/content-authoring.md) — 新的目录内容如何撰写、如何把关，以及把关保证不了什么。
- [`features/lesson-path.md`](features/lesson-path.md) — 一个级别被划分成的单元、单元的题目如何挑选，以及下一个何时开放。
- [`features/jlpt-practice.md`](features/jlpt-practice.md) — JLPT 真题练习：考卷的构成、哪些照搬哪些没有，以及一份卷子的题目如何挑选。
- [`features/reminders.md`](features/reminders.md) — 每日提醒说什么，以及权限在什么时候请求。
- [`features/quizzes.md`](features/quizzes.md) — 围绕同一个内容库的十三种提问方式，以及一道题如何被生成或被舍弃。
- [`algorithms/spaced-repetition.md`](algorithms/spaced-repetition.md) — SM-2 的调度、与教科书的两处偏离，以及复习队列如何派生。
- [`algorithms/furigana-alignment.md`](algorithms/furigana-alignment.md) — 读音如何与它所属的字对上，以及它在什么时候拒绝猜测。
- [`algorithms/pronunciation-scoring.md`](algorithms/pronunciation-scoring.md) — 一次朗读尝试如何逐音拍地与读音作对照。
- [`algorithms/sentence-analysis.md`](algorithms/sentence-analysis.md) — 输入的句子如何变成词、结构、语法点和可能的问题。
- [`store-listing.md`](store-listing.md) — 发布与商店文案。

## 此处不涵盖

- `doc/zh-cn/functions/` — 逐源文件的函数索引页面。单独维护；从 [`functions/INDEX.md`](functions/INDEX.md) 开始。
- `PLAN.md` — 路线图，位于仓库根目录。

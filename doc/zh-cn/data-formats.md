# 数据格式

本页描述内置内容的 schema、`StudyRecord` 进度模型（`lib/features/progress/models/study_record.dart`）、凡遇到未知 JSON 时使用的向前兼容模式，以及应用持久化到磁盘的完整文件清单。进度记录如何跨设备合并见 [`sync.md`](sync.md)。

## 内容目录（只读，内置）

内容以 JSON 资源的形式放在 `assets/content/` 下，由 `ContentRepository` 每次运行解析一次成 `ContentCatalog`。它既不同步也不备份——它是应用的数据，不是用户的——并通过 `schemaVersion` 随构建版本化。

### 单词（`vocab.json`）

由 `tool/import_vocab.dart` 生成；流水线见
[`features/content-catalog.md`](features/content-catalog.md)。文件头为便于查阅采用缩进格式，条目则每行一个
紧凑对象，因此 2 MB 的文件仍能给出可读的 diff。

```json
{
  "schemaVersion": 2,
  "source": "jmdict+jlpt",
  "sources": [ { "name": "JMdict", "url": "…", "license": "CC BY-SA 4.0 (EDRDG)", "via": "…" } ],
  "inputs": { "jmdictVersion": "3.6.2", "jmdictDate": "2026-08-31" },
  "entries": [
    {"id":"vocab:jm1311110","level":"N5","kanji":"私","reading":"わたし","romaji":"watashi","pos":["pronoun"],"meanings":{"en":["I","me"],"zh":["我"]},"common":true,"aliases":["vocab:watashi"],"examples":[{"ja":"私は学生です。","reading":"わたしはがくせいです。","en":"I am a student.","zh":"我是学生。"}]}
  ]
}
```

- `id` —— 稳定 id，形如 `vocab:jm<JMdict 序号>`；同时也是进度记录的 id。**必填。**
- `level` —— JLPT 标签，`N5` 到 `N1`，解析时忽略大小写。**必填。**
- `kanji` —— 有汉字写法时的书写形式；纯假名词没有该字段。模型的 `headword` 在有 `kanji` 时取它，否则取
  `reading`。
- `reading` —— 假名读音。**必填。**
- `romaji` —— 可选罗马字；只有手写的种子词带这一字段。
- `pos` —— 取自 `lib/features/content/models/parts_of_speech.dart` 中封闭集合的词性标签。集合之外的标签会
  让内容测试失败。
- `meanings` —— 语言代码到释义列表。`en` 始终存在；`zh` 存在于 N5 与种子词，其余条目由界面回退到英语。`zh_TW` 由 `zh` 生成，`zh` 出现的地方它都出现——见[繁体中文](#繁体中文)。
- `common` —— JMdict 将所选书写形式标为常用时该字段为 true。用于排序建议，绝不用于隐藏条目。
- `aliases` —— 该条目曾经使用过的 id。`vocabById` 会把它们解析到同一个条目。
- `examples` —— 每项为 `{ja, reading?, <语言>: 译文…}`；除 `ja` 与 `reading` 外的每个键都是语言代码。

### 中文释义覆盖文件（`vocab_zh.json`）

```json
{
  "schemaVersion": 1,
  "entries": {
    "vocab:jm1198180": { "zh": ["见面；遇见"], "reviewed": false }
  }
}
```

这是构建输入，之所以随包发布，只是为了让内容测试能把它与实际发布的目录比对。`reviewed` 属于写作状态，绝不
进入 `vocab.json`。

### 语法（`grammar/n5.json`，每级一个文件）

```json
{
  "schemaVersion": 2,
  "level": "N5",
  "points": [
    {
      "id": "grammar:desu",
      "level": "N5",
      "pattern": "〜です",
      "structure": "N + です",
      "match": ["です", "でした"],
      "meaning": { "en": "is; am; are (polite copula)", "zh": "是（敬体判断句）" },
      "explanation": { "en": "…", "zh": "…" },
      "examples": [ { "ja": "これは本です。", "reading": "これはほんです。", "en": "This is a book.", "zh": "这是一本书。" } ]
    }
  ]
}
```

- `id`、`level`、`pattern` 为必填；`structure` 可选。
- `match` —— 可选的字面字符串，用于在句中标出该语法点，解析为 `GrammarPoint.matchForms`。单字助词必须给出
  该字段，因为从其句型推导出的形式几乎会匹配任何句子。
- `meaning` 与 `explanation` 按语言分键；纯字符串按英语处理。两者都在 `zh` 旁带有生成的 `zh_TW`。

### 假名

假名目录编译在代码中（`lib/features/kana/models/kana.dart`），不是资源文件：三张 `const` 表
（`kanaBasicRows`、`kanaVoicedRows`、`kanaYoonRows`），元素为 `KanaEntry(平假名, 片假名, 罗马字)`。每个条目的
进度 id 是 `kana:<平假名>`；用平假名而非罗马字，是因为罗马字不唯一（`ji` 与 `zu` 各出现两次）。
`kanaEntryById` 可把 id 解析回其条目。

### 假名注释（`kana_notes.json`）

```json
{
  "schemaVersion": 1,
  "notes": {
    "kana:し": { "strokes": 1, "hint": { "en": "…", "zh": "…" }, "confusableWith": ["kana:つ"] }
  }
}
```

它是文字说明而非表格数据，因此做成资源文件：只有需要说明的假名才有条目，每个字段都可选，且每个键都必须
指向假名表中确实存在的假名。
### 功能词（`function_words.json`）

句子分析器所读的助词、系动词各形、助动词与形式名词。**不属于目录：** 它描述的是把目录中的词组织起来的语法，没有任何进度追踪它，而且它单独加载——只有句子实验室需要它，与 2 MB 的词汇一起加载会让每个页面为一个可能永远不会打开的页面付出代价。

```json
{ "id": "fw:masendeshita", "surface": "ませんでした", "category": "auxiliary",
  "lemma": "ます", "needs": "masuStem", "forms": ["polite", "negative", "past"],
  "gloss": { "en": "polite negative past", "zh": "敬体否定过去" } }
```

| 字段 | 含义 |
|---|---|
| `id` | `fw:` 加一个 slug。与 `vocab:` id 一样是兼容性约定：已发布的绝不重命名 |
| `surface` | 该词如何书写 |
| `reading` | 与书写不同时的假名读音——提示助词和宾格助词都属于这种情况 |
| `category` | `particle-case`、`particle-binding`、`particle-conjunctive`、`particle-final`、`copula`、`auxiliary`、`formal-noun` |
| `lemma` | 其词族的基本形，使整套活用都归到同一个词 |
| `needs` | 它所接的词干形态；缺失表示接在任何东西之后 |
| `forms` | 它为所关闭的文节贡献的 `InflectionForm` 值 |
| `gloss` | `en` 与 `zh`，两者必需——功能词没有目录条目，因此色块携带自己的含义；`zh_TW` 由 `zh` 生成 |

文件还携带 `sets`：各项检查所读的命名词表（`time-past`、`time-future`、`path-verbs`、`motion-verbs`）以及 `transitivity-pairs`；后者是二元数组而非对象，因为检查会双向查找它们。

对同一表层而言，该表**优先于词汇表**。`test/function_words_test.dart` 强制执行上述规则，正如 `content_catalog_test.dart` 之于目录。

### 解析规则

`LocalizedStrings.fromJson` 接受语言代码到字符串或字符串列表的映射，或视为英语的裸字符串。`resolve(locale)` 按 `lookupOrder(locale)` 依次查找——完整标签、裸语言码、英语——再回退到第一个存在的语言。正是这个顺序让 `zh_TW` 回退到 `zh`：某条目没有繁体字符串时，繁体读者看到的是它的简体文本，而不是直接跳到英语。畸形条目——缺少 id、级别、词条或句型——被跳过而不是让整个文件失败；内容是内置的，因此坏条目是由 `test/content_catalog_test.dart` 捕获的内容 bug，而不是需要保护的用户数据。

### 繁体中文

内容中的每一个 `zh_TW` 字符串都由 `tool/convert_zh_tw.dart` 从旁边的 `zh` 字符串**生成**，使用 OpenCC 的简繁转换词典，并提交到仓库。它绝不手工编辑：`test/content_zh_tw_test.dart` 会把每一条与重新转换的结果比对，因此改了 `zh` 却没有运行工具，以及手工编辑了 `zh_TW`，都会以同样的方式失败。两种情况的修法都是改 `zh` 然后重新运行工具。

转换基于词组，因为一个简体字对应哪个繁体字取决于它所在的词（干净 → 乾淨，但 干部 → 幹部）。中文行文中引用的日语词列在 `tool/content/opencc/preserve.txt` 中并原样保留：讲 来る 的语法说明不能发布成 來る，那在两种语言里都不是词。见 [`features/content-catalog.md`](features/content-catalog.md)。

### 内容 id 是契约

进度记录以其跟踪条目的 id 为键。重命名或移除已发布的 id 会让每个用户在该条目上的进度成为孤儿。可以新增 id；已发布的 id 绝不改变，退役的 id 在目录中保留为别名。JMdict 导入把每个单词 id 改成了 `vocab:jm<序号>`；种子发布时使用的 24 个 id 现在都是别名，并有测试断言它们仍能解析。

## `StudyRecord` 模型

用户学过的每个条目一条记录。记录不携带内容——只有 id、计数器和间隔重复状态——由目录把 id 解析为可读的东西。

### 标识

- `id` — `<kind>:<slug>`，目录条目的 id。同步合并键。
- `kind` — 由 `studyKindOf` 从 id 前缀**推导**：`kana`、`vocab`、`grammar`，或本构建不认识的前缀对应的 `other`。不存储，因此没有任何东西会与 id 脱节，而新版构建以新类别写下的记录仍能加载并合并。

### 计数器

- `correct`、`wrong` — 累计答题次数。`reviews` 是两者之和；`accuracy` 是 `correct / reviews`，首次复习前为 0。
- `streak` — 连续正确次数，答错即重置。

### 间隔重复（SM-2 字段，第三阶段起调度）

- `intervalDays` — 当前间隔，首次复习前为 0。
- `ease` — 难度系数（ease），默认 `2.5`（`defaultStudyEase`）。
- `dueAt` — 下次到期时间，UTC；首次复习前为 null。
- `lastReviewedAt` — UTC；首次复习前为 null。

### 阶段推导

`StudyStage`（`fresh`、`learning`、`mastered`）是**推导**的，不存储：`lastReviewedAt` 设置前为 `fresh`，`intervalDays >= 21`（`masteredIntervalDays`）起为 `mastered`，其间为 `learning`。该阈值只是显示约定，不改变任何调度。

### 时间戳

`createdAt` 和 `modifiedAt` 是 UTC。`copyWith` 除非另有指定，否则把 `modifiedAt` 设为当前时间，这正是让每次编辑对同步合并可见的原因；对不应算作编辑的改动，显式传入现有值。解析时缺少 `modifiedAt` 的记录得到 Unix 纪元，使它输掉每一次合并，而不是意外胜出。

### JSON 形状

```json
{
  "records": [
    {
      "id": "kana:あ",
      "correct": 12,
      "wrong": 2,
      "streak": 5,
      "intervalDays": 6,
      "ease": 2.6,
      "dueAt": "2026-09-08T00:00:00.000Z",
      "lastReviewedAt": "2026-09-02T09:15:00.000Z",
      "createdAt": "2026-08-20T10:00:00.000Z",
      "modifiedAt": "2026-09-02T09:15:00.000Z"
    }
  ]
}
```

可空字段被省略，而不是写成 `null`。

### 学习者档案，以及其他并非条目的记录

有两种记录与其他记录共享这个文件，但并不指向任何目录条目：

- **`profile:me`**——学习者的目标级别、每日上限与学习连续天数。
- **`lesson:<id>`**——一节课的结果，来自第三阶段 M3.3。它的计数器表示通过与未通过而不是作答次数，并且从不参与调度。

`ProgressData.studyRecords` 是其中*确实*被学习的子集，因此「已记录条目数」与复习队列都会跳过上述两种。

档案的负载放在其记录 `extraJson` 的 `profile` 键下：

```json
{
  "id": "profile:me",
  "correct": 0,
  "wrong": 0,
  "streak": 0,
  "intervalDays": 0,
  "ease": 2.5,
  "createdAt": "2026-09-03T12:00:00.000Z",
  "modifiedAt": "2026-09-03T12:00:00.000Z",
  "profile": {
    "targetLevel": "N5",
    "dailyNewLimit": 10,
    "dailyReviewLimit": 100,
    "streakDays": 3,
    "streakLastDate": "2026-09-03"
  }
}
```

**为什么用记录而不是顶层对象。** `ProgressData` 唯一已知的键是 `records`，因此顶层的 `"profile": {...}` 会落进容器的 `extraJson`——那里的合并是逐键并集，**本地永远获胜，且完全没有冲突检测**。作为记录，它获得普通的按记录三方合并，以 `id` 为键、按 `modifiedAt` 比较，真正的分歧会像其他记录一样进入冲突对话框。

**为什么放在 `extraJson` 里而不是新增 `StudyRecord` 字段。** `extraJson` 本就能让未知键完整往返于加载、保存与合并，因此档案不需要改动记录模型、不需要改动新增字段必须触及的那五处，也不需要重新录制黄金记录。旧版本会原封不动地把整个负载带过去，这正是这一模式存在的意义。

`streakLastDate` 是**本地**日历日期而不是 UTC：学习连续天数是按学习者自己的天数计的，用时刻比较会让所有深夜学习的人断掉连续记录。这是对 UTC 规则唯一一处刻意的例外，而且它是日期而不是时间戳，因此根本不存在跨时区比较的问题。

连续天数**每天写一次**，而不是每答一题写一次——同一天的第二次作答不会改动该记录。这正是两台设备在同一天使用时档案冲突仍然稀少的原因。设置写入会沿用已存储的连续天数，而不是采用调用方给出的值，因此修改每日上限不会清掉学习者已经挣得的进度。

### 兼容性：未知 JSON 字段保留（`extraJson`）

`StudyRecord` 和 `ProgressData`（顶层 `{records: [...]}` 容器）各带一个 `extraJson` 映射，保存当前应用版本不认识的任何 JSON 键。模式如下：

- `fromJson()` 把 `extraJson` 计算为「原始 JSON 中的每个键减去该类型的已知键」，并把**可空**字段中解析失败的值（无法解析的 `dueAt` 或 `lastReviewedAt`）放回 `extraJson`，而不是丢弃。解析失败的计数器或 SRS 字段取默认值并以该默认值写回——有类型的值和原始值不能共用一个键。
- `toJson()` 从 `extraJson` 的副本开始，再把已知字段覆盖在上面，因此未知键原样随行，且永远不会遮蔽真实字段。可空字段只在有值时写入，因此其键下保留的原始值得以保存。
- `withPreservedUnknownJson(sources)` 合并多个候选来源（同步合并时同一记录的本地副本与远程副本）的 `extraJson`，使*本*版本应用不认识、但任一侧存在的字段在合并后幸存。嵌套映射逐键合并。

这正是让旧版应用在正常保存、导入或同步合并时不会静默删除新版引入字段的机制。

### JSON 美化输出

凡是写入磁盘的 JSON——数据文件、同步上传、备份——都使用 `JsonEncoder.withIndent('  ')`。这不是装饰：共享同步引擎写入合并后 JSON 的格式与本地 `NihongoStorage` 保存的格式相同，因此未改动的文件在下次同步时命中原始字符串相等的快速路径，而不是触发多余的重新上传。

## 持久化数据清单

默认应用数据目录是 `<documents>/MyNihongo`——所有平台上的平台应用文档目录，没有按平台分支。自定义存储路径保存在 `storage_config.json` 中；更改路径会迁移文件夹里除该配置文件外的一切。设置页仅在桌面端显示解析出的路径，见 [`platform-notes.md`](platform-notes.md) 中的 `platform_capabilities.dart`。

| 数据 | 文件 | 同步 | 说明 |
| --- | --- | --- | --- |
| 学习进度 | `nihongo_progress.json` | 是 | 按 `id` 和 `modifiedAt` 逐记录；保留未知字段 |
| 主题模式 | `storage_config.json` | 否 | 设备特定偏好（`themeMode`：`light`/`dark`；缺失表示跟随系统） |
| 语言 | `storage_config.json` | 否 | 设备特定偏好（`locale`：`en`/`zh`/`zh_TW`；缺失表示跟随系统） |
| 存储路径覆盖 | `storage_config.json` | 否 | 设备特定路径（`storagePath`） |
| 自动备份启用 | `storage_config.json` | 否 | 设备特定配置（`autoBackupEnabled`） |
| 备份保留天数 | `storage_config.json` | 否 | 设备特定配置（`backupRetentionDays`） |
| 上次标签页 | `storage_config.json` | 否 | 应用重新打开时所在的标签页（`lastTab`） |
| 词汇等级筛选 | `storage_config.json` | 否 | JLPT 标签，缺失表示全部等级（`vocabLevel`） |
| 语法等级筛选 | `storage_config.json` | 否 | JLPT 标签，缺失表示全部等级（`grammarLevel`） |
| 假名字体 | `storage_config.json` | 否 | `katakana`，缺失表示平假名（`kanaScript`） |
| 参考列表列数 | `storage_config.json` | 否 | 1-4，缺失表示自动（`referenceListColumns`） |
| 朗读速度 | `storage_config.json` | 否 | 0.6-1.2，缺失表示 1.0（`ttsRate`） |
| 选定的日语语音 | `storage_config.json` | 否 | 引擎的语音名，缺失表示可用的最佳日语语音（`ttsVoice`） |
| 选定的语音引擎 | `storage_config.json` | 否 | 引擎包名，缺失表示系统默认引擎（`ttsEngine`） |
| 网络语音识别 | `storage_config.json` | 否 | 仅在开启时为 `true`；缺失表示仅离线（`speechNetworkFallback`） |
| 端侧 AI 辅助 | `storage_config.json` | 否 | 仅在开启时为 `true`；缺失表示关闭（`aiAssistEnabled`） |
| WebDAV 配置 | `webdav_config.json` | 否 | 仅本地密钥 / 配置 |
| 同步基线快照 | `.sync_base/nihongo_progress.json` | 否 | 本地合并跟踪 |
| 上传锁记录 | `.sync_base/upload_lock.json` | 否 | 检测中途中断的上传 |
| 本地备份 | `backups/backup_*.json` | 否 | 本地恢复；v2 bundle |
| 备份图像 blob | `backups/blobs/` | 否 | 共享格式中存在；此处始终为空——没有图像 |

### `storage_config.json`

保存上表中不属于 WebDAV 配置的每项设备本地偏好。本文件不做任何同步——它刻意是设备特定的。键在设回默认值时被移除而不是写入，因此全新安装和重置后的安装产生同样的文件。

### `webdav_config.json`

WebDAV 连接细节和同步偏好（服务器 URL、凭据、远程路径、自动同步开关）。本身永不同步。默认远程路径是 `/MyNihongo`。见 [`sync.md`](sync.md)。

### `.sync_base/`

保存 `.sync_base/nihongo_progress.json`——下次同步时用作三方合并基线的上次已合并快照——以及 `.sync_base/upload_lock.json`，让下次启动能检测到中途中断的上传。

### `backups/`

`backups/backup_*.json` — 共享 v2 格式的备份 bundle，见 [`backup-restore.md`](backup-restore.md)。

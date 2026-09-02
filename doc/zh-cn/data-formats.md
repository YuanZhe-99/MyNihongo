# 数据格式

本页描述内置内容的 schema、`StudyRecord` 进度模型（`lib/features/progress/models/study_record.dart`）、凡遇到未知 JSON 时使用的向前兼容模式，以及应用持久化到磁盘的完整文件清单。进度记录如何跨设备合并见 [`sync.md`](sync.md)。

## 内容目录（只读，内置）

内容以 JSON 资源的形式放在 `assets/content/` 下，由 `ContentRepository` 每次运行解析一次成 `ContentCatalog`。它既不同步也不备份——它是应用的数据，不是用户的——并通过 `schemaVersion` 随构建版本化。

### 单词（`vocab_seed.json`）

```json
{
  "schemaVersion": 1,
  "source": "seed",
  "license": "…",
  "entries": [
    {
      "id": "vocab:watashi",
      "level": "N5",
      "kanji": "私",
      "reading": "わたし",
      "romaji": "watashi",
      "pos": ["pronoun"],
      "meanings": { "en": ["I", "me"], "zh": ["我"] },
      "examples": [
        { "ja": "私は学生です。", "reading": "わたしはがくせいです。", "en": "I am a student.", "zh": "我是学生。" }
      ]
    }
  ]
}
```

- `id` — 稳定，`vocab:<slug>`；也是进度记录 id。**必填。**
- `level` — JLPT 标签，`N5` 到 `N1`，大小写不敏感地解析。**必填。**
- `kanji` — 有汉字时的书写形式；纯假名词省略。模型的 `headword` 在有 `kanji` 时取它，否则取 `reading`。
- `reading` — 假名读音。**必填。**
- `romaji` — 可选的罗马音。
- `pos` — 作为内容字符串的词性标签（`noun`、`verb-godan`、`verb-ichidan`、`verb-irregular`、`i-adjective`、`na-adjective`、`pronoun`、`adverb`、`expression`、`transitive`、`intransitive`）。
- `meanings` — 语言代码到释义列表。
- `examples` — 每条 `{ja, reading?, <lang>: translation…}`；除 `ja` 和 `reading` 以外的每个键都是一种语言。

### 语法（`grammar_seed.json`）

```json
{
  "schemaVersion": 1,
  "points": [
    {
      "id": "grammar:desu",
      "level": "N5",
      "pattern": "〜です",
      "structure": "N + です",
      "meaning": { "en": "is; am; are (polite copula)", "zh": "是（敬体判断句）" },
      "explanation": { "en": "…", "zh": "…" },
      "examples": [ { "ja": "これは本です。", "reading": "これはほんです。", "en": "This is a book.", "zh": "这是一本书。" } ]
    }
  ]
}
```

- `id`、`level`、`pattern` 必填；`structure` 可选。
- `meaning` 和 `explanation` 按语言分键；裸字符串视为英语。

### 假名

假名目录是编译进应用的（`lib/features/kana/models/kana.dart`），不是资源：三张 `const` 表（`kanaBasicRows`、`kanaVoicedRows`、`kanaYoonRows`），每格是 `KanaEntry(hiragana, katakana, romaji)`。每个条目的进度 id 是 `kana:<hiragana>`；用平假名而不是罗马音，因为罗马音不唯一（`ji` 和 `zu` 各出现两次）。

### 解析规则

`LocalizedStrings.fromJson` 接受语言代码到字符串或字符串列表的映射，或视为英语的裸字符串。`resolve(locale)` 返回该语言的内容，其次英语，再次第一个存在的语言。畸形条目——缺少 id、级别、词条或句型——被跳过而不是让整个文件失败；内容是内置的，因此坏条目是由 `test/content_catalog_test.dart` 捕获的内容 bug，而不是需要保护的用户数据。

### 内容 id 是契约

进度记录以其跟踪条目的 id 为键。重命名或移除已发布的 id 会让每个用户在该条目上的进度成为孤儿。可以新增 id；已发布的 id 绝不改变，退役的 id 在目录中保留为别名（别名机制随 JMdict 导入到来，`PLAN.md` M1.2）。

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

### 兼容性：未知 JSON 字段保留（`extraJson`）

`StudyRecord` 和 `ProgressData`（顶层 `{records: [...]}` 容器）各带一个 `extraJson` 映射，保存当前应用版本不认识的任何 JSON 键。模式如下：

- `fromJson()` 把 `extraJson` 计算为「原始 JSON 中的每个键减去该类型的已知键」，并把**可空**字段中解析失败的值（无法解析的 `dueAt` 或 `lastReviewedAt`）放回 `extraJson`，而不是丢弃。解析失败的计数器或 SRS 字段取默认值并以该默认值写回——有类型的值和原始值不能共用一个键。
- `toJson()` 从 `extraJson` 的副本开始，再把已知字段覆盖在上面，因此未知键原样随行，且永远不会遮蔽真实字段。可空字段只在有值时写入，因此其键下保留的原始值得以保存。
- `withPreservedUnknownJson(sources)` 合并多个候选来源（同步合并时同一记录的本地副本与远程副本）的 `extraJson`，使*本*版本应用不认识、但任一侧存在的字段在合并后幸存。嵌套映射逐键合并。

这正是让旧版应用在正常保存、导入或同步合并时不会静默删除新版引入字段的机制。

### JSON 美化输出

凡是写入磁盘的 JSON——数据文件、同步上传、备份——都使用 `JsonEncoder.withIndent('  ')`。这不是装饰：共享同步引擎写入合并后 JSON 的格式与本地 `NihongoStorage` 保存的格式相同，因此未改动的文件在下次同步时命中原始字符串相等的快速路径，而不是触发多余的重新上传。

## 持久化数据清单

默认应用数据目录是 `<documents>/MyNihongo`——Android 上的平台应用文档目录。自定义存储路径保存在 `storage_config.json` 中；更改路径会迁移文件夹里除该配置文件外的一切。

| 数据 | 文件 | 同步 | 说明 |
| --- | --- | --- | --- |
| 学习进度 | `nihongo_progress.json` | 是 | 按 `id` 和 `modifiedAt` 逐记录；保留未知字段 |
| 主题模式 | `storage_config.json` | 否 | 设备特定偏好（`themeMode`：`light`/`dark`；缺失表示跟随系统） |
| 语言 | `storage_config.json` | 否 | 设备特定偏好（`locale`：`en`/`zh`；缺失表示跟随系统） |
| 存储路径覆盖 | `storage_config.json` | 否 | 设备特定路径（`storagePath`） |
| 自动备份启用 | `storage_config.json` | 否 | 设备特定配置（`autoBackupEnabled`） |
| 备份保留天数 | `storage_config.json` | 否 | 设备特定配置（`backupRetentionDays`） |
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

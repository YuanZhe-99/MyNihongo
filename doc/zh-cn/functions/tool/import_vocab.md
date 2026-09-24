# tool/import_vocab.dart

从 JMdict 与 JLPT 词表离线重新生成 `assets/content/vocab.json` 的命令，并叠加中文释义覆盖文件（`vocab_zh.json`）、例句覆盖文件（`vocab_examples.json`）与日语释义覆盖文件（`vocab_ja.json`）。全部文件读写都在这里；规则位于
[`src/vocab_import_core.md`](src/vocab_import_core.md)，因此无需 117 MB 的词典即可做单元测试。见
[`../../features/content-catalog.md`](../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 从 JMdict 与 JLPT 词表重新生成单词资源。 |
| `main` | 顶层函数 | A | 执行导入。 |
| `_parseArgs` | 顶层函数 | B | 读取命令行参数。 |
| `_findJmdict` | 顶层函数 | B | 按文件名前缀查找解包后的 JMdict JSON。 |
| `_readOverlay` | 顶层函数 | B | 解析按目录 id 分键的覆盖文件——中文覆盖文件与日语释义覆盖文件都用它。 |
| `_reportOrphans` | 顶层函数 | B | 在 stderr 上报告每一条指向目录中已不存在 id 的覆盖行；只报告，绝不悄悄丢弃。 |
| `_applyOverlayOnly` | 顶层函数 | B | 把覆盖文件（中文释义、经 `applyJapaneseOverlay` 的日语释义、例句）重新应用到已有目录。 |
| `_write` | 顶层函数 | B | 写出目录文件。 |

### `main`

- **Purpose:** 执行导入。
- **Inputs:** `args` —— `--data`、`--out`、`--overlay`、`--overlay-ja`、`--examples`、`--seed`、
  `--overlay-only`。`--overlay-ja` 默认为 `assets/content/vocab_ja.json`。
- **Returns:** 无；设置退出码。
- **Side effects:** 读取词典、五份词表、种子与三个覆盖文件（中文释义、日语释义、例句）；重写单词资源。
- **Algorithm:** 先读取覆盖文件，然后要么只重新应用它们，要么执行完整导入：按序号为词典建索引、解析每份词表、
  合入种子，应用例句、再应用日语释义（`applyJapaneseOverlay`，用 `_reportOrphans` 报告孤立的行），最后写出。
  词典缺失，或词表引用了词典中不存在的序号时，以退出码 1 结束，而不是写出有缺口的目录。缺失的覆盖文件按空覆盖处理。
- **Usage:** `dart run tool/import_vocab.dart`；加 `--overlay-only` 可在不下载词典的情况下重新应用覆盖文件。
- **Notes:** 不写入时间戳且条目有序，因此输入未变时重跑会留下空的 `git diff` —— 正是这一性质让重跑值得。
  文件头为便于查阅采用缩进格式，每个条目占一行紧凑输出，因此 2 MB 的文件仍能给出可读的 diff。日语覆盖文件在**两种**
  模式下都会应用：完整导入会从 JMdict 重建每一个条目，所以若只在 `--overlay-only` 中应用它，下一次 JMdict 刷新就会删掉
  每一条日语释义，而 `vocab_ja.json` 里仍保存着它们。

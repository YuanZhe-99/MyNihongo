# tool/import_vocab.dart

从 JMdict 与 JLPT 词表离线重新生成 `assets/content/vocab.json` 的命令。全部文件读写都在这里；规则位于
[`src/vocab_import_core.md`](src/vocab_import_core.md)，因此无需 117 MB 的词典即可做单元测试。见
[`../../features/content-catalog.md`](../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 从 JMdict 与 JLPT 词表重新生成单词资源。 |
| `main` | 顶层函数 | A | 执行导入。 |
| `_parseArgs` | 顶层函数 | B | 读取命令行参数。 |
| `_findJmdict` | 顶层函数 | B | 按文件名前缀查找解包后的 JMdict JSON。 |
| `_readOverlay` | 顶层函数 | B | 解析中文覆盖文件。 |
| `_applyOverlayOnly` | 顶层函数 | B | 把覆盖文件重新应用到已有目录。 |
| `_write` | 顶层函数 | B | 写出目录文件。 |

### `main`

- **Purpose:** 执行导入。
- **Inputs:** `args` —— `--data`、`--out`、`--overlay`、`--seed`、`--overlay-only`。
- **Returns:** 无；设置退出码。
- **Side effects:** 读取词典、五份词表、种子与覆盖文件；重写单词资源。
- **Algorithm:** 先读取覆盖文件，然后要么只重新应用它，要么执行完整导入：按序号为词典建索引、解析每份词表、
  合入种子，最后写出。词典缺失，或词表引用了词典中不存在的序号时，以退出码 1 结束，而不是写出有缺口的目录。
- **Usage:** `dart run tool/import_vocab.dart`；加 `--overlay-only` 可在不下载词典的情况下重新应用中文。
- **Notes:** 不写入时间戳且条目有序，因此输入未变时重跑会留下空的 `git diff` —— 正是这一性质让重跑值得。
  文件头为便于查阅采用缩进格式，每个条目占一行紧凑输出，因此 2 MB 的文件仍能给出可读的 diff。

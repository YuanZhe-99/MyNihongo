# tool/merge_drafts.dart

把检查过的草稿批次并入已发布的内容文件。

创作循环的最后一步，而且**刻意做得最笨**：关于一份草稿的每一个判断，都已经由
`test/content_gate_test.dart` 在这一步之前做完了。它做的只是合并、排序和写入，好让一个通过了门禁的
批次无论运行多少次都逐字节一样地落地。

```
dart run tool/merge_drafts.dart gloss    tool/content/drafts/gloss/n4-*.json
dart run tool/merge_drafts.dart examples tool/content/drafts/examples/n5-*.json
dart run tool/merge_drafts.dart grammar --level N4 tool/content/drafts/grammar/n4-*.json
dart run tool/merge_drafts.dart units   --level N5 tool/content/drafts/units/n5.json
dart run tool/merge_drafts.dart drills  --level N5 --section reading tool/content/drafts/drills/n5-reading-01.json
dart run tool/merge_drafts.dart gloss-ja tool/content/drafts/gloss-ja/n5-*.json
dart run tool/merge_drafts.dart ja      tool/content/drafts/ja/grammar/n5-*.json
```

之后，对三个词汇覆盖层（中文释义、例句、日语释义）：
`dart run tool/import_vocab.dart --overlay-only && dart run tool/convert_zh_tw.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| library header | library doc | B | 把检查过的草稿批次并入已发布的内容文件。 |
| `_encoder` | 常量 | B | 按 `AGENTS.md`，每个内容文件都用的那个编码器。 |
| `_source` | 常量 | B | 模型创作的文件对自己来历的声明。 |
| `main` | 函数 | B | 解析参数并按种类分派。 |
| `_rows` | 函数 | B | 按给出的顺序读取每个草稿文件的行。 |
| `_mergeGloss` | 函数 | B | 把中文释义并入词汇覆盖层。 |
| `_mergeExamples` | 函数 | B | 把例句并入例句覆盖层。 |
| `_mergeGrammar` | 函数 | B | 把语法点并入某级别的语法文件。 |
| `_mergeUnits` | 函数 | B | 替换某级别的单元，因为一个级别是整体规划的。 |
| [`_mergeDrills`](#drills) | 函数 | A | 把练习题与文章追加到某级别某部分的文件里。 |
| `_stripTw`、`_stripTwMap` | 函数 | B | 丢掉草稿带来的任何 `zh_TW`；它是生成的，从不由人撰写。 |
| `_jaSource` | 常量 | B | 手写文件在 `ja` 流写入之后所声明的来历：`en` 与 `zh` 为手写，`ja` 为模型创作且未经审阅。 |
| `_mergeGlossJa` | 函数 | B | 把日语释义批次并入 `vocab_ja.json`（不存在则创建）：`_mergeGloss` 的孪生——已有的行从不覆盖，按 id 排序，`reviewed: false`，读音与释义并列、每个义项一个。 |
| `_putJa` | 函数 | B | 向一个本地化字段添加一个 `ja` 字符串，从不覆盖，并追加在已有键之后；写入了东西时返回 1。 |
| `_withJaSource` | 函数 | B | 在 `schemaVersion` 之后紧接着设置 `source`，把手写文件标记为现在带有模型创作的 `ja`；模型创作的文件保持原样。 |
| [`_mergeJa`](#mergeja) | 函数 | A | 把 `ja` 批次并入它们所属的已发布语法、课程、练习题或功能词文件。 |

## 文档

### `void _mergeDrills(String assets, String level, String section, List<String> drafts)` <a id="drills"></a>

- **种类：** 函数
- **用途：** 把练习题与文章追加到某级别某部分的文件里。
- **输入：** 资产路径、`level`、`section`，以及草稿路径。
- **返回：** 无；遇到重复 id 时以非零码退出。
- **副作用：** 重写 `assets/content/drills/<level>-<section>.json`。
- **算法：** 读入已发布的文件（如果存在），追加每份草稿的文章与题目，剥掉任何 `zh_TW`，然后连同
  `schemaVersion`、`source`、`license`、`level` 与 `section` 头部，用 `_encoder` 把整个文件写回。
- **使用：** 在一个练习题批次通过内容门禁之后。
- **注意：** **是追加，而且重复 id 是致命的。** 与释义和例句的合并不同——那两者是把一个值覆盖到已经
  存在的词条上——一道练习题每次都是一个新东西。默默替换掉它，意味着重跑一次批次会悄悄丢掉第一次的成
  果；而重复的 id 会破坏无重复采样器，因为它的一切都以 id 为键。退出是正确的反应，因为要修的地方在
  草稿里，不在这里。

  无论草稿怎么写，`zh_TW` 都会被剥掉。内容里的繁体中文由 `convert_zh_tw.dart` 从旁边的简体生成，从
  不由人撰写，所以一个产出了繁体的代理产出的是下一次运行就会被覆盖的东西——而把它留下来，会让
  `content_zh_tw_test.dart` 在一段没有人有意写下的文字上失败。

  `source` 字段是写入的，不是抄来的：每个发布的练习题文件都用自己的文字写着
  `model-authored (Claude), unreviewed`，所以读资产的人不必找到这份文档就能知道它从哪里来。

### `void _mergeJa(String assets, List<String> drafts)` <a id="mergeja"></a>

- **种类：** 函数
- **用途：** 把 `ja` 批次并入它们所属的已发布文件。
- **输入：** 资产路径与草稿路径；每份草稿都写明自己的 `target` 与 `level`。
- **返回：** 无；各草稿的目标或级别不一致、目标未知或 id 未知时，以非零码退出。
- **副作用：** 重写一个语法、课程或功能词文件，或该级别的练习题文件。
- **算法：** 要求所有草稿共用同一个 `target` 与同一个 `level`。加载该目标的已发布文件——
  `grammar/<level>.json`、`function_words.json`、`lessons/<level>.json`，或每一个 `drills/<level>-*.json`——
  并按 id 为其记录建索引。对草稿的每一行，就该目标携带的每个字段调用 `_putJa`：语法点的 `meaning` 与
  `explanation`（写入了含义时，再加上取自该行 `meaningReading` 的 `meaningJaReading`）、功能词的 `gloss`、
  单元的 `title`、`writingPrompt`、情景标题以及每道题的 `prompt` 与 `explanation`、练习题的 `prompt` 与
  `explanation`。收集文件中没有的任何 id。只要有一个，就什么都不写；否则用 `_encoder` 把每个已加载的文件
  写回，并用 `_withJaSource` 标记 `source`。
- **使用：** 在一个 `ja` 批次通过内容门禁之后。之后没有导入或转换步骤：文本直接落进已发布的文件。
- **注意：** **未知 id 是致命的，而且什么都不会写入**：点名了文件中没有的题目的草稿，是针对错误文件写成的
  草稿。已有的 `ja` 从不被覆盖，除了 `ja`（以及语法点的 `meaningJaReading`）之外的键一概不动。草稿行中的
  `zh_TW` 会被忽略——门禁禁止它——而已发布的块是被追加而不是被重写，所以 `{en, zh, zh_TW}` 变成
  `{en, zh, zh_TW, ja}`，下一次 `convert_zh_tw.dart` 无事可做。`source` 那一行会被重写，因为一个原本手写的
  文件现在带有模型创作的文字，读资产的人应当从文件本身得知这一点。

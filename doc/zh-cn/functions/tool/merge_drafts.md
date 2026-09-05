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
```

之后，对两个词汇覆盖层：
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

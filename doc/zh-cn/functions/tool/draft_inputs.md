# tool/draft_inputs.dart

写出内容创作代理据以工作的输入批次。

创作代理拿到的是一个小 JSON 文件，写回的也是一个小 JSON 文件。它从不读那个 1.5 MB 的目录，从不运行
构建，也从不需要被告知哪些词已经做完了——**批次本身就是「还缺什么」的清单**，所以两个代理同时工作不
会撞车，而合并之后再跑一次只会生成更少的批次。

```
dart run tool/draft_inputs.dart gloss --level N4 --batch 300
dart run tool/draft_inputs.dart examples --level N5 --batch 150
dart run tool/draft_inputs.dart grammar-inventory --level N4
dart run tool/draft_inputs.dart units --level N5
dart run tool/draft_inputs.dart drills --level N5 --section reading
```

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| library header | library doc | B | 写出创作代理据以工作的输入批次。 |
| `draftRoot` | 常量 | B | 批次写到哪里；被 git 忽略，提交前清空。 |
| `main` | 函数 | B | 解析参数、加载目录，并按种类分派。 |
| `_glossRows` | 函数 | B | 列出某级别里还没有中文释义的词。 |
| `_exampleRows` | 函数 | B | 列出某级别里还没有例句的词。 |
| `_write` | 函数 | B | 把行切成批次，每批写一个输入文件。 |
| `_inventory` | 函数 | B | 写出某级别的语法清单。 |
| `_units` | 函数 | B | 写出整个级别的教学大纲，因为一个级别是整体规划的。 |
| `drillTypeSections` | 常量 | B | 每个大问属于哪个部分，供练习题批次使用。 |
| `drillPassageShapes` | 常量 | B | 每个阅读与听力大问想要多长的文章。 |
| [`_drills`](#drills) | 函数 | A | 写出一个练习题批次以及随附的资源文件。 |

## 文档

### `void _drills(String out, String level, String section, String assets, List<Map<String, Object?>> entries, int target, int batch)` <a id="drills"></a>

- **种类：** 函数
- **用途：** 写出一个练习题批次以及随附的资源文件。
- **输入：** 输出根目录、`level` 与 `section`、资产路径、目录 `entries`、官方数量的 `target` 倍数，
  以及批次大小。
- **返回：** 无。
- **副作用：** 在 `draftRoot` 下写出一个 `.input.json` 和一个 `.resources.json`。
- **算法：** 从 `structure.json` 读出该级别每个大问的数量，减去已发布文件里已有的，写出按题型的缺
  口。资源文件另写：该级别的词汇与语法、已被占用的 id，以及这个部分里各大问的文章形状。
- **使用：** 手工运行，之后再派一个创作代理去做这个批次。
- **注意：** **「缺什么」是算出来的，不是声明的。** 缺口等于 `structure.json` 的数量乘以目标倍数再
  减去已经发布的，所以合并之后重跑一次要的正好是还差的部分，而对一个已经完成的级别运行则什么也不产
  生，而不是产生重复。

  资源放在与输入**分开的文件**里。输入是要求代理产出的东西；资源是它可以使用的东西。把两者分开，才
  能让输入小到一眼看得完，而它背后的词汇表可以长达几百条。

  已被占用的 id 会交出去，好让新批次从上一批停下的地方接着编号。`merge_drafts.dart` 把重复 id 视为
  致命错误，所以这里是那条规则便宜的一半，而合并才是执行的那一半。

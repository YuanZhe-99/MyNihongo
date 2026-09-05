# lib/features/drills/services/drill_repository.dart

加载一份 JLPT 卷子取题所依据的练习题文件，以及说明一份卷子由什么构成的结构文件。

它与 `ContentRepository` 分开，理由和 `LessonRepository` 一样：目录是每个页面都需要的东西，值得为它开一个 isolate；而一个练习题文件只是某一级别的某一个部分，只在有人打开那个部分时才读，并且某个级别还没有文件是一种普通状态，不是失败。

使用方：`jlpt_practice_card.dart`（`drillLevelProvider`）、`quiz_page.dart`（`drillLevelProvider`、`jlptStructureProvider`）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `DrillRepository` | 类 | B | 加载卷子取题所依据的练习题文件。 |
| `DrillRepository._` | 构造函数 | B | 阻止构造；所有成员都是静态的。 |
| `assetFor` | 静态方法 | B | 给出某一级别的某个部分所在的资源名：`assets/content/drills/<level>-<section>.json`。 |
| [`load`](#load) | 静态方法 | A | 加载某一级别的一个部分，文件缺失时视为空的部分。 |
| `loadStructure` | 静态方法 | B | 加载 `structure.json`；加载不出来时为 `JlptStructure.empty`。 |
| [`_exists`](#exists) | 静态方法 | A | 说明某个资源是否真的被打包进来了。 |
| `drillFileProvider` | provider | B | 某一级别的一个部分，按需加载，以级别与部分之组为族。 |
| `drillLevelProvider` | provider | B | 某一级别的全部部分，一起加载。 |
| `jlptStructureProvider` | provider | B | JLPT 自身的题目构成与计时。 |

## 文档

### `static Future<DrillFile> load(JlptLevel level, DrillSection section, [AssetBundle? bundle])` <a id="load"></a>

- **种类：** 静态方法
- **用途：** 加载某一级别的一个部分。
- **输入：** `level`、`section`，以及供测试使用的 `bundle`。
- **返回：** `Future<DrillFile>`——该部分没有文件时为空文件。
- **副作用：** 读取一个资源。
- **算法：** 先问清单该资源是否被打包；没有就为该级别与部分返回一个空文件。否则加载字符串并交给 `DrillFile.fromJson`，中途有任何抛出就同样返回那个空文件。
- **使用：** `drillFileProvider`、`drillLevelProvider`。
- **说明：** 文件缺失是一个空的部分，不是错误。级别是一个版本一个版本写出来的，所以一次只发布了 N5 而没有 N4 的构建是正常状态，Learn 卡片会如实说明，而不是显示一个失败。`assetFor` 是平铺的——`n5-reading.json`，不是 `n5/reading.json`——这样 `pubspec.yaml` 只需要一行资源声明而不是每个级别一行，`tool/convert_zh_tw.dart` 与 `content_zh_tw_test.dart` 里那两份硬编码的目录列表也只多一个条目而不是五个。

### `static Future<bool> _exists(String asset, AssetBundle bundle)` <a id="exists"></a>

- **种类：** 静态方法
- **用途：** 说明某个资源是否真的被打包进来了。
- **输入：** `asset` 路径，以及要询问的 `bundle`。
- **返回：** `Future<bool>`。
- **副作用：** 读取资源清单，bundle 会缓存它。
- **算法：** 加载清单并在其中查找该路径；如果清单本身加载不出来则返回 true。
- **使用：** `load`，在每一次尝试之前。
- **说明：** 这是去问清单，而不是直接尝试再捕获异常。在各级别还在陆续写出来的过程中，二十个级别—部分组合里的大多数缺失资源都是**正常**状态，而 `loadString` 遇到一个缺失资源时并不只是抛出——它会先报告一个 Flutter 错误，即使抛出本身已被处理，控件测试仍会因此失败。清单完全加载不出来时按「先试试看」处理，这样在无法使用清单的平台上会退化成旧行为，而不是把每个级别都报告成尚未写出。

# lib/features/quiz/widgets/grammar_point_link.dart

测验题点明它背后语法点的两个位置：生成的题在作答之前于题面上方点明，以及任何语法题在答完之后给出一个通向该语法点页面的纸片按钮。

两者都通过 `contentCatalogProvider` 解析 `QuizQuestion.itemId`，若它不是目录认识的语法点就什么都不画——这与测验其余部分对解析不了的 id 所保持的沉默是同一种。

使用方：`quiz_runner.dart`。

那一行**只**在生成的题上显示。在自己编写的题里，语法点往往就是答案——「这句用了哪个语法点？」的四个选项正是四个语法点——所以在上面点明它等于把答案送出去。而在生成的题里，语法点是题目的前提：模型被要求考的是 〜ね，不告诉学习者这一点，就是在要求他连题目带答案一起猜。纸片按钮则在每一道语法题上显示，答对答错都显示，因为到那时答案已经在屏幕上，语法点不再是秘密。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `GrammarPointLine` | 类 | B | 在题面上方点明生成的题在考哪个语法点。 |
| `GrammarPointLine.new` | 构造函数 | B | 保存目录 id。 |
| `GrammarPointLine.build` | 方法 | B | 解析语法点，写出它的句式和意思。 |
| `GrammarPointChip` | 类 | B | 答完之后，打开这道题所依据的语法点。 |
| `GrammarPointChip.new` | 构造函数 | B | 保存目录 id。 |
| `GrammarPointChip.build` | 方法 | B | 解析语法点并提供 `showGrammarDetailSheet`。 |

## 文档

两个控件接收的都是 id 而不是 `GrammarPoint`，因为语言环境在控件这一侧，而语法点的意思必须对着它来解析。两者都不自己去读目录：`contentCatalogProvider` 在任何测验运行的地方都已经加载过了，所以这次查找不花任何代价，而抢在它前面的一帧只会什么都不画。

纸片按钮复用了 `lib/shared/widgets/content_sheets.dart` 里的 `showGrammarDetailSheet`，也就是参考标签页和句子实验室打开的同一个面板。测验此前从未通向它所取材的目录：答错之后学习者拿到一段解释，却没有任何办法走到这段解释所来自的那一页。

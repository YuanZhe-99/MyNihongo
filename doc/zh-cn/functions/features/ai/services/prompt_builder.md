# lib/features/ai/services/prompt_builder.dart

带版本号的提示词模板，以及把确定性分析变成送给端侧模型的文本的构建器。

提示词是内容资产而不是字符串字面量，理由与其他每个内容文件相同：改变模型被问的内容就改变了学习者读到的内容，它应当以数据 diff 的形式被审阅。它们**不在** ARB 文件里——这里的内容永远不会被渲染。

使用方：`aicore_sentence_enhancer.dart`、`sentence_analyzer.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `PromptTemplates` | 类 | B | 已加载的模板。 |
| `PromptTemplates.empty` | 常量 | B | 资产无法读取时使用的空集合。 |
| `PromptTemplates.limit` | 方法 | B | 按名查一个上限，带回退值。 |
| `PromptTemplates.fromJson` | 工厂 | B | 宽容地解析模板文件。 |
| `PromptTask` | 类 | B | 某个任务在某种语言下的指令与要求。 |
| `PromptBuilder` | 类 | B | 构建送给模型的文本。 |
| [`forIssue`](#forissue) | 方法 | A | 针对某个被标记问题的提示词。 |
| `forSentence` | 方法 | B | 针对整个句子的提示词。 |
| [`forProofreading`](#forproofreading) | 方法 | A | 为校对模型准备一个句子。 |
| [`_build`](#build) | 方法 | A | 拼装一个提示词。 |
| `_words` | 方法 | B | 把分词结果渲染成一行。 |
| [`_grammar`](#grammar) | 方法 | A | 引用目录自身对每个匹配语法点的说明。 |
| `_span` | 方法 | B | 引用句子中的一段。 |
| `_cap` | 静态方法 | B | 把字符串截到最大长度。 |
| `loadPromptTemplates` | 函数 | B | 读取并解析模板资产。 |

## 文档

### `String? forIssue(SentenceAnalysis, Issue, String message, ContentCatalog?, Locale locale)` <a id="forissue"></a>

- **种类：** 方法
- **用途：** 就检查标记出的某一处向模型发问。
- **输入：** 分析结果、问题、**它已经措好辞的说明**、目录，以及界面 locale。
- **返回：** `String?` —— 模板缺失时为 null。
- **副作用：** 无。
- **算法：** 以引用的片段与该说明作为 note，转交 `_build`。
- **使用：** `AiCoreSentenceEnhancer.explain`。
- **说明：** `message` 由 widget 传入而不是在这里另行推导，这是刻意的：它就是学习者屏幕上的那句话。一个把问题换了说法的提示词会得到一个他们看不见的问题的答案，而这个答案就摆在他们看得见的那句问题正下方。

### `String? forProofreading(String sentence)` <a id="forproofreading"></a>

- **种类：** 方法
- **用途：** 判断一个句子能否被校对，并把它交出去。
- **输入：** `sentence`。
- **返回：** `String?` —— 为空或过长时为 null。
- **副作用：** 无。
- **算法：** 去空白，空则拒绝，超过字符上限则拒绝。
- **使用：** `AiCoreSentenceEnhancer.suggestCorrection`。
- **说明：** 过长是**拒绝，而不是截断**。校对半句话等于对学习者从未写过的句子提出修改建议，这比不提建议更糟。上限以字符计，对应 256 token 的 API 限制，取值偏低是因为日语每字符对应的 token 数比英语多。

### `String? _build({required String task, ...})` <a id="build"></a>

- **种类：** 方法
- **用途：** 从模板与分析结果拼装一个提示词。
- **输入：** 任务名、locale、分析结果、目录，以及可选的 note。
- **返回：** `String?`。
- **副作用：** 无。
- **算法：** 通过 `LocalizedStrings.lookupOrder` 取该任务在该语言下的块，缺失时回退英文；写入句子、分词结果、note、语法摘录与要求；最后对整体截断。
- **使用：** `forIssue`、`forSentence`。
- **说明：** 仅在本文件内使用的辅助函数。每一部分都**先于**整体被截断，这样失控的语法摘录才不会把末尾的要求挤掉——丢掉要求会悄悄把一个受约束的请求变成开放请求。回退英文意味着不受支持的界面语言仍能得到一个可用的提示词，而不是干脆没有这项功能。与内容共用同一套查找顺序，正是繁体中文的提示词既用繁体提问、又引用繁体语法说明的原因：用一种字体提问却用另一种字体做依据，等于让模型去翻译。

### `List<String> _grammar(SentenceAnalysis, ContentCatalog?, Locale locale)` <a id="grammar"></a>

- **种类：** 方法
- **用途：** 引用应用自己对每个匹配语法点的讲解。
- **输入：** 分析结果、目录与语言。
- **返回：** 最多配置条数的行，每行都有长度上限。
- **副作用：** 无。
- **算法：** 遍历匹配项，解析每个语法点，优先取其说明而非释义，截断。
- **使用：** `_build`。
- **说明：** 仅在本文件内使用的辅助函数。**这就是「依据」所在。** 模型拿到的是应用自己的教学文字，并被要求不得与之相矛盾，这正是防止解释偏离语法页对同一语法点说法的手段——也就是 `AGENTS.md` 所说的生成文字绝不替代确定性结果。

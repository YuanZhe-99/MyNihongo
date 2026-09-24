# lib/features/content/models/grammar_point.dart

`GrammarPoint` 是内置内容中的一个语法点：id、JLPT 级别、句型、可选结构、按语言分键的释义（可附其日语文本的读音）与说明，以及例句。`fromJson` 在缺少 id、级别或句型时返回 null。搜索匹配句型、结构和释义，但刻意不匹配说明。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `GrammarPoint.new` | 构造函数 | B | 创建语法点实例。 |
| `GrammarPoint.fromJson` | 静态方法 | B | 从内容 JSON 解析；缺少 id、级别或句型时为 null。 |
| `GrammarPoint.matches` | 方法 | B | 测试小写查询是否为句型、结构或任一语言任一释义的子串。 |

`matchForms` 随 M1.2 加入，来自 JSON 键 `match`：用于在句中标出该语法点的字面字符串，供
`content_links.dart` 的交叉链接使用。单字助词必须显式给出该列表，因为从其句型推导出的形式几乎会匹配任何句子。

`meaningJaReading` 来自同名 JSON 键，是日语 `meaning`（`meaning.ja`）的平假名读音，由 `ja` 内容流写在它旁边。语法详情面板据此以注音绘制日语的一行释义；没有读音时它为 null，释义便不带注音绘制。较长的说明不带读音。

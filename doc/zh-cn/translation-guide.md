# 英译中翻译指南

本指南规定 `doc/zh-cn/` 如何在 MyAnime、MyDay、MyDevice、MyApps-DATA 和 MyNihongo 各仓库中生成并与 `doc/en-us/` 保持同步。第 1–4 节和第 6 节被逐字节复制到每个仓库的 `doc/en-us/translation-guide.md`；第 5 节的术语表被拆分为处处相同的共享核心，外加每个仓库只归自己用的术语一节（并且 `doc/zh-cn/translation-guide.md` 保存这份指南的中文版）。在编写或更新任何中文文档页面之前先读本指南。

## 1. 范围与工作流

- `doc/en-us/` 是权威。`doc/zh-cn/` 是它的翻译，绝不是独立的来源。
- 英文内容优先编写，直接依据实际源代码和 `AGENTS.md`。然后使用本指南和第 5 节的术语表，从完成后的英文页面产出中文内容。
- 任何未来对函数、数据格式、同步规则或功能的变更，必须在同一提交中同时更新英文页面和中文页面。绝不让两棵树漂移。
- 翻译中遇到的新术语写进第 5 节。只有当该术语确实跨领域（同步、备份、存储、文档、Flutter 和 Dart 词汇）时，才放进 **5.1 节**并复制到每个兄弟仓库。如果它只指某个应用独有的东西，放进该仓库的 **5.2 节**，不要动其他仓库——MyDevice 里没人能遇到的术语不属于 MyDevice 的术语表。

## 2. 结构对等规则

`doc/zh-cn/<path>` 必须与 `doc/en-us/<path>` 完全镜像：

- 两棵树中存在同一组文件——任何文件不得只存在于一种语言而缺失于另一种。
- 相同的标题层级和数量（`#`、`##`、`###`、……）。
- 相同数量的表格和表格行，顺序相同。
- 相同数量的围栏代码块，**代码内部逐字节相同**（代码是数据，不是散文）。
- 相同的内部链接和锚点，指向翻译后的对应物。

验证过程会逐文件比较两棵树的标题数、表格行数和代码围栏数；两者必须完全一致。

## 3. 绝不翻译的内容

- 标识符：类/函数/变量/字段名、文件路径、目录名。
- CLI 命令及其标志/输出。
- 配置键（如 `storage_config.json` 的键、`webdav_config.json` 的键）。
- URL 和被掩码的占位符 `<local_gitea_address>`。
- 产品、框架和协议名称：WebDAV、Riverpod、go_router、Flutter、Dart、Gitea、GitHub、MSIX、Inno Setup、AGP、Gradle、JMdict、JLPT。
- 函数索引中使用的 Tier A / Tier B 标签。
- 围栏代码块内的任何内容，包括作为示例代码一部分写下的注释——除非该注释是在可执行行之外解释示例的散文，此时只翻译解释性注释文字，绝不翻译代码记号本身。
- 日语文本——假名、汉字、例句、`〜です` 这类句型——保持原样。

## 4. 风格规则

- 使用中性、陈述性的技术语气。不要使用敬称"您"；只有在无法避免第二人称时才用"你"，否则优先使用无人称表达。
- 散文中使用全角中文标点（，。：；「」），但所有 Markdown 语法字符（`#`、`` ` ``、`|`、`-`、`*`、`[]()`）保持正常 ASCII 形式，使 Markdown 仍能解析。
- 在 CJK 字符与相邻的拉丁字母或数字之间插入一个空格（如"支持 WebDAV 同步"、"保留 60 秒"）。
- 保持句子简短；宁可把一句长英文拆成两句中文，也不要写出一句冗长缠绕的长句。
- 数字、版本号、文件名和代码标识符与英文中完全一致。

## 5. 术语表

5.1 节是共享核心，每个兄弟仓库必须保持一致。5.2 节列出本仓库自身领域特有的术语，每个仓库刻意不同。添加术语前，先判断它属于哪一节——见第 1 节的规则。

### 5.1 共享核心（每个兄弟仓库完全相同）

| English | 中文 | Notes |
|---|---|---|
| sync / synchronization | 同步 | |
| three-way merge | 三方合并 | base/local/remote 三方 |
| base snapshot | 基线快照 | the `.sync_base` copy used for merge comparison |
| conflict / conflict resolution | 冲突 / 冲突解决 | |
| auto-resolve | 自动解决 | |
| backup / restore | 备份 / 恢复 | |
| snapshot | 快照 | |
| blob | blob | 不译；指内容寻址的二进制附件对象 |
| retention (policy) | 保留策略 | |
| WebDAV | WebDAV | 不译 |
| lock / lock file | 锁 / 锁文件 | |
| heartbeat | 心跳 | periodic lock-refresh signal |
| stale lock | 过期锁 | |
| interrupted upload | 中断的上传 | |
| provider | provider | Riverpod 术语，不译 |
| route / router | 路由 / 路由器 | |
| deep link | 深层链接 | |
| flavor (build flavor) | 构建风味 | Flutter build flavor 概念，不译作"口味"以外的怪异译法时保留英文首次标注 |
| barrel file | 桶文件（barrel file） | 首次出现附英文原词 |
| unknown-key preservation | 未知键保留 | 向前兼容的数据保留机制 |
| duplicate detection | 重复检测 | |
| declaration | 声明 | function/method/constructor/getter/setter 统称 |
| getter / setter | getter / setter | 不译 |
| widget | 组件（widget） | 首次出现附英文原词 |
| side effects | 副作用 | |
| remote (git) | 远程仓库 | |
| submodule | 子模块 | git submodule |
| facade | 门面（facade） | 设计模式术语，首次出现附英文原词 |
| atomic write | 原子写入 | tmp-then-rename pattern |
| storage hub | 存储中枢 | per-app central storage class |
| function index | 函数索引 | |
| algorithm documentation | 算法文档 | |
| usage / example documentation | 用法 / 示例文档 | |
| Tier A / Tier B | Tier A / Tier B | 文档覆盖分级标签，不译 |
| build method | build 方法 | Flutter widget 的 build() |
| l10n / localization | 本地化（l10n） | |
| ARB file | ARB 文件 | Application Resource Bundle |
| ZIP export / import | ZIP 导出 / 导入 | |
| path traversal | 路径穿越 | 安全术语，指目录遍历攻击 |
| allowlist | 允许列表 | |
| garbage collection (GC) | 垃圾回收（GC） | 指备份 blob 的引用计数回收 |
| debounce | 防抖 | |
| wake lock | 唤醒锁 | screen wake lock, `wakelock_plus` |
| adaptive layout | 自适应布局 | |
| window size class | 窗口尺寸类别 | Material 的 compact/medium/expanded 分级 |
| breakpoint | 断点 | 布局阈值 |
| viewport | 视口 | |
| logical pixel (dp) | 逻辑像素（dp） | 与密度无关的布局单位 |
| aspect ratio | 宽高比 | width / height |
| foldable | 折叠屏设备 | |
| cover screen | 外屏 | 折叠状态下的外部屏幕 |
| split layout | 分栏布局 | |
| pane | 窗格（pane） | 首次出现附英文原词 |
| two-pane | 双栏 | 左右两个窗格的布局 |
| navigation rail | 导航栏（NavigationRail） | Material 侧边导航；不译作「轨道」 |
| bottom navigation bar | 底部导航栏 | |
| content width | 内容宽度 | 扣除导航栏后页面内容实际获得的宽度 |
| column capacity | 列容量 | 给定最小列宽时一行能容纳的列数 |

### 5.2 MyNihongo 特有术语

不复制到其他仓库——没有其他应用拥有这些。

| English | 中文 | Notes |
|---|---|---|
| kana | 假名 | |
| hiragana / katakana | 平假名 / 片假名 | |
| gojūon | 五十音 | 基础表；App 内标签「五十音」 |
| dakuten / handakuten | 浊音 / 半浊音 | |
| yōon | 拗音 | contracted sounds |
| sokuon | 促音 | small っ |
| long vowel | 长音 | |
| mora | 音拍（mora） | 首次出现附英文原词 |
| romaji | 罗马音 | |
| script (hiragana/katakana) | 书写体系 | 平假名与片假名之间的切换 |
| JLPT level | JLPT 级别 | N5–N1 本身不翻译 |
| content catalog | 内容目录 | 随应用打包的只读学习内容 |
| seed content | 种子内容 | 手写的首批内容，待正式目录替换 |
| vocabulary entry | 单词条目 | |
| headword | 词条（headword） | 有汉字时为汉字写法，否则为假名 |
| reading | 读音 | 假名读音 |
| gloss / meaning | 释义 | |
| part of speech | 词性 | |
| grammar point | 语法点 | |
| pattern | 句型 | 如 `〜です` |
| structure | 结构 | 接续方式，如 `N + です` |
| example sentence | 例句 | |
| level filter | 级别筛选 | |
| tile | 条目卡片 | 单词或语法列表中的一格 |
| detail sheet | 详情面板 | 底部弹出的详情 |
| learning progress | 学习进度 | 同步的用户数据 |
| study record | 学习记录 | 每个学习项一条 |
| kind (study kind) | 类别 | kana / vocab / grammar，由 id 前缀推导 |
| stage (fresh / learning / mastered) | 阶段（未学 / 学习中 / 已掌握） | 由复习状态推导 |
| spaced repetition (SRS) | 间隔重复（SRS） | |
| review | 复习 | |
| interval | 间隔 | SM-2 的 `intervalDays` |
| ease | 难度系数（ease） | SM-2 的 ease factor |
| due | 到期 | `dueAt` |
| streak | 连续正确次数 | 记录字段；「连续学习天数」另译 |
| lesson | 课程 | |
| lesson path | 学习路径 | Duolingo 式的单元 → 课程 |
| drill | 练习题 | JLPT 分项练习 |
| mock test | 模拟考试 | |
| quiz mode | 测验模式 | |
| pronunciation practice | 发音练习 | |
| speech recognition (STT) | 语音识别（STT） | |
| text-to-speech (TTS) | 语音合成（TTS） | |
| speaking rate | 朗读速度 | 设置中的 0.6×–1.2× 倍速 |
| voice (TTS) | 语音 | 引擎的具体嗓音；不译作"声音" |
| utterance | 一段朗读 | 一次朗读请求的文本 |
| on-device | 端侧 | 在设备上运行，数据不外传 |
| pronunciation score | 发音评分 | 0–100 的对照结果 |
| sentence lab | 句子实验室 | 句法分析页 |
| token | 词元（token） | 首次出现附英文原词 |
| bunsetsu | 文节（bunsetsu） | 首次出现附英文原词 |
| dependency (syntax) | 依存关系 | |
| lattice (segmentation) | 词格 | 分词搜索所用的候选图 |
| de-inflection | 活用还原 | 由活用形反推词典形 |
| conjugation class | 活用类 | 五段、一段、不规则等 |
| function word | 功能词 | 助词、系动词、助动词、形式名词 |
| stem | 词干 | 活用形去掉词尾后的部分 |
| lemma | 词元 | 词的词典形 |
| predicate | 谓语 | 文节能否支配其他文节 |
| attributive | 连体形 | 修饰名词的形式 |
| possible issue | 可能的问题 | 检查的结论措辞，绝不说"错误" |
| conjugation | 活用 | 动词、形容词的变形 |
| on-device AI assistance | 端侧 AI 辅助 | 设置中的开关名；默认关闭 |
| AICore | AICore | Android 系统服务，不译 |
| Gemini Nano | Gemini Nano | 模型名，不译 |
| generated text | 生成的文字 | 始终带标注；绝不替代确定性结果 |
| prompt (to a model) | 提示词 | 送给模型的文本；与「句型」无关 |
| model download | 模型下载 | 由 AICore 完成，不是应用 |
| explanation (AI) | 解释 | 「解释这个句子」 |
| correction suggestion | 改写建议 | 校对 API 的输出；不说「纠错」 |
| Learn tab | 学习标签页 | 首页 |
| dashboard | 仪表盘 | 学习标签页的卡片总览 |
| roadmap | 路线图 | `PLAN.md` |

## 6. 复查清单（提交中文页面之前运行）

- [ ] 文件存在于 `doc/zh-cn/` 下与其英文对应物相同的相对路径。
- [ ] 标题数量一致（`grep -c '^#'`）。
- [ ] 代码围栏数量一致（`grep -c '^```'`），且代码内容与英文逐字节相同。
- [ ] 表格行数一致。
- [ ] 用到的每个术语表条目都与第 5 节完全一致；任何新增的跨领域术语已添加到每个兄弟仓库的 5.1 节，任何应用特有术语只添加到本仓库的 5.2 节。
- [ ] 不出现真实 Gitea 主机；凡是需要主机的地方都用 `<local_gitea_address>`。
- [ ] 内部链接指向中文树的对应物，而不是指回 `doc/en-us/`。

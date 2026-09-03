# English → Simplified Chinese Translation Guide

This guide governs how `doc/zh-cn/` is produced and kept in sync with `doc/en-us/` across
MyAnime, MyDay, MyDevice, MyApps-DATA and MyNihongo. Sections 1-4 and 6 are copied byte-identically
into every repo's `doc/en-us/translation-guide.md`; Section 5's glossary is split into a shared core
that is identical everywhere plus a per-repo section for terms only that repo uses (and
`doc/zh-cn/translation-guide.md` holds the Chinese rendering of this same guide). Read this before
writing or updating any Chinese documentation page.

## 1. Scope and workflow

- `doc/en-us/` is authoritative. `doc/zh-cn/` is a translation of it, never an independent source.
- English content is authored first, directly from the actual source code and `AGENTS.md`.
  Chinese content is then produced from the finished English page using this guide and the
  glossary in Section 5.
- Any future change to a function, data format, sync rule, or feature must update the English
  page and the Chinese page in the same commit. Do not let the two trees drift.
- New terminology encountered while translating goes into Section 5. Put it in **Section 5.1** and
  copy it to every sibling repo only if the term is genuinely cross-cutting (sync, backup, storage,
  documentation, Flutter and Dart vocabulary). If it names something only one app has, put it in
  that repo's **Section 5.2** and leave the other repos alone — a term nobody in MyDevice can
  encounter does not belong in MyDevice's glossary.

## 2. Structural parity rules

`doc/zh-cn/<path>` must mirror `doc/en-us/<path>` exactly:

- The same set of files exists in both trees — no file present in one language and missing in
  the other.
- The same heading hierarchy and count (`#`, `##`, `###`, ...).
- The same number of tables and table rows, in the same order.
- The same number of fenced code blocks, with **identical code inside** (code is data, not prose).
- The same internal links and anchors, pointing at the translated equivalents.

A verification pass compares heading counts, table-row counts, and code-fence counts between the
two trees file-by-file; both must match exactly.

## 3. What is never translated

- Identifiers: class/function/variable/field names, file paths, directory names.
- CLI commands and their flags/output.
- Configuration keys (e.g. `storage_config.json` keys, `webdav_config.json` keys).
- URLs and the masked placeholder `<local_gitea_address>`.
- Product, framework, and protocol names: WebDAV, Riverpod, go_router, Flutter, Dart, Gitea,
  GitHub, MSIX, Inno Setup, AGP, Gradle, JMdict, JLPT.
- The Tier A / Tier B labels used in the function index.
- Anything inside a fenced code block, including comments written as part of example code,
  unless the comment is prose explaining the example outside the executable line — in which case
  translate the explanatory comment text but never the code tokens themselves.
- Japanese text — kana, kanji, example sentences, patterns like `〜です` — stays exactly as written.

## 4. Style rules

- Use a neutral, declarative technical tone. Do not use the formal pronoun 您; use 你 only if a
  second-person address is unavoidable, otherwise prefer impersonal phrasing.
- Use full-width Chinese punctuation in prose (，。：；「」) but keep all Markdown syntax
  characters (`#`, `` ` ``, `|`, `-`, `*`, `[]()`) in their normal ASCII form so Markdown still
  parses.
- Insert a single space between CJK characters and adjacent Latin letters or digits
  (e.g. "支持 WebDAV 同步", "保留 60 秒").
- Keep sentences short; prefer splitting a long English sentence into two Chinese sentences over
  producing one dense run-on sentence.
- Numbers, version numbers, file names, and code identifiers stay exactly as written in English.

## 5. Terminology glossary

Section 5.1 is the shared core and must stay identical in every sibling repo. Section 5.2 lists
terms specific to this repo's own domain and deliberately differs per repo. Before adding a term,
decide which one it belongs in — see the rule in Section 1.

### 5.1 Shared core (identical in every sibling repo)

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

### 5.2 MyNihongo-specific terms

Not copied to the other repos — no other app has these.

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
| conjugation | 活用 | 动词、形容词的变形 |
| Learn tab | 学习标签页 | 首页 |
| dashboard | 仪表盘 | 学习标签页的卡片总览 |
| roadmap | 路线图 | `PLAN.md` |

## 6. Review checklist (run before committing a Chinese page)

- [ ] File exists at the same relative path under `doc/zh-cn/` as its English counterpart.
- [ ] Heading count matches (`grep -c '^#'`).
- [ ] Code-fence count matches (`grep -c '^```'`), and code contents are byte-identical to English.
- [ ] Table row counts match.
- [ ] Every glossary term used matches Section 5 exactly; any new cross-cutting term was added to
      Section 5.1 in every sibling repo, and any app-specific term was added only to this repo's
      Section 5.2.
- [ ] No real Gitea host appears; `<local_gitea_address>` is used wherever the host would be.
- [ ] Internal links resolve to the Chinese-tree equivalents, not back to `doc/en-us/`.

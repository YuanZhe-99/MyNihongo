# 假名速查

五十音图是两个文件：目录 `lib/features/kana/models/kana.dart` 和页面 `lib/features/kana/views/kana_page.dart`。页面是**纯 UI** 的——它不读任何用户数据，除普通组件（widget）状态外没有持久化状态——但与 MyAnime!!!!! 的版本不同，它背后的数据是公开模型，使测验、发音练习和进度目录可以共享同一来源。

它占据应用五个标签中的第二个（见 [`../architecture.md`](../architecture.md)）。

## 目录

- `KanaEntry(hiragana, katakana, romaji)`，用 `kana(script)` 选择书写体系，用 `matches(query)` 搜索（对平假名、片假名或小写罗马音做子串匹配；没有罗马字变体，因此 `si` 找不到 `shi`）。
- `KanaRow(label, entries)` — 一个辅音行；`null` 槽位标记不存在的组合（`yi`、`ye`、`wi`、`wu`、`we`）。
- 三张 `const` 表：`kanaBasicRows`（五十音加 ん）、`kanaVoicedRows`（浊音和半浊音）、`kanaYoonRows`（拗音）。列标题 `kanaVowelColumns` 和 `kanaYoonColumns`。
- `allKanaEntries()` 把各表展平、每项一次；`matchingKanaEntries(query)` 修剪、转小写并搜索。
- **进度 id：** `KanaEntry.progressId` 是 `kana:<hiragana>`——平假名而不是罗马音，因为罗马音不唯一（じ/ぢ 都是 `ji`，ず/づ 都是 `zu`）。该 id 是兼容性契约；见 [`../data-formats.md`](../data-formats.md)。

## 页面

- 平假名和片假名的分段切换。
- 假名和罗马音搜索；结果替换表格，规则保留。
- 基础五十音表、浊音 / 半浊音表、拗音表。
- 音拍节奏、稳定元音、浊音、拗音、促音、长音和 ん 的发音规则卡片。

## 布局

本页是自适应的。在全应用分栏规则允许、且宽到足以放下两张不低于 `kanaTableMinWidth`（330 逻辑像素）的假名表的窗口上，它把各节排成两列——高的五十音表与拗音表在左，矮的浊音表与规则卡在右——并把书写体系切换放到搜索框旁边而不是其上方。否则保持单列堆叠。规则卡则自行决定排一列还是两列，量的是这一节实际获得的宽度。

实际结果：Z Fold 8 展开横持、Fold 8 Ultra 两个方向、Pixel 10 Pro Fold、平板横持与桌面窗口得到两列；Fold 8 竖持、较窄的展开态折叠屏、平板竖持以及所有手机保持一列。两道门控及其背后的数字见 [`../adaptive-layout.md`](../adaptive-layout.md)，`test/kana_layout_ui_test.dart` 固定了其中每一台设备。

## 详情面板

点击格子或搜索结果会在底部弹层中打开该假名：大字显示两种字体并在旁标注罗马字；`assets/content/kana_notes.json` 中有条目时显示笔画数与教学要点；为易混淆的假名显示标签；并列出以它开头的最简单、最常用的单词。这些示例单词才是弹层的重点——字表教的是字形，而初学者需要在单词中看到这个字形才能读出来。单词标签打开单词弹层，易混淆标签打开另一个假名，因此 ツ 与 シ 可以直接对照，无需离开页面。弹层位于 `lib/shared/widgets/content_sheets.dart`，排序规则是 `content_links.dart` 中的 `vocabStartingWithKana`。

## 计划

第二阶段添加长按语音合成和假名听力测验；第三阶段添加假名测验模式，其结果成为 `kana:` 进度记录。

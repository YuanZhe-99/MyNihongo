# lib/l10n/ — 生成的本地化代码

`lib/l10n/` 中的三个 Dart 文件（`app_localizations.dart`、`app_localizations_en.dart`、`app_localizations_zh.dart`）由 Flutter 的 `gen-l10n` 工具从 ARB 模板（`app_en.arb`、`app_zh.arb`、`app_zh_TW.arb`）生成。它们被源码控制跟踪但不是手写的，并且——与本仓库其他每个文件不同——不带任何 `/// Purpose:` 函数解释层注释。

`AppLocalizationsZhTw` 作为 `AppLocalizationsZh` 的子类生成在 `app_localizations_zh.dart` 中，因此一个从未翻译的繁体字符串会回落到简体的那一条——不过在那之前 `test/l10n_arb_test.dart` 就会失败。

每个语言子类（`AppLocalizationsEn`、`AppLocalizationsZh`、`AppLocalizationsZhTw`）实现抽象基类 `AppLocalizations`，为 ARB 模板中定义的每个可翻译键提供一个平凡的字符串 getter，或为带占位符的字符串提供一个方法。由于它们是生成而非编写的，且除「为此键返回本地化字符串」外不含任何算法或用法，本文档集不逐个列举它们。字符串目录的规范、人工维护的事实来源是 `lib/l10n/app_en.arb`（模板 ARB 文件）；按本仓库 `AGENTS.md` 的要求，编辑任何 ARB 文件后用 `flutter gen-l10n` 重新生成这些代码。

| 源文件 | 类型 | 声明 | Tier |
|---|---|---|---|
| `lib/l10n/app_localizations.dart` | 生成的抽象基类 + delegate | 基类、`LocalizationsDelegate` 查找、`of(context)`、`lookupAppLocalizations` | B（生成） |
| `lib/l10n/app_localizations_en.dart` | 生成的语言子类 | 每个 ARB 键一个 getter 或方法 | B（生成） |
| `lib/l10n/app_localizations_zh.dart` | 生成的语言子类（两种中文目录） | 每个 ARB 键一个 getter 或方法 | B（生成） |

本目录中的任何声明都不计入 [../INDEX.md](../INDEX.md) 跟踪的手写声明；此处列出只为函数索引的完整性。

# lib/app/locale_resolution.dart

设备偏好的语言列表如何匹配到应用的三种界面语言之一。在 [app.md](app.md) 中作为 `MaterialApp.localeListResolutionCallback` 接入，因此它只在学习者没有在设置中选择语言时才做决定。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `traditionalChineseCountry` | 常量 | B | 繁体中文 locale 归档所用的国家代码。 |
| `traditionalChineseRegions` | 常量 | B | 以繁体字书写中文的地区。 |
| [`normalizeChinese`](#normalizechinese) | 函数 | A | 把任意中文 locale 归约为应用的两种之一。 |
| [`resolveAppLocale`](#resolveapplocale) | 函数 | A | 为设备的语言列表选择界面语言。 |

## 文档

### `Locale normalizeChinese(Locale locale)` <a id="normalizechinese"></a>

- **类型：** 函数
- **源码：** `lib/app/locale_resolution.dart`
- **Purpose：** 判断一个中文 locale 指的是繁体还是简体。
- **Inputs：** `locale`。
- **Returns：** `zh_TW`、`zh`，其他语言原样返回。
- **Side effects：** 无。
- **Algorithm：** 存在文字系统子标签时 `Hant` → 繁体、`Hans` → 简体；否则由国家代码决定，`TW`、`HK`、`MO` 读作繁体。
- **Usage：** `resolveAppLocale`，对设备列表中的每一项调用一次。
- **Notes：** 文字系统优先于地区，因为那才是用户真正要求的，所以 `zh-Hans-HK` 是简体，尽管香港是繁体地区。这是应用中唯一读取文字系统子标签的地方；其下游只会看到 `zh` 或 `zh_TW`。

### `Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported)` <a id="resolveapplocale"></a>

- **类型：** 函数
- **源码：** `lib/app/locale_resolution.dart`
- **Purpose：** 为没有被指定语言的设备挑选界面语言。
- **Inputs：** `preferred`——设备的列表，最优先在前；`supported`——`AppLocalizations.supportedLocales`。
- **Returns：** 要显示的 locale。
- **Side effects：** 无。
- **Algorithm：** 归一化列表中的每个中文条目，然后把列表交给 Flutter 自己的 `basicLocaleListResolution`。
- **Usage：** `app.dart` 中 `MaterialApp.router` 的 `localeListResolutionCallback`。
- **Notes：** 保留 Flutter 的算法而不是取代它——只修正它的输入。它按语言与国家匹配，因此请求 `zh-Hant-HK` 的手机会被给到简体中文：国家 `HK` 不是 `TW`，而它确实发送了的文字系统被忽略。修正输入而不是算法，使所有非中文情况完全保持 Flutter 定义的行为，包括无匹配时回落到模板语言。

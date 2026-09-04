# lib/features/speech/models/voice_ordering.dart

一组纯谓词和一个比较器，决定哪个日语语音最好、以及选择面板按什么顺序列出它们。它不依赖 Flutter，也不涉及本地化，因此服务和控件都可以使用它，而不必由其中任何一方拥有它。

这个顺序不是装饰。学习者没有选择时，`TtsService` 取其中第一个已安装的语音；而选择面板按位置为语音命名——「日语语音 1、2、3」。顺序不稳定就会让语音在两次运行之间改名，并悄悄改变实际朗读的是哪一个。

使用方：`tts_service.dart`（`_loadVoices`）、`voice_labels.dart`（编号与限定词）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 为引擎提供的日语语音排序并加以描述。 |
| `_qualityOrder` | 顶层常量 | B | 音质名称，由差到好，与 `flutter_tts` 的写法一致。 |
| `voiceIsNotInstalled` | 顶层函数 | B | 报告引擎是否声明该语音的数据不在设备上。 |
| `voiceNeedsNetwork` | 顶层函数 | B | 报告使用该语音朗读是否需要联网。 |
| `voiceQualityRank` | 顶层函数 | B | 为语音音质排名；引擎未说明时为 -1。 |
| [`compareJapaneseVoices`](#comparejapanesevoices) | 顶层函数 | A | 按优先顺序排列日语语音。 |
| `sortJapaneseVoices` | 顶层函数 | B | 返回排序后的语音列表副本。 |

## 文档

### `int compareJapaneseVoices(Map<String, String> a, Map<String, String> b)` <a id="comparejapanesevoices"></a>

- **种类：** 顶层函数
- **用途：** 按优先顺序排列日语语音。
- **输入：** 两个语音映射，形如 `TtsBackend.voices()` 的返回值。
- **返回：** 供 `List.sort` 使用的 `int`。
- **副作用：** 无。
- **算法：** 依次比较四个键：已安装优先于缺失、离线优先于联网、音质高者优先，最后按引擎自己的名称。
- **使用：** `sortJapaneseVoices`，并经由它用于 `TtsService._loadVoices` 与选择面板。
- **说明：** 每个键都有其理由。标记为 `notInstalled` 的语音可以被选中，然后播不出声音，因此绝不能作为默认。联网语音可用，但更慢，而且会把文本发出设备，凡是应用有得选的地方都会避免这一点。音质用的是引擎自己的说法。名称放在最后是为了让顺序**完全确定**：没有它，两个被引擎描述得完全相同的语音可能在两次运行之间互换位置，选择面板里的编号也会随之移动。这些字段全是可选的——桌面引擎的语音可能一个都不带，那时就只由名称决定。

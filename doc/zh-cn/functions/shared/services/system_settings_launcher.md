# lib/shared/services/system_settings_launcher.dart

打开平台自身的语音设置，让"未安装日语语音"成为一个可以采取的动作，而不只是一句说明。

使用方：`speech_settings_tiles.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SystemSettingsLauncher` | 类 | B | 通往平台设置界面的深链接。 |
| [`openSpeechSettings`](#openspeechsettings) | 静态方法 | A | 打开系统语音设置。 |

## 文档

### `static Future<bool> openSpeechSettings()` <a id="openspeechsettings"></a>

- **种类：** 静态方法
- **用途：** 把用户送到可以安装日语语音的地方。
- **输入：** 无。
- **返回：** 平台没有深链接、或打开失败时为 `false`。
- **副作用：** 把用户送往另一个应用。
- **算法：** 以 `canOpenSystemSpeechSettings` 为门槛。Android 走应用唯一的方法通道 `com.yuanzhe.my_nihongo/system`，其在 `MainActivity` 中的处理程序发出 `com.android.settings.TTS_SETTINGS` intent 并回答是否有 activity 接收。Windows 把 `ms-settings:speech` 交给 `explorer.exe`——这是在不引入 URL 启动插件的情况下打开 `ms-settings:` URI 的方式。
- **使用：** 设置 → 语音中缺少语音的说明。
- **说明：** 永不抛出——失败即 `false`，调用方转而显示一条消息。Windows 的 URI 处理程序是否真的打开了面板无法从退出码观察，因此 `explorer.exe` 正常启动即视为成功。

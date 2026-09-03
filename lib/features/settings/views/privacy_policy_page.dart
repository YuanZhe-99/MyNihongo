import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  /// Purpose: Create a privacy policy page instance.
  /// Inputs: None.
  /// Returns: A new `PrivacyPolicyPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const PrivacyPolicyPage({super.key});

  /// Purpose: Build the privacy policy page in the active language.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// text mirrors `PRIVACY_POLICY.md` at the repository root; update both.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final text = _getText(locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  /// Purpose: Pick the policy text for a locale.
  /// Inputs: `locale`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. English is the
  /// fallback for every language without its own text. The policy is one of
  /// the few places where a machine translation would not do: it is the
  /// document a user is entitled to rely on, so each language's text is kept
  /// as its own string.
  String _getText(Locale locale) {
    if (locale.languageCode != 'zh') return _en;
    return locale.countryCode == 'TW' ? _zhTw : _zh;
  }

  static const _en = '''Privacy Policy

Thank you for using MyNihongo!!!!!. We take your privacy seriously. This privacy policy explains how the app handles your data.

Data Collection

MyNihongo!!!!! does not collect, upload, or share any personal information. The app contains no analytics, advertising trackers, crash reporting, or data collection of any kind. It has no accounts and no server of its own.

Data Storage

All data the app creates — your learning progress and your settings — is stored locally on your device, in the app's own folder or in a folder you choose in Settings. The kana, vocabulary, and grammar content is bundled inside the app and is never sent anywhere.

Network Access

MyNihongo!!!!! accesses the internet only in the following situations, each of which you have to turn on yourself:

• WebDAV sync: If you enable WebDAV cloud sync, the app sends your learning progress to a WebDAV server that you configure yourself. The app does not send data to any other server.
• Network speech recognition, only if you turn on the switch described under Speech Recognition below. It is off by default.
• Downloading an on-device AI model, only if you turn on On-device AI assistance and then tap Download. The download is performed by the Android AICore system service, not by the app.

No other network communication takes place. The app requests the INTERNET permission for this and nothing else.

Two details worth stating plainly:

• Your WebDAV credentials are stored in plain text in the app's folder, as they are in the other apps in this series. Anyone with access to that folder — including a device backup that includes it — can read them. Use an app password rather than your main account password where your server offers one.

• Your device is kept awake while a sync is running, so a sync is not interrupted mid-upload. It is released as soon as the sync finishes or fails.

Data Backup, Export and Import

The app provides a local backup feature and a ZIP export and import. Backup files are stored on your device; an export goes to the folder you pick. Both contain your learning progress. Where these files go afterwards is entirely under your control — the app never uploads them.

Picking a folder or a file uses the system picker, which grants the app access to that one location and requires no storage permission.

Text to Speech

The app can read Japanese aloud — kana, words and example sentences. This uses the text-to-speech engine that is already installed on your device (Android's, Apple's, or the Windows speech platform): the text is handed to that engine and the audio is produced on the device. Nothing is sent anywhere, nothing is recorded, and no audio file is written. Your chosen speaking speed and voice are stored on the device only.

If no Japanese voice is installed, nothing is spoken and the app says so; installing one is done in your system settings, not in the app.

Speech Recognition

Pronunciation practice listens to you and compares what the speech recognizer understood with the item's reading. Recognition is done by the speech service already on your device — Android's, Apple's, or the Windows speech platform.

By default the app asks for offline recognition only. On a device with no offline Japanese data installed the attempt fails and the app tells you so, rather than quietly sending your voice anywhere. Settings has a switch, off by default, that allows a fallback to the system's network recognition; only when you turn it on can what you say be sent to the system speech service to be transcribed. On most Android devices that service is Google's.

No audio is recorded to a file, and nothing you say is stored. The microphone is used only while you are recording an attempt, and the permission is requested the first time you tap record, with a reason.

On-device AI Assistance

On an Android phone that has Google's AICore system service, the sentence lab can explain one of its own findings in more words, explain a sentence, and suggest a rewrite. This is off by default; nothing happens until you turn on On-device AI assistance in Settings.

When it is on, the sentence you typed — together with the app's own analysis of it and the app's own grammar notes — is handed to a model that runs on your phone, through AICore. Nothing is sent to a server, nothing is recorded, and nothing generated is saved: it is gone when you change the sentence or leave the page.

One part of this does use the network, and only when you ask for it: the first time you tap Download for a feature, the AICore system service fetches that model from Google. The app does not perform the download and does not send anything with it. Once the model is on your phone, the feature works with no network at all.

Generated text is always labelled as generated. It can be wrong, it never changes the app's own analysis, and it is never written into the app's dictionary or grammar content.

Changes to This Policy

This privacy policy may be updated from time to time. Updated versions will be published within the app or on the relevant distribution channels. Text to speech, speech recognition and on-device AI assistance are described above. Any future feature that could send anything off the device will be described here before it ships, and will be off unless you turn it on.''';

  static const _zh = '''隐私政策

感谢您使用 MyNihongo!!!!!。我们非常重视您的隐私。本隐私政策说明了应用如何处理您的数据。

数据收集

MyNihongo!!!!! 不收集、上传或共享任何个人信息。应用不包含任何分析工具、广告追踪器、崩溃上报或数据收集功能。它没有账号，也没有自己的服务器。

数据存储

应用产生的所有数据——您的学习进度和设置——均存储在您的设备本地，位于应用自身的文件夹，或您在设置中选择的文件夹。五十音、单词和语法内容随应用一起打包，绝不会被发送到任何地方。

网络访问

MyNihongo!!!!! 仅在以下情况下访问互联网，且每一项都需要您自己开启：

• WebDAV 同步：如果您启用了 WebDAV 云同步，应用会将您的学习进度发送到您自行配置的 WebDAV 服务器。应用不会向其他任何服务器发送数据。
• 网络语音识别，仅当您打开下文「语音识别」中描述的开关时。它默认关闭。
• 下载端侧 AI 模型，仅当您打开「端侧 AI 辅助」并点击「下载」时。下载由 Android AICore 系统服务完成，而不是由应用完成。

除此之外不进行任何网络通信。应用仅为此申请 INTERNET 权限，别无他用。

有两点需要明确说明：

• 您的 WebDAV 凭据以明文存放在应用的文件夹中，与本系列其他应用相同。任何能访问该文件夹的人——包括包含它的设备备份——都可以读到。如果您的服务器支持应用专用密码，请使用它，而不要使用主账号密码。

• 同步进行期间会保持设备唤醒，以免上传中途被打断。同步完成或失败后立即释放。

数据备份、导出与导入

应用提供本地备份功能以及 ZIP 导出与导入。备份文件存放在您的设备上；导出写入您选择的文件夹。两者都包含您的学习进度。这些文件之后去向何处完全由您掌控——应用绝不会上传它们。

选择文件夹或文件时使用系统选择器，它只授予应用对该位置的访问权限，无需存储权限。

语音合成

应用可以朗读日语——假名、单词和例句。这使用您设备上已安装的语音合成引擎（Android 的、Apple 的，或 Windows 语音平台）：文本交给该引擎，音频在设备上生成。没有任何内容被发送到别处，没有录音，也不会写出音频文件。您选择的朗读速度和语音仅保存在设备上。

如果没有安装日语语音，则不会朗读，应用会明确说明；安装语音是在您的系统设置中完成的，而不是在应用内。

语音识别

发音练习会听取你的朗读，并把语音识别理解到的内容与词条读音作对照。识别由你设备上已有的语音服务完成——Android 的、Apple 的，或 Windows 语音平台。

默认情况下应用只请求离线识别。在没有安装离线日语数据的设备上，请求会失败并明确告知你，而不是悄悄把你的声音发往任何地方。设置中有一个默认关闭的开关，允许回退到系统的网络识别；只有在你打开它之后，你说的内容才可能被发送到系统语音服务进行转写。在多数 Android 设备上，该服务是 Google 的。

不会把音频录成文件，你说的话也不会被保存。麦克风仅在你录制一次尝试期间使用，权限在你第一次点击录音时带理由申请。

端侧 AI 辅助

在装有 Google AICore 系统服务的 Android 手机上，句子实验室可以用更多文字解释它自己的一处发现、解释整个句子，并给出改写建议。此功能默认关闭；在你于设置中打开「端侧 AI 辅助」之前，什么都不会发生。

打开之后，你输入的句子——连同应用对它的分析以及应用自带的语法说明——会交给一个在你手机上运行的模型，通过 AICore 完成。没有任何内容被发送到服务器，没有录音，生成的内容也不会被保存：当你更换句子或离开页面时它就消失了。

其中只有一件事会用到网络，而且只在你主动要求时：你首次为某项功能点击「下载」时，AICore 系统服务会从 Google 获取该模型。应用不执行这次下载，也不会随之发送任何内容。模型下载到手机后，该功能完全不需要网络。

生成的文字始终带有「生成」标注。它可能有误，绝不会改变应用自身的分析结果，也绝不会写入应用的词典或语法内容。

政策变更

本隐私政策可能会不时更新。更新版本将在应用内或相关分发渠道发布。语音合成、语音识别与端侧 AI 辅助已在上文说明。今后任何可能把内容发出设备的功能，都会在发布前写入本政策，并且默认关闭，除非你自己打开。''';

  static const _zhTw = '''隱私政策

感謝您使用 MyNihongo!!!!!。我們非常重視您的隱私。本隱私政策說明了應用程式如何處理您的資料。

資料收集

MyNihongo!!!!! 不收集、上傳或共享任何個人資訊。應用程式不包含任何分析工具、廣告追蹤器、當機回報或資料收集功能。它沒有帳號，也沒有自己的伺服器。

資料儲存

應用程式產生的所有資料——您的學習進度和設定——均儲存在您的裝置本地，位於應用程式自身的資料夾，或您在設定中選擇的資料夾。五十音、單字和文法內容隨應用程式一起內建，絕不會被發送到任何地方。

網路存取

MyNihongo!!!!! 僅在以下情況下存取網際網路，且每一項都需要您自己開啟：

• WebDAV 同步：如果您啟用了 WebDAV 雲同步，應用程式會將您的學習進度發送到您自行設定的 WebDAV 伺服器。應用程式不會向其他任何伺服器發送資料。
• 網路語音辨識，僅當您開啟下文「語音辨識」中描述的開關時。它預設關閉。
• 下載裝置端 AI 模型，僅當您開啟「裝置端 AI 輔助」並點選「下載」時。下載由 Android AICore 系統服務完成，而不是由應用程式完成。

除此之外不進行任何網路通訊。應用程式僅為此申請 INTERNET 權限，別無他用。

有兩點需要明確說明：

• 您的 WebDAV 憑證以明文存放在應用程式的資料夾中，與本系列其他應用程式相同。任何能存取該資料夾的人——包括包含它的裝置備份——都可以讀到。如果您的伺服器支援應用程式專用密碼，請使用它，而不要使用主帳號密碼。

• 同步進行期間會保持裝置喚醒，以免上傳中途被打斷。同步完成或失敗後立即釋放。

資料備份、匯出與匯入

應用程式提供本地備份功能以及 ZIP 匯出與匯入。備份檔案存放在您的裝置上；匯出寫入您選擇的資料夾。兩者都包含您的學習進度。這些檔案之後去向何處完全由您掌控——應用程式絕不會上傳它們。

選擇資料夾或檔案時使用系統選擇器，它只授予應用程式對該位置的存取權限，無需儲存權限。

語音合成

應用程式可以朗讀日語——假名、單字和例句。這使用您裝置上已安裝的語音合成引擎（Android 的、Apple 的，或 Windows 語音平台）：文字交給該引擎，音訊在裝置上生成。沒有任何內容被發送到別處，沒有錄音，也不會寫出音訊檔案。您選擇的朗讀速度和語音僅儲存在裝置上。

如果沒有安裝日語語音，則不會朗讀，應用程式會明確說明；安裝語音是在您的系統設定中完成的，而不是在應用程式內。

語音辨識

發音練習會聽取你的朗讀，並把語音辨識理解到的內容與詞條讀音作對照。辨識由你裝置上已有的語音服務完成——Android 的、Apple 的，或 Windows 語音平台。

預設情況下應用程式只請求離線辨識。在沒有安裝離線日語資料的裝置上，請求會失敗並明確告知你，而不是悄悄把你的聲音發往任何地方。設定中有一個預設關閉的開關，允許改用系統的網路辨識；只有在你開啟它之後，你說的內容才可能被發送到系統語音服務進行轉寫。在多數 Android 裝置上，該服務是 Google 的。

不會把音訊錄成檔案，你說的話也不會被儲存。麥克風僅在你錄製一次嘗試期間使用，權限在你第一次點選錄音時帶理由申請。

裝置端 AI 輔助

在裝有 Google AICore 系統服務的 Android 手機上，句子實驗室可以用更多文字解釋它自己的一處發現、解釋整個句子，並給出改寫建議。此功能預設關閉；在你於設定中開啟「裝置端 AI 輔助」之前，什麼都不會發生。

開啟之後，你輸入的句子——連同應用程式對它的分析以及應用程式自帶的文法說明——會交給一個在你手機上執行的模型，透過 AICore 完成。沒有任何內容被發送到伺服器，沒有錄音，生成的內容也不會被儲存：當你更換句子或離開頁面時它就消失了。

其中只有一件事會用到網路，而且只在你主動要求時：你首次為某項功能點選「下載」時，AICore 系統服務會從 Google 取得該模型。應用程式不執行這次下載，也不會隨之發送任何內容。模型下載到手機後，該功能完全不需要網路。

生成的文字始終帶有「生成」標註。它可能有誤，絕不會改變應用程式自身的分析結果，也絕不會寫入應用程式的詞典或文法內容。

政策變更

本隱私政策可能會不時更新。更新版本將在應用程式內或相關發行管道發布。語音合成、語音辨識與裝置端 AI 輔助已在上文說明。今後任何可能把內容發出裝置的功能，都會在發布前寫入本政策，並且預設關閉，除非你自己開啟。''';
}

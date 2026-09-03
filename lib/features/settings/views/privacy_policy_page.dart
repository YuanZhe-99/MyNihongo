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
  /// fallback for every language without its own text.
  String _getText(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return _zh;
      default:
        return _en;
    }
  }

  static const _en = '''Privacy Policy

Thank you for using MyNihongo!!!!!. We take your privacy seriously. This privacy policy explains how the app handles your data.

Data Collection

MyNihongo!!!!! does not collect, upload, or share any personal information. The app contains no analytics, advertising trackers, crash reporting, or data collection of any kind. It has no accounts and no server of its own.

Data Storage

All data the app creates — your learning progress and your settings — is stored locally on your device, in the app's own folder or in a folder you choose in Settings. The kana, vocabulary, and grammar content is bundled inside the app and is never sent anywhere.

Network Access

MyNihongo!!!!! accesses the internet only in the following situations, both of which you have to turn on yourself:

• WebDAV sync: If you enable WebDAV cloud sync, the app sends your learning progress to a WebDAV server that you configure yourself. The app does not send data to any other server.
• Network speech recognition, only if you turn on the switch described under Speech Recognition below. It is off by default.

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

Changes to This Policy

This privacy policy may be updated from time to time. Updated versions will be published within the app or on the relevant distribution channels. Text to speech and speech recognition are described above. Any future feature that could send anything off the device will be described here before it ships, and will be off unless you turn it on.''';

  static const _zh = '''隐私政策

感谢您使用 MyNihongo!!!!!。我们非常重视您的隐私。本隐私政策说明了应用如何处理您的数据。

数据收集

MyNihongo!!!!! 不收集、上传或共享任何个人信息。应用不包含任何分析工具、广告追踪器、崩溃上报或数据收集功能。它没有账号，也没有自己的服务器。

数据存储

应用产生的所有数据——您的学习进度和设置——均存储在您的设备本地，位于应用自身的文件夹，或您在设置中选择的文件夹。五十音、单词和语法内容随应用一起打包，绝不会被发送到任何地方。

网络访问

MyNihongo!!!!! 仅在以下两种情况下访问互联网，且两者都需要您自己开启：

• WebDAV 同步：如果您启用了 WebDAV 云同步，应用会将您的学习进度发送到您自行配置的 WebDAV 服务器。应用不会向其他任何服务器发送数据。
• 网络语音识别，仅当您打开下文「语音识别」中描述的开关时。它默认关闭。

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

政策变更

本隐私政策可能会不时更新。更新版本将在应用内或相关分发渠道发布。语音合成与语音识别已在上文说明。今后任何可能把内容发出设备的功能，都会在发布前写入本政策，并且默认关闭，除非你自己打开。''';
}

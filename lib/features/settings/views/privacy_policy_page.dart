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

MyNihongo!!!!! accesses the internet only in the following situation:

• WebDAV sync: If you enable WebDAV cloud sync, the app sends your learning progress to a WebDAV server that you configure yourself. The app does not send data to any other server.

No other network communication takes place. The app requests the INTERNET permission for this and nothing else.

Two details worth stating plainly:

• Your WebDAV credentials are stored in plain text in the app's folder, as they are in the other apps in this series. Anyone with access to that folder — including a device backup that includes it — can read them. Use an app password rather than your main account password where your server offers one.

• Your device is kept awake while a sync is running, so a sync is not interrupted mid-upload. It is released as soon as the sync finishes or fails.

Data Backup, Export and Import

The app provides a local backup feature and a ZIP export and import. Backup files are stored on your device; an export goes to the folder you pick. Both contain your learning progress. Where these files go afterwards is entirely under your control — the app never uploads them.

Picking a folder or a file uses the system picker, which grants the app access to that one location and requires no storage permission.

Changes to This Policy

This privacy policy may be updated from time to time. Updated versions will be published within the app or on the relevant distribution channels. In particular, the planned pronunciation features (speech recognition and text-to-speech) will be described here before they ship; they are designed to run on the device, and the microphone permission will be requested at first use with a reason, never at install.''';

  static const _zh = '''隐私政策

感谢您使用 MyNihongo!!!!!。我们非常重视您的隐私。本隐私政策说明了应用如何处理您的数据。

数据收集

MyNihongo!!!!! 不收集、上传或共享任何个人信息。应用不包含任何分析工具、广告追踪器、崩溃上报或数据收集功能。它没有账号，也没有自己的服务器。

数据存储

应用产生的所有数据——您的学习进度和设置——均存储在您的设备本地，位于应用自身的文件夹，或您在设置中选择的文件夹。五十音、单词和语法内容随应用一起打包，绝不会被发送到任何地方。

网络访问

MyNihongo!!!!! 仅在以下情况下访问互联网：

• WebDAV 同步：如果您启用了 WebDAV 云同步，应用会将您的学习进度发送到您自行配置的 WebDAV 服务器。应用不会向其他任何服务器发送数据。

除此之外不进行任何网络通信。应用仅为此申请 INTERNET 权限，别无他用。

有两点需要明确说明：

• 您的 WebDAV 凭据以明文存放在应用的文件夹中，与本系列其他应用相同。任何能访问该文件夹的人——包括包含它的设备备份——都可以读到。如果您的服务器支持应用专用密码，请使用它，而不要使用主账号密码。

• 同步进行期间会保持设备唤醒，以免上传中途被打断。同步完成或失败后立即释放。

数据备份、导出与导入

应用提供本地备份功能以及 ZIP 导出与导入。备份文件存放在您的设备上；导出写入您选择的文件夹。两者都包含您的学习进度。这些文件之后去向何处完全由您掌控——应用绝不会上传它们。

选择文件夹或文件时使用系统选择器，它只授予应用对该位置的访问权限，无需存储权限。

政策变更

本隐私政策可能会不时更新。更新版本将在应用内或相关分发渠道发布。特别地，计划中的发音功能（语音识别与语音合成）会在发布前写入本政策；它们设计为在设备上运行，麦克风权限将在首次使用时带说明申请，而不会在安装时申请。''';
}

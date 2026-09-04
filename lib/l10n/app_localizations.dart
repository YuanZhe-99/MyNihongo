import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyNihongo!!!!!'**
  String get appTitle;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navKana.
  ///
  /// In en, this message translates to:
  /// **'Kana'**
  String get navKana;

  /// No description provided for @navVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get navVocab;

  /// No description provided for @navGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get navGrammar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @contentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the bundled content'**
  String get contentLoadFailed;

  /// No description provided for @referenceLevelAll.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get referenceLevelAll;

  /// No description provided for @referenceExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get referenceExamples;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTitle;

  /// No description provided for @learnWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MyNihongo!!!!!'**
  String get learnWelcome;

  /// No description provided for @learnWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews come back on a spaced-repetition schedule, so the words you nearly forgot arrive on the day you would have.'**
  String get learnWelcomeBody;

  /// No description provided for @learnToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get learnToday;

  /// No description provided for @learnStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String learnStreak(int count);

  /// No description provided for @learnStreakNone.
  ///
  /// In en, this message translates to:
  /// **'No streak yet — one answer starts it'**
  String get learnStreakNone;

  /// No description provided for @learnDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} due for review'**
  String learnDueCount(int count);

  /// No description provided for @learnDueNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing due'**
  String get learnDueNone;

  /// No description provided for @learnDueCapped.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} due today'**
  String learnDueCapped(int shown, int total);

  /// No description provided for @learnNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new items available'**
  String learnNewCount(int count);

  /// No description provided for @learnNewNone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s new items are done'**
  String get learnNewNone;

  /// No description provided for @learnAllDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do right now. Come back tomorrow, or browse.'**
  String get learnAllDone;

  /// No description provided for @learnReviewLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review limit is reached. Raise it in Settings if you want more.'**
  String get learnReviewLimitReached;

  /// No description provided for @learnContentSummary.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get learnContentSummary;

  /// No description provided for @learnKanaCount.
  ///
  /// In en, this message translates to:
  /// **'{count} kana'**
  String learnKanaCount(int count);

  /// No description provided for @learnVocabCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String learnVocabCount(int count);

  /// No description provided for @learnGrammarCount.
  ///
  /// In en, this message translates to:
  /// **'{count} grammar points'**
  String learnGrammarCount(int count);

  /// No description provided for @learnProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get learnProgressSummary;

  /// No description provided for @learnTrackedItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items tracked'**
  String learnTrackedItems(int count);

  /// No description provided for @learnMasteredItems.
  ///
  /// In en, this message translates to:
  /// **'{count} mastered'**
  String learnMasteredItems(int count);

  /// No description provided for @learnNoProgress.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet. Answer anything and it starts being scheduled.'**
  String get learnNoProgress;

  /// No description provided for @learnLevelProgress.
  ///
  /// In en, this message translates to:
  /// **'{level} progress'**
  String learnLevelProgress(Object level);

  /// No description provided for @learnLevelStarted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} items started'**
  String learnLevelStarted(int done, int total);

  /// No description provided for @learnQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get learnQuickStart;

  /// No description provided for @learnOpenKana.
  ///
  /// In en, this message translates to:
  /// **'Browse the kana chart'**
  String get learnOpenKana;

  /// No description provided for @learnOpenVocab.
  ///
  /// In en, this message translates to:
  /// **'Browse vocabulary'**
  String get learnOpenVocab;

  /// No description provided for @learnOpenGrammar.
  ///
  /// In en, this message translates to:
  /// **'Browse grammar'**
  String get learnOpenGrammar;

  /// No description provided for @learnRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Coming next'**
  String get learnRoadmap;

  /// No description provided for @learnRoadmapSrs.
  ///
  /// In en, this message translates to:
  /// **'Quizzes and a step-by-step lesson path'**
  String get learnRoadmapSrs;

  /// No description provided for @learnRoadmapJlpt.
  ///
  /// In en, this message translates to:
  /// **'JLPT N5–N1 practice sets'**
  String get learnRoadmapJlpt;

  /// No description provided for @kanaTitle.
  ///
  /// In en, this message translates to:
  /// **'Kana'**
  String get kanaTitle;

  /// No description provided for @kanaScriptHiragana.
  ///
  /// In en, this message translates to:
  /// **'Hiragana'**
  String get kanaScriptHiragana;

  /// No description provided for @kanaScriptKatakana.
  ///
  /// In en, this message translates to:
  /// **'Katakana'**
  String get kanaScriptKatakana;

  /// No description provided for @kanaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search kana or romaji…'**
  String get kanaSearchHint;

  /// No description provided for @kanaSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Matches ({count})'**
  String kanaSearchResults(int count);

  /// No description provided for @kanaNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching kana'**
  String get kanaNoMatches;

  /// No description provided for @kanaBasicSection.
  ///
  /// In en, this message translates to:
  /// **'Gojūon'**
  String get kanaBasicSection;

  /// No description provided for @kanaVoicedSection.
  ///
  /// In en, this message translates to:
  /// **'Dakuten'**
  String get kanaVoicedSection;

  /// No description provided for @kanaYoonSection.
  ///
  /// In en, this message translates to:
  /// **'Yōon'**
  String get kanaYoonSection;

  /// No description provided for @kanaRulesSection.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get kanaRulesSection;

  /// No description provided for @kanaRuleMoraTitle.
  ///
  /// In en, this message translates to:
  /// **'One kana, one beat'**
  String get kanaRuleMoraTitle;

  /// No description provided for @kanaRuleMoraBody.
  ///
  /// In en, this message translates to:
  /// **'Each kana is one mora. Keep the rhythm even, like ka-ki-ku-ke-ko.'**
  String get kanaRuleMoraBody;

  /// No description provided for @kanaRuleVowelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stable vowels'**
  String get kanaRuleVowelsTitle;

  /// No description provided for @kanaRuleVowelsBody.
  ///
  /// In en, this message translates to:
  /// **'a, i, u, e, o stay short and clean. Do not reduce them like unstressed English vowels.'**
  String get kanaRuleVowelsBody;

  /// No description provided for @kanaRuleDakutenTitle.
  ///
  /// In en, this message translates to:
  /// **'Dakuten and handakuten'**
  String get kanaRuleDakutenTitle;

  /// No description provided for @kanaRuleDakutenBody.
  ///
  /// In en, this message translates to:
  /// **'゛voices consonants: k to g, s to z, t to d, h to b. ゜changes h to p.'**
  String get kanaRuleDakutenBody;

  /// No description provided for @kanaRuleYoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Yōon combinations'**
  String get kanaRuleYoonTitle;

  /// No description provided for @kanaRuleYoonBody.
  ///
  /// In en, this message translates to:
  /// **'Small ゃ/ゅ/ょ merges with an i-row kana: き + ゃ becomes きゃ kya.'**
  String get kanaRuleYoonBody;

  /// No description provided for @kanaRuleSokuonTitle.
  ///
  /// In en, this message translates to:
  /// **'Small tsu'**
  String get kanaRuleSokuonTitle;

  /// No description provided for @kanaRuleSokuonBody.
  ///
  /// In en, this message translates to:
  /// **'Small っ/ッ doubles the next consonant with a brief stop, as in まって matte.'**
  String get kanaRuleSokuonBody;

  /// No description provided for @kanaRuleLongVowelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Long vowels'**
  String get kanaRuleLongVowelsTitle;

  /// No description provided for @kanaRuleLongVowelsBody.
  ///
  /// In en, this message translates to:
  /// **'ー lengthens katakana sounds. In hiragana, おう often sounds like long o, and えい like long e.'**
  String get kanaRuleLongVowelsBody;

  /// No description provided for @kanaRuleNTitle.
  ///
  /// In en, this message translates to:
  /// **'ん / ン'**
  String get kanaRuleNTitle;

  /// No description provided for @kanaRuleNBody.
  ///
  /// In en, this message translates to:
  /// **'Usually n, but it becomes m before m, b, or p, and a soft nasal before k or g.'**
  String get kanaRuleNBody;

  /// No description provided for @vocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabTitle;

  /// No description provided for @vocabSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search kanji, reading, or meaning…'**
  String get vocabSearchHint;

  /// No description provided for @vocabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching words'**
  String get vocabEmpty;

  /// No description provided for @vocabCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String vocabCount(int count);

  /// No description provided for @vocabPartOfSpeech.
  ///
  /// In en, this message translates to:
  /// **'Part of speech'**
  String get vocabPartOfSpeech;

  /// No description provided for @grammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammarTitle;

  /// No description provided for @grammarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search pattern or meaning…'**
  String get grammarSearchHint;

  /// No description provided for @grammarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching grammar points'**
  String get grammarEmpty;

  /// No description provided for @grammarCount.
  ///
  /// In en, this message translates to:
  /// **'{count} grammar points'**
  String grammarCount(int count);

  /// No description provided for @grammarStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get grammarStructure;

  /// No description provided for @grammarExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get grammarExplanation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsFurigana.
  ///
  /// In en, this message translates to:
  /// **'Kana over kanji'**
  String get settingsFurigana;

  /// No description provided for @settingsFuriganaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the reading above words that use kanji'**
  String get settingsFuriganaSubtitle;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get settingsStorageLocation;

  /// No description provided for @settingsSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Select an item from the list'**
  String get settingsSelectItem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'License (GPLv3)'**
  String get settingsLicense;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settingsLicenses;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settingsLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get settingsLearning;

  /// No description provided for @settingsTargetLevel.
  ///
  /// In en, this message translates to:
  /// **'Target level'**
  String get settingsTargetLevel;

  /// No description provided for @settingsTargetLevelBody.
  ///
  /// In en, this message translates to:
  /// **'New words and grammar are introduced from this level.'**
  String get settingsTargetLevelBody;

  /// No description provided for @settingsDailyNew.
  ///
  /// In en, this message translates to:
  /// **'New items a day'**
  String get settingsDailyNew;

  /// No description provided for @settingsDailyReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews a day'**
  String get settingsDailyReviews;

  /// No description provided for @settingsDailyLimitsBody.
  ///
  /// In en, this message translates to:
  /// **'Daily limits are part of your profile, so they follow you to your other devices.'**
  String get settingsDailyLimitsBody;

  /// No description provided for @settingsWebDAVSync.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get settingsWebDAVSync;

  /// No description provided for @settingsWebDAVServerURL.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsWebDAVServerURL;

  /// No description provided for @settingsWebDAVUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsWebDAVUsername;

  /// No description provided for @settingsWebDAVPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsWebDAVPassword;

  /// No description provided for @settingsWebDAVRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote Path'**
  String get settingsWebDAVRemotePath;

  /// No description provided for @settingsWebDAVNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud Preset'**
  String get settingsWebDAVNextcloud;

  /// No description provided for @settingsWebDAVTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settingsWebDAVTestConnection;

  /// No description provided for @settingsWebDAVAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get settingsWebDAVAutoSync;

  /// No description provided for @settingsWebDAVAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync after a review and when the app resumes'**
  String get settingsWebDAVAutoSyncDesc;

  /// No description provided for @settingsWebDAVSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsWebDAVSyncNow;

  /// No description provided for @settingsWebDAVSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get settingsWebDAVSyncing;

  /// No description provided for @settingsWebDAVDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsWebDAVDisconnect;

  /// No description provided for @settingsWebDAVConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get settingsWebDAVConfigSaved;

  /// No description provided for @settingsWebDAVConfigRemoved.
  ///
  /// In en, this message translates to:
  /// **'Configuration removed'**
  String get settingsWebDAVConfigRemoved;

  /// No description provided for @settingsWebDAVConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get settingsWebDAVConnectionSuccess;

  /// No description provided for @settingsWebDAVConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get settingsWebDAVConnectionFailed;

  /// No description provided for @settingsWebDAVSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get settingsWebDAVSyncSuccess;

  /// No description provided for @settingsWebDAVSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get settingsWebDAVSyncFailed;

  /// No description provided for @settingsWebDAVAutoSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync failed'**
  String get settingsWebDAVAutoSyncFailed;

  /// No description provided for @settingsWebDAVAutoSyncConflict.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync found conflicts'**
  String get settingsWebDAVAutoSyncConflict;

  /// No description provided for @settingsWebDAVLastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Last successful sync'**
  String get settingsWebDAVLastSuccess;

  /// No description provided for @settingsWebDAVNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsWebDAVNotConfigured;

  /// No description provided for @settingsWebDAVSyncWarnings.
  ///
  /// In en, this message translates to:
  /// **'Sync completed with {count} warning(s)'**
  String settingsWebDAVSyncWarnings(int count);

  /// No description provided for @settingsWebDAVForceUpload.
  ///
  /// In en, this message translates to:
  /// **'Force Upload'**
  String get settingsWebDAVForceUpload;

  /// No description provided for @settingsWebDAVForceDownload.
  ///
  /// In en, this message translates to:
  /// **'Force Download'**
  String get settingsWebDAVForceDownload;

  /// No description provided for @settingsWebDAVForceUploadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Force upload?'**
  String get settingsWebDAVForceUploadConfirmTitle;

  /// No description provided for @settingsWebDAVForceUploadConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite the remote progress with your local copy. Remote changes since the last sync will be lost.'**
  String get settingsWebDAVForceUploadConfirmBody;

  /// No description provided for @settingsWebDAVForceDownloadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Force download?'**
  String get settingsWebDAVForceDownloadConfirmTitle;

  /// No description provided for @settingsWebDAVForceDownloadConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace your local progress with the remote copy. Local changes since the last sync will be lost.'**
  String get settingsWebDAVForceDownloadConfirmBody;

  /// No description provided for @syncPhaseConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get syncPhaseConnecting;

  /// No description provided for @syncPhaseDownloadingData.
  ///
  /// In en, this message translates to:
  /// **'Downloading {file} ({current}/{total})'**
  String syncPhaseDownloadingData(Object file, int current, int total);

  /// No description provided for @syncPhaseMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging {file}…'**
  String syncPhaseMerging(Object file);

  /// No description provided for @syncPhaseUploadingData.
  ///
  /// In en, this message translates to:
  /// **'Uploading {file}…'**
  String syncPhaseUploadingData(Object file);

  /// No description provided for @syncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync conflict: {name}'**
  String syncConflictTitle(Object name);

  /// No description provided for @syncConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'This item was studied on both devices since the last sync. Keep one version.'**
  String get syncConflictDesc;

  /// No description provided for @syncUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'This item is not in the current content catalog.'**
  String get syncUnknownItem;

  /// No description provided for @syncLocalVersion.
  ///
  /// In en, this message translates to:
  /// **'Local version'**
  String get syncLocalVersion;

  /// No description provided for @syncRemoteVersion.
  ///
  /// In en, this message translates to:
  /// **'Remote version'**
  String get syncRemoteVersion;

  /// No description provided for @syncModifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified: {time}'**
  String syncModifiedAt(Object time);

  /// No description provided for @syncRecordAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct {correct} · Wrong {wrong}'**
  String syncRecordAnswers(int correct, int wrong);

  /// No description provided for @syncStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak: {count}'**
  String syncStreak(int count);

  /// No description provided for @syncProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your learning profile'**
  String get syncProfileTitle;

  /// No description provided for @syncProfileLevel.
  ///
  /// In en, this message translates to:
  /// **'Target level: {level}'**
  String syncProfileLevel(Object level);

  /// No description provided for @syncProfileDaily.
  ///
  /// In en, this message translates to:
  /// **'{newItems} new, {reviews} reviews a day'**
  String syncProfileDaily(int newItems, int reviews);

  /// No description provided for @syncProfileStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String syncProfileStreak(int count);

  /// No description provided for @syncStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get syncStage;

  /// No description provided for @stageFresh.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get stageFresh;

  /// No description provided for @stageLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get stageLearning;

  /// No description provided for @stageMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get stageMastered;

  /// No description provided for @syncLastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed: {time}'**
  String syncLastReviewed(Object time);

  /// No description provided for @syncNeverReviewed.
  ///
  /// In en, this message translates to:
  /// **'Never reviewed'**
  String get syncNeverReviewed;

  /// No description provided for @syncKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get syncKeepLocal;

  /// No description provided for @syncKeepRemote.
  ///
  /// In en, this message translates to:
  /// **'Keep Remote'**
  String get syncKeepRemote;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full local backup of your learning progress'**
  String get backupSubtitle;

  /// No description provided for @backupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreate;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the backup'**
  String get backupFailed;

  /// No description provided for @backupAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoBackup;

  /// No description provided for @backupAutoBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Back up once a day when the app starts'**
  String get backupAutoBackupDesc;

  /// No description provided for @backupRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep backups for'**
  String get backupRetention;

  /// No description provided for @backupKeepForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get backupKeepForever;

  /// No description provided for @backupKeepDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String backupKeepDays(int days);

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'History ({count})'**
  String backupHistory(int count);

  /// No description provided for @backupNoBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupNoBackups;

  /// No description provided for @backupCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get backupCorrupt;

  /// No description provided for @backupLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Backups stay on this device. They are never uploaded anywhere.'**
  String get backupLocalOnlyNote;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'This replaces the selected data with the backup. Continue?'**
  String get backupRestoreConfirm;

  /// No description provided for @backupRestoreModules.
  ///
  /// In en, this message translates to:
  /// **'What to restore'**
  String get backupRestoreModules;

  /// No description provided for @backupSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get backupSelectAll;

  /// No description provided for @backupModuleProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning progress'**
  String get backupModuleProgress;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestored;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore the backup'**
  String get backupRestoreFailed;

  /// No description provided for @backupDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get backupDeleteConfirm;

  /// No description provided for @backupRestoredSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync has been turned off so the restored data is not merged into your server by accident.'**
  String get backupRestoredSyncDisabled;

  /// No description provided for @backupForceUploadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the remote copy with the restored data?'**
  String get backupForceUploadPrompt;

  /// No description provided for @backupForceUploadSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get backupForceUploadSkip;

  /// No description provided for @backupForceUploadDone.
  ///
  /// In en, this message translates to:
  /// **'Remote copy overwritten'**
  String get backupForceUploadDone;

  /// No description provided for @backupForceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get backupForceUploadFailed;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export to ZIP'**
  String get exportData;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import from ZIP'**
  String get importData;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'This replaces your local progress with the contents of the archive. Continue?'**
  String get importConfirm;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @licenseContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Content licenses'**
  String get licenseContentTitle;

  /// No description provided for @licenseContentBody.
  ///
  /// In en, this message translates to:
  /// **'The vocabulary in this app is derived from open dictionaries and word lists. Their licences require the attribution below, which is why it is not translated.'**
  String get licenseContentBody;

  /// No description provided for @vocabGrammarUsed.
  ///
  /// In en, this message translates to:
  /// **'Grammar in these examples'**
  String get vocabGrammarUsed;

  /// No description provided for @grammarWordsUsed.
  ///
  /// In en, this message translates to:
  /// **'Words in these examples'**
  String get grammarWordsUsed;

  /// No description provided for @kanaExampleWords.
  ///
  /// In en, this message translates to:
  /// **'Words starting with this kana'**
  String get kanaExampleWords;

  /// No description provided for @kanaStrokes.
  ///
  /// In en, this message translates to:
  /// **'{count} strokes'**
  String kanaStrokes(int count);

  /// No description provided for @kanaConfusableWith.
  ///
  /// In en, this message translates to:
  /// **'Easily confused with'**
  String get kanaConfusableWith;

  /// No description provided for @kanaNoExtras.
  ///
  /// In en, this message translates to:
  /// **'No notes for this kana yet.'**
  String get kanaNoExtras;

  /// No description provided for @listColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get listColumns;

  /// No description provided for @listColumnsAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get listColumnsAuto;

  /// No description provided for @listColumnsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String listColumnsCount(int count);

  /// No description provided for @speechSection.
  ///
  /// In en, this message translates to:
  /// **'Speech'**
  String get speechSection;

  /// No description provided for @speechSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get speechSpeak;

  /// No description provided for @speechStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get speechStop;

  /// No description provided for @speechRate.
  ///
  /// In en, this message translates to:
  /// **'Speaking speed'**
  String get speechRate;

  /// No description provided for @speechRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate}x'**
  String speechRateValue(Object rate);

  /// No description provided for @speechRatePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get speechRatePreview;

  /// No description provided for @speechVoice.
  ///
  /// In en, this message translates to:
  /// **'Japanese voice'**
  String get speechVoice;

  /// No description provided for @speechVoiceDefault.
  ///
  /// In en, this message translates to:
  /// **'Chosen automatically'**
  String get speechVoiceDefault;

  /// No description provided for @speechVoiceUsing.
  ///
  /// In en, this message translates to:
  /// **'Using {voice}'**
  String speechVoiceUsing(Object voice);

  /// No description provided for @speechVoicePick.
  ///
  /// In en, this message translates to:
  /// **'Choose a Japanese voice'**
  String get speechVoicePick;

  /// No description provided for @speechVoiceNumbered.
  ///
  /// In en, this message translates to:
  /// **'Japanese voice {number}'**
  String speechVoiceNumbered(int number);

  /// No description provided for @speechVoicePreview.
  ///
  /// In en, this message translates to:
  /// **'Play a sample'**
  String get speechVoicePreview;

  /// No description provided for @speechVoiceOffline.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get speechVoiceOffline;

  /// No description provided for @speechVoiceNetwork.
  ///
  /// In en, this message translates to:
  /// **'Needs the network'**
  String get speechVoiceNetwork;

  /// No description provided for @speechVoiceNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get speechVoiceNotInstalled;

  /// No description provided for @speechVoiceQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'Higher quality'**
  String get speechVoiceQualityHigh;

  /// No description provided for @speechVoiceQualityNormal.
  ///
  /// In en, this message translates to:
  /// **'Standard quality'**
  String get speechVoiceQualityNormal;

  /// No description provided for @speechVoiceQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Lower quality'**
  String get speechVoiceQualityLow;

  /// No description provided for @speechEngine.
  ///
  /// In en, this message translates to:
  /// **'Speech engine'**
  String get speechEngine;

  /// No description provided for @speechEngineDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get speechEngineDefault;

  /// No description provided for @speechNoVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'No Japanese voice installed'**
  String get speechNoVoiceTitle;

  /// No description provided for @speechNoVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'The device speech engine has no Japanese voice, so nothing can be read aloud. Install one in the system speech settings, then reopen the app.'**
  String get speechNoVoiceBody;

  /// No description provided for @speechOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open speech settings'**
  String get speechOpenSystemSettings;

  /// No description provided for @speechOpenSystemSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the system speech settings'**
  String get speechOpenSystemSettingsFailed;

  /// No description provided for @speechSettingsHintApple.
  ///
  /// In en, this message translates to:
  /// **'Add a Japanese voice in System Settings, under Accessibility then Spoken Content.'**
  String get speechSettingsHintApple;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation practice'**
  String get practiceTitle;

  /// No description provided for @practiceStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get practiceStart;

  /// No description provided for @practiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get practiceListening;

  /// No description provided for @practiceProcessing.
  ///
  /// In en, this message translates to:
  /// **'Working out what you said…'**
  String get practiceProcessing;

  /// No description provided for @practiceRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get practiceRetry;

  /// No description provided for @practiceHeard.
  ///
  /// In en, this message translates to:
  /// **'Heard: {text}'**
  String practiceHeard(Object text);

  /// No description provided for @practiceScore.
  ///
  /// In en, this message translates to:
  /// **'{score} of 100'**
  String practiceScore(int score);

  /// No description provided for @practicePerfect.
  ///
  /// In en, this message translates to:
  /// **'Every mora matched.'**
  String get practicePerfect;

  /// No description provided for @practiceLegendCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get practiceLegendCorrect;

  /// No description provided for @practiceLegendSubstituted.
  ///
  /// In en, this message translates to:
  /// **'Different'**
  String get practiceLegendSubstituted;

  /// No description provided for @practiceLegendMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get practiceLegendMissing;

  /// No description provided for @practiceLegendExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get practiceLegendExtra;

  /// No description provided for @practiceLimitsNote.
  ///
  /// In en, this message translates to:
  /// **'This compares what the speech recognizer understood with the reading. It judges whether you were recognisable, not your accent or pitch.'**
  String get practiceLimitsNote;

  /// No description provided for @practiceNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recognized. Try again, a little closer to the microphone.'**
  String get practiceNoMatch;

  /// No description provided for @practiceLanguageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No offline Japanese recognition on this device. Install the Japanese speech data in the system settings, or allow the network fallback in Settings › Speech.'**
  String get practiceLanguageUnavailable;

  /// No description provided for @practicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was declined, so nothing can be heard.'**
  String get practicePermissionDenied;

  /// No description provided for @practiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no speech recognizer the app can use.'**
  String get practiceUnavailable;

  /// No description provided for @practiceMicRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the microphone?'**
  String get practiceMicRationaleTitle;

  /// No description provided for @practiceMicRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'To compare your pronunciation, the app needs to hear you. Recognition runs on your device and no audio is stored or sent anywhere.'**
  String get practiceMicRationaleBody;

  /// No description provided for @practiceMicRationaleAllow.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get practiceMicRationaleAllow;

  /// No description provided for @speechNetworkFallback.
  ///
  /// In en, this message translates to:
  /// **'Allow network recognition'**
  String get speechNetworkFallback;

  /// No description provided for @speechNetworkFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Off by default. When on, and your device has no offline Japanese recognition, what you say is sent to the system speech service to be transcribed.'**
  String get speechNetworkFallbackBody;

  /// No description provided for @speechRecognizerReady.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is available'**
  String get speechRecognizerReady;

  /// No description provided for @speechRecognizerMissing.
  ///
  /// In en, this message translates to:
  /// **'No Japanese speech recognition on this device'**
  String get speechRecognizerMissing;

  /// No description provided for @speechRecognizerUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is checked the first time you practise'**
  String get speechRecognizerUnchecked;

  /// No description provided for @practiceAction.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get practiceAction;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @quizStartReviews.
  ///
  /// In en, this message translates to:
  /// **'Start reviews'**
  String get quizStartReviews;

  /// No description provided for @quizStartNew.
  ///
  /// In en, this message translates to:
  /// **'Learn new items'**
  String get quizStartNew;

  /// No description provided for @quizThisLevel.
  ///
  /// In en, this message translates to:
  /// **'Quiz this level'**
  String get quizThisLevel;

  /// No description provided for @quizThisTable.
  ///
  /// In en, this message translates to:
  /// **'Quiz these kana'**
  String get quizThisTable;

  /// No description provided for @quizProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String quizProgress(int done, int total);

  /// No description provided for @quizCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get quizCheck;

  /// No description provided for @quizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quizContinue;

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get quizWrong;

  /// No description provided for @quizExpected.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String quizExpected(Object answer);

  /// No description provided for @quizListenPrompt.
  ///
  /// In en, this message translates to:
  /// **'Listen, then choose'**
  String get quizListenPrompt;

  /// No description provided for @quizTypeReadingHint.
  ///
  /// In en, this message translates to:
  /// **'Type the reading'**
  String get quizTypeReadingHint;

  /// No description provided for @quizOrderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Put the pieces in order'**
  String get quizOrderPrompt;

  /// No description provided for @quizOrderReset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get quizOrderReset;

  /// No description provided for @quizConjugationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which form belongs in the blank?'**
  String get quizConjugationPrompt;

  /// No description provided for @quizParticlePrompt.
  ///
  /// In en, this message translates to:
  /// **'Which particle belongs in the blank?'**
  String get quizParticlePrompt;

  /// No description provided for @quizPatternPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which grammar point does this use?'**
  String get quizPatternPrompt;

  /// No description provided for @quizSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session finished'**
  String get quizSummaryTitle;

  /// No description provided for @quizSummaryScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} right first time'**
  String quizSummaryScore(int correct, int total);

  /// No description provided for @quizSummaryPerfect.
  ///
  /// In en, this message translates to:
  /// **'Everything right first time.'**
  String get quizSummaryPerfect;

  /// No description provided for @quizSummaryReview.
  ///
  /// In en, this message translates to:
  /// **'Worth another look'**
  String get quizSummaryReview;

  /// No description provided for @quizSummaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get quizSummaryDone;

  /// No description provided for @quizEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to ask about yet. Enable more quiz modes, or study some items first.'**
  String get quizEmpty;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Answers already given are kept. The rest of the session is discarded.'**
  String get quizLeaveBody;

  /// No description provided for @quizLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quizLeaveConfirm;

  /// No description provided for @quizModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz modes'**
  String get quizModesTitle;

  /// No description provided for @quizModesBody.
  ///
  /// In en, this message translates to:
  /// **'Switch off any way of asking you would rather not see. A mode that this device or this word cannot support is skipped anyway.'**
  String get quizModesBody;

  /// No description provided for @quizModesVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get quizModesVocab;

  /// No description provided for @quizModesKana.
  ///
  /// In en, this message translates to:
  /// **'Kana'**
  String get quizModesKana;

  /// No description provided for @quizModesGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get quizModesGrammar;

  /// No description provided for @quizModesNoneWarning.
  ///
  /// In en, this message translates to:
  /// **'At least one mode has to stay on.'**
  String get quizModesNoneWarning;

  /// No description provided for @quizModeVocabJaToMeaning.
  ///
  /// In en, this message translates to:
  /// **'Japanese to meaning'**
  String get quizModeVocabJaToMeaning;

  /// No description provided for @quizModeVocabMeaningToJa.
  ///
  /// In en, this message translates to:
  /// **'Meaning to Japanese'**
  String get quizModeVocabMeaningToJa;

  /// No description provided for @quizModeVocabReadingToKanji.
  ///
  /// In en, this message translates to:
  /// **'Reading to written form'**
  String get quizModeVocabReadingToKanji;

  /// No description provided for @quizModeVocabKanjiToReading.
  ///
  /// In en, this message translates to:
  /// **'Written form to reading'**
  String get quizModeVocabKanjiToReading;

  /// No description provided for @quizModeVocabListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get quizModeVocabListening;

  /// No description provided for @quizModeVocabTypeReading.
  ///
  /// In en, this message translates to:
  /// **'Type the reading'**
  String get quizModeVocabTypeReading;

  /// No description provided for @quizModeKanaToRomaji.
  ///
  /// In en, this message translates to:
  /// **'Kana to romaji'**
  String get quizModeKanaToRomaji;

  /// No description provided for @quizModeRomajiToKana.
  ///
  /// In en, this message translates to:
  /// **'Romaji to kana'**
  String get quizModeRomajiToKana;

  /// No description provided for @quizModeKanaListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get quizModeKanaListening;

  /// No description provided for @quizModeGrammarParticle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the particle'**
  String get quizModeGrammarParticle;

  /// No description provided for @quizModeGrammarConjugation.
  ///
  /// In en, this message translates to:
  /// **'Choose the form'**
  String get quizModeGrammarConjugation;

  /// No description provided for @quizModeGrammarOrder.
  ///
  /// In en, this message translates to:
  /// **'Order the pieces'**
  String get quizModeGrammarOrder;

  /// No description provided for @quizModeGrammarPattern.
  ///
  /// In en, this message translates to:
  /// **'Pick the grammar point'**
  String get quizModeGrammarPattern;

  /// No description provided for @formDictionary.
  ///
  /// In en, this message translates to:
  /// **'dictionary'**
  String get formDictionary;

  /// No description provided for @formMasuStem.
  ///
  /// In en, this message translates to:
  /// **'masu stem'**
  String get formMasuStem;

  /// No description provided for @formNaiStem.
  ///
  /// In en, this message translates to:
  /// **'nai stem'**
  String get formNaiStem;

  /// No description provided for @formTeStem.
  ///
  /// In en, this message translates to:
  /// **'te stem'**
  String get formTeStem;

  /// No description provided for @formEStem.
  ///
  /// In en, this message translates to:
  /// **'e stem'**
  String get formEStem;

  /// No description provided for @formPolite.
  ///
  /// In en, this message translates to:
  /// **'polite'**
  String get formPolite;

  /// No description provided for @formNegative.
  ///
  /// In en, this message translates to:
  /// **'negative'**
  String get formNegative;

  /// No description provided for @formPast.
  ///
  /// In en, this message translates to:
  /// **'past'**
  String get formPast;

  /// No description provided for @formTe.
  ///
  /// In en, this message translates to:
  /// **'te form'**
  String get formTe;

  /// No description provided for @formTai.
  ///
  /// In en, this message translates to:
  /// **'want to'**
  String get formTai;

  /// No description provided for @formPotential.
  ///
  /// In en, this message translates to:
  /// **'potential'**
  String get formPotential;

  /// No description provided for @formPassive.
  ///
  /// In en, this message translates to:
  /// **'passive'**
  String get formPassive;

  /// No description provided for @formCausative.
  ///
  /// In en, this message translates to:
  /// **'causative'**
  String get formCausative;

  /// No description provided for @formImperative.
  ///
  /// In en, this message translates to:
  /// **'imperative'**
  String get formImperative;

  /// No description provided for @formVolitional.
  ///
  /// In en, this message translates to:
  /// **'volitional'**
  String get formVolitional;

  /// No description provided for @formConditionalBa.
  ///
  /// In en, this message translates to:
  /// **'conditional ba'**
  String get formConditionalBa;

  /// No description provided for @formConditionalTara.
  ///
  /// In en, this message translates to:
  /// **'conditional tara'**
  String get formConditionalTara;

  /// No description provided for @formTari.
  ///
  /// In en, this message translates to:
  /// **'tari'**
  String get formTari;

  /// No description provided for @formNagara.
  ///
  /// In en, this message translates to:
  /// **'while'**
  String get formNagara;

  /// No description provided for @formAdverbial.
  ///
  /// In en, this message translates to:
  /// **'adverbial'**
  String get formAdverbial;

  /// No description provided for @formAttributive.
  ///
  /// In en, this message translates to:
  /// **'attributive'**
  String get formAttributive;

  /// No description provided for @formProgressive.
  ///
  /// In en, this message translates to:
  /// **'progressive'**
  String get formProgressive;

  /// No description provided for @formRequest.
  ///
  /// In en, this message translates to:
  /// **'request'**
  String get formRequest;

  /// No description provided for @labTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentence lab'**
  String get labTitle;

  /// No description provided for @labSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what a sentence is made of'**
  String get labSubtitle;

  /// No description provided for @labInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste a Japanese sentence'**
  String get labInputHint;

  /// No description provided for @labAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyse'**
  String get labAnalyze;

  /// No description provided for @labClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get labClear;

  /// No description provided for @labEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type a sentence above, or open one from a vocabulary or grammar example.'**
  String get labEmpty;

  /// No description provided for @labWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get labWords;

  /// No description provided for @labStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get labStructure;

  /// No description provided for @labGrammarUsed.
  ///
  /// In en, this message translates to:
  /// **'Grammar used'**
  String get labGrammarUsed;

  /// No description provided for @labGrammarNone.
  ///
  /// In en, this message translates to:
  /// **'No taught grammar point matched this sentence.'**
  String get labGrammarNone;

  /// No description provided for @labIssues.
  ///
  /// In en, this message translates to:
  /// **'Possible issues'**
  String get labIssues;

  /// No description provided for @labIssuesNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing looked unusual.'**
  String get labIssuesNone;

  /// No description provided for @labUnknownWarning.
  ///
  /// In en, this message translates to:
  /// **'Some characters are not in the bundled dictionary, so parts of this may be wrong.'**
  String get labUnknownWarning;

  /// No description provided for @labDependsOn.
  ///
  /// In en, this message translates to:
  /// **'modifies'**
  String get labDependsOn;

  /// No description provided for @labRoot.
  ///
  /// In en, this message translates to:
  /// **'main predicate'**
  String get labRoot;

  /// No description provided for @labLimitsNote.
  ///
  /// In en, this message translates to:
  /// **'This is a dictionary and a set of rules, not a translator. The structure is a best guess, and possible issues are worth checking rather than trusting.'**
  String get labLimitsNote;

  /// No description provided for @labOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Analyse this sentence'**
  String get labOpenAction;

  /// No description provided for @labIssueParticleFrame.
  ///
  /// In en, this message translates to:
  /// **'{word} usually takes が rather than を here.'**
  String labIssueParticleFrame(Object word);

  /// No description provided for @labIssueParticleFrameSuggest.
  ///
  /// In en, this message translates to:
  /// **'{word} usually takes が rather than を. Did you mean {suggestion}?'**
  String labIssueParticleFrameSuggest(Object word, Object suggestion);

  /// No description provided for @labIssueNaNo.
  ///
  /// In en, this message translates to:
  /// **'{word} may need {suggestion} before the next noun.'**
  String labIssueNaNo(Object word, Object suggestion);

  /// No description provided for @labIssueTense.
  ///
  /// In en, this message translates to:
  /// **'{word} points at another time than the verb\'s form.'**
  String labIssueTense(Object word);

  /// No description provided for @labIssueCopula.
  ///
  /// In en, this message translates to:
  /// **'This ends on {word} with nothing to predicate it. Did you mean {word}です?'**
  String labIssueCopula(Object word);

  /// No description provided for @labIssueAdjectiveAsVerb.
  ///
  /// In en, this message translates to:
  /// **'{word} is an adjective and does not take a verb ending.'**
  String labIssueAdjectiveAsVerb(Object word);

  /// No description provided for @labCategoryNoun.
  ///
  /// In en, this message translates to:
  /// **'noun'**
  String get labCategoryNoun;

  /// No description provided for @labCategoryVerb.
  ///
  /// In en, this message translates to:
  /// **'verb'**
  String get labCategoryVerb;

  /// No description provided for @labCategoryAdjective.
  ///
  /// In en, this message translates to:
  /// **'adjective'**
  String get labCategoryAdjective;

  /// No description provided for @labCategoryParticle.
  ///
  /// In en, this message translates to:
  /// **'particle'**
  String get labCategoryParticle;

  /// No description provided for @labCategoryAuxiliary.
  ///
  /// In en, this message translates to:
  /// **'auxiliary'**
  String get labCategoryAuxiliary;

  /// No description provided for @labCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get labCategoryOther;

  /// No description provided for @labCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'not in the dictionary'**
  String get labCategoryUnknown;

  /// No description provided for @aiSection.
  ///
  /// In en, this message translates to:
  /// **'On-device AI'**
  String get aiSection;

  /// No description provided for @aiEnable.
  ///
  /// In en, this message translates to:
  /// **'On-device AI assistance'**
  String get aiEnable;

  /// No description provided for @aiEnableBody.
  ///
  /// In en, this message translates to:
  /// **'Off by default. When on, the sentence lab can explain a finding in more words and suggest a correction, using a model that runs on this device. Generated text is always labelled and never changes the analysis.'**
  String get aiEnableBody;

  /// No description provided for @aiUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'This platform has no on-device model.'**
  String get aiUnsupportedPlatform;

  /// No description provided for @aiStatusPrompt.
  ///
  /// In en, this message translates to:
  /// **'Explanations'**
  String get aiStatusPrompt;

  /// No description provided for @aiStatusProofread.
  ///
  /// In en, this message translates to:
  /// **'Correction suggestions'**
  String get aiStatusProofread;

  /// No description provided for @aiStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get aiStatusUnavailable;

  /// No description provided for @aiStatusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The AI service could not be reached'**
  String get aiStatusUnreachable;

  /// No description provided for @aiStatusDownloadable.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded yet'**
  String get aiStatusDownloadable;

  /// No description provided for @aiStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'The system is downloading it'**
  String get aiStatusDownloading;

  /// No description provided for @aiStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get aiStatusAvailable;

  /// No description provided for @aiCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get aiCheckAgain;

  /// No description provided for @aiCoreVersion.
  ///
  /// In en, this message translates to:
  /// **'AICore {version}'**
  String aiCoreVersion(Object version);

  /// No description provided for @aiCoreMissing.
  ///
  /// In en, this message translates to:
  /// **'AICore is not installed on this device.'**
  String get aiCoreMissing;

  /// No description provided for @aiDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get aiDownload;

  /// No description provided for @aiDownloadNote.
  ///
  /// In en, this message translates to:
  /// **'The download is performed by the Android AICore system service, which fetches the model from Google. It starts only when you tap Download.'**
  String get aiDownloadNote;

  /// No description provided for @aiDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get aiDownloading;

  /// No description provided for @aiDownloadedBytes.
  ///
  /// In en, this message translates to:
  /// **'{megabytes} MB so far'**
  String aiDownloadedBytes(Object megabytes);

  /// No description provided for @aiDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The model could not be downloaded. You can try again.'**
  String get aiDownloadFailed;

  /// No description provided for @aiExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get aiExplain;

  /// No description provided for @aiExplainSentence.
  ///
  /// In en, this message translates to:
  /// **'Explain this sentence'**
  String get aiExplainSentence;

  /// No description provided for @aiSuggestCorrection.
  ///
  /// In en, this message translates to:
  /// **'Suggest a correction'**
  String get aiSuggestCorrection;

  /// No description provided for @aiGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'Generated on this device — may be wrong'**
  String get aiGeneratedLabel;

  /// No description provided for @aiGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating on your device…'**
  String get aiGenerating;

  /// No description provided for @aiDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get aiDismiss;

  /// No description provided for @aiCorrectionNone.
  ///
  /// In en, this message translates to:
  /// **'The model did not suggest a different sentence.'**
  String get aiCorrectionNone;

  /// No description provided for @aiCorrectionHeading.
  ///
  /// In en, this message translates to:
  /// **'One possible rewrite'**
  String get aiCorrectionHeading;

  /// No description provided for @aiFailedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The on-device model is not ready. Check Settings.'**
  String get aiFailedUnavailable;

  /// No description provided for @aiFailedBusy.
  ///
  /// In en, this message translates to:
  /// **'Another answer is still being generated.'**
  String get aiFailedBusy;

  /// No description provided for @aiFailedTimeout.
  ///
  /// In en, this message translates to:
  /// **'The model took too long. Try again.'**
  String get aiFailedTimeout;

  /// No description provided for @aiFailedTooLong.
  ///
  /// In en, this message translates to:
  /// **'This sentence is too long for the on-device model.'**
  String get aiFailedTooLong;

  /// No description provided for @aiFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Nothing could be generated for this.'**
  String get aiFailedGeneric;

  /// No description provided for @aiHintDownload.
  ///
  /// In en, this message translates to:
  /// **'On-device AI is on, but the model is not downloaded yet. Settings › On-device AI.'**
  String get aiHintDownload;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

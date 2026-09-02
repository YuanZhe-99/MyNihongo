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
  /// **'Kana, vocabulary and grammar to browse now; lessons, reviews and pronunciation practice are on the way.'**
  String get learnWelcomeBody;

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
  /// **'Nothing tracked yet. Lessons and reviews arrive in a later release.'**
  String get learnNoProgress;

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

  /// No description provided for @learnRoadmapPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation practice with speech recognition and text-to-speech'**
  String get learnRoadmapPronunciation;

  /// No description provided for @learnRoadmapSrs.
  ///
  /// In en, this message translates to:
  /// **'Spaced-repetition reviews and step-by-step lessons'**
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyNihongo!!!!!';

  @override
  String get navLearn => 'Learn';

  @override
  String get navKana => 'Kana';

  @override
  String get navVocab => 'Vocabulary';

  @override
  String get navGrammar => 'Grammar';

  @override
  String get navSettings => 'Settings';

  @override
  String get contentLoadFailed => 'Could not load the bundled content';

  @override
  String get referenceLevelAll => 'All levels';

  @override
  String get referenceExamples => 'Examples';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnWelcome => 'Welcome to MyNihongo!!!!!';

  @override
  String get learnWelcomeBody =>
      'Kana, vocabulary and grammar to browse now; lessons, reviews and pronunciation practice are on the way.';

  @override
  String get learnContentSummary => 'Content';

  @override
  String learnKanaCount(int count) {
    return '$count kana';
  }

  @override
  String learnVocabCount(int count) {
    return '$count words';
  }

  @override
  String learnGrammarCount(int count) {
    return '$count grammar points';
  }

  @override
  String get learnProgressSummary => 'Your progress';

  @override
  String learnTrackedItems(int count) {
    return '$count items tracked';
  }

  @override
  String learnMasteredItems(int count) {
    return '$count mastered';
  }

  @override
  String get learnNoProgress =>
      'Nothing tracked yet. Lessons and reviews arrive in a later release.';

  @override
  String get learnQuickStart => 'Quick start';

  @override
  String get learnOpenKana => 'Browse the kana chart';

  @override
  String get learnOpenVocab => 'Browse vocabulary';

  @override
  String get learnOpenGrammar => 'Browse grammar';

  @override
  String get learnRoadmap => 'Coming next';

  @override
  String get learnRoadmapPronunciation =>
      'Pronunciation practice with speech recognition and text-to-speech';

  @override
  String get learnRoadmapSrs =>
      'Spaced-repetition reviews and step-by-step lessons';

  @override
  String get learnRoadmapJlpt => 'JLPT N5–N1 practice sets';

  @override
  String get kanaTitle => 'Kana';

  @override
  String get kanaScriptHiragana => 'Hiragana';

  @override
  String get kanaScriptKatakana => 'Katakana';

  @override
  String get kanaSearchHint => 'Search kana or romaji…';

  @override
  String kanaSearchResults(int count) {
    return 'Matches ($count)';
  }

  @override
  String get kanaNoMatches => 'No matching kana';

  @override
  String get kanaBasicSection => 'Gojūon';

  @override
  String get kanaVoicedSection => 'Dakuten';

  @override
  String get kanaYoonSection => 'Yōon';

  @override
  String get kanaRulesSection => 'Pronunciation';

  @override
  String get kanaRuleMoraTitle => 'One kana, one beat';

  @override
  String get kanaRuleMoraBody =>
      'Each kana is one mora. Keep the rhythm even, like ka-ki-ku-ke-ko.';

  @override
  String get kanaRuleVowelsTitle => 'Stable vowels';

  @override
  String get kanaRuleVowelsBody =>
      'a, i, u, e, o stay short and clean. Do not reduce them like unstressed English vowels.';

  @override
  String get kanaRuleDakutenTitle => 'Dakuten and handakuten';

  @override
  String get kanaRuleDakutenBody =>
      '゛voices consonants: k to g, s to z, t to d, h to b. ゜changes h to p.';

  @override
  String get kanaRuleYoonTitle => 'Yōon combinations';

  @override
  String get kanaRuleYoonBody =>
      'Small ゃ/ゅ/ょ merges with an i-row kana: き + ゃ becomes きゃ kya.';

  @override
  String get kanaRuleSokuonTitle => 'Small tsu';

  @override
  String get kanaRuleSokuonBody =>
      'Small っ/ッ doubles the next consonant with a brief stop, as in まって matte.';

  @override
  String get kanaRuleLongVowelsTitle => 'Long vowels';

  @override
  String get kanaRuleLongVowelsBody =>
      'ー lengthens katakana sounds. In hiragana, おう often sounds like long o, and えい like long e.';

  @override
  String get kanaRuleNTitle => 'ん / ン';

  @override
  String get kanaRuleNBody =>
      'Usually n, but it becomes m before m, b, or p, and a soft nasal before k or g.';

  @override
  String get vocabTitle => 'Vocabulary';

  @override
  String get vocabSearchHint => 'Search kanji, reading, or meaning…';

  @override
  String get vocabEmpty => 'No matching words';

  @override
  String vocabCount(int count) {
    return '$count words';
  }

  @override
  String get vocabPartOfSpeech => 'Part of speech';

  @override
  String get grammarTitle => 'Grammar';

  @override
  String get grammarSearchHint => 'Search pattern or meaning…';

  @override
  String get grammarEmpty => 'No matching grammar points';

  @override
  String grammarCount(int count) {
    return '$count grammar points';
  }

  @override
  String get grammarStructure => 'Structure';

  @override
  String get grammarExplanation => 'Explanation';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsStorageLocation => 'Storage Location';

  @override
  String get settingsSelectItem => 'Select an item from the list';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsLicense => 'License (GPLv3)';

  @override
  String get settingsLicenses => 'Open Source Licenses';
}

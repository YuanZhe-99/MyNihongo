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

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get settingsWebDAVSync => 'WebDAV Sync';

  @override
  String get settingsWebDAVServerURL => 'Server URL';

  @override
  String get settingsWebDAVUsername => 'Username';

  @override
  String get settingsWebDAVPassword => 'Password';

  @override
  String get settingsWebDAVRemotePath => 'Remote Path';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud Preset';

  @override
  String get settingsWebDAVTestConnection => 'Test Connection';

  @override
  String get settingsWebDAVAutoSync => 'Auto-sync';

  @override
  String get settingsWebDAVAutoSyncDesc =>
      'Automatically sync after a review and when the app resumes';

  @override
  String get settingsWebDAVSyncNow => 'Sync Now';

  @override
  String get settingsWebDAVSyncing => 'Syncing…';

  @override
  String get settingsWebDAVDisconnect => 'Disconnect';

  @override
  String get settingsWebDAVConfigSaved => 'Configuration saved';

  @override
  String get settingsWebDAVConfigRemoved => 'Configuration removed';

  @override
  String get settingsWebDAVConnectionSuccess => 'Connection successful';

  @override
  String get settingsWebDAVConnectionFailed => 'Connection failed';

  @override
  String get settingsWebDAVSyncSuccess => 'Sync completed';

  @override
  String get settingsWebDAVSyncFailed => 'Sync failed';

  @override
  String get settingsWebDAVAutoSyncFailed => 'Auto-sync failed';

  @override
  String get settingsWebDAVAutoSyncConflict => 'Auto-sync found conflicts';

  @override
  String get settingsWebDAVLastSuccess => 'Last successful sync';

  @override
  String get settingsWebDAVNotConfigured => 'Not connected';

  @override
  String settingsWebDAVSyncWarnings(int count) {
    return 'Sync completed with $count warning(s)';
  }

  @override
  String get settingsWebDAVForceUpload => 'Force Upload';

  @override
  String get settingsWebDAVForceDownload => 'Force Download';

  @override
  String get settingsWebDAVForceUploadConfirmTitle => 'Force upload?';

  @override
  String get settingsWebDAVForceUploadConfirmBody =>
      'This will overwrite the remote progress with your local copy. Remote changes since the last sync will be lost.';

  @override
  String get settingsWebDAVForceDownloadConfirmTitle => 'Force download?';

  @override
  String get settingsWebDAVForceDownloadConfirmBody =>
      'This will replace your local progress with the remote copy. Local changes since the last sync will be lost.';

  @override
  String get syncPhaseConnecting => 'Connecting…';

  @override
  String syncPhaseDownloadingData(Object file, int current, int total) {
    return 'Downloading $file ($current/$total)';
  }

  @override
  String syncPhaseMerging(Object file) {
    return 'Merging $file…';
  }

  @override
  String syncPhaseUploadingData(Object file) {
    return 'Uploading $file…';
  }

  @override
  String syncConflictTitle(Object name) {
    return 'Sync conflict: $name';
  }

  @override
  String get syncConflictDesc =>
      'This item was studied on both devices since the last sync. Keep one version.';

  @override
  String get syncUnknownItem =>
      'This item is not in the current content catalog.';

  @override
  String get syncLocalVersion => 'Local version';

  @override
  String get syncRemoteVersion => 'Remote version';

  @override
  String syncModifiedAt(Object time) {
    return 'Modified: $time';
  }

  @override
  String syncRecordAnswers(int correct, int wrong) {
    return 'Correct $correct · Wrong $wrong';
  }

  @override
  String syncStreak(int count) {
    return 'Streak: $count';
  }

  @override
  String get syncStage => 'Stage';

  @override
  String get stageFresh => 'Not started';

  @override
  String get stageLearning => 'Learning';

  @override
  String get stageMastered => 'Mastered';

  @override
  String syncLastReviewed(Object time) {
    return 'Last reviewed: $time';
  }

  @override
  String get syncNeverReviewed => 'Never reviewed';

  @override
  String get syncKeepLocal => 'Keep Local';

  @override
  String get syncKeepRemote => 'Keep Remote';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupSubtitle => 'Full local backup of your learning progress';

  @override
  String get backupCreate => 'Create backup';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupFailed => 'Could not create the backup';

  @override
  String get backupAutoBackup => 'Automatic backup';

  @override
  String get backupAutoBackupDesc => 'Back up once a day when the app starts';

  @override
  String get backupRetention => 'Keep backups for';

  @override
  String get backupKeepForever => 'Forever';

  @override
  String backupKeepDays(int days) {
    return '$days days';
  }

  @override
  String backupHistory(int count) {
    return 'History ($count)';
  }

  @override
  String get backupNoBackups => 'No backups yet';

  @override
  String get backupCorrupt => 'Damaged';

  @override
  String get backupLocalOnlyNote =>
      'Backups stay on this device. They are never uploaded anywhere.';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupRestoreConfirm =>
      'This replaces the selected data with the backup. Continue?';

  @override
  String get backupRestoreModules => 'What to restore';

  @override
  String get backupSelectAll => 'Select all';

  @override
  String get backupModuleProgress => 'Learning progress';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String get backupRestoreFailed => 'Could not restore the backup';

  @override
  String get backupDeleteConfirm => 'Delete this backup?';

  @override
  String get backupRestoredSyncDisabled =>
      'Auto-sync has been turned off so the restored data is not merged into your server by accident.';

  @override
  String get backupForceUploadPrompt =>
      'Overwrite the remote copy with the restored data?';

  @override
  String get backupForceUploadSkip => 'Not now';

  @override
  String get backupForceUploadDone => 'Remote copy overwritten';

  @override
  String get backupForceUploadFailed => 'Upload failed';

  @override
  String get exportData => 'Export to ZIP';

  @override
  String get exportSuccess => 'Exported';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get importData => 'Import from ZIP';

  @override
  String get importConfirm =>
      'This replaces your local progress with the contents of the archive. Continue?';

  @override
  String get importSuccess => 'Import complete';

  @override
  String get importFailed => 'Import failed';

  @override
  String get licenseContentTitle => 'Content licenses';

  @override
  String get licenseContentBody =>
      'The vocabulary in this app is derived from open dictionaries and word lists. Their licences require the attribution below, which is why it is not translated.';

  @override
  String get vocabGrammarUsed => 'Grammar in these examples';

  @override
  String get grammarWordsUsed => 'Words in these examples';

  @override
  String get kanaExampleWords => 'Words starting with this kana';

  @override
  String kanaStrokes(int count) {
    return '$count strokes';
  }

  @override
  String get kanaConfusableWith => 'Easily confused with';

  @override
  String get kanaNoExtras => 'No notes for this kana yet.';

  @override
  String get listColumns => 'Columns';

  @override
  String get listColumnsAuto => 'Automatic';

  @override
  String listColumnsCount(int count) {
    return '$count';
  }
}

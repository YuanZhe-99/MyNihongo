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
      'Kana, vocabulary and grammar to browse, everything read aloud, pronunciation practice and the sentence lab; lessons and reviews are on the way.';

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
  String get learnRoadmapSrs =>
      'Spaced-repetition reviews, quizzes and a step-by-step lesson path';

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

  @override
  String get speechSection => 'Speech';

  @override
  String get speechSpeak => 'Speak';

  @override
  String get speechStop => 'Stop';

  @override
  String get speechRate => 'Speaking speed';

  @override
  String speechRateValue(Object rate) {
    return '${rate}x';
  }

  @override
  String get speechRatePreview => 'Preview';

  @override
  String get speechVoice => 'Japanese voice';

  @override
  String get speechVoiceDefault => 'Engine default';

  @override
  String get speechNoVoiceTitle => 'No Japanese voice installed';

  @override
  String get speechNoVoiceBody =>
      'The device speech engine has no Japanese voice, so nothing can be read aloud. Install one in the system speech settings, then reopen the app.';

  @override
  String get speechOpenSystemSettings => 'Open speech settings';

  @override
  String get speechOpenSystemSettingsFailed =>
      'Could not open the system speech settings';

  @override
  String get speechSettingsHintApple =>
      'Add a Japanese voice in System Settings, under Accessibility then Spoken Content.';

  @override
  String get practiceTitle => 'Pronunciation practice';

  @override
  String get practiceStart => 'Tap to speak';

  @override
  String get practiceListening => 'Listening…';

  @override
  String get practiceProcessing => 'Working out what you said…';

  @override
  String get practiceRetry => 'Try again';

  @override
  String practiceHeard(Object text) {
    return 'Heard: $text';
  }

  @override
  String practiceScore(int score) {
    return '$score of 100';
  }

  @override
  String get practicePerfect => 'Every mora matched.';

  @override
  String get practiceLegendCorrect => 'Correct';

  @override
  String get practiceLegendSubstituted => 'Different';

  @override
  String get practiceLegendMissing => 'Missing';

  @override
  String get practiceLegendExtra => 'Extra';

  @override
  String get practiceLimitsNote =>
      'This compares what the speech recognizer understood with the reading. It judges whether you were recognisable, not your accent or pitch.';

  @override
  String get practiceNoMatch =>
      'Nothing was recognized. Try again, a little closer to the microphone.';

  @override
  String get practiceLanguageUnavailable =>
      'No offline Japanese recognition on this device. Install the Japanese speech data in the system settings, or allow the network fallback in Settings › Speech.';

  @override
  String get practicePermissionDenied =>
      'Microphone access was declined, so nothing can be heard.';

  @override
  String get practiceUnavailable =>
      'This device has no speech recognizer the app can use.';

  @override
  String get practiceMicRationaleTitle => 'Use the microphone?';

  @override
  String get practiceMicRationaleBody =>
      'To compare your pronunciation, the app needs to hear you. Recognition runs on your device and no audio is stored or sent anywhere.';

  @override
  String get practiceMicRationaleAllow => 'Continue';

  @override
  String get speechNetworkFallback => 'Allow network recognition';

  @override
  String get speechNetworkFallbackBody =>
      'Off by default. When on, and your device has no offline Japanese recognition, what you say is sent to the system speech service to be transcribed.';

  @override
  String get speechRecognizerReady => 'Speech recognition is available';

  @override
  String get speechRecognizerMissing =>
      'No Japanese speech recognition on this device';

  @override
  String get speechRecognizerUnchecked =>
      'Speech recognition is checked the first time you practise';

  @override
  String get practiceAction => 'Practise';

  @override
  String get labTitle => 'Sentence lab';

  @override
  String get labSubtitle => 'See what a sentence is made of';

  @override
  String get labInputHint => 'Type or paste a Japanese sentence';

  @override
  String get labAnalyze => 'Analyse';

  @override
  String get labClear => 'Clear';

  @override
  String get labEmpty =>
      'Type a sentence above, or open one from a vocabulary or grammar example.';

  @override
  String get labWords => 'Words';

  @override
  String get labStructure => 'Structure';

  @override
  String get labGrammarUsed => 'Grammar used';

  @override
  String get labGrammarNone => 'No taught grammar point matched this sentence.';

  @override
  String get labIssues => 'Possible issues';

  @override
  String get labIssuesNone => 'Nothing looked unusual.';

  @override
  String get labUnknownWarning =>
      'Some characters are not in the bundled dictionary, so parts of this may be wrong.';

  @override
  String get labDependsOn => 'modifies';

  @override
  String get labRoot => 'main predicate';

  @override
  String get labLimitsNote =>
      'This is a dictionary and a set of rules, not a translator. The structure is a best guess, and possible issues are worth checking rather than trusting.';

  @override
  String get labOpenAction => 'Analyse this sentence';

  @override
  String labIssueParticleFrame(Object word) {
    return '$word usually takes が rather than を here.';
  }

  @override
  String labIssueParticleFrameSuggest(Object word, Object suggestion) {
    return '$word usually takes が rather than を. Did you mean $suggestion?';
  }

  @override
  String labIssueNaNo(Object word, Object suggestion) {
    return '$word may need $suggestion before the next noun.';
  }

  @override
  String labIssueTense(Object word) {
    return '$word points at another time than the verb\'s form.';
  }

  @override
  String labIssueCopula(Object word) {
    return 'This ends on $word with nothing to predicate it. Did you mean $wordです?';
  }

  @override
  String labIssueAdjectiveAsVerb(Object word) {
    return '$word is an adjective and does not take a verb ending.';
  }

  @override
  String get labCategoryNoun => 'noun';

  @override
  String get labCategoryVerb => 'verb';

  @override
  String get labCategoryAdjective => 'adjective';

  @override
  String get labCategoryParticle => 'particle';

  @override
  String get labCategoryAuxiliary => 'auxiliary';

  @override
  String get labCategoryOther => 'other';

  @override
  String get labCategoryUnknown => 'not in the dictionary';

  @override
  String get aiSection => 'On-device AI';

  @override
  String get aiEnable => 'On-device AI assistance';

  @override
  String get aiEnableBody =>
      'Off by default. When on, the sentence lab can explain a finding in more words and suggest a correction, using a model that runs on this device. Generated text is always labelled and never changes the analysis.';

  @override
  String get aiUnsupportedPlatform => 'This platform has no on-device model.';

  @override
  String get aiStatusPrompt => 'Explanations';

  @override
  String get aiStatusProofread => 'Correction suggestions';

  @override
  String get aiStatusUnavailable => 'Not available on this device';

  @override
  String get aiStatusDownloadable => 'Not downloaded yet';

  @override
  String get aiStatusDownloading => 'The system is downloading it';

  @override
  String get aiStatusAvailable => 'Ready';

  @override
  String get aiDownload => 'Download';

  @override
  String get aiDownloadNote =>
      'The download is performed by the Android AICore system service, which fetches the model from Google. It starts only when you tap Download.';

  @override
  String get aiDownloading => 'Downloading…';

  @override
  String aiDownloadedBytes(Object megabytes) {
    return '$megabytes MB so far';
  }

  @override
  String get aiDownloadFailed =>
      'The model could not be downloaded. You can try again.';

  @override
  String get aiExplain => 'Explain';

  @override
  String get aiExplainSentence => 'Explain this sentence';

  @override
  String get aiSuggestCorrection => 'Suggest a correction';

  @override
  String get aiGeneratedLabel => 'Generated on this device — may be wrong';

  @override
  String get aiGenerating => 'Generating on your device…';

  @override
  String get aiDismiss => 'Dismiss';

  @override
  String get aiCorrectionNone =>
      'The model did not suggest a different sentence.';

  @override
  String get aiCorrectionHeading => 'One possible rewrite';

  @override
  String get aiFailedUnavailable =>
      'The on-device model is not ready. Check Settings.';

  @override
  String get aiFailedBusy => 'Another answer is still being generated.';

  @override
  String get aiFailedTimeout => 'The model took too long. Try again.';

  @override
  String get aiFailedTooLong =>
      'This sentence is too long for the on-device model.';

  @override
  String get aiFailedGeneric => 'Nothing could be generated for this.';

  @override
  String get aiHintDownload =>
      'On-device AI is on, but the model is not downloaded yet. Settings › On-device AI.';
}

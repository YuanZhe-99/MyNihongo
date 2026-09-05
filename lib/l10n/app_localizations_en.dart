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
      'Reviews come back on a spaced-repetition schedule, so the words you nearly forgot arrive on the day you would have.';

  @override
  String get learnToday => 'Today';

  @override
  String learnStreak(int count) {
    return '$count-day streak';
  }

  @override
  String get learnStreakNone => 'No streak yet — one answer starts it';

  @override
  String learnDueCount(int count) {
    return '$count due for review';
  }

  @override
  String get learnDueNone => 'Nothing due';

  @override
  String learnDueCapped(int shown, int total) {
    return '$shown of $total due today';
  }

  @override
  String learnNewCount(int count) {
    return '$count new items available';
  }

  @override
  String get learnNewNone => 'Today\'s new items are done';

  @override
  String get learnAllDone =>
      'Nothing to do right now. Come back tomorrow, or browse.';

  @override
  String get learnReviewLimitReached =>
      'Today\'s review limit is reached. Raise it in Settings if you want more.';

  @override
  String pathTitle(String level) {
    return '$level path';
  }

  @override
  String pathNotWritten(String level) {
    return 'The $level units are not written yet. The reference lists and quizzes work at every level.';
  }

  @override
  String pathUnitItems(int grammar, int vocab) {
    return '$grammar grammar points, $vocab words';
  }

  @override
  String get pathPractise => 'Practise';

  @override
  String get pathCheckpoint => 'Checkpoint';

  @override
  String get pathWriting => 'Write about this';

  @override
  String get pathScenario => 'Conversation';

  @override
  String get scenarioChoose => 'What do you say?';

  @override
  String get scenarioNext => 'Next';

  @override
  String scenarioDone(int right, int total) {
    return '$right of $total replies were the expected one';
  }

  @override
  String get pathCheckpointAgain => 'Checkpoint again';

  @override
  String get pathCheckpointPassed =>
      'Checkpoint passed — the next unit is open.';

  @override
  String pathCheckpointFailed(int percent, int needed) {
    return 'Not this time. $percent% right; $needed% opens the next unit.';
  }

  @override
  String get reminderTitle => 'MyNihongo!!!!!';

  @override
  String reminderDueBody(int count) {
    return '$count items are due today.';
  }

  @override
  String reminderUnitBody(String unit) {
    return 'Next up: $unit.';
  }

  @override
  String get reminderPlainBody => 'A few minutes of Japanese?';

  @override
  String get reminderSection => 'Daily reminder';

  @override
  String get reminderEnable => 'Remind me to study';

  @override
  String get reminderEnableSubtitle =>
      'One local notification a day. Nothing leaves the device.';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderDenied =>
      'Notifications are switched off for this app. Turn them on in the system settings first.';

  @override
  String get calendarTitle => 'Study calendar';

  @override
  String calendarSummary(int days) {
    return '$days days studied in the last twelve weeks';
  }

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
      'Nothing tracked yet. Answer anything and it starts being scheduled.';

  @override
  String learnLevelProgress(Object level) {
    return '$level progress';
  }

  @override
  String learnLevelStarted(int done, int total) {
    return '$done of $total items started';
  }

  @override
  String get learnQuickStart => 'Quick start';

  @override
  String get learnOpenKana => 'Browse the kana chart';

  @override
  String get learnOpenVocab => 'Browse vocabulary';

  @override
  String get learnOpenGrammar => 'Browse grammar';

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
  String get settingsFurigana => 'Kana over kanji';

  @override
  String get settingsAutoSpeak => 'Read the question aloud';

  @override
  String get settingsAutoSpeakSubtitle =>
      'Speak a word or sentence when the question appears, where there is audio';

  @override
  String get settingsFuriganaSubtitle =>
      'Show the reading above words that use kanji';

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
  String get settingsLearning => 'Learning';

  @override
  String get settingsTargetLevel => 'Target level';

  @override
  String get settingsTargetLevelBody =>
      'New words and grammar are introduced from this level.';

  @override
  String get settingsDailyNew => 'New items a day';

  @override
  String get settingsDailyReviews => 'Reviews a day';

  @override
  String get settingsDailyLimitsBody =>
      'Daily limits are part of your profile, so they follow you to your other devices.';

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
  String get syncProfileTitle => 'Your learning profile';

  @override
  String syncProfileLevel(Object level) {
    return 'Target level: $level';
  }

  @override
  String syncProfileDaily(int newItems, int reviews) {
    return '$newItems new, $reviews reviews a day';
  }

  @override
  String syncProfileStreak(int count) {
    return '$count-day streak';
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
  String get speechVoiceDefault => 'Chosen automatically';

  @override
  String speechVoiceUsing(Object voice) {
    return 'Using $voice';
  }

  @override
  String get speechVoicePick => 'Choose a Japanese voice';

  @override
  String speechVoiceNumbered(int number) {
    return 'Japanese voice $number';
  }

  @override
  String get speechVoicePreview => 'Play a sample';

  @override
  String get speechVoiceOffline => 'On this device';

  @override
  String get speechVoiceNetwork => 'Needs the network';

  @override
  String get speechVoiceNotInstalled => 'Not downloaded';

  @override
  String get speechVoiceQualityHigh => 'Higher quality';

  @override
  String get speechVoiceQualityNormal => 'Standard quality';

  @override
  String get speechVoiceQualityLow => 'Lower quality';

  @override
  String get speechEngine => 'Speech engine';

  @override
  String get speechEngineDefault => 'System default';

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
  String get quizTitle => 'Quiz';

  @override
  String get quizStartReviews => 'Start reviews';

  @override
  String get quizStartNew => 'Learn new items';

  @override
  String get quizThisLevel => 'Quiz this level';

  @override
  String get quizThisTable => 'Quiz these kana';

  @override
  String quizProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get quizCheck => 'Check';

  @override
  String get quizContinue => 'Continue';

  @override
  String get quizSkipGenerated => 'Skip this question';

  @override
  String quizAcceptedByAi(String comment) {
    return 'Accepted by the on-device model: $comment';
  }

  @override
  String get quizWhyWrong => 'Why was this wrong?';

  @override
  String get quizCorrect => 'Correct';

  @override
  String get quizWrong => 'Not quite';

  @override
  String quizExpected(Object answer) {
    return 'Answer: $answer';
  }

  @override
  String get quizListenPrompt => 'Listen, then choose';

  @override
  String get quizTypeReadingHint => 'Type the reading';

  @override
  String get quizOrderPrompt => 'Put the pieces in order';

  @override
  String get quizOrderReset => 'Start over';

  @override
  String get quizConjugationPrompt => 'Which form belongs in the blank?';

  @override
  String get quizParticlePrompt => 'Which particle belongs in the blank?';

  @override
  String get quizPatternPrompt => 'Which grammar point does this use?';

  @override
  String get quizSummaryTitle => 'Session finished';

  @override
  String quizSummaryScore(int correct, int total) {
    return '$correct of $total right first time';
  }

  @override
  String get quizSummaryPerfect => 'Everything right first time.';

  @override
  String get quizSummaryReview => 'Worth another look';

  @override
  String get quizSummaryDone => 'Done';

  @override
  String get quizEmpty =>
      'Nothing to ask about yet. Enable more quiz modes, or study some items first.';

  @override
  String get quizLeaveTitle => 'Leave the quiz?';

  @override
  String get quizLeaveBody =>
      'Answers already given are kept. The rest of the session is discarded.';

  @override
  String get quizLeaveConfirm => 'Leave';

  @override
  String get quizModesTitle => 'Quiz modes';

  @override
  String get quizModesBody =>
      'Switch off any way of asking you would rather not see. A mode that this device or this word cannot support is skipped anyway.';

  @override
  String get quizModesVocab => 'Vocabulary';

  @override
  String get quizModesKana => 'Kana';

  @override
  String get quizModesGrammar => 'Grammar';

  @override
  String get quizModesNoneWarning => 'At least one mode has to stay on.';

  @override
  String get quizModeVocabJaToMeaning => 'Japanese to meaning';

  @override
  String get quizModeVocabMeaningToJa => 'Meaning to Japanese';

  @override
  String get quizModeVocabReadingToKanji => 'Reading to written form';

  @override
  String get quizModeVocabKanjiToReading => 'Written form to reading';

  @override
  String get quizModeVocabListening => 'Listening';

  @override
  String get quizModeVocabTypeReading => 'Type the reading';

  @override
  String get quizModeVocabCloze => 'Fill in the word';

  @override
  String get quizModeKanaToRomaji => 'Kana to romaji';

  @override
  String get quizModeRomajiToKana => 'Romaji to kana';

  @override
  String get quizModeKanaListening => 'Listening';

  @override
  String get quizModeGrammarParticle => 'Fill in the particle';

  @override
  String get quizModeGrammarConjugation => 'Choose the form';

  @override
  String get quizModeGrammarOrder => 'Order the pieces';

  @override
  String get quizModeGrammarPattern => 'Pick the grammar point';

  @override
  String get quizModeGrammarSentenceToMeaning => 'Sentence to meaning';

  @override
  String get quizModeGrammarMeaningToSentence => 'Meaning to sentence';

  @override
  String get quizClozePrompt => 'Which word belongs in the blank?';

  @override
  String get quizSentenceToMeaningPrompt => 'What does this sentence say?';

  @override
  String get quizMeaningToSentencePrompt => 'Which sentence says this?';

  @override
  String get formDictionary => 'dictionary';

  @override
  String get formMasuStem => 'masu stem';

  @override
  String get formNaiStem => 'nai stem';

  @override
  String get formTeStem => 'te stem';

  @override
  String get formEStem => 'e stem';

  @override
  String get formPolite => 'polite';

  @override
  String get formNegative => 'negative';

  @override
  String get formPast => 'past';

  @override
  String get formTe => 'te form';

  @override
  String get formTai => 'want to';

  @override
  String get formPotential => 'potential';

  @override
  String get formPassive => 'passive';

  @override
  String get formCausative => 'causative';

  @override
  String get formImperative => 'imperative';

  @override
  String get formVolitional => 'volitional';

  @override
  String get formConditionalBa => 'conditional ba';

  @override
  String get formConditionalTara => 'conditional tara';

  @override
  String get formTari => 'tari';

  @override
  String get formNagara => 'while';

  @override
  String get formAdverbial => 'adverbial';

  @override
  String get formAttributive => 'attributive';

  @override
  String get formProgressive => 'progressive';

  @override
  String get formRequest => 'request';

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
      'Off by default. When it is on, the app can explain an answer in more detail, suggest a correction, and write extra practice questions. Everything runs on this phone — nothing you write is sent anywhere.';

  @override
  String get aiUnsupportedPlatform => 'This platform has no on-device model.';

  @override
  String get aiStatusPrompt => 'Explanations and extra questions';

  @override
  String get aiStatusProofread => 'Correction suggestions';

  @override
  String get aiStatusUnavailable => 'Not available on this device';

  @override
  String get aiStatusUnreachable => 'The AI service could not be reached';

  @override
  String get aiStatusUnknown =>
      'The device reported a status this version does not recognise';

  @override
  String get aiStatusDownloadable => 'Needs a one-time download';

  @override
  String get aiStatusDownloading => 'Downloading…';

  @override
  String get aiStatusAvailable => 'Ready';

  @override
  String get aiCheckAgain => 'Check again';

  @override
  String aiCoreVersion(Object version) {
    return 'AICore $version';
  }

  @override
  String get aiCoreMissing => 'AICore is not installed on this device.';

  @override
  String get aiCoreCompatible => 'AICore can serve models on this device';

  @override
  String get aiCoreIncompatible => 'AICore cannot serve models on this device';

  @override
  String get aiDownload => 'Download';

  @override
  String get aiDownloadNote =>
      'Android downloads the model, not this app, and only when you tap Download.';

  @override
  String get aiPreferFast => 'Use the faster model';

  @override
  String get aiPreferFastBody =>
      'Answers come sooner, and are usually shorter.';

  @override
  String get aiModelStorageNote =>
      'The model belongs to Android and is shared with other apps that use it, so it cannot be removed from here.';

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
  String get writingTitle => 'Writing practice';

  @override
  String get writingHint => 'Write a few sentences in Japanese';

  @override
  String get writingCheck => 'Check my sentences';

  @override
  String get writingRewrite => 'Rewrite naturally';

  @override
  String writingWordsUsed(int used, int target) {
    return '$used of $target of this unit\'s words used';
  }

  @override
  String get aiMoreExamples => 'More examples';

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

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty =>
      'Nothing here yet. What you analyse is remembered on this device and synced with your progress.';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyShow => 'History';

  @override
  String writingSentenceN(int n) {
    return 'Sentence $n';
  }

  @override
  String get quizModeDrill => 'JLPT drill';

  @override
  String get drillSectionVocab => 'Vocabulary';

  @override
  String get drillSectionGrammar => 'Grammar';

  @override
  String get drillSectionReading => 'Reading';

  @override
  String get drillSectionListening => 'Listening';

  @override
  String get drillShowTranslation => 'Show translation';

  @override
  String get drillHideTranslation => 'Hide translation';

  @override
  String get drillTranscript => 'Transcript';

  @override
  String get drillPlay => 'Play';

  @override
  String get drillPlayAgain => 'Play again';

  @override
  String drillPlaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n plays left',
      one: '1 play left',
      zero: 'no plays left',
    );
    return '$_temp0';
  }

  @override
  String get drillNoVoice =>
      'This device has no Japanese voice, so this cannot be played.';

  @override
  String jlptPracticeTitle(String level) {
    return 'JLPT $level practice';
  }

  @override
  String get jlptPracticeBody =>
      'Questions written in the shape of the paper, one section at a time. Untimed, with the answer explained after each.';

  @override
  String jlptQuestionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get jlptNoContent => 'Not written yet for this level.';

  @override
  String get jlptNoVoice => 'Needs a Japanese voice on this device.';

  @override
  String get jlptMock => 'Mock exam';

  @override
  String get jlptHistory => 'Results';

  @override
  String get jlptComingNext => 'Timed mock exams come in the next update.';

  @override
  String get jlptModePractice => 'Practice';

  @override
  String jlptScore(int right, int asked) {
    return '$right of $asked correct';
  }

  @override
  String get jlptHistoryTitle => 'JLPT results';

  @override
  String get jlptHistoryEmpty =>
      'Nothing here yet. Finish a practice section and it is recorded on this device and synced with your progress.';

  @override
  String jlptHistorySection(String section, int right, int asked) {
    return '$section: $right/$asked';
  }

  @override
  String get jlptHistoryDelete => 'Delete';

  @override
  String get jlptHistoryDeleted => 'Attempt deleted.';

  @override
  String get jlptHistoryWrong => 'Got wrong';

  @override
  String get jlptHistoryUnanswered => 'Not answered';

  @override
  String get jlptHistoryGone => 'This question is no longer in the app.';

  @override
  String get jlptHistoryNote =>
      'A score here is over the questions this app asked. It is not a JLPT score.';

  @override
  String get settingsDebugMode => 'Developer options';

  @override
  String get settingsDebugModeBody =>
      'Shows technical detail about the on-device AI: which model this phone is using and why it is or is not available. Useful in a bug report; nothing here changes how the app works.';

  @override
  String get settingsDebugUnlocked => 'Developer options are on.';

  @override
  String settingsDebugStepsLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more taps for developer options',
      one: '1 more tap for developer options',
    );
    return '$_temp0';
  }

  @override
  String examBlockTitle(int n, int total) {
    return 'Part $n of $total';
  }

  @override
  String examBlockMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String examQuestionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get examStartBlock => 'Start this part';

  @override
  String get examLeaveTitle => 'Leave the exam?';

  @override
  String get examLeaveBody =>
      'The exam is saved with the time you have left. Continue it from the Learn tab.';

  @override
  String get examLeaveConfirm => 'Leave';

  @override
  String get examResultsTitle => 'Mock exam results';

  @override
  String examUnansweredCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n not answered',
      one: '1 not answered',
    );
    return '$_temp0';
  }

  @override
  String examBlockTime(String sections, int used, int limit) {
    return '$sections: $used of $limit minutes used';
  }

  @override
  String get examContinue => 'Continue the exam';

  @override
  String examContinueBody(String level, int block, int minutes) {
    return '$level mock, part $block, $minutes minutes left';
  }

  @override
  String get examDiscard => 'Discard';

  @override
  String get examDiscardTitle => 'Discard the saved exam?';

  @override
  String get examDiscardBody =>
      'The answers you have given are kept in your progress. The exam itself is not recorded.';

  @override
  String get examStartNew => 'Start a mock exam';

  @override
  String get examReplaceTitle => 'Start a new exam?';

  @override
  String get examReplaceBody =>
      'There is a saved exam. Starting a new one discards it.';

  @override
  String get weaknessTitle => 'What to work on';

  @override
  String get weaknessEmpty =>
      'Sit a practice section or a mock exam and this will show what you keep getting wrong.';

  @override
  String weaknessBasis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'From your last $n attempts',
      one: 'From your last attempt',
    );
    return '$_temp0';
  }

  @override
  String get weaknessBySection => 'By section';

  @override
  String get weaknessByType => 'By question type';

  @override
  String get weaknessByItem => 'Words and grammar to review';

  @override
  String weaknessScore(int right, int asked) {
    return '$right of $asked';
  }

  @override
  String get weaknessNothingWeak =>
      'Nothing stands out yet. Keep going and this will fill in.';

  @override
  String get readinessTitle => 'Readiness';

  @override
  String get readinessUnknown => 'Not enough answered yet';

  @override
  String get readinessNotYet => 'Not yet';

  @override
  String get readinessClose => 'Close';

  @override
  String get readinessReady => 'Looking ready';

  @override
  String get readinessUnmeasured => 'Not measured';

  @override
  String get readinessNote =>
      'This is an estimate from your practice in this app. It is not an official JLPT score.';

  @override
  String get readinessCapped =>
      'Held at Close until you have met more of the level\'s words and grammar.';

  @override
  String get readinessNoListening =>
      'Listening is not measured on this device, so it is missing from this estimate.';

  @override
  String get readinessGroupLanguageKnowledge => 'Language knowledge';

  @override
  String get readinessGroupLanguageReading => 'Language knowledge and reading';

  @override
  String get readinessGroupReading => 'Reading';

  @override
  String get readinessGroupListening => 'Listening';

  @override
  String get weaknessOpen => 'What to work on';
}

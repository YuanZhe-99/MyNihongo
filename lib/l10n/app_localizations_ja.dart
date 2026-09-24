// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MyNihongo!!!!!';

  @override
  String get navLearn => '学習';

  @override
  String get navKana => 'かな';

  @override
  String get navVocab => '単語';

  @override
  String get navGrammar => '文法';

  @override
  String get navSettings => '設定';

  @override
  String get contentLoadFailed => '同梱のコンテンツを読み込めませんでした';

  @override
  String get referenceLevelAll => 'すべてのレベル';

  @override
  String get referenceExamples => '例文';

  @override
  String get learnTitle => '学習';

  @override
  String get learnWelcome => 'MyNihongo!!!!! へようこそ';

  @override
  String get learnWelcomeBody =>
      '復習は間隔反復のスケジュールで出題されます。忘れかけた単語は、ちょうど忘れそうになる日に戻ってきます。';

  @override
  String get learnToday => '今日';

  @override
  String learnStreak(int count) {
    return '$count日連続';
  }

  @override
  String get learnStreakNone => 'まだ連続記録はありません。1問答えると始まります';

  @override
  String learnDueCount(int count) {
    return '復習予定 $count件';
  }

  @override
  String get learnDueNone => '復習予定はありません';

  @override
  String learnDueCapped(int shown, int total) {
    return '今日の復習予定 $total件中 $shown件';
  }

  @override
  String learnNewCount(int count) {
    return '新しい項目 $count件';
  }

  @override
  String get learnNewNone => '今日の新しい項目は終わりました';

  @override
  String get learnAllDone => '今はやることがありません。また明日来るか、一覧を見てみましょう。';

  @override
  String get learnReviewLimitReached =>
      '今日の復習の上限に達しました。もっと復習したい場合は、設定で上限を上げてください。';

  @override
  String pathTitle(String level) {
    return '$level 学習パス';
  }

  @override
  String pathNotWritten(String level) {
    return '$level の単元はまだ作成されていません。一覧とクイズはすべてのレベルで使えます。';
  }

  @override
  String pathUnitItems(int grammar, int vocab) {
    return '文法 $grammar項目・単語 $vocab語';
  }

  @override
  String get pathPractise => '練習';

  @override
  String get pathCheckpoint => '確認テスト';

  @override
  String get pathWriting => 'このテーマで書く';

  @override
  String get pathScenario => '会話';

  @override
  String get scenarioChoose => '何と言いますか？';

  @override
  String get scenarioNext => '次へ';

  @override
  String scenarioDone(int right, int total) {
    return '$total回中 $right回、想定どおりの返答でした';
  }

  @override
  String get scenarioContinue => '会話を続ける';

  @override
  String scenarioContinueHint(Object speaker) {
    return '次に言うことを日本語で入力してください。$speakerが役になりきって答えます。';
  }

  @override
  String get scenarioPartner => '相手';

  @override
  String get scenarioInputHint => '日本語で話しかけてみましょう';

  @override
  String get scenarioSend => '送信';

  @override
  String get scenarioEnd => '会話を終える';

  @override
  String get scenarioEnded => '会話を終えました。';

  @override
  String scenarioTurns(int used, int total) {
    return '$totalターン中 $usedターン目';
  }

  @override
  String get scenarioCapReached => 'この会話はここまでです。お疲れさまでした。';

  @override
  String scenarioReplyTitle(Object speaker) {
    return '$speakerの返答';
  }

  @override
  String scenarioProofread(Object text) {
    return '校正: $text';
  }

  @override
  String get scenarioProofreadOk => '校正: 直すところはありません';

  @override
  String get pathCheckpointAgain => 'もう一度確認テスト';

  @override
  String get pathCheckpointPassed => '確認テストに合格しました。次の単元が開きました。';

  @override
  String pathCheckpointFailed(int percent, int needed) {
    return '今回は不合格です。正答率 $percent%、次の単元に進むには $needed% が必要です。';
  }

  @override
  String get reminderTitle => 'MyNihongo!!!!!';

  @override
  String reminderDueBody(int count) {
    return '今日の復習予定は $count件です。';
  }

  @override
  String reminderUnitBody(String unit) {
    return '次は「$unit」です。';
  }

  @override
  String get reminderPlainBody => '少しだけ日本語を勉強しませんか？';

  @override
  String get reminderSection => '毎日のリマインダー';

  @override
  String get reminderEnable => '学習リマインダー';

  @override
  String get reminderEnableSubtitle => '1日1回、端末内で通知します。データが端末の外に出ることはありません。';

  @override
  String get reminderTime => '通知時刻';

  @override
  String get reminderDenied => 'このアプリの通知がオフになっています。先にシステム設定で通知をオンにしてください。';

  @override
  String get calendarTitle => '学習カレンダー';

  @override
  String calendarSummary(int days) {
    return '過去12週間で $days日学習しました';
  }

  @override
  String get learnContentSummary => 'コンテンツ';

  @override
  String learnKanaCount(int count) {
    return 'かな $count字';
  }

  @override
  String learnVocabCount(int count) {
    return '単語 $count語';
  }

  @override
  String learnGrammarCount(int count) {
    return '文法 $count項目';
  }

  @override
  String get learnProgressSummary => '学習状況';

  @override
  String learnTrackedItems(int count) {
    return '記録中 $count項目';
  }

  @override
  String learnMasteredItems(int count) {
    return '習得済み $count項目';
  }

  @override
  String get learnNoProgress => 'まだ記録がありません。何か1問答えると、復習のスケジュールが始まります。';

  @override
  String learnLevelProgress(Object level) {
    return '$level の進み具合';
  }

  @override
  String learnLevelStarted(int done, int total) {
    return '$total項目中 $done項目に着手';
  }

  @override
  String get learnQuickStart => 'クイックスタート';

  @override
  String get learnOpenKana => 'かな早見表を見る';

  @override
  String get learnOpenVocab => '単語一覧を見る';

  @override
  String get learnOpenGrammar => '文法一覧を見る';

  @override
  String get kanaTitle => 'かな早見表';

  @override
  String get kanaScriptHiragana => 'ひらがな';

  @override
  String get kanaScriptKatakana => 'カタカナ';

  @override
  String get kanaSearchHint => 'かな・ローマ字を検索…';

  @override
  String kanaSearchResults(int count) {
    return '一致 ($count)';
  }

  @override
  String get kanaNoMatches => '一致するかながありません';

  @override
  String get kanaBasicSection => '五十音';

  @override
  String get kanaVoicedSection => '濁音・半濁音';

  @override
  String get kanaYoonSection => '拗音';

  @override
  String get kanaRulesSection => '発音ルール';

  @override
  String get kanaRuleMoraTitle => '一かな一拍';

  @override
  String get kanaRuleMoraBody => '各かなは一つのモーラです。か・き・く・け・このように一定のリズムで発音します。';

  @override
  String get kanaRuleVowelsTitle => '母音は安定';

  @override
  String get kanaRuleVowelsBody =>
      'a, i, u, e, o は短くはっきり保ちます。英語の弱い母音のように曖昧にしません。';

  @override
  String get kanaRuleDakutenTitle => '濁点と半濁点';

  @override
  String get kanaRuleDakutenBody =>
      '゛は子音を濁らせます: k は g、s は z、t は d、h は b。゜は h を p にします。';

  @override
  String get kanaRuleYoonTitle => '拗音';

  @override
  String get kanaRuleYoonBody => '小さい ゃ/ゅ/ょ はイ段のかなと結びます: き + ゃ = きゃ kya。';

  @override
  String get kanaRuleSokuonTitle => '小さいつ';

  @override
  String get kanaRuleSokuonBody => '小さい っ/ッ は次の子音を短く詰めます。例: まって matte。';

  @override
  String get kanaRuleLongVowelsTitle => '長音';

  @override
  String get kanaRuleLongVowelsBody =>
      'ー はカタカナの音を伸ばします。ひらがなでは おう が長い o、えい が長い e になることが多いです。';

  @override
  String get kanaRuleNTitle => 'ん / ン';

  @override
  String get kanaRuleNBody => '基本は n。m, b, p の前では m に近く、k, g の前では柔らかい鼻音になります。';

  @override
  String get vocabTitle => '単語';

  @override
  String get vocabSearchHint => '漢字・読み・意味で検索…';

  @override
  String get vocabEmpty => '一致する単語がありません';

  @override
  String vocabCount(int count) {
    return '$count語';
  }

  @override
  String get vocabPartOfSpeech => '品詞';

  @override
  String get posNoun => '名詞';

  @override
  String get posPronoun => '代名詞';

  @override
  String get posProperNoun => '固有名詞';

  @override
  String get posVerbGodan => '五段動詞';

  @override
  String get posVerbIchidan => '一段動詞';

  @override
  String get posVerbIrregular => '不規則動詞';

  @override
  String get posSuruVerb => 'する動詞';

  @override
  String get posTransitive => '他動詞';

  @override
  String get posIntransitive => '自動詞';

  @override
  String get posAuxiliary => '助動詞';

  @override
  String get posIAdjective => 'い形容詞';

  @override
  String get posNaAdjective => 'な形容詞';

  @override
  String get posNoAdjective => 'の形容詞';

  @override
  String get posAdnominal => '連体詞';

  @override
  String get posAdverb => '副詞';

  @override
  String get posParticle => '助詞';

  @override
  String get posConjunction => '接続詞';

  @override
  String get posInterjection => '感動詞';

  @override
  String get posExpression => '表現';

  @override
  String get posCounter => '助数詞';

  @override
  String get posNumeric => '数詞';

  @override
  String get posPrefix => '接頭辞';

  @override
  String get posSuffix => '接尾辞';

  @override
  String get grammarTitle => '文法';

  @override
  String get grammarSearchHint => '文型や意味で検索…';

  @override
  String get grammarEmpty => '一致する文法項目がありません';

  @override
  String grammarCount(int count) {
    return '文法 $count項目';
  }

  @override
  String get grammarStructure => '接続';

  @override
  String get grammarExplanation => '解説';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システム';

  @override
  String get settingsFurigana => '漢字にふりがな';

  @override
  String get settingsAutoSpeak => '問題を読み上げる';

  @override
  String get settingsAutoSpeakSubtitle => '問題が表示されたとき、音声があれば単語や文を読み上げます';

  @override
  String get settingsFuriganaSubtitle => '漢字を含む語の上に読みを表示します';

  @override
  String get settingsData => 'データ';

  @override
  String get settingsStorageLocation => '保存場所';

  @override
  String get settingsSelectItem => '左のリストから項目を選択してください';

  @override
  String get settingsAbout => 'バージョン情報';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsLicense => 'ライセンス (GPLv3)';

  @override
  String get settingsLicenses => 'オープンソースライセンス';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get settingsLearning => '学習';

  @override
  String get settingsTargetLevel => '目標レベル';

  @override
  String get settingsTargetLevelBody => '新しい単語と文法はこのレベルから出題されます。';

  @override
  String get settingsDailyNew => '1日の新規項目数';

  @override
  String get settingsDailyReviews => '1日の復習数';

  @override
  String get settingsDailyLimitsBody => '1日の上限はプロフィールの一部なので、ほかの端末にも引き継がれます。';

  @override
  String get settingsWebDAVSync => 'WebDAV同期';

  @override
  String get settingsWebDAVServerURL => 'サーバーURL';

  @override
  String get settingsWebDAVUsername => 'ユーザー名';

  @override
  String get settingsWebDAVPassword => 'パスワード';

  @override
  String get settingsWebDAVRemotePath => 'リモートパス';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud プリセット';

  @override
  String get settingsWebDAVTestConnection => '接続テスト';

  @override
  String get settingsWebDAVAutoSync => '自動同期';

  @override
  String get settingsWebDAVAutoSyncDesc => '復習のあとやアプリの再開時に自動で同期します';

  @override
  String get settingsWebDAVSyncNow => '今すぐ同期';

  @override
  String get settingsWebDAVSyncing => '同期中…';

  @override
  String get settingsWebDAVDisconnect => '切断';

  @override
  String get settingsWebDAVConfigSaved => '設定を保存しました';

  @override
  String get settingsWebDAVConfigRemoved => '設定を削除しました';

  @override
  String get settingsWebDAVConnectionSuccess => '接続成功';

  @override
  String get settingsWebDAVConnectionFailed => '接続失敗';

  @override
  String get settingsWebDAVConnectionFailedLocalNetwork =>
      '接続に失敗しました。サーバーがローカルネットワーク上にある場合は、システム設定でこのアプリにローカルネットワークへのアクセスを許可してから、もう一度お試しください。';

  @override
  String get settingsWebDAVSyncSuccess => '同期完了';

  @override
  String get settingsWebDAVSyncFailed => '同期失敗';

  @override
  String get settingsWebDAVAutoSyncFailed => '自動同期失敗';

  @override
  String get settingsWebDAVAutoSyncConflict => '自動同期で競合を検出';

  @override
  String get settingsWebDAVLastSuccess => '前回の同期成功';

  @override
  String get settingsWebDAVNotConfigured => '未接続';

  @override
  String settingsWebDAVSyncWarnings(int count) {
    return '同期は完了しましたが、警告が $count件あります';
  }

  @override
  String get settingsWebDAVForceUpload => '強制アップロード';

  @override
  String get settingsWebDAVForceDownload => '強制ダウンロード';

  @override
  String get settingsWebDAVForceUploadConfirmTitle => '強制アップロードしますか？';

  @override
  String get settingsWebDAVForceUploadConfirmBody =>
      'リモートの進捗をローカルのデータで上書きします。前回の同期以降のリモートの変更は失われます。';

  @override
  String get settingsWebDAVForceDownloadConfirmTitle => '強制ダウンロードしますか？';

  @override
  String get settingsWebDAVForceDownloadConfirmBody =>
      'ローカルの進捗をリモートのデータで置き換えます。前回の同期以降のローカルの変更は失われます。';

  @override
  String get syncPhaseConnecting => '接続中…';

  @override
  String syncPhaseDownloadingData(Object file, int current, int total) {
    return '$file をダウンロード中（$current/$total）';
  }

  @override
  String syncPhaseMerging(Object file) {
    return '$file をマージ中…';
  }

  @override
  String syncPhaseUploadingData(Object file) {
    return '$file をアップロード中…';
  }

  @override
  String syncConflictTitle(Object name) {
    return '同期の競合: $name';
  }

  @override
  String get syncConflictDesc => '前回の同期以降、この項目は両方の端末で学習されました。どちらか一方を残してください。';

  @override
  String get syncUnknownItem => 'この項目は現在のコンテンツカタログにありません。';

  @override
  String get syncLocalVersion => 'ローカル版';

  @override
  String get syncRemoteVersion => 'リモート版';

  @override
  String syncModifiedAt(Object time) {
    return '更新日時: $time';
  }

  @override
  String syncRecordAnswers(int correct, int wrong) {
    return '正解 $correct · 不正解 $wrong';
  }

  @override
  String syncStreak(int count) {
    return '連続正解: $count';
  }

  @override
  String get syncProfileTitle => '学習プロフィール';

  @override
  String syncProfileLevel(Object level) {
    return '目標レベル: $level';
  }

  @override
  String syncProfileDaily(int newItems, int reviews) {
    return '1日に新規 $newItems件・復習 $reviews件';
  }

  @override
  String syncProfileStreak(int count) {
    return '$count日連続';
  }

  @override
  String get syncStage => '段階';

  @override
  String get stageFresh => '未学習';

  @override
  String get stageLearning => '学習中';

  @override
  String get stageMastered => '習得済み';

  @override
  String syncLastReviewed(Object time) {
    return '最終復習: $time';
  }

  @override
  String get syncNeverReviewed => '未復習';

  @override
  String get syncKeepLocal => 'ローカルを保持';

  @override
  String get syncKeepRemote => 'リモートを保持';

  @override
  String get backupTitle => 'バックアップ';

  @override
  String get backupSubtitle => '学習の進捗をまるごと端末内にバックアップします';

  @override
  String get backupCreate => 'バックアップを作成';

  @override
  String get backupCreated => 'バックアップを作成しました';

  @override
  String get backupFailed => 'バックアップを作成できませんでした';

  @override
  String get backupAutoBackup => '自動バックアップ';

  @override
  String get backupAutoBackupDesc => 'アプリの起動時に1日1回バックアップします';

  @override
  String get backupRetention => '保存期間';

  @override
  String get backupKeepForever => '無期限';

  @override
  String backupKeepDays(int days) {
    return '$days日間';
  }

  @override
  String backupHistory(int count) {
    return '履歴 ($count)';
  }

  @override
  String get backupNoBackups => 'バックアップはまだありません';

  @override
  String get backupCorrupt => '破損';

  @override
  String get backupLocalOnlyNote => 'バックアップはこの端末内にだけ保存され、どこにもアップロードされません。';

  @override
  String get backupRestore => '復元';

  @override
  String get backupRestoreConfirm => '選択したデータをバックアップの内容で置き換えます。続けますか？';

  @override
  String get backupRestoreModules => '復元する項目';

  @override
  String get backupSelectAll => 'すべて選択';

  @override
  String get backupModuleProgress => '学習の進捗';

  @override
  String get backupRestored => 'バックアップを復元しました';

  @override
  String get backupRestoreFailed => 'バックアップを復元できませんでした';

  @override
  String get backupDeleteConfirm => 'このバックアップを削除しますか？';

  @override
  String get backupRestoredSyncDisabled =>
      '復元したデータが誤ってサーバーのデータとマージされないよう、自動同期をオフにしました。';

  @override
  String get backupForceUploadPrompt => '復元したデータでリモートのデータを上書きしますか？';

  @override
  String get backupForceUploadSkip => '後で';

  @override
  String get backupForceUploadDone => 'リモートのデータを上書きしました';

  @override
  String get backupForceUploadFailed => 'アップロードに失敗しました';

  @override
  String get exportData => 'ZIPにエクスポート';

  @override
  String get exportSuccess => 'エクスポートしました';

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String get importData => 'ZIPからインポート';

  @override
  String get importConfirm => 'ローカルの進捗をアーカイブの内容で置き換えます。続けますか？';

  @override
  String get importSuccess => 'インポートが完了しました';

  @override
  String get importFailed => 'インポートに失敗しました';

  @override
  String get licenseContentTitle => 'コンテンツのライセンス';

  @override
  String get licenseContentBody =>
      'このアプリの単語データは、オープンな辞書や単語リストをもとにしています。それらのライセンスにより以下の帰属表示が求められているため、翻訳せずに掲載しています。';

  @override
  String get vocabGrammarUsed => 'これらの例文に出てくる文法';

  @override
  String get grammarWordsUsed => 'これらの例文に出てくる単語';

  @override
  String get kanaExampleWords => 'このかなで始まる単語';

  @override
  String kanaStrokes(int count) {
    return '$count画';
  }

  @override
  String get kanaConfusableWith => '間違えやすい字';

  @override
  String get kanaNoExtras => 'このかなのメモはまだありません。';

  @override
  String get listColumns => '列数';

  @override
  String get listColumnsAuto => '自動';

  @override
  String listColumnsCount(int count) {
    return '$count';
  }

  @override
  String get speechSection => '音声';

  @override
  String get speechSpeak => '読み上げ';

  @override
  String get speechStop => '停止';

  @override
  String get speechRate => '読み上げ速度';

  @override
  String speechRateValue(Object rate) {
    return '$rate倍';
  }

  @override
  String get speechRatePreview => '試聴';

  @override
  String get speechVoice => '日本語の音声';

  @override
  String get speechVoiceDefault => '自動で選択';

  @override
  String speechVoiceUsing(Object voice) {
    return '$voice を使用中';
  }

  @override
  String get speechVoicePick => '日本語の音声を選ぶ';

  @override
  String speechVoiceNumbered(int number) {
    return '日本語の音声 $number';
  }

  @override
  String get speechVoicePreview => 'サンプルを再生';

  @override
  String get speechVoiceOffline => 'この端末で利用可';

  @override
  String get speechVoiceNetwork => 'ネットワークが必要';

  @override
  String get speechVoiceNotInstalled => '未ダウンロード';

  @override
  String get speechVoiceQualityHigh => '高音質';

  @override
  String get speechVoiceQualityNormal => '標準音質';

  @override
  String get speechVoiceQualityLow => '低音質';

  @override
  String get speechEngine => '音声エンジン';

  @override
  String get speechEngineDefault => 'システムのデフォルト';

  @override
  String get speechNoVoiceTitle => '日本語の音声がインストールされていません';

  @override
  String get speechNoVoiceBody =>
      '端末の音声エンジンに日本語の音声がないため、読み上げができません。システムの音声設定で日本語の音声をインストールしてから、アプリを開き直してください。';

  @override
  String get speechOpenSystemSettings => '音声設定を開く';

  @override
  String get speechOpenSystemSettingsFailed => 'システムの音声設定を開けませんでした';

  @override
  String get speechSettingsHintApple =>
      'システム設定の「アクセシビリティ」→「読み上げコンテンツ」で日本語の音声を追加してください。';

  @override
  String get practiceTitle => '発音練習';

  @override
  String get practiceStart => 'タップして話す';

  @override
  String get practiceListening => '聞き取り中…';

  @override
  String get practiceProcessing => '認識しています…';

  @override
  String get practiceRetry => 'もう一度';

  @override
  String practiceHeard(Object text) {
    return '認識結果: $text';
  }

  @override
  String practiceScore(int score) {
    return '$score点（100点満点）';
  }

  @override
  String get practicePerfect => 'すべてのモーラが一致しました。';

  @override
  String get practiceLegendCorrect => '一致';

  @override
  String get practiceLegendSubstituted => '相違';

  @override
  String get practiceLegendMissing => '不足';

  @override
  String get practiceLegendExtra => '余分';

  @override
  String get practiceLimitsNote =>
      '音声認識が聞き取った内容を読みと比べています。判定しているのは聞き取れる発音だったかどうかで、なまりや高低アクセントではありません。';

  @override
  String get practiceNoMatch => '何も認識されませんでした。マイクに少し近づいて、もう一度お試しください。';

  @override
  String get practiceLanguageUnavailable =>
      'この端末ではオフラインの日本語音声認識を使えません。システム設定で日本語の音声データをインストールするか、「設定 › 音声」でネットワーク認識を許可してください。';

  @override
  String get practicePermissionDenied => 'マイクへのアクセスが拒否されたため、音声を聞き取れません。';

  @override
  String get practiceUnavailable => 'この端末には、アプリが使える音声認識機能がありません。';

  @override
  String get practiceMicRationaleTitle => 'マイクを使用しますか？';

  @override
  String get practiceMicRationaleBody =>
      '発音を比べるには、アプリがあなたの声を聞く必要があります。認識は端末上で行われ、音声が保存されたり、どこかへ送信されたりすることはありません。';

  @override
  String get practiceMicRationaleAllow => '続ける';

  @override
  String get speechNetworkFallback => 'ネットワーク認識を許可';

  @override
  String get speechNetworkFallbackBody =>
      'デフォルトではオフです。オンにすると、端末にオフラインの日本語音声認識がない場合、話した内容がシステムの音声サービスに送信され、文字に変換されます。';

  @override
  String get speechRecognizerReady => '音声認識を利用できます';

  @override
  String get speechRecognizerMissing => 'この端末には日本語の音声認識がありません';

  @override
  String get speechRecognizerUnchecked => '音声認識は最初に練習するときに確認されます';

  @override
  String get practiceAction => '練習';

  @override
  String get quizTitle => 'クイズ';

  @override
  String get quizStartReviews => '復習を始める';

  @override
  String get quizStartNew => '新しい項目を学ぶ';

  @override
  String get quizThisLevel => 'このレベルでクイズ';

  @override
  String get quizThisTable => 'このかなでクイズ';

  @override
  String quizProgress(int done, int total) {
    return '$done / $total';
  }

  @override
  String get quizCheck => '答え合わせ';

  @override
  String get quizContinue => '次へ';

  @override
  String get quizSkipGenerated => 'この問題をスキップ';

  @override
  String get quizKeyboardHint =>
      'キー: 1–9 選択 · Enter 答え合わせ、続けて次へ · Backspace 取り消し · R 再生 · S スキップ';

  @override
  String quizAcceptedByAi(String comment) {
    return '端末上のモデルが正解と判定しました: $comment';
  }

  @override
  String get quizWhyWrong => 'なぜ不正解？';

  @override
  String get quizCorrect => '正解';

  @override
  String get quizWrong => '惜しい';

  @override
  String quizExpected(Object answer) {
    return '正解: $answer';
  }

  @override
  String get quizListenPrompt => '聞いて選んでください';

  @override
  String get quizTypeReadingHint => '読みを入力';

  @override
  String get quizTypeSentenceHint => '日本語の文を入力';

  @override
  String get quizOrderPrompt => '正しい順に並べてください';

  @override
  String get quizOrderReset => 'やり直す';

  @override
  String get quizConjugationPrompt => '空欄に入る形はどれですか？';

  @override
  String get quizParticlePrompt => '空欄に入る助詞はどれですか？';

  @override
  String get quizPatternPrompt => 'この文で使われている文法項目はどれですか？';

  @override
  String get quizGeneratedPrompt => 'この文法項目を表す形で空欄を埋めてください';

  @override
  String quizGrammarPointLine(Object pattern, Object meaning) {
    return '文法項目: $pattern · $meaning';
  }

  @override
  String get quizOpenGrammarPoint => 'この文法項目を開く';

  @override
  String get quizSummaryTitle => 'セッション終了';

  @override
  String quizSummaryScore(int correct, int total) {
    return '$total問中 $correct問を1回目で正解';
  }

  @override
  String get quizSummaryPerfect => 'すべて1回目で正解しました。';

  @override
  String get quizSummaryReview => 'もう一度見ておきたい項目';

  @override
  String get quizSummaryDone => '完了';

  @override
  String get quizEmpty => '出題できる項目がまだありません。クイズモードを増やすか、先にいくつか学習してください。';

  @override
  String get quizLeaveTitle => 'クイズを終了しますか？';

  @override
  String get quizLeaveBody => '答えた分は記録されます。残りの問題は破棄されます。';

  @override
  String get quizLeaveConfirm => '終了';

  @override
  String get quizModesTitle => 'クイズモード';

  @override
  String get quizModesBody =>
      '見たくない出題形式はオフにできます。この端末やこの単語で使えない形式は、オンでも出題されません。';

  @override
  String get quizModeNeedsTranslation => '日本語表示では使えません。このモードは訳語について出題するためです。';

  @override
  String get quizModesVocab => '単語';

  @override
  String get quizModesKana => 'かな';

  @override
  String get quizModesGrammar => '文法';

  @override
  String get quizModesNoneWarning => '少なくとも1つのモードをオンにしておく必要があります。';

  @override
  String get quizModeVocabJaToMeaning => '日本語 → 意味';

  @override
  String get quizModeVocabMeaningToJa => '意味 → 日本語';

  @override
  String get quizModeVocabReadingToKanji => '読み → 表記';

  @override
  String get quizModeVocabKanjiToReading => '表記 → 読み';

  @override
  String get quizModeVocabListening => '聞き取り';

  @override
  String get quizModeVocabTypeReading => '読みを入力';

  @override
  String get quizModeVocabCloze => '単語の穴埋め';

  @override
  String get quizModeKanaToRomaji => 'かな → ローマ字';

  @override
  String get quizModeRomajiToKana => 'ローマ字 → かな';

  @override
  String get quizModeKanaListening => '聞き取り';

  @override
  String get quizModeGrammarParticle => '助詞の穴埋め';

  @override
  String get quizModeGrammarConjugation => '形を選ぶ';

  @override
  String get quizModeGrammarOrder => '並べ替え';

  @override
  String get quizModeGrammarPattern => '文法項目を選ぶ';

  @override
  String get quizModeGrammarSentenceToMeaning => '文 → 意味';

  @override
  String get quizModeGrammarMeaningToSentence => '意味 → 文';

  @override
  String get quizModeGrammarTypeSentence => '文を書く';

  @override
  String get quizClozePrompt => '空欄に入る単語はどれですか？';

  @override
  String get quizSentenceToMeaningPrompt => 'この文はどういう意味ですか？';

  @override
  String get quizMeaningToSentencePrompt => 'この意味を表す文はどれですか？';

  @override
  String get quizTypeSentencePrompt => '日本語で書いてください。';

  @override
  String get formDictionary => '辞書形';

  @override
  String get formMasuStem => 'ます形';

  @override
  String get formNaiStem => 'ない形';

  @override
  String get formTeStem => 'て形語幹';

  @override
  String get formEStem => 'え段';

  @override
  String get formPolite => '丁寧形';

  @override
  String get formNegative => '否定形';

  @override
  String get formPast => '過去形';

  @override
  String get formTe => 'て形';

  @override
  String get formTai => 'たい形';

  @override
  String get formPotential => '可能形';

  @override
  String get formPassive => '受身形';

  @override
  String get formCausative => '使役形';

  @override
  String get formImperative => '命令形';

  @override
  String get formVolitional => '意向形';

  @override
  String get formConditionalBa => 'ば形';

  @override
  String get formConditionalTara => 'たら形';

  @override
  String get formTari => 'たり形';

  @override
  String get formNagara => 'ながら形';

  @override
  String get formAdverbial => '連用形';

  @override
  String get formAttributive => '連体形';

  @override
  String get formProgressive => '進行形';

  @override
  String get formRequest => '依頼形';

  @override
  String get labTitle => 'センテンスラボ';

  @override
  String get labSubtitle => '文の成り立ちを見てみましょう';

  @override
  String get labInputHint => '日本語の文を入力または貼り付け';

  @override
  String get labAnalyze => '分析';

  @override
  String get labClear => 'クリア';

  @override
  String get labEmpty => '上に文を入力するか、単語や文法の例文から開いてください。';

  @override
  String get labWords => '単語';

  @override
  String get labStructure => '構造';

  @override
  String get labGrammarUsed => '使われている文法';

  @override
  String get labGrammarNone => '学習する文法項目のうち、この文に当てはまるものはありませんでした。';

  @override
  String get labIssues => '気になる点';

  @override
  String get labIssuesNone => '特に気になる点はありませんでした。';

  @override
  String get labUnknownWarning => '同梱の辞書にない文字があるため、一部が正しくない可能性があります。';

  @override
  String get labDependsOn => '係り先';

  @override
  String get labRoot => '主述語';

  @override
  String get labLimitsNote =>
      'これは辞書と規則による分析で、翻訳ツールではありません。構造はあくまで推定なので、気になる点はうのみにせず確かめてください。';

  @override
  String get labOpenAction => 'この文を分析';

  @override
  String labIssueParticleFrame(Object word) {
    return '$word は、ここでは「を」ではなく「が」をとるのが普通です。';
  }

  @override
  String labIssueParticleFrameSuggest(Object word, Object suggestion) {
    return '$word は「を」ではなく「が」をとるのが普通です。$suggestion のことですか？';
  }

  @override
  String labIssueNaNo(Object word, Object suggestion) {
    return '$word と次の名詞の間に $suggestion が必要かもしれません。';
  }

  @override
  String labIssueTense(Object word) {
    return '$word が指す時と、動詞の形が表す時が合っていません。';
  }

  @override
  String labIssueCopula(Object word) {
    return '$word で終わっていて、述語がありません。$wordです のことですか？';
  }

  @override
  String labIssueAdjectiveAsVerb(Object word) {
    return '$word は形容詞なので、動詞の語尾はつきません。';
  }

  @override
  String get labCategoryNoun => '名詞';

  @override
  String get labCategoryVerb => '動詞';

  @override
  String get labCategoryAdjective => '形容詞';

  @override
  String get labCategoryParticle => '助詞';

  @override
  String get labCategoryAuxiliary => '助動詞';

  @override
  String get labCategoryOther => 'その他';

  @override
  String get labCategoryUnknown => '辞書にない語';

  @override
  String get aiSection => 'オンデバイスAI';

  @override
  String get aiEnable => 'オンデバイスAIによるサポート';

  @override
  String get aiEnableBody =>
      'デフォルトではオフです。オンにすると、答えをさらに詳しく説明したり、修正案を示したり、練習問題を追加で作成したりできます。すべてこのスマートフォン上で動作し、書いた内容がどこかへ送信されることはありません。';

  @override
  String get aiUnsupportedPlatform => 'このプラットフォームにはオンデバイスモデルがありません。';

  @override
  String get aiStatusPrompt => '説明と追加の問題';

  @override
  String get aiStatusProofread => '修正案';

  @override
  String get aiStatusUnavailable => 'この端末では利用できません';

  @override
  String get aiStatusUnreachable => 'AIサービスに接続できませんでした';

  @override
  String get aiStatusUnknown => 'このバージョンでは認識できない状態が端末から返されました';

  @override
  String get aiStatusDownloadable => '初回のみダウンロードが必要';

  @override
  String get aiStatusDownloading => 'ダウンロード中…';

  @override
  String get aiStatusAvailable => '利用可能';

  @override
  String get aiCheckAgain => '再確認';

  @override
  String aiCoreVersion(Object version) {
    return 'AICore $version';
  }

  @override
  String get aiCoreMissing => 'この端末にはAICoreがインストールされていません。';

  @override
  String get aiCoreCompatible => 'この端末ではAICoreがモデルを提供できます';

  @override
  String get aiCoreIncompatible => 'この端末ではAICoreがモデルを提供できません';

  @override
  String get aiDownload => 'ダウンロード';

  @override
  String get aiDownloadNote =>
      'モデルをダウンロードするのはこのアプリではなくAndroidで、「ダウンロード」をタップしたときだけです。';

  @override
  String get aiPreferFast => '高速なモデルを使う';

  @override
  String get aiPreferFastBody => '答えが早く返り、たいていは短めになります。';

  @override
  String get aiModelStorageNote =>
      'モデルはAndroidが管理し、ほかのアプリとも共有されるため、ここから削除することはできません。';

  @override
  String get aiDownloading => 'ダウンロード中…';

  @override
  String aiDownloadedBytes(Object megabytes) {
    return '$megabytes MB ダウンロード済み';
  }

  @override
  String get aiDownloadFailed => 'モデルをダウンロードできませんでした。もう一度お試しください。';

  @override
  String get aiExplain => '説明';

  @override
  String get aiExplainSentence => 'この文を説明';

  @override
  String get aiSuggestCorrection => '修正案を出す';

  @override
  String get writingTitle => '作文練習';

  @override
  String get writingHint => '日本語で文をいくつか書いてください';

  @override
  String get writingCheck => '文をチェック';

  @override
  String get writingRewrite => '自然な文に書き直す';

  @override
  String writingWordsUsed(int used, int target) {
    return 'この単元の単語 $target語中 $used語を使用';
  }

  @override
  String get aiMoreExamples => '例文をもっと見る';

  @override
  String get aiGeneratedLabel => 'この端末で生成 — 誤りを含む可能性があります';

  @override
  String get aiGenerating => '端末上で生成中…';

  @override
  String get aiDismiss => '閉じる';

  @override
  String get aiCorrectionNone => 'モデルからは別の文の提案はありませんでした。';

  @override
  String get aiCorrectionHeading => '書き直しの一例';

  @override
  String get aiFailedUnavailable => 'オンデバイスモデルの準備ができていません。設定を確認してください。';

  @override
  String get aiFailedBusy => '別の回答を生成中です。';

  @override
  String get aiFailedTimeout => 'モデルの応答に時間がかかりすぎました。もう一度お試しください。';

  @override
  String get aiFailedTooLong => 'この文はオンデバイスモデルで扱うには長すぎます。';

  @override
  String get aiFailedGeneric => '生成できませんでした。';

  @override
  String get aiHintDownload =>
      'オンデバイスAIはオンですが、モデルがまだダウンロードされていません。設定 › オンデバイスAI。';

  @override
  String get historyTitle => '履歴';

  @override
  String get historyEmpty => 'まだ何もありません。分析した文はこの端末に記録され、進捗と一緒に同期されます。';

  @override
  String get historyDelete => '削除';

  @override
  String get historyShow => '履歴';

  @override
  String writingSentenceN(int n) {
    return '文 $n';
  }

  @override
  String get quizModeDrill => 'JLPT練習問題';

  @override
  String get drillSectionVocab => '語彙';

  @override
  String get drillSectionGrammar => '文法';

  @override
  String get drillSectionReading => '読解';

  @override
  String get drillSectionListening => '聴解';

  @override
  String get drillShowTranslation => '訳を表示';

  @override
  String get drillHideTranslation => '訳を隠す';

  @override
  String get drillTranscript => 'スクリプト';

  @override
  String get drillPlay => '再生';

  @override
  String get drillPlayAgain => 'もう一度再生';

  @override
  String drillPlaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n回再生できます',
      zero: 'もう再生できません',
    );
    return '$_temp0';
  }

  @override
  String get drillNoVoice => 'この端末には日本語の音声がないため、再生できません。';

  @override
  String jlptPracticeTitle(String level) {
    return 'JLPT $level 練習';
  }

  @override
  String get jlptPracticeBody =>
      '本番の試験と同じ形式の問題を、1セクションずつ解きます。時間制限はなく、1問ごとに解説が表示されます。';

  @override
  String jlptQuestionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n問');
    return '$_temp0';
  }

  @override
  String get jlptNoContent => 'このレベルはまだ作成されていません。';

  @override
  String get jlptNoVoice => 'この端末に日本語の音声が必要です。';

  @override
  String get jlptMock => '模擬試験';

  @override
  String get jlptHistory => '結果';

  @override
  String get jlptComingNext => '時間制限つきの模擬試験は次のアップデートで追加されます。';

  @override
  String get jlptModePractice => '練習';

  @override
  String jlptScore(int right, int asked) {
    return '$asked問中 $right問正解';
  }

  @override
  String get jlptHistoryTitle => 'JLPTの結果';

  @override
  String get jlptHistoryEmpty =>
      'まだ何もありません。練習セクションを終えると、この端末に記録され、進捗と一緒に同期されます。';

  @override
  String jlptHistorySection(String section, int right, int asked) {
    return '$section: $right/$asked';
  }

  @override
  String get jlptHistoryDelete => '削除';

  @override
  String get jlptHistoryDeleted => '記録を削除しました。';

  @override
  String get jlptHistoryWrong => '不正解';

  @override
  String get jlptHistoryUnanswered => '未回答';

  @override
  String get jlptHistoryGone => 'この問題はもうアプリにありません。';

  @override
  String get jlptHistoryNote => 'ここでの得点は、このアプリで出題した問題に対するものです。JLPTの得点ではありません。';

  @override
  String get settingsDebugMode => '開発者向けオプション';

  @override
  String get settingsDebugModeBody =>
      'オンデバイスAIの技術的な詳細を表示します。この端末がどのモデルを使っているか、利用できる・できない理由などです。不具合の報告に役立ちます。ここでの表示がアプリの動作を変えることはありません。';

  @override
  String get settingsDebugUnlocked => '開発者向けオプションがオンになりました。';

  @override
  String settingsDebugStepsLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n回タップすると開発者向けオプションが有効になります',
    );
    return '$_temp0';
  }

  @override
  String examBlockTitle(int n, int total) {
    return '第$n部（全$total部）';
  }

  @override
  String examBlockMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String examQuestionCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n問');
    return '$_temp0';
  }

  @override
  String get examStartBlock => 'この部を始める';

  @override
  String get examLeaveTitle => '試験を中断しますか？';

  @override
  String get examLeaveBody => '試験は残り時間とともに保存されます。「学習」タブから再開できます。';

  @override
  String get examLeaveConfirm => '中断';

  @override
  String get examResultsTitle => '模擬試験の結果';

  @override
  String examUnansweredCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '未回答 $n問',
    );
    return '$_temp0';
  }

  @override
  String examBlockTime(String sections, int used, int limit) {
    return '$sections: $limit分中 $used分使用';
  }

  @override
  String get examContinue => '試験を再開';

  @override
  String examContinueBody(String level, int block, int minutes) {
    return '$level 模擬試験、第$block部、残り$minutes分';
  }

  @override
  String get examDiscard => '破棄';

  @override
  String get examDiscardTitle => '保存した試験を破棄しますか？';

  @override
  String get examDiscardBody => '回答済みの問題は進捗に残ります。試験自体は記録されません。';

  @override
  String get examStartNew => '模擬試験を始める';

  @override
  String get examReplaceTitle => '新しい試験を始めますか？';

  @override
  String get examReplaceBody => '保存された試験があります。新しく始めると、保存された試験は破棄されます。';

  @override
  String get weaknessTitle => '弱点';

  @override
  String get weaknessEmpty => '練習セクションか模擬試験を受けると、よく間違える点がここに表示されます。';

  @override
  String weaknessBasis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '直近$n回の結果から',
    );
    return '$_temp0';
  }

  @override
  String get weaknessBySection => 'セクション別';

  @override
  String get weaknessByType => '問題形式別';

  @override
  String get weaknessByItem => '復習したい単語と文法';

  @override
  String weaknessScore(int right, int asked) {
    return '$asked問中 $right問';
  }

  @override
  String get weaknessNothingWeak => '今のところ目立つ弱点はありません。続けていけば、ここに表示されるようになります。';

  @override
  String get readinessTitle => '合格への準備度';

  @override
  String get readinessUnknown => 'まだ回答が足りません';

  @override
  String get readinessNotYet => 'まだ';

  @override
  String get readinessClose => 'もう少し';

  @override
  String get readinessReady => '準備ができていそう';

  @override
  String get readinessUnmeasured => '未測定';

  @override
  String get readinessNote => 'これはこのアプリでの練習をもとにした推定です。JLPTの公式な得点ではありません。';

  @override
  String get readinessCapped => 'このレベルの単語と文法にもっと触れるまで、「もう少し」にとどめています。';

  @override
  String get readinessNoListening => 'この端末では聴解を測定できないため、この推定には含まれていません。';

  @override
  String get readinessGroupLanguageKnowledge => '言語知識';

  @override
  String get readinessGroupLanguageReading => '言語知識・読解';

  @override
  String get readinessGroupReading => '読解';

  @override
  String get readinessGroupListening => '聴解';

  @override
  String get weaknessOpen => '弱点';

  @override
  String get writingRubricTitle => 'アプリが測定したこと';

  @override
  String writingRubricSentences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count文',
    );
    return '$_temp0';
  }

  @override
  String writingRubricGrammar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '学習済みの文法項目 $count個',
    );
    return '$_temp0';
  }

  @override
  String writingRubricLevel(int percent, String level) {
    return '認識できた単語の $percent% が $level またはそれより易しい単語です';
  }

  @override
  String writingRubricUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '読み取れなかった単語 $count語',
    );
    return '$_temp0';
  }

  @override
  String get writingRubricNote => 'ここに得点はありません。JLPTに作文の試験はありません。';

  @override
  String get aiRubric => '次に試すこと';

  @override
  String get aiParaphrase => 'もっと簡単に言うと';

  @override
  String get aiContradiction => '本文ではどこで違うことを言っていますか？';

  @override
  String get aiListeningReview => '答えはどのセリフにありましたか？';

  @override
  String get aiWeaknessNote => '対策';
}

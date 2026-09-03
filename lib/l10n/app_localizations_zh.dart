// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MyNihongo!!!!!';

  @override
  String get navLearn => '学习';

  @override
  String get navKana => '五十音';

  @override
  String get navVocab => '单词';

  @override
  String get navGrammar => '语法';

  @override
  String get navSettings => '设置';

  @override
  String get contentLoadFailed => '无法加载内置内容';

  @override
  String get referenceLevelAll => '全部级别';

  @override
  String get referenceExamples => '例句';

  @override
  String get learnTitle => '学习';

  @override
  String get learnWelcome => '欢迎使用 MyNihongo!!!!!';

  @override
  String get learnWelcomeBody =>
      '可以浏览五十音、单词和语法，全部内容都可朗读，还有发音练习与句子实验室；课程与复习正在路上。';

  @override
  String get learnContentSummary => '内容';

  @override
  String learnKanaCount(int count) {
    return '$count 个假名';
  }

  @override
  String learnVocabCount(int count) {
    return '$count 个单词';
  }

  @override
  String learnGrammarCount(int count) {
    return '$count 个语法点';
  }

  @override
  String get learnProgressSummary => '学习进度';

  @override
  String learnTrackedItems(int count) {
    return '已记录 $count 项';
  }

  @override
  String learnMasteredItems(int count) {
    return '已掌握 $count 项';
  }

  @override
  String get learnNoProgress => '尚无学习记录。课程与复习功能将在后续版本提供。';

  @override
  String get learnQuickStart => '快速开始';

  @override
  String get learnOpenKana => '查看五十音图';

  @override
  String get learnOpenVocab => '查看单词';

  @override
  String get learnOpenGrammar => '查看语法';

  @override
  String get learnRoadmap => '即将推出';

  @override
  String get learnRoadmapSrs => '间隔重复复习、测验与循序渐进的课程路径';

  @override
  String get learnRoadmapJlpt => 'JLPT N5–N1 练习';

  @override
  String get kanaTitle => '五十音速查';

  @override
  String get kanaScriptHiragana => '平假名';

  @override
  String get kanaScriptKatakana => '片假名';

  @override
  String get kanaSearchHint => '搜索假名或罗马音…';

  @override
  String kanaSearchResults(int count) {
    return '匹配 ($count)';
  }

  @override
  String get kanaNoMatches => '没有匹配的假名';

  @override
  String get kanaBasicSection => '清音五十音';

  @override
  String get kanaVoicedSection => '浊音 / 半浊音';

  @override
  String get kanaYoonSection => '拗音';

  @override
  String get kanaRulesSection => '发音规则';

  @override
  String get kanaRuleMoraTitle => '一个假名一拍';

  @override
  String get kanaRuleMoraBody => '每个假名占一个 mora。像 ka-ki-ku-ke-ko 一样保持均匀节奏。';

  @override
  String get kanaRuleVowelsTitle => '元音稳定';

  @override
  String get kanaRuleVowelsBody => 'a, i, u, e, o 要短而清楚，不像英语弱读元音那样被吞掉。';

  @override
  String get kanaRuleDakutenTitle => '浊音与半浊音';

  @override
  String get kanaRuleDakutenBody => '゛让辅音浊化: k 变 g，s 变 z，t 变 d，h 变 b。゜让 h 变 p。';

  @override
  String get kanaRuleYoonTitle => '拗音组合';

  @override
  String get kanaRuleYoonBody => '小写 ゃ/ゅ/ょ 与 i 段假名合并: き + ゃ = きゃ kya。';

  @override
  String get kanaRuleSokuonTitle => '促音';

  @override
  String get kanaRuleSokuonBody => '小写 っ/ッ 表示下一个辅音前有短暂停顿，并双写辅音，如 まって matte。';

  @override
  String get kanaRuleLongVowelsTitle => '长音';

  @override
  String get kanaRuleLongVowelsBody => 'ー 延长片假名音。平假名里 おう 常读长 o，えい 常读长 e。';

  @override
  String get kanaRuleNTitle => 'ん / ン';

  @override
  String get kanaRuleNBody => '通常读 n；在 m, b, p 前接近 m，在 k, g 前会变成较轻的鼻音。';

  @override
  String get vocabTitle => '单词';

  @override
  String get vocabSearchHint => '搜索汉字、读音或释义…';

  @override
  String get vocabEmpty => '没有匹配的单词';

  @override
  String vocabCount(int count) {
    return '$count 个单词';
  }

  @override
  String get vocabPartOfSpeech => '词性';

  @override
  String get grammarTitle => '语法';

  @override
  String get grammarSearchHint => '搜索句型或释义…';

  @override
  String get grammarEmpty => '没有匹配的语法点';

  @override
  String grammarCount(int count) {
    return '$count 个语法点';
  }

  @override
  String get grammarStructure => '结构';

  @override
  String get grammarExplanation => '说明';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsData => '数据';

  @override
  String get settingsStorageLocation => '存储位置';

  @override
  String get settingsSelectItem => '从左侧列表中选择一项';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsLicense => '许可证 (GPLv3)';

  @override
  String get settingsLicenses => '开源许可证';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get settingsWebDAVSync => 'WebDAV 同步';

  @override
  String get settingsWebDAVServerURL => '服务器地址';

  @override
  String get settingsWebDAVUsername => '用户名';

  @override
  String get settingsWebDAVPassword => '密码';

  @override
  String get settingsWebDAVRemotePath => '远程路径';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud 预设';

  @override
  String get settingsWebDAVTestConnection => '测试连接';

  @override
  String get settingsWebDAVAutoSync => '自动同步';

  @override
  String get settingsWebDAVAutoSyncDesc => '复习后和应用恢复时自动同步';

  @override
  String get settingsWebDAVSyncNow => '立即同步';

  @override
  String get settingsWebDAVSyncing => '同步中…';

  @override
  String get settingsWebDAVDisconnect => '断开连接';

  @override
  String get settingsWebDAVConfigSaved => '配置已保存';

  @override
  String get settingsWebDAVConfigRemoved => '配置已移除';

  @override
  String get settingsWebDAVConnectionSuccess => '连接成功';

  @override
  String get settingsWebDAVConnectionFailed => '连接失败';

  @override
  String get settingsWebDAVSyncSuccess => '同步完成';

  @override
  String get settingsWebDAVSyncFailed => '同步失败';

  @override
  String get settingsWebDAVAutoSyncFailed => '自动同步失败';

  @override
  String get settingsWebDAVAutoSyncConflict => '自动同步发现冲突';

  @override
  String get settingsWebDAVLastSuccess => '上次成功同步';

  @override
  String get settingsWebDAVNotConfigured => '尚未连接';

  @override
  String settingsWebDAVSyncWarnings(int count) {
    return '同步完成，但有 $count 条警告';
  }

  @override
  String get settingsWebDAVForceUpload => '强制上传';

  @override
  String get settingsWebDAVForceDownload => '强制下载';

  @override
  String get settingsWebDAVForceUploadConfirmTitle => '确认强制上传？';

  @override
  String get settingsWebDAVForceUploadConfirmBody =>
      '将用本地学习进度覆盖远程内容。上次同步后远程的更改将丢失。';

  @override
  String get settingsWebDAVForceDownloadConfirmTitle => '确认强制下载？';

  @override
  String get settingsWebDAVForceDownloadConfirmBody =>
      '将用远程学习进度替换本地内容。上次同步后本地的更改将丢失。';

  @override
  String get syncPhaseConnecting => '正在连接…';

  @override
  String syncPhaseDownloadingData(Object file, int current, int total) {
    return '正在下载 $file（$current/$total）';
  }

  @override
  String syncPhaseMerging(Object file) {
    return '正在合并 $file…';
  }

  @override
  String syncPhaseUploadingData(Object file) {
    return '正在上传 $file…';
  }

  @override
  String syncConflictTitle(Object name) {
    return '同步冲突：$name';
  }

  @override
  String get syncConflictDesc => '上次同步后，两台设备都学习过这一项。请保留其中一个版本。';

  @override
  String get syncUnknownItem => '当前内容库中没有这一项。';

  @override
  String get syncLocalVersion => '本地版本';

  @override
  String get syncRemoteVersion => '远程版本';

  @override
  String syncModifiedAt(Object time) {
    return '修改时间：$time';
  }

  @override
  String syncRecordAnswers(int correct, int wrong) {
    return '正确 $correct · 错误 $wrong';
  }

  @override
  String syncStreak(int count) {
    return '连续答对：$count';
  }

  @override
  String get syncStage => '阶段';

  @override
  String get stageFresh => '未开始';

  @override
  String get stageLearning => '学习中';

  @override
  String get stageMastered => '已掌握';

  @override
  String syncLastReviewed(Object time) {
    return '上次复习：$time';
  }

  @override
  String get syncNeverReviewed => '尚未复习';

  @override
  String get syncKeepLocal => '保留本地';

  @override
  String get syncKeepRemote => '保留远程';

  @override
  String get backupTitle => '备份';

  @override
  String get backupSubtitle => '学习进度的完整本机备份';

  @override
  String get backupCreate => '创建备份';

  @override
  String get backupCreated => '备份已创建';

  @override
  String get backupFailed => '无法创建备份';

  @override
  String get backupAutoBackup => '自动备份';

  @override
  String get backupAutoBackupDesc => '每天首次启动应用时备份一次';

  @override
  String get backupRetention => '保留期限';

  @override
  String get backupKeepForever => '永久保留';

  @override
  String backupKeepDays(int days) {
    return '$days 天';
  }

  @override
  String backupHistory(int count) {
    return '历史记录（$count）';
  }

  @override
  String get backupNoBackups => '暂无备份';

  @override
  String get backupCorrupt => '已损坏';

  @override
  String get backupLocalOnlyNote => '备份仅保存在本机，不会上传到任何地方。';

  @override
  String get backupRestore => '还原';

  @override
  String get backupRestoreConfirm => '这将用备份覆盖所选数据，是否继续？';

  @override
  String get backupRestoreModules => '还原内容';

  @override
  String get backupSelectAll => '全选';

  @override
  String get backupModuleProgress => '学习进度';

  @override
  String get backupRestored => '备份已还原';

  @override
  String get backupRestoreFailed => '无法还原备份';

  @override
  String get backupDeleteConfirm => '删除这个备份？';

  @override
  String get backupRestoredSyncDisabled => '自动同步已关闭，以免还原的数据被误合并到服务器。';

  @override
  String get backupForceUploadPrompt => '是否用还原后的数据覆盖远程副本？';

  @override
  String get backupForceUploadSkip => '暂不';

  @override
  String get backupForceUploadDone => '远程副本已覆盖';

  @override
  String get backupForceUploadFailed => '上传失败';

  @override
  String get exportData => '导出为 ZIP';

  @override
  String get exportSuccess => '已导出';

  @override
  String get exportFailed => '导出失败';

  @override
  String get importData => '从 ZIP 导入';

  @override
  String get importConfirm => '这将用压缩包中的内容替换本地学习进度，是否继续？';

  @override
  String get importSuccess => '导入完成';

  @override
  String get importFailed => '导入失败';

  @override
  String get licenseContentTitle => '内容许可';

  @override
  String get licenseContentBody =>
      '本应用的词汇内容来自开放的词典与词表。其许可证要求保留下方的署名，因此该部分不作翻译。';

  @override
  String get vocabGrammarUsed => '例句中的语法';

  @override
  String get grammarWordsUsed => '例句中的单词';

  @override
  String get kanaExampleWords => '以此假名开头的单词';

  @override
  String kanaStrokes(int count) {
    return '$count 画';
  }

  @override
  String get kanaConfusableWith => '容易混淆';

  @override
  String get kanaNoExtras => '这个假名暂无说明。';

  @override
  String get listColumns => '列数';

  @override
  String get listColumnsAuto => '自动';

  @override
  String listColumnsCount(int count) {
    return '$count';
  }

  @override
  String get speechSection => '语音';

  @override
  String get speechSpeak => '朗读';

  @override
  String get speechStop => '停止';

  @override
  String get speechRate => '朗读速度';

  @override
  String speechRateValue(Object rate) {
    return '$rate×';
  }

  @override
  String get speechRatePreview => '试听';

  @override
  String get speechVoice => '日语语音';

  @override
  String get speechVoiceDefault => '引擎默认';

  @override
  String get speechNoVoiceTitle => '未安装日语语音';

  @override
  String get speechNoVoiceBody =>
      '设备的语音引擎没有日语语音，因此无法朗读。请在系统语音设置中安装一个，然后重新打开应用。';

  @override
  String get speechOpenSystemSettings => '打开语音设置';

  @override
  String get speechOpenSystemSettingsFailed => '无法打开系统语音设置';

  @override
  String get speechSettingsHintApple => '在系统设置的「辅助功能 → 朗读内容」中添加日语语音。';

  @override
  String get practiceTitle => '发音练习';

  @override
  String get practiceStart => '点击开始朗读';

  @override
  String get practiceListening => '正在聆听……';

  @override
  String get practiceProcessing => '正在识别你说的话……';

  @override
  String get practiceRetry => '再试一次';

  @override
  String practiceHeard(Object text) {
    return '听到：$text';
  }

  @override
  String practiceScore(int score) {
    return '$score / 100';
  }

  @override
  String get practicePerfect => '每个音拍都对上了。';

  @override
  String get practiceLegendCorrect => '正确';

  @override
  String get practiceLegendSubstituted => '不同';

  @override
  String get practiceLegendMissing => '缺少';

  @override
  String get practiceLegendExtra => '多余';

  @override
  String get practiceLimitsNote => '这是把语音识别理解到的内容与读音作对照。它判断的是你是否能被听懂，而不是口音或声调。';

  @override
  String get practiceNoMatch => '没有识别到内容。请再试一次，离麦克风近一些。';

  @override
  String get practiceLanguageUnavailable =>
      '本设备没有离线日语识别。请在系统设置中安装日语语音数据，或在「设置 › 语音」中允许网络回退。';

  @override
  String get practicePermissionDenied => '麦克风权限被拒绝，因此无法收音。';

  @override
  String get practiceUnavailable => '本设备没有应用可以使用的语音识别器。';

  @override
  String get practiceMicRationaleTitle => '使用麦克风？';

  @override
  String get practiceMicRationaleBody =>
      '为了对照你的发音，应用需要听到你的声音。识别在你的设备上进行，不会保存或发送任何音频。';

  @override
  String get practiceMicRationaleAllow => '继续';

  @override
  String get speechNetworkFallback => '允许网络识别';

  @override
  String get speechNetworkFallbackBody =>
      '默认关闭。开启后，若你的设备没有离线日语识别，你说的内容会被发送到系统语音服务进行转写。';

  @override
  String get speechRecognizerReady => '语音识别可用';

  @override
  String get speechRecognizerMissing => '本设备没有日语语音识别';

  @override
  String get speechRecognizerUnchecked => '首次练习发音时才会检查语音识别';

  @override
  String get practiceAction => '练习';

  @override
  String get labTitle => '句子实验室';

  @override
  String get labSubtitle => '看看一个句子由什么组成';

  @override
  String get labInputHint => '输入或粘贴一个日语句子';

  @override
  String get labAnalyze => '分析';

  @override
  String get labClear => '清空';

  @override
  String get labEmpty => '在上面输入一个句子，或者从词汇、语法的例句打开一个。';

  @override
  String get labWords => '词';

  @override
  String get labStructure => '结构';

  @override
  String get labGrammarUsed => '用到的语法';

  @override
  String get labGrammarNone => '没有匹配到已收录的语法点。';

  @override
  String get labIssues => '可能的问题';

  @override
  String get labIssuesNone => '没有看到异常之处。';

  @override
  String get labUnknownWarning => '有些字不在内置词典中，因此这里的部分结果可能不对。';

  @override
  String get labDependsOn => '修饰';

  @override
  String get labRoot => '主谓语';

  @override
  String get labLimitsNote => '这是一部词典加一组规则，不是翻译器。结构是最佳猜测，「可能的问题」值得核对，而不宜直接采信。';

  @override
  String get labOpenAction => '分析这个句子';

  @override
  String labIssueParticleFrame(Object word) {
    return '这里的$word通常用が而不是を。';
  }

  @override
  String labIssueParticleFrameSuggest(Object word, Object suggestion) {
    return '$word通常用が而不是を。你想说的是$suggestion吗？';
  }

  @override
  String labIssueNaNo(Object word, Object suggestion) {
    return '$word后面接名词时可能需要$suggestion。';
  }

  @override
  String labIssueTense(Object word) {
    return '$word指向的时间与动词形式不一致。';
  }

  @override
  String labIssueCopula(Object word) {
    return '句子以$word结尾，却没有谓语。你想说的是$wordです吗？';
  }

  @override
  String labIssueAdjectiveAsVerb(Object word) {
    return '$word是形容词，不接动词词尾。';
  }

  @override
  String get labCategoryNoun => '名词';

  @override
  String get labCategoryVerb => '动词';

  @override
  String get labCategoryAdjective => '形容词';

  @override
  String get labCategoryParticle => '助词';

  @override
  String get labCategoryAuxiliary => '助动词';

  @override
  String get labCategoryOther => '其他';

  @override
  String get labCategoryUnknown => '不在词典中';

  @override
  String get aiSection => '端侧 AI';

  @override
  String get aiEnable => '端侧 AI 辅助';

  @override
  String get aiEnableBody =>
      '默认关闭。打开后，句子实验室可以用更多文字解释一处发现，并给出一个改写建议，模型在本设备上运行。生成的文字始终带有标注，且绝不会改变分析结果。';

  @override
  String get aiUnsupportedPlatform => '此平台没有端侧模型。';

  @override
  String get aiStatusPrompt => '解释';

  @override
  String get aiStatusProofread => '改写建议';

  @override
  String get aiStatusUnavailable => '本设备不支持';

  @override
  String get aiStatusDownloadable => '尚未下载';

  @override
  String get aiStatusDownloading => '系统正在下载';

  @override
  String get aiStatusAvailable => '可以使用';

  @override
  String get aiDownload => '下载';

  @override
  String get aiDownloadNote =>
      '下载由 Android AICore 系统服务完成，模型从 Google 获取。只有你点击「下载」后才会开始。';

  @override
  String get aiDownloading => '下载中…';

  @override
  String aiDownloadedBytes(Object megabytes) {
    return '已下载 $megabytes MB';
  }

  @override
  String get aiDownloadFailed => '模型下载失败，可以再试一次。';

  @override
  String get aiExplain => '解释';

  @override
  String get aiExplainSentence => '解释这个句子';

  @override
  String get aiSuggestCorrection => '给出改写建议';

  @override
  String get aiGeneratedLabel => '在本设备上生成——可能有误';

  @override
  String get aiGenerating => '正在本设备上生成…';

  @override
  String get aiDismiss => '收起';

  @override
  String get aiCorrectionNone => '模型没有给出与原句不同的写法。';

  @override
  String get aiCorrectionHeading => '一种可能的改写';

  @override
  String get aiFailedUnavailable => '端侧模型尚未就绪，请到设置中查看。';

  @override
  String get aiFailedBusy => '还有一条回答正在生成。';

  @override
  String get aiFailedTimeout => '模型耗时过长，请再试一次。';

  @override
  String get aiFailedTooLong => '这个句子对端侧模型来说太长了。';

  @override
  String get aiFailedGeneric => '无法为此生成内容。';

  @override
  String get aiHintDownload => '端侧 AI 已打开，但模型尚未下载。设置 › 端侧 AI。';
}

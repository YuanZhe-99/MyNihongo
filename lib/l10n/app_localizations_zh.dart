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
  String get learnWelcomeBody => '现在可以浏览五十音、单词和语法；课程、复习与发音练习正在路上。';

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
  String get learnRoadmapPronunciation => '借助语音识别与语音合成的发音练习';

  @override
  String get learnRoadmapSrs => '间隔重复复习与循序渐进的课程';

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
}

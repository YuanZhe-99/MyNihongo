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
}

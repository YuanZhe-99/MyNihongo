/// Purpose: Name the four sections of a JLPT paper and the question types each
/// one is built from.
/// Inputs: Content files name these; nothing else constructs them.
/// Returns: Two enums and their parsers.
/// Side effects: None.
/// Notes: **These names are a compatibility contract.** A section name is
/// written into every exam record's payload and a type key is written into
/// every drill file, so renaming one silently orphans the records and the
/// content that already use it. The *counts* per type are not here — they are
/// in `structure.json`, because JEES says they vary from session to session,
/// and a number that varies is content rather than code.
library;

/// One section of the paper.
///
/// The JLPT calls these 文字・語彙, 文法, 読解 and 聴解. They are separate here
/// even where a level examines two of them in one timed block, because a
/// scoring group is made of sections and a weakness report is read per section.
enum DrillSection {
  /// 文字・語彙 — writing and vocabulary.
  vocab,

  /// 文法 — grammar.
  grammar,

  /// 読解 — reading, which needs a passage on screen.
  reading,

  /// 聴解 — listening, which needs a voice.
  listening;

  /// Purpose: Parse a section from content JSON or from a saved record.
  /// Inputs: `value`.
  /// Returns: `DrillSection?` — null for anything unrecognized.
  /// Side effects: None.
  /// Notes: Case-folded, so a file written `Vocab` still loads. Null rather
  /// than a default, because a question in no section cannot be scored and
  /// silently filing it under vocabulary would put it in the wrong group.
  static DrillSection? parse(Object? value) {
    if (value is! String) return null;
    final folded = value.toLowerCase();
    for (final section in values) {
      if (section.name.toLowerCase() == folded) return section;
    }
    return null;
  }
}

/// One 大問 — a numbered question type on the paper.
///
/// The key is what a drill file writes; the section is what the type is scored
/// under. Two levels can share a type and give it different counts, which is
/// why the count lives in `structure.json` and only the *shape* is here.
enum DrillType {
  /// 漢字読み — how the underlined word is read.
  kanjiReading('kanji-reading', DrillSection.vocab),

  /// 表記 — which spelling is the written form of the underlined reading.
  orthography('orthography', DrillSection.vocab),

  /// 語形成 — which prefix or suffix completes the compound. N2 only.
  wordFormation('word-formation', DrillSection.vocab),

  /// 文脈規定 — which word the context calls for.
  context('context', DrillSection.vocab),

  /// 言い換え類義 — which option means the same as the underlined part.
  paraphrase('paraphrase', DrillSection.vocab),

  /// 用法 — which sentence uses the word correctly.
  usage('usage', DrillSection.vocab),

  /// 文の文法1 — which form fits the blank.
  formSelection('form-selection', DrillSection.grammar),

  /// 文の文法2 — put the fragments in order and say which lands on ★.
  sentenceComposition('sentence-composition', DrillSection.grammar),

  /// 文章の文法 — a blank in a passage rather than in one sentence.
  textGrammar('text-grammar', DrillSection.grammar),

  /// 内容理解（短文）.
  short('short', DrillSection.reading),

  /// 内容理解（中文）.
  mid('mid', DrillSection.reading),

  /// 内容理解（長文）.
  long('long', DrillSection.reading),

  /// 統合理解 — two passages compared.
  integrated('integrated', DrillSection.reading),

  /// 主張理解 — what the writer is arguing.
  thematic('thematic', DrillSection.reading),

  /// 情報検索 — find one fact in a notice or a timetable.
  info('info', DrillSection.reading),

  /// 課題理解 — what the speaker has to do next.
  task('task', DrillSection.listening),

  /// ポイント理解 — one stated detail.
  point('point', DrillSection.listening),

  /// 概要理解 — what the talk was about.
  outline('outline', DrillSection.listening),

  /// 発話表現 — what to say in the situation described.
  expression('expression', DrillSection.listening),

  /// 即時応答 — reply to one spoken line.
  quickResponse('quick-response', DrillSection.listening),

  /// 統合理解（聴解） — a longer exchange with more than one question.
  integratedListening('integrated-listening', DrillSection.listening);

  /// Purpose: Bind a type to its key and its section.
  /// Inputs: `key` as content writes it; `section` it is scored under.
  /// Returns: A new `DrillType` value.
  /// Side effects: None.
  /// Notes: The key is kebab-case rather than the Dart name because content
  /// files are hand-written and hyphens read better there than camel case.
  const DrillType(this.key, this.section);

  /// What a drill file writes in `type`.
  final String key;

  /// Which section this type is scored under.
  final DrillSection section;

  /// Purpose: Parse a type from a drill file.
  /// Inputs: `value`.
  /// Returns: `DrillType?` — null for anything unrecognized.
  /// Side effects: None.
  /// Notes: Null rather than a default. The gate rejects an unknown type
  /// before it ships; this is the second line of defence, and dropping the
  /// question is better than scoring it under a section it does not belong to.
  static DrillType? parse(Object? value) {
    if (value is! String) return null;
    for (final type in values) {
      if (type.key == value) return type;
    }
    return null;
  }
}

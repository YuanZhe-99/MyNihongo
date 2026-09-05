/// Purpose: Parse one drill file and the structure file, and turn a drill
/// question into the shape the quiz runner already knows.
/// Inputs: The JSON of `assets/content/drills/*.json`.
/// Returns: Immutable values.
/// Side effects: None.
/// Notes: A malformed row costs the row, never the file — the same stance as
/// `LessonPath`, and for the same reason: these files are hand-written and
/// hand-merged, and one bad question must not empty a level.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../content/models/jlpt_level.dart';
import '../../content/models/localized_strings.dart';
import '../../lessons/models/scenario.dart';
import '../../quiz/models/quiz_question.dart';
import 'drill_section.dart';

/// How much of a paper an exam asks.
///
/// Here rather than beside the exam session because it is the *structure* that
/// knows how to scale — the composition of a short paper is a fact about the
/// paper, not about the session running it.
enum ExamScale {
  /// About a third of each 大問, rounded up, never below one.
  ///
  /// The default. A full N1 paper is 165 minutes; the point of practising is
  /// to do it often, and an exam nobody has an afternoon for is not practice.
  short,

  /// The official composition.
  full,
}

/// One passage: a reading text, a listening script, or a 文章の文法 text.
class DrillPassage {
  /// Purpose: Hold one passage and its translations.
  /// Inputs: `id`, `type`, `lines`, `translations`.
  /// Returns: A new `DrillPassage` instance.
  /// Side effects: None.
  /// Notes: Stored line by line rather than as one string, because the same
  /// shape has to serve three things: a reading text that is shown, a
  /// listening script that is spoken one line at a time and highlighted as it
  /// goes, and a dialogue whose speakers are named.
  const DrillPassage({
    required this.id,
    required this.type,
    required this.lines,
    this.translations = LocalizedStrings.empty,
  });

  /// `p:n5-r-001`.
  final String id;

  /// Which 大問 this passage belongs to.
  final DrillType type;

  /// The passage, one line at a time.
  final List<DialogueLine> lines;

  /// The whole passage in the learner's language, where one was written.
  ///
  /// A line may carry its own translation too. Both are optional and both are
  /// hidden until the question has been answered.
  final LocalizedStrings translations;

  /// The whole passage as one string, for a reading text.
  String get ja => [for (final line in lines) line.ja].join();

  /// Purpose: Parse one passage.
  /// Inputs: `json`.
  /// Returns: `DrillPassage?` — null without an id, a known type or a line.
  /// Side effects: None.
  /// Notes: `DialogueLine.fromJson` is reused rather than copied: it already
  /// takes `speaker`, `ja`, `reading` and every other key as a language, which
  /// is exactly the shape a script needs.
  static DrillPassage? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = '${json['id'] ?? ''}';
    final type = DrillType.parse(json['type']);
    final lines = [
      for (final line in _list(json['lines'])) ?DialogueLine.fromJson(line),
    ];
    if (id.isEmpty || type == null || lines.isEmpty) return null;
    return DrillPassage(
      id: id,
      type: type,
      lines: lines,
      translations: LocalizedStrings.fromJson({
        for (final entry in json.entries)
          if (entry.key != 'id' && entry.key != 'type' && entry.key != 'lines')
            entry.key: entry.value,
      }),
    );
  }
}

/// One question on a paper.
class DrillQuestion {
  /// Purpose: Hold one drill question.
  /// Inputs: All fields; see each one.
  /// Returns: A new `DrillQuestion` instance.
  /// Side effects: None.
  /// Notes: `items` is what the answer is recorded against and is never
  /// empty — the gate refuses a question that teaches nothing identifiable.
  /// The **first** id is the one the scheduler sees; the rest are what the
  /// weakness report joins on, because a sentence can turn on two points and
  /// only one of them can own the review interval.
  const DrillQuestion({
    required this.id,
    required this.type,
    required this.items,
    required this.kind,
    required this.prompt,
    this.ja,
    this.reading,
    this.blank,
    this.passageId,
    this.options = const [],
    this.answer,
    this.answerOrder = const [],
    this.frameBefore,
    this.frameAfter,
    this.explanation,
  });

  /// `q:n5-v-001`. Stable, so a question can be named in a bug report and
  /// remembered as already asked.
  final String id;

  /// Which 大問 this is.
  final DrillType type;

  /// The catalog ids this question is about, most important first.
  final List<String> items;

  /// How it is answered.
  final AnswerKind kind;

  /// The instruction or the question itself, in each language.
  final LocalizedStrings prompt;

  /// The Japanese the question is about, where the question shows one.
  ///
  /// Absent for a reading or listening question, whose Japanese is the
  /// passage.
  final String? ja;

  /// [ja]'s reading in kana.
  final String? reading;

  /// The span of [ja] the question turns on.
  ///
  /// Rendered as a gap or as a marked span depending on the type — see
  /// [DrillTypeRendering.blankStyle]. Absent where the whole sentence is the
  /// question.
  final String? blank;

  /// The passage this question is about.
  final String? passageId;

  /// The four options, or the fragments of an ordering question.
  final List<String> options;

  /// Which option is right, for a choice question.
  final int? answer;

  /// Where each fragment goes, for an ordering question.
  ///
  /// `answerOrder[i]` is the position fragment `i` ends up in, which is the
  /// convention `QuizSession` already reads.
  final List<int> answerOrder;

  /// What stands before the fragments in the finished sentence.
  final String? frameBefore;

  /// What stands after them.
  final String? frameAfter;

  /// Why the right answer is right, in each language.
  final LocalizedStrings? explanation;

  /// The catalog id the answer is recorded against.
  String get itemId => items.first;

  /// Purpose: Parse one question.
  /// Inputs: `json`.
  /// Returns: `DrillQuestion?` — null when it could not be asked or answered.
  /// Side effects: None.
  /// Notes: The refusals mirror `AuthoredQuestion.fromJson` and add the two
  /// this shape makes possible: an ordering question whose `answerOrder` is
  /// not a permutation of its fragments cannot be marked, and a question with
  /// no `items` cannot be recorded against anything.
  static DrillQuestion? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = '${json['id'] ?? ''}';
    final type = DrillType.parse(json['type']);
    final items = [
      for (final item in _list(json['items']))
        if ('$item'.isNotEmpty) '$item',
    ];
    final options = [for (final option in _list(json['options'])) '$option'];
    final kind = switch ('${json['kind'] ?? 'choice'}') {
      'order' => AnswerKind.order,
      'choice' => AnswerKind.choice,
      _ => null,
    };
    if (id.isEmpty || type == null || items.isEmpty || kind == null) {
      return null;
    }
    if (options.length < 2 || options.any((option) => option.isEmpty)) {
      return null;
    }

    final answer = json['answer'];
    final answerOrder = [
      for (final index in _list(json['answerOrder']))
        if (index is int) index,
    ];
    if (kind == AnswerKind.order) {
      // Not a permutation means two fragments claim one position, or one
      // position is claimed by none. Either way the sentence cannot be
      // rebuilt, so there is nothing to mark against.
      final sorted = [...answerOrder]..sort();
      final expected = [for (var i = 0; i < options.length; i++) i];
      if (!_sameOrder(sorted, expected)) return null;
    } else if (answer is! int || answer < 0 || answer >= options.length) {
      return null;
    }

    final frame = json['frame'];
    return DrillQuestion(
      id: id,
      type: type,
      items: items,
      kind: kind,
      prompt: LocalizedStrings.fromJson(json['prompt']),
      ja: _text(json['ja']),
      reading: _text(json['reading']),
      blank: _text(json['blank']),
      passageId: _text(json['passage']),
      options: options,
      answer: answer is int ? answer : null,
      answerOrder: answerOrder,
      frameBefore: frame is Map ? _text(frame['before']) : null,
      frameAfter: frame is Map ? _text(frame['after']) : null,
      explanation: json['explanation'] == null
          ? null
          : LocalizedStrings.fromJson(json['explanation']),
    );
  }

  /// Purpose: Turn this into the question the quiz runner already renders.
  /// Inputs: The `locale` to resolve the written text in.
  /// Returns: `QuizQuestion`.
  /// Side effects: None.
  /// Notes: The adapter `QuestionBank` never had a public equivalent of, and
  /// the one place the paper's conventions are turned into the app's.
  ///
  /// - The **big** line is the Japanese where the question shows Japanese, and
  ///   the question itself where it does not. A reading question's question is
  ///   the thing to answer; making it a grey instruction under an empty prompt
  ///   would bury it.
  /// - The **small** line is the paper's instruction, written per question
  ///   because a paper writes it per 大問 and two 大問 that look identical ask
  ///   for different things.
  /// - The reading is withheld for the two types where the reading **is** the
  ///   answer. Printing furigana over 公園 in a 漢字読み question would answer
  ///   it.
  /// - `speakText` is null for every drill question. A listening drill is
  ///   played by `ListeningScriptPlayer`, line by line, and a speak button
  ///   that read the localized question aloud in a Japanese voice would be
  ///   worse than none.
  QuizQuestion toQuizQuestion(Locale locale) {
    final written = ja;
    final question = prompt.resolveJoined(locale);
    return QuizQuestion(
      itemId: itemId,
      questionId: id,
      mode: QuizMode.drill,
      kind: kind,
      prompt: written == null ? question : renderJa(),
      promptReading: written == null || type.hidesReading ? null : reading,
      instruction: written == null ? null : question,
      passageId: passageId,
      options: options,
      answerIndex: answer,
      answerOrder: answerOrder,
      explanation: _nullIfEmpty(explanation?.resolveJoined(locale)),
    );
  }

  /// Purpose: Render the Japanese the way this 大問 shows it.
  /// Inputs: None; reads [ja], [blank] and the type's blank style.
  /// Returns: `String`; empty when there is no Japanese.
  /// Side effects: None.
  /// Notes: A gap is `（　　）` and a marked span is `【…】`, both full-width,
  /// because that is what the paper does and what a learner sitting the real
  /// thing will see. Only the **first** occurrence is touched: a sentence that
  /// says the word twice is asking about one of them, and blanking both would
  /// change the question.
  String renderJa() {
    final written = ja;
    if (written == null) return '';
    final span = blank;
    if (span == null || !written.contains(span)) return written;
    return switch (type.blankStyle) {
      BlankStyle.gap => written.replaceFirst(span, '（　　）'),
      BlankStyle.marked => written.replaceFirst(span, '【$span】'),
      BlankStyle.none => written,
    };
  }
}

/// One drill file: a level, a section, its passages and its questions.
class DrillFile {
  /// Purpose: Hold one level's questions for one section.
  /// Inputs: `level`, `section`, `passages`, `questions`.
  /// Returns: A new `DrillFile` instance.
  /// Side effects: None.
  /// Notes: One file per level per section, flat, so a section can be written
  /// and reviewed without touching another and `pubspec.yaml` gains one line
  /// for the whole of Phase 4.
  const DrillFile({
    required this.level,
    required this.section,
    this.passages = const [],
    this.questions = const [],
  });

  /// The level this file is for.
  final JlptLevel level;

  /// The section it covers.
  final DrillSection section;

  /// Its passages, if any.
  final List<DrillPassage> passages;

  /// Its questions.
  final List<DrillQuestion> questions;

  /// Whether this file has nothing to ask.
  bool get isEmpty => questions.isEmpty;

  /// Purpose: Find one passage.
  /// Inputs: `id`.
  /// Returns: `DrillPassage?`.
  /// Side effects: None.
  /// Notes: Linear over at most a few dozen passages, which is cheaper than
  /// the map it would take to avoid.
  DrillPassage? passageById(String? id) {
    if (id == null) return null;
    for (final passage in passages) {
      if (passage.id == id) return passage;
    }
    return null;
  }

  /// Purpose: Parse one drill file.
  /// Inputs: `json`, and the `level` and `section` the caller asked for.
  /// Returns: `DrillFile` — empty when the JSON is not a file of that shape.
  /// Side effects: None.
  /// Notes: The level and section come from the caller and the file's own are
  /// checked against them. A file that says it is N4 grammar under the N5
  /// vocabulary name is a merge accident, and loading it anyway would score N4
  /// grammar as N5 vocabulary.
  static DrillFile fromJson(
    Object? json, {
    required JlptLevel level,
    required DrillSection section,
  }) {
    final empty = DrillFile(level: level, section: section);
    if (json is! Map) return empty;
    if (JlptLevel.parse(json['level']) != level) return empty;
    if (DrillSection.parse(json['section']) != section) return empty;
    return DrillFile(
      level: level,
      section: section,
      passages: [
        for (final passage in _list(json['passages']))
          ?DrillPassage.fromJson(passage),
      ],
      questions: [
        for (final question in _list(json['questions']))
          ?DrillQuestion.fromJson(question),
      ],
    );
  }
}

/// One scoring group of a level, as JEES reports it.
class ScoringGroup {
  /// Purpose: Hold one scoring group.
  /// Inputs: `id`, the `sections` it covers, its `max` and its `pass` mark.
  /// Returns: A new `ScoringGroup` instance.
  /// Side effects: None.
  /// Notes: The app cannot compute a scaled score — the raw-to-scaled equating
  /// is unpublished — so `max` and `pass` are carried to explain the rule
  /// ("fail one group and you fail the level"), not to pretend to apply it.
  const ScoringGroup({
    required this.id,
    required this.sections,
    required this.max,
    required this.pass,
  });

  /// `languageKnowledge`, `reading`, `listening` or `languageReading`.
  final String id;

  /// The sections scored together in this group.
  final List<DrillSection> sections;

  /// The scaled score this group is out of.
  final int max;

  /// The sectional pass mark.
  final int pass;
}

/// One timed block of a paper.
class ExamBlockSpec {
  /// Purpose: Hold one block's sections and its time.
  /// Inputs: `sections`, `minutes`.
  /// Returns: A new `ExamBlockSpec` instance.
  /// Side effects: None.
  /// Notes: A block is what the clock runs on, which is why N2's single
  /// 105-minute block over three sections is one entry and not three.
  const ExamBlockSpec({required this.sections, required this.minutes});

  /// The sections examined in this block, in the order the paper asks them.
  final List<DrillSection> sections;

  /// How long the block runs.
  final int minutes;
}

/// One level's paper.
class LevelStructure {
  /// Purpose: Hold one level's blocks, scoring groups and composition.
  /// Inputs: All fields.
  /// Returns: A new `LevelStructure` instance.
  /// Side effects: None.
  /// Notes: None.
  const LevelStructure({
    required this.blocks,
    required this.scoring,
    required this.types,
    required this.overallMax,
    required this.overallPass,
  });

  /// The timed blocks, in order.
  final List<ExamBlockSpec> blocks;

  /// The scoring groups.
  final List<ScoringGroup> scoring;

  /// How many questions each 大問 has on a full paper.
  final Map<DrillType, int> types;

  /// The scaled score the whole paper is out of.
  final int overallMax;

  /// The overall pass mark.
  final int overallPass;

  /// How many questions a full paper asks.
  int get fullCount => types.values.fold(0, (a, b) => a + b);

  /// Purpose: Say how many questions of each type a paper at this scale asks.
  /// Inputs: `scale`.
  /// Returns: `Map<DrillType, int>`.
  /// Side effects: None.
  /// Notes: A third, **rounded up, never below one**. Rounding up rather than
  /// down is what keeps every 大問 on the paper: a third of a 大問 with one
  /// question is a third of a question, and dropping it would quietly stop
  /// examining 情報検索 at all.
  Map<DrillType, int> composition(ExamScale scale) => switch (scale) {
    ExamScale.full => Map.unmodifiable(types),
    ExamScale.short => Map.unmodifiable({
      for (final entry in types.entries)
        entry.key: math.max(1, (entry.value / 3).ceil()),
    }),
  };

  /// Purpose: Say how long each block runs at this scale.
  /// Inputs: `scale`.
  /// Returns: `List<int>` of minutes, one per block, in order.
  /// Side effects: None.
  /// Notes: Scaled the same way as the counts, so a short paper is under the
  /// same time pressure per question as a full one. That pressure is most of
  /// what makes a mock different from practice.
  List<int> minutes(ExamScale scale) => [
    for (final block in blocks)
      switch (scale) {
        ExamScale.full => block.minutes,
        ExamScale.short => math.max(1, (block.minutes / 3).ceil()),
      },
  ];

  /// Purpose: Find the scoring group one section is marked under.
  /// Inputs: `section`.
  /// Returns: `ScoringGroup?`.
  /// Side effects: None.
  /// Notes: None.
  ScoringGroup? groupFor(DrillSection section) {
    for (final group in scoring) {
      if (group.sections.contains(section)) return group;
    }
    return null;
  }

  /// Purpose: Parse one level.
  /// Inputs: `json`.
  /// Returns: `LevelStructure?` — null without blocks or types.
  /// Side effects: None.
  /// Notes: An unknown type key is dropped rather than fatal, so a structure
  /// file that names a 大問 this build has no enum for still yields the rest.
  static LevelStructure? fromJson(Object? json) {
    if (json is! Map) return null;
    final blocks = [
      for (final block in _list(json['blocks']))
        if (block is Map)
          ExamBlockSpec(
            sections: [
              for (final section in _list(block['sections']))
                ?DrillSection.parse(section),
            ],
            minutes: _int(block['minutes']) ?? 0,
          ),
    ]..removeWhere((block) => block.sections.isEmpty || block.minutes <= 0);

    final types = <DrillType, int>{};
    final raw = json['types'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final type = DrillType.parse('${entry.key}');
        final count = _int(entry.value);
        if (type != null && count != null && count > 0) types[type] = count;
      }
    }
    if (blocks.isEmpty || types.isEmpty) return null;

    return LevelStructure(
      blocks: blocks,
      scoring: [
        for (final group in _list(json['scoring']))
          if (group is Map && '${group['id'] ?? ''}'.isNotEmpty)
            ScoringGroup(
              id: '${group['id']}',
              sections: [
                for (final section in _list(group['sections']))
                  ?DrillSection.parse(section),
              ],
              max: _int(group['max']) ?? 60,
              pass: _int(group['pass']) ?? 19,
            ),
      ],
      types: Map.unmodifiable(types),
      overallMax: _int(json['overallMax']) ?? 180,
      overallPass: _int(json['overallPass']) ?? 0,
    );
  }
}

/// The whole structure file.
class JlptStructure {
  /// Purpose: Hold every level's paper.
  /// Inputs: `source` — where the numbers came from; `levels`.
  /// Returns: A new `JlptStructure` instance.
  /// Side effects: None.
  /// Notes: `source` is carried into the app rather than left in the file as a
  /// comment because these numbers are somebody else's published fact, and a
  /// screen that shows them should be able to say whose.
  const JlptStructure({required this.source, required this.levels});

  /// An instance with no levels, for a build whose asset failed to load.
  static const empty = JlptStructure(source: '', levels: {});

  /// Where the numbers came from.
  final String source;

  /// One entry per level that has been written down.
  final Map<JlptLevel, LevelStructure> levels;

  /// Purpose: Look one level up.
  /// Inputs: `level`.
  /// Returns: `LevelStructure?`.
  /// Side effects: None.
  /// Notes: None.
  LevelStructure? forLevel(JlptLevel level) => levels[level];

  /// Purpose: Parse the structure file.
  /// Inputs: `json`.
  /// Returns: `JlptStructure` — [empty] for anything unreadable.
  /// Side effects: None.
  /// Notes: None.
  static JlptStructure fromJson(Object? json) {
    if (json is! Map) return empty;
    final raw = json['levels'];
    if (raw is! Map) return empty;
    final levels = <JlptLevel, LevelStructure>{};
    for (final entry in raw.entries) {
      final level = JlptLevel.parse('${entry.key}');
      final structure = LevelStructure.fromJson(entry.value);
      if (level != null && structure != null) levels[level] = structure;
    }
    return JlptStructure(
      source: '${json['source'] ?? ''}',
      levels: Map.unmodifiable(levels),
    );
  }
}

/// How a 大問 shows the part of the sentence it is about.
enum BlankStyle {
  /// The sentence is shown whole.
  none,

  /// The span is replaced by `（　　）`; the options fill it.
  gap,

  /// The span is wrapped in `【…】`; the options are about it.
  marked,
}

/// The rendering and reading rules each 大問 follows.
extension DrillTypeRendering on DrillType {
  /// How this type shows `DrillQuestion.blank`.
  ///
  /// A gap asks what belongs there; a marked span asks about something that is
  /// already there. Rendering one as the other changes the question, which is
  /// why this is a property of the type and not a field in the file.
  BlankStyle get blankStyle => switch (this) {
    DrillType.context ||
    DrillType.wordFormation ||
    DrillType.formSelection ||
    DrillType.textGrammar => BlankStyle.gap,
    DrillType.kanjiReading ||
    DrillType.orthography ||
    DrillType.paraphrase => BlankStyle.marked,
    _ => BlankStyle.none,
  };

  /// Whether furigana must be withheld because the reading is the answer.
  ///
  /// 漢字読み asks how the word is read and 表記 asks how the reading is
  /// written. Printing the reading over the sentence answers both.
  bool get hidesReading =>
      this == DrillType.kanjiReading || this == DrillType.orthography;

  /// Whether this type needs a passage on screen or in the ear.
  bool get needsPassage =>
      section == DrillSection.reading ||
      section == DrillSection.listening ||
      this == DrillType.textGrammar;
}

/// Purpose: Read a JSON value as a list, whatever it turns out to be.
/// Inputs: `value`.
/// Returns: `List<Object?>` — empty for anything that is not a list.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
List<Object?> _list(Object? value) => value is List ? value : const [];

/// Purpose: Read a JSON value as a non-empty string.
/// Inputs: `value`.
/// Returns: `String?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. An empty string and an
/// absent key mean the same thing here, and collapsing them means every reader
/// has one case to handle rather than two.
String? _text(Object? value) {
  if (value == null) return null;
  final text = '$value';
  return text.isEmpty ? null : text;
}

/// Purpose: Return null for a string with nothing in it.
/// Inputs: `value`.
/// Returns: `String?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. A question whose
/// explanation was written in no language at all shows no explanation card
/// rather than an empty one.
String? _nullIfEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;

/// Purpose: Read a JSON value as an integer.
/// Inputs: `value`.
/// Returns: `int?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. A number written as a
/// string is accepted, because these files are hand-edited.
int? _int(Object? value) => switch (value) {
  final int number => number,
  final String text => int.tryParse(text),
  _ => null,
};

/// Purpose: Compare two integer lists element by element.
/// Inputs: `a`, `b`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. `listEquals` would mean
/// importing `foundation` into a model file that otherwise needs nothing from
/// Flutter but `Locale`.
bool _sameOrder(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

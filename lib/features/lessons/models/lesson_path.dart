/// The units a level is taught in, parsed from `assets/content/lessons/*.json`.
///
/// A unit is a topic: a name, the grammar points and words it teaches, a few
/// sentences that use them, and some hand-written questions. It is the thing
/// the Learn tab shows and the thing a practice session draws from.
///
/// Everything here is tolerant of a malformed row, like the rest of the
/// catalog: a unit with a broken sentence loses the sentence, not the unit.
/// The one thing that is not tolerated is a missing id, because an id is what
/// progress is recorded against.
library;

import '../../content/models/localized_strings.dart';
import 'scenario.dart';

/// One level's path.
class LessonPath {
  /// Purpose: Hold the units of one level.
  /// Inputs: `level`, `units`.
  /// Returns: A new `LessonPath` instance.
  /// Side effects: None.
  /// Notes: None.
  const LessonPath({required this.level, required this.units});

  /// The JLPT level label the file declares, `N5` and so on.
  final String level;

  /// The units, in teaching order.
  final List<LessonUnit> units;

  /// Purpose: Parse one lessons file.
  /// Inputs: `json` — the decoded file.
  /// Returns: `LessonPath` — empty when the file cannot be read.
  /// Side effects: None.
  /// Notes: An unreadable file is an empty path rather than an exception. The
  /// Learn tab then shows the dashboard it showed before the path existed,
  /// which is the honest thing for a build whose content did not load.
  factory LessonPath.fromJson(Object? json) {
    if (json is! Map) return const LessonPath(level: '', units: []);
    return LessonPath(
      level: '${json['level'] ?? ''}',
      units: [
        for (final unit in _list(json['units']))
          ?LessonUnit.fromJson(unit),
      ],
    );
  }

  /// Purpose: Find a unit by its id.
  /// Inputs: `id`.
  /// Returns: `LessonUnit?`.
  /// Side effects: None.
  /// Notes: None.
  LessonUnit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }
}

/// One unit: a topic, what it teaches, and what it asks.
class LessonUnit {
  /// Purpose: Hold one unit.
  /// Inputs: All fields.
  /// Returns: A new `LessonUnit` instance.
  /// Side effects: None.
  /// Notes: None.
  const LessonUnit({
    required this.id,
    required this.title,
    this.grammar = const [],
    this.vocab = const [],
    this.sentences = const [],
    this.questions = const [],
    this.writingPrompt,
    this.scenario,
  });

  /// `unit:n5-1`. A compatibility contract: the pass record is keyed by it.
  final String id;

  /// The topic's name.
  final LocalizedStrings title;

  /// The grammar ids this unit teaches.
  final List<String> grammar;

  /// The vocabulary ids this unit teaches.
  final List<String> vocab;

  /// Sentences written for this unit, which questions are generated from.
  final List<UnitSentence> sentences;

  /// Questions written for this unit rather than generated.
  final List<AuthoredQuestion> questions;

  /// What a writing exercise asks for, when there is one.
  final LocalizedStrings? writingPrompt;

  /// The scripted conversation this unit ends with, when it has one.
  final Scenario? scenario;

  /// Every catalog id this unit teaches, grammar first.
  List<String> get items => [...grammar, ...vocab];

  /// Purpose: Parse one unit.
  /// Inputs: `json`.
  /// Returns: `LessonUnit?` — null when it has no usable id.
  /// Side effects: None.
  /// Notes: None.
  static LessonUnit? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = '${json['id'] ?? ''}';
    if (id.isEmpty) return null;
    return LessonUnit(
      id: id,
      title: LocalizedStrings.fromJson(json['title']),
      grammar: [for (final g in _list(json['grammar'])) '$g'],
      vocab: [for (final v in _list(json['vocab'])) '$v'],
      sentences: [
        for (final s in _list(json['sentences']))
          ?UnitSentence.fromJson(s),
      ],
      questions: [
        for (final q in _list(json['questions']))
          ?AuthoredQuestion.fromJson(q),
      ],
      writingPrompt: json['writingPrompt'] == null
          ? null
          : LocalizedStrings.fromJson(json['writingPrompt']),
      scenario: Scenario.fromJson(json['scenario']),
    );
  }
}

/// One sentence written for a unit.
class UnitSentence {
  /// Purpose: Hold one unit sentence.
  /// Inputs: All fields.
  /// Returns: A new `UnitSentence` instance.
  /// Side effects: None.
  /// Notes: The same shape as a `ContentExample` plus the ids it teaches, so
  /// a question generated from it can be recorded against the right item.
  const UnitSentence({
    required this.ja,
    required this.translations,
    this.reading,
    this.items = const [],
  });

  /// The sentence as written.
  final String ja;

  /// Its reading in kana.
  final String? reading;

  /// Its translations.
  final LocalizedStrings translations;

  /// The catalog ids this sentence is here to teach.
  final List<String> items;

  /// Purpose: Parse one sentence.
  /// Inputs: `json`.
  /// Returns: `UnitSentence?` — null without Japanese.
  /// Side effects: None.
  /// Notes: None.
  static UnitSentence? fromJson(Object? json) {
    if (json is! Map) return null;
    final ja = '${json['ja'] ?? ''}';
    if (ja.isEmpty) return null;
    return UnitSentence(
      ja: ja,
      reading: json['reading'] == null ? null : '${json['reading']}',
      translations: LocalizedStrings.fromJson({
        for (final entry in json.entries)
          if (entry.key != 'ja' &&
              entry.key != 'reading' &&
              entry.key != 'items')
            entry.key: entry.value,
      }),
      items: [for (final item in _list(json['items'])) '$item'],
    );
  }

  /// Purpose: Present this sentence as a catalog example.
  /// Inputs: None.
  /// Returns: `ContentExample`.
  /// Side effects: None.
  /// Notes: So the question generator and the example widgets treat a unit's
  /// own sentences exactly like the catalog's, with no second code path.
  ContentExample toExample() =>
      ContentExample(ja: ja, reading: reading, translations: translations);
}

/// One question written for a unit rather than generated from the catalog.
class AuthoredQuestion {
  /// Purpose: Hold one hand-written question.
  /// Inputs: All fields.
  /// Returns: A new `AuthoredQuestion` instance.
  /// Side effects: None.
  /// Notes: `item` is what the answer is recorded against, so it has to be a
  /// catalog id the unit teaches rather than the question's own id.
  const AuthoredQuestion({
    required this.id,
    required this.item,
    required this.prompt,
    required this.options,
    required this.answer,
    this.explanation,
  });

  /// `q:n5-1-01`. Stable, so a question can be referred to in a bug report.
  final String id;

  /// The catalog id this question is about.
  final String item;

  /// What it asks.
  final LocalizedStrings prompt;

  /// Its four options, as written.
  final List<String> options;

  /// Which option is right.
  final int answer;

  /// Why it is right, shown after the answer.
  final LocalizedStrings? explanation;

  /// Purpose: Parse one question.
  /// Inputs: `json`.
  /// Returns: `AuthoredQuestion?` — null when it could not be answered.
  /// Side effects: None.
  /// Notes: A question with an answer index outside its options, or with
  /// fewer than two options, is dropped rather than shown: the gate rejects
  /// those before they ship, and this is the second line of defence for a file
  /// edited by hand.
  static AuthoredQuestion? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = '${json['id'] ?? ''}';
    final item = '${json['item'] ?? ''}';
    final options = [
      for (final option in _list(json['options'])) '$option',
    ];
    final answer = json['answer'];
    if (id.isEmpty || item.isEmpty || options.length < 2) return null;
    if (answer is! int || answer < 0 || answer >= options.length) return null;
    return AuthoredQuestion(
      id: id,
      item: item,
      prompt: LocalizedStrings.fromJson(json['prompt']),
      options: options,
      answer: answer,
      explanation: json['explanation'] == null
          ? null
          : LocalizedStrings.fromJson(json['explanation']),
    );
  }
}

/// Purpose: Read a JSON value as a list, whatever it turns out to be.
/// Inputs: `value`.
/// Returns: `List<Object?>` — empty for anything that is not a list.
/// Side effects: None.
/// Notes: Internal helper used within this file only. A cast would throw, and
/// this file's whole contract is that a malformed row costs the row rather
/// than the file — a hand-edited unit file must not stop the app from opening
/// the Learn tab.
List<Object?> _list(Object? value) => value is List ? value : const [];

/// The scripted conversations a unit can end with.
///
/// A scenario is a reading exercise with one thing a quiz cannot do: the
/// learner is **inside** the conversation. The script runs line by line, and
/// at the points the author marked it stops and asks what to say next.
///
/// A wrong choice is not a dead end. The conversation continues either way and
/// the count of right choices is what is reported at the end, because a
/// conversation that stops when you say the wrong thing teaches nothing about
/// what to say instead.
///
/// Nothing here is recorded against the scheduler. Choosing a reply is not
/// recalling a word, and the unit's own practice session is where recall is
/// measured.
library;

import '../../content/models/localized_strings.dart';

/// Purpose: Read a list that may be absent or the wrong shape.
/// Inputs: `value`.
/// Returns: `List<Object?>` — empty when it is neither.
/// Side effects: None.
/// Notes: Same tolerance as the rest of the catalog: a malformed row loses
/// itself, not the file around it.
List<Object?> _list(Object? value) => value is List ? value : const [];

/// One scripted conversation.
class Scenario {
  /// Purpose: Hold one scripted conversation.
  /// Inputs: `title`, the `dialogue` lines, and the `branches`.
  /// Returns: A new `Scenario` instance.
  /// Side effects: None.
  /// Notes: None.
  const Scenario({
    required this.title,
    required this.dialogue,
    this.branches = const [],
  });

  /// What the conversation is about.
  final LocalizedStrings title;

  /// The lines, in order.
  final List<DialogueLine> dialogue;

  /// Where the learner is asked to choose.
  final List<ScenarioBranch> branches;

  /// Purpose: Find the branch that follows a given point in the script.
  /// Inputs: `index` — how many lines have been shown.
  /// Returns: `ScenarioBranch?`.
  /// Side effects: None.
  /// Notes: None.
  ScenarioBranch? branchAfter(int index) {
    for (final branch in branches) {
      if (branch.after == index) return branch;
    }
    return null;
  }

  /// Purpose: Parse one scenario.
  /// Inputs: `json`.
  /// Returns: `Scenario?` — null when there is nothing to play.
  /// Side effects: None.
  /// Notes: None.
  static Scenario? fromJson(Object? json) {
    if (json is! Map) return null;
    final dialogue = [
      for (final line in _list(json['dialogue'])) ?DialogueLine.fromJson(line),
    ];
    if (dialogue.isEmpty) return null;
    return Scenario(
      title: LocalizedStrings.fromJson(json['title']),
      dialogue: dialogue,
      branches: [
        for (final branch in _list(json['branches']))
          ?ScenarioBranch.fromJson(branch),
      ],
    );
  }
}

/// One line of a scripted conversation.
class DialogueLine {
  /// Purpose: Hold one line.
  /// Inputs: All fields.
  /// Returns: A new `DialogueLine` instance.
  /// Side effects: None.
  /// Notes: `speaker` is a bare label the author chose, `A` or `店員`. It is
  /// not translated, because it is a name rather than a sentence.
  const DialogueLine({
    required this.speaker,
    required this.ja,
    required this.translations,
    this.reading,
  });

  /// Who says it.
  final String speaker;

  /// The line as written.
  final String ja;

  /// Its reading in kana.
  final String? reading;

  /// Its translations.
  final LocalizedStrings translations;

  /// Purpose: Parse one line.
  /// Inputs: `json`.
  /// Returns: `DialogueLine?` — null without Japanese.
  /// Side effects: None.
  /// Notes: None.
  static DialogueLine? fromJson(Object? json) {
    if (json is! Map) return null;
    final ja = '${json['ja'] ?? ''}';
    if (ja.isEmpty) return null;
    return DialogueLine(
      speaker: '${json['speaker'] ?? ''}',
      ja: ja,
      reading: json['reading'] == null ? null : '${json['reading']}',
      translations: LocalizedStrings.fromJson({
        for (final entry in json.entries)
          if (entry.key != 'ja' &&
              entry.key != 'reading' &&
              entry.key != 'speaker')
            entry.key: entry.value,
      }),
    );
  }
}

/// A point where the learner chooses what to say.
class ScenarioBranch {
  /// Purpose: Hold one choice point.
  /// Inputs: `after` — how many lines run first; `choices`.
  /// Returns: A new `ScenarioBranch` instance.
  /// Side effects: None.
  /// Notes: None.
  const ScenarioBranch({required this.after, required this.choices});

  /// How many dialogue lines are shown before this is asked.
  final int after;

  /// What the learner may say.
  final List<ScenarioChoice> choices;

  /// Purpose: Parse one branch.
  /// Inputs: `json`.
  /// Returns: `ScenarioBranch?` — null without at least two choices, because
  /// a single choice is not a choice.
  /// Side effects: None.
  /// Notes: None.
  static ScenarioBranch? fromJson(Object? json) {
    if (json is! Map) return null;
    final choices = [
      for (final choice in _list(json['choices']))
        ?ScenarioChoice.fromJson(choice),
    ];
    if (choices.length < 2) return null;
    return ScenarioBranch(
      after: switch (json['after']) {
        final int value => value,
        final Object? value => int.tryParse('$value') ?? 0,
      },
      choices: choices,
    );
  }
}

/// One thing the learner may say at a branch.
class ScenarioChoice {
  /// Purpose: Hold one candidate reply.
  /// Inputs: All fields.
  /// Returns: A new `ScenarioChoice` instance.
  /// Side effects: None.
  /// Notes: None.
  const ScenarioChoice({
    required this.ja,
    required this.translations,
    this.reading,
    this.correct = false,
  });

  /// The reply as written.
  final String ja;

  /// Its reading in kana.
  final String? reading;

  /// Its translations.
  final LocalizedStrings translations;

  /// Whether this is the reply the conversation expects.
  final bool correct;

  /// Purpose: Parse one choice.
  /// Inputs: `json`.
  /// Returns: `ScenarioChoice?` — null without Japanese.
  /// Side effects: None.
  /// Notes: None.
  static ScenarioChoice? fromJson(Object? json) {
    if (json is! Map) return null;
    final ja = '${json['ja'] ?? ''}';
    if (ja.isEmpty) return null;
    return ScenarioChoice(
      ja: ja,
      reading: json['reading'] == null ? null : '${json['reading']}',
      correct: json['correct'] == true,
      translations: LocalizedStrings.fromJson({
        for (final entry in json.entries)
          if (entry.key != 'ja' &&
              entry.key != 'reading' &&
              entry.key != 'correct')
            entry.key: entry.value,
      }),
    );
  }
}

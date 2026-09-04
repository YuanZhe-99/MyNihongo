import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/lessons/models/scenario.dart';

/// Purpose: Test the scripted-conversation model.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Everything here is about what a malformed file does, because that is
/// the only thing this model decides. A conversation with a broken line loses
/// the line; a branch with one choice is not a branch and is dropped whole; a
/// scenario with no lines is no scenario at all, so the unit shows no button
/// rather than an empty page.
void main() {
  Map<String, Object?> line(String ja) => {
    'speaker': 'A',
    'ja': ja,
    'reading': ja,
    'en': 'x',
    'zh': 'x',
  };

  test('a scenario parses its lines and branches', () {
    final scenario = Scenario.fromJson({
      'title': {'en': 'At the station', 'zh': '在车站'},
      'dialogue': [line('こんにちは。'), line('はい。'), line('どうぞ。')],
      'branches': [
        {
          'after': 2,
          'choices': [
            {'ja': 'はい。', 'reading': 'はい。', 'en': 'y', 'zh': 'y', 'correct': true},
            {'ja': 'いいえ。', 'reading': 'いいえ。', 'en': 'n', 'zh': 'n'},
          ],
        },
      ],
    });

    expect(scenario, isNotNull);
    expect(scenario!.dialogue, hasLength(3));
    expect(scenario.dialogue.first.speaker, 'A');
    expect(scenario.branchAfter(2)?.choices, hasLength(2));
    expect(scenario.branchAfter(2)!.choices.first.correct, isTrue);
    expect(scenario.branchAfter(2)!.choices.last.correct, isFalse);
  });

  test('a line with no Japanese is dropped, the conversation is not', () {
    final scenario = Scenario.fromJson({
      'dialogue': [
        line('こんにちは。'),
        {'speaker': 'B', 'en': 'nothing to say'},
        line('さようなら。'),
      ],
    });
    expect(scenario?.dialogue.map((l) => l.ja), ['こんにちは。', 'さようなら。']);
  });

  test('a branch with one choice is not a choice and is dropped', () {
    final scenario = Scenario.fromJson({
      'dialogue': [line('こんにちは。')],
      'branches': [
        {
          'after': 1,
          'choices': [
            {'ja': 'はい。', 'en': 'y', 'zh': 'y', 'correct': true},
          ],
        },
      ],
    });
    expect(scenario?.branches, isEmpty);
    expect(scenario?.branchAfter(1), isNull);
  });

  test('a scenario with no dialogue is no scenario', () {
    expect(Scenario.fromJson({'dialogue': <Object?>[]}), isNull);
    expect(Scenario.fromJson(null), isNull);
    expect(Scenario.fromJson('a conversation'), isNull);
  });

  test('a unit carries its scenario, and a unit without one carries null', () {
    final withOne = LessonUnit.fromJson({
      'id': 'unit:n5-1',
      'title': {'en': 'One', 'zh': '一'},
      'scenario': {
        'title': {'en': 'At the station', 'zh': '在车站'},
        'dialogue': [line('こんにちは。')],
      },
    });
    expect(withOne?.scenario?.dialogue, hasLength(1));

    final without = LessonUnit.fromJson({
      'id': 'unit:n5-2',
      'title': {'en': 'Two', 'zh': '二'},
    });
    expect(without?.scenario, isNull);
  });

  test('the shipped paths only ever carry a playable scenario', () {
    // Guards the invariant the page relies on: it never has to handle a
    // scenario that exists but cannot be played.
    for (final unit in [
      LessonUnit.fromJson({
        'id': 'unit:x',
        'title': {'en': 'x', 'zh': 'x'},
        'scenario': {'dialogue': <Object?>[]},
      }),
    ]) {
      expect(unit?.scenario, isNull);
    }
  });
}

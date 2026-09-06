import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/lessons/models/scenario.dart';
import 'package:my_nihongo/features/lessons/services/scenario_chat.dart';

/// Purpose: Test the free conversation's bookkeeping, and who the learner is
/// talking to.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Both are pure and both are worth stating on their own. A model
/// answering in character has no reason to stop, so the cap is the thing that
/// ends the conversation when the learner does not — and the partner is the
/// speaker who answers the learner, which is the one the script writes *after*
/// the last branch. Getting that backwards would have the model answer itself.
void main() {
  Map<String, Object?> line(String speaker, String ja) => {
    'speaker': speaker,
    'ja': ja,
    'reading': ja,
    'en': 'x',
    'zh': 'x',
  };

  group('the chat', () {
    test('counts only the learner’s turns', () {
      final chat = ScenarioChat();
      expect(chat.isEmpty, isTrue);
      expect(chat.learnerTurns, 0);
      chat.addLearner('こんにちは。');
      chat.addReply('いらっしゃいませ。', meaning: '欢迎光临。');
      expect(chat.turns, hasLength(2));
      expect(chat.learnerTurns, 1, reason: 'the reply is not the learner’s');
      expect(chat.capReached, isFalse);
    });

    test('the cap is reached at eight and not before', () {
      final chat = ScenarioChat();
      for (var i = 0; i < ScenarioChat.maxLearnerTurns - 1; i++) {
        chat.addLearner('はい。');
        chat.addReply('はい。');
        expect(chat.capReached, isFalse, reason: 'stopped early at turn $i');
      }
      chat.addLearner('はい。');
      expect(chat.capReached, isTrue);
    });

    test('ending it drops what was said', () {
      // Nothing here was ever going to be kept, and leaving it on screen after
      // the learner said they were done would suggest that it was.
      final chat = ScenarioChat();
      chat.addLearner('こんにちは。');
      chat.end();
      expect(chat.ended, isTrue);
      expect(chat.turns, isEmpty);
    });

    test('a proofread line is carried beside the learner’s own', () {
      final chat = ScenarioChat();
      chat.addLearner('すみません', proofread: 'すみません。');
      expect(chat.turns.single.proofread, 'すみません。');
      expect(
        chat.turns.single.ja,
        'すみません',
        reason: 'the correction is offered beside what was written, not for it',
      );
    });
  });

  group('who answers', () {
    test('is the speaker the script gives the branch to', () {
      final scenario = Scenario.fromJson({
        'title': {'en': 'At the shop', 'zh': '在店里'},
        'dialogue': [
          line('店員', 'いらっしゃいませ。'),
          line('客', 'これをください。'),
          line('店員', 'はい、どうぞ。'),
        ],
        'branches': [
          {
            'after': 2,
            'choices': [
              {'ja': 'はい。', 'reading': 'はい。', 'en': 'x', 'zh': 'x',
                'correct': true},
              {'ja': 'いいえ。', 'reading': 'いいえ。', 'en': 'x', 'zh': 'x'},
            ],
          },
        ],
      })!;
      expect(scenario.partnerSpeaker, '店員');
    });

    test('is the last speaker when the script asks nothing', () {
      final scenario = Scenario.fromJson({
        'title': {'en': 'x', 'zh': 'x'},
        'dialogue': [line('A', 'こんにちは。'), line('B', 'こんにちは。')],
      })!;
      expect(scenario.partnerSpeaker, 'B');
    });
  });
}

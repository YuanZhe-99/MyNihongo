// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/vocab_import_core.dart';

/// Purpose: Test the vocabulary import rules on fixtures rather than on the
/// 117 MB JMdict body.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; the pure half of the tool takes no file system.
/// Notes: The rules under test are the ones that decide what a learner sees:
/// which level a word is taught at, which written form heads it, which senses
/// are worth showing, and whether re-running the tool changes the file.
Map<String, Object?> word(
  String id, {
  List<Map<String, Object?>> kanji = const [],
  List<Map<String, Object?>> kana = const [],
  List<Map<String, Object?>> sense = const [],
}) => {'id': id, 'kanji': kanji, 'kana': kana, 'sense': sense};

Map<String, Object?> form(String text, {bool common = true}) => {
  'text': text,
  'common': common,
  'tags': const [],
};

Map<String, Object?> sense({
  List<String> pos = const ['n'],
  List<String> misc = const [],
  List<String> gloss = const ['meaning'],
  List<String> appliesToKanji = const ['*'],
  List<String> appliesToKana = const ['*'],
}) => {
  'partOfSpeech': pos,
  'misc': misc,
  'appliesToKanji': appliesToKanji,
  'appliesToKana': appliesToKana,
  'gloss': [
    for (final text in gloss) {'lang': 'eng', 'text': text},
  ],
};

void main() {
  test('the CSV parser skips the header and keeps the three columns', () {
    final rows = parseJlptCsv(
      'jmdict_seq,kana,kanji,waller_definition\n'
      '1000000,あう,会う,"to meet, to see"\n'
      'bad row\n'
      '1000001,あお,青,blue\n',
    );
    expect(rows.length, 2);
    expect(rows.first.seq, 1000000);
    expect(rows.first.kana, 'あう');
    expect(rows.first.kanji, '会う');
  });

  test('a known-bad list row is corrected to the word it means', () {
    final rows = parseJlptCsv(
      'jmdict_seq,kana,kanji,waller_definition\n2846389,コップ,,glass\n',
    );
    expect(rows.single.seq, 1050390, reason: 'コップ is not "police officer"');
  });

  test('a word on two lists is taught at the easier level', () {
    final result = buildEntries(
      jmdictIndex: {
        1: word('1', kanji: [form('本')], kana: [form('ほん')], sense: [sense()]),
      },
      listsByLevel: {
        'N5': [const JlptRow(seq: 1, kana: 'ほん', kanji: '本')],
        'N1': [const JlptRow(seq: 1, kana: 'ほん', kanji: '本')],
      },
      seedEntries: const [],
      overlay: const {},
    );
    expect(result.entries.single['level'], 'N5');
  });

  test('a second row for the same form inside one level is dropped', () {
    final result = buildEntries(
      jmdictIndex: {
        1: word('1', kanji: [form('本')], kana: [form('ほん')], sense: [sense()]),
        2: word('2', kanji: [form('本')], kana: [form('ほん')], sense: [sense()]),
      },
      listsByLevel: {
        'N5': [
          const JlptRow(seq: 1, kana: 'ほん', kanji: '本'),
          const JlptRow(seq: 2, kana: 'ほん', kanji: '本'),
        ],
      },
      seedEntries: const [],
      overlay: const {},
    );
    expect(result.entries.length, 1);
    expect(result.log.join(), contains('duplicate'));
  });

  test('a sequence number JMdict does not carry is reported, not skipped', () {
    final result = buildEntries(
      jmdictIndex: const {},
      listsByLevel: {
        'N5': [const JlptRow(seq: 99, kana: 'ほん', kanji: '本')],
      },
      seedEntries: const [],
      overlay: const {},
    );
    expect(result.entries, isEmpty);
    expect(result.missingSeqs, [99]);
  });

  test('a usually-kana word is headed by its reading', () {
    final entry = chooseForms(
      word(
        '1',
        kanji: [form('有る')],
        kana: [form('ある')],
        sense: [
          sense(misc: ['uk']),
        ],
      ),
      const JlptRow(seq: 1, kana: 'ある', kanji: '有る'),
    );
    expect(entry.headword, 'ある');
    expect(entry.reading, 'ある');
  });

  test('a list form JMdict marks as rare loses to the common one', () {
    final entry = chooseForms(
      word(
        '1',
        kanji: [form('明るい'), form('明い', common: false)],
        kana: [form('あかるい')],
        sense: [
          sense(pos: ['adj-i']),
        ],
      ),
      const JlptRow(seq: 1, kana: 'あかるい', kanji: '明い'),
    );
    expect(entry.headword, '明るい');
    expect(entry.warning, contains('not a common form'));
  });

  test('archaic and form-restricted senses are left out', () {
    final glosses = glossesOf(
      word(
        '1',
        kanji: [form('物')],
        kana: [form('もの')],
        sense: [
          sense(gloss: ['thing']),
          sense(misc: ['arch'], gloss: ['archaic sense']),
          sense(appliesToKanji: ['者'], gloss: ['other form only']),
        ],
      ),
      '物',
      'もの',
    );
    expect(glosses, ['thing']);
  });

  test('a word made only of archaic senses still gets a meaning', () {
    final glosses = glossesOf(
      word(
        '1',
        kana: [form('こっぷ')],
        sense: [
          sense(misc: ['arch'], gloss: ['only sense']),
        ],
      ),
      'こっぷ',
      'こっぷ',
    );
    expect(glosses, ['only sense'], reason: 'better than shipping no meaning');
  });

  test('at most three senses, three glosses each', () {
    final glosses = glossesOf(
      word(
        '1',
        kana: [form('あ')],
        sense: [
          sense(gloss: ['a', 'b', 'c', 'd']),
          sense(gloss: ['e']),
          sense(gloss: ['f']),
          sense(gloss: ['g']),
        ],
      ),
      'あ',
      'あ',
    );
    expect(glosses, ['a; b; c', 'e', 'f']);
  });

  test('part-of-speech tags are mapped and ordered by the app set', () {
    final unmapped = <String, int>{};
    final pos = posOf(
      word(
        '1',
        kana: [form('たべる')],
        sense: [
          sense(pos: ['vt', 'v1', 'nonsense-tag']),
        ],
      ),
      unmapped,
    );
    expect(pos, ['verb-ichidan', 'transitive']);
    expect(unmapped['nonsense-tag'], 1);
  });

  test('a seed entry contributes its id as an alias and keeps its glosses', () {
    final result = buildEntries(
      jmdictIndex: {
        1: word(
          '1',
          kanji: [form('私')],
          kana: [form('わたし')],
          sense: [
            sense(pos: ['pn'], gloss: ['I; me; myself']),
          ],
        ),
      },
      listsByLevel: {
        'N5': [const JlptRow(seq: 1, kana: 'わたし', kanji: '私')],
      },
      seedEntries: const [
        {
          'id': 'vocab:watashi',
          'jmdictSeq': 1,
          'level': 'N5',
          'kanji': '私',
          'reading': 'わたし',
          'romaji': 'watashi',
          'meanings': {
            'en': ['I', 'me'],
            'zh': ['我'],
          },
          'examples': [
            {'ja': '私は学生です。'},
          ],
        },
      ],
      overlay: const {},
    );
    final entry = result.entries.single;
    expect(entry['id'], 'vocab:jm1');
    expect(entry['aliases'], ['vocab:watashi']);
    expect(entry['romaji'], 'watashi');
    expect((entry['meanings'] as Map)['en'], ['I', 'me']);
    expect((entry['meanings'] as Map)['zh'], ['我']);
    expect(entry['examples'], isNotEmpty);
  });

  test('a seed word no list carries still ships', () {
    final result = buildEntries(
      jmdictIndex: {
        7: word(
          '7',
          kanji: [form('日本語')],
          kana: [form('にほんご')],
          sense: [
            sense(gloss: ['Japanese language']),
          ],
        ),
      },
      listsByLevel: const {},
      seedEntries: const [
        {
          'id': 'vocab:nihongo',
          'jmdictSeq': 7,
          'level': 'N5',
          'kanji': '日本語',
          'reading': 'にほんご',
        },
      ],
      overlay: const {},
    );
    expect(result.entries.single['id'], 'vocab:jm7');
    expect(result.entries.single['level'], 'N5');
  });

  test('the overlay supplies Chinese and its reviewed flag stays behind', () {
    final result = buildEntries(
      jmdictIndex: {
        1: word(
          '1',
          kana: [form('ねこ')],
          sense: [
            sense(gloss: ['cat']),
          ],
        ),
      },
      listsByLevel: {
        'N5': [const JlptRow(seq: 1, kana: 'ねこ', kanji: '')],
      },
      seedEntries: const [],
      overlay: const {
        'vocab:jm1': {
          'zh': ['猫'],
          'reviewed': false,
        },
      },
    );
    final meanings = result.entries.single['meanings'] as Map;
    expect(meanings['zh'], ['猫']);
    expect(result.entries.single.containsKey('reviewed'), isFalse);
  });

  test('an overlay row for a word that is gone is reported', () {
    final result = buildEntries(
      jmdictIndex: const {},
      listsByLevel: const {},
      seedEntries: const [],
      overlay: const {
        'vocab:jm404': {
          'zh': ['幽灵'],
        },
      },
    );
    expect(result.log.join(), contains('vocab:jm404'));
  });

  test('output order does not depend on input order', () {
    Map<int, Map<String, Object?>> index() => {
      1: word('1', kana: [form('あ')], sense: [sense()]),
      2: word('2', kana: [form('い')], sense: [sense()]),
      3: word('3', kana: [form('う')], sense: [sense()]),
    };
    final forward = buildEntries(
      jmdictIndex: index(),
      listsByLevel: {
        'N5': [
          const JlptRow(seq: 3, kana: 'う', kanji: ''),
          const JlptRow(seq: 1, kana: 'あ', kanji: ''),
          const JlptRow(seq: 2, kana: 'い', kanji: ''),
        ],
      },
      seedEntries: const [],
      overlay: const {},
    );
    expect(forward.entries.map((e) => e['id']), [
      'vocab:jm1',
      'vocab:jm2',
      'vocab:jm3',
    ]);
  });
}

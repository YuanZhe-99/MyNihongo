import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/content/models/vocab_entry.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';

/// Purpose: Check the bundled content parses and meets the catalog rules.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the two content assets.
/// Notes: Every id must be unique and carry the prefix its progress records
/// will be filed under, and every entry must have both shipped languages, or
/// one UI language would show blanks the other does not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentRepository.load();
  });

  test('the seed content loads and is non-empty', () {
    expect(catalog.vocab, isNotEmpty);
    expect(catalog.grammar, isNotEmpty);
  });

  test('every id is unique and carries its kind prefix', () {
    final ids = <String>{};
    for (final entry in catalog.vocab) {
      expect(ids.add(entry.id), isTrue, reason: 'duplicate ${entry.id}');
      expect(studyKindOf(entry.id), StudyKind.vocab, reason: entry.id);
    }
    for (final point in catalog.grammar) {
      expect(ids.add(point.id), isTrue, reason: 'duplicate ${point.id}');
      expect(studyKindOf(point.id), StudyKind.grammar, reason: point.id);
    }
    for (final kana in allKanaEntries()) {
      expect(ids.add(kana.progressId), isTrue, reason: kana.progressId);
      expect(studyKindOf(kana.progressId), StudyKind.kana);
    }
  });

  test('every entry has English and Chinese text', () {
    const en = Locale('en');
    const zh = Locale('zh');
    for (final entry in catalog.vocab) {
      expect(
        entry.meanings.values.keys,
        containsAll(['en', 'zh']),
        reason: entry.id,
      );
      expect(entry.meanings.resolve(en), isNotEmpty);
      expect(entry.meanings.resolve(zh), isNotEmpty);
      for (final example in entry.examples) {
        expect(example.translations.values.keys, containsAll(['en', 'zh']));
      }
    }
    for (final point in catalog.grammar) {
      expect(
        point.meaning.values.keys,
        containsAll(['en', 'zh']),
        reason: point.id,
      );
      expect(point.explanation.values.keys, containsAll(['en', 'zh']));
      expect(point.examples, isNotEmpty, reason: point.id);
    }
  });

  test('lookups and search behave', () {
    final watashi = catalog.vocabById('vocab:watashi');
    expect(watashi, isNotNull);
    expect(watashi!.level, JlptLevel.n5);
    expect(watashi.hasKanji, isTrue);
    expect(watashi.matches('私'), isTrue);
    expect(watashi.matches('わたし'), isTrue);
    expect(watashi.matches('watashi'), isTrue);
    expect(watashi.matches('我'), isTrue);
    expect(watashi.matches('zzz'), isFalse);

    final arigatou = catalog.vocabById('vocab:arigatou');
    expect(arigatou!.hasKanji, isFalse);

    final desu = catalog.grammarById('grammar:desu');
    expect(desu, isNotNull);
    expect(desu!.matches('です'), isTrue);
    expect(desu.matches('copula'), isTrue);
  });

  test('localized strings fall back to English, then anything', () {
    const strings = LocalizedStrings({
      'en': ['one'],
      'ja': ['いち'],
    });
    expect(strings.resolve(const Locale('zh')), ['one']);
    expect(strings.resolve(const Locale('ja')), ['いち']);
    const noEnglish = LocalizedStrings({
      'ja': ['いち'],
    });
    expect(noEnglish.resolve(const Locale('zh')), ['いち']);
    expect(LocalizedStrings.empty.resolve(const Locale('en')), isEmpty);
    expect(LocalizedStrings.fromJson('bare').resolve(const Locale('zh')), [
      'bare',
    ]);
  });

  test('malformed entries are skipped rather than fatal', () {
    expect(VocabEntry.fromJson({'id': 'vocab:x'}), isNull);
    expect(
      VocabEntry.fromJson({'id': 'vocab:x', 'level': 'N9', 'reading': 'x'}),
      isNull,
    );
    final parsed = ContentCatalog.fromJson({
      'entries': [
        1,
        {'id': 'vocab:ok', 'level': 'n5', 'reading': 'おけ'},
      ],
    }, null);
    expect(parsed.vocab.single.id, 'vocab:ok');
    expect(parsed.vocab.single.headword, 'おけ');
    expect(parsed.grammar, isEmpty);
  });

  test('JLPT levels parse case-insensitively and label themselves', () {
    expect(JlptLevel.parse('N1'), JlptLevel.n1);
    expect(JlptLevel.parse('n3'), JlptLevel.n3);
    expect(JlptLevel.parse('N6'), isNull);
    expect(JlptLevel.parse(5), isNull);
    expect(JlptLevel.n5.label, 'N5');
  });
}

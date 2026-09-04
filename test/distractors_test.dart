import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';
import 'package:my_nihongo/features/quiz/services/distractors.dart';

/// Purpose: Test that wrong options are wrong for the right reasons.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: A distractor has two ways to fail and only one of them is obvious.
/// The obvious one is being accidentally correct — a synonym, or the same kana
/// twice — which makes the question unanswerable. The quiet one is being too
/// easy: a noun among verbs, or a three-kanji compound among two-kana words, is
/// eliminated on shape alone and the question tests nothing. Both are asserted
/// here against the real catalog, because whether N5 can supply four
/// same-level, same-part-of-speech words is a fact about the shipped data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late Distractors distractors;
  const en = Locale('en');

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    distractors = Distractors(catalog, random: Random(20260903));
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  test('a meaning distractor never shares a meaning with the answer', () {
    for (final entry in catalog.vocab.take(300)) {
      final meanings = entry.meanings.resolve(en).toSet();
      if (meanings.isEmpty) continue;
      for (final other in distractors.forMeaning(entry, locale: en)) {
        expect(
          other.meanings.resolve(en).any(meanings.contains),
          isFalse,
          reason: '${other.id} means the same as ${entry.id}',
        );
        expect(other.id, isNot(entry.id));
      }
    }
  });

  test('a meaning distractor prefers the same level and part of speech', () {
    final entry = catalog.vocab.firstWhere(
      (v) =>
          v.level.label == 'N5' &&
          v.partsOfSpeech.isNotEmpty &&
          v.partsOfSpeech.first == 'noun',
    );
    final wrong = distractors.forMeaning(entry, locale: en);
    expect(wrong, hasLength(distractorCount));
    expect(
      wrong.every((v) => v.level == entry.level),
      isTrue,
      reason: 'a word from another level can be eliminated by difficulty',
    );
    expect(
      wrong.every((v) => v.partsOfSpeech.first == 'noun'),
      isTrue,
      reason: 'a verb among nouns is eliminated without knowing the word',
    );
  });

  test('a written-form distractor is always another word with kanji', () {
    final entry = catalog.vocab.firstWhere(
      (v) => v.hasKanji && v.level.label == 'N5',
    );
    final wrong = distractors.forWriting(entry);
    expect(wrong, hasLength(distractorCount));
    for (final other in wrong) {
      expect(other.hasKanji, isTrue);
      expect(other.headword, isNot(entry.headword));
      expect(
        other.reading,
        isNot(entry.reading),
        reason: 'a homophone would make the reading question ambiguous',
      );
    }
  });

  test('a kana distractor offers the confusable kana first', () {
    // し and つ are the pair the catalog flags, and the mistake a learner
    // actually makes — so it is the wrong answer worth offering.
    final shi = kanaEntryById('kana:し')!;
    final wrong = distractors.forKana(shi);
    expect(wrong, hasLength(distractorCount));
    expect(wrong.first.progressId, 'kana:つ');
  });

  test('a kana distractor never repeats a romaji', () {
    for (final entry in allKanaEntries()) {
      final wrong = distractors.forKana(entry);
      final romaji = [entry.romaji, ...wrong.map((k) => k.romaji)];
      expect(
        romaji.toSet(),
        hasLength(romaji.length),
        reason: 'じ and ぢ are both "ji"; both as options has two answers',
      );
    }
  });

  test('a kana distractor is never the kana being asked about', () {
    for (final entry in allKanaEntries()) {
      for (final other in distractors.forKana(entry)) {
        expect(other.progressId, isNot(entry.progressId));
      }
    }
  });

  test('every kana can supply a full set of distractors', () {
    for (final entry in allKanaEntries()) {
      expect(
        distractors.forKana(entry),
        hasLength(distractorCount),
        reason: '${entry.progressId} could not fill four options',
      );
    }
  });

  test('a word with no usable neighbours returns short rather than junk', () {
    // A single-entry catalog cannot fill four options, and saying so is the
    // point: the generator drops the question rather than padding it.
    final tiny = ContentCatalog.fromJson({
      'schemaVersion': 2,
      'entries': [
        {
          'id': 'vocab:only',
          'level': 'N5',
          'reading': 'ひとつ',
          'meanings': {
            'en': ['one'],
          },
        },
      ],
    }, const []);
    final lonely = Distractors(tiny, random: Random(1));
    expect(
      lonely.forMeaning(tiny.vocab.first, locale: en),
      isEmpty,
    );
  });
}

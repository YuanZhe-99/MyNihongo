/// Purpose: Choose the wrong options a multiple-choice question offers.
/// Inputs: The catalog, the item being asked about, and a random source.
/// Returns: Lists of option strings, or fewer than asked for when the data
/// cannot supply them.
/// Side effects: None.
/// Notes: A distractor has to be **wrong but plausible**. Too easy and the
/// question tests nothing; accidentally also correct and the question is
/// unanswerable. Each rule below narrows first and widens only if it must, and
/// every one of them can return short — the caller drops the question rather
/// than padding it with something arbitrary.
library;

import 'dart:math';
import 'dart:ui';

import '../../content/models/content_catalog.dart';
import '../../content/models/vocab_entry.dart';
import '../../kana/models/kana.dart';
import '../../kana/models/kana_note.dart';

/// How many wrong options a choice question offers.
const distractorCount = 3;

/// Picks wrong answers that are wrong for the right reasons.
class Distractors {
  /// Purpose: Create a distractor picker.
  /// Inputs: `catalog`; `random` for shuffling.
  /// Returns: A new `Distractors` instance.
  /// Side effects: None.
  /// Notes: The random source is injected so tests are deterministic.
  Distractors(this.catalog, {Random? random}) : _random = random ?? Random();

  /// The bundled content.
  final ContentCatalog catalog;

  final Random _random;

  /// Purpose: Find words whose meanings could be confused with this one's.
  /// Inputs: `entry`, the `locale` the meanings are read in, and how many.
  /// Returns: `List<VocabEntry>`, possibly shorter than `count`.
  /// Side effects: None.
  /// Notes: Same level and same part of speech first — a noun among verbs is
  /// answerable without knowing the word. Common words are preferred so the
  /// wrong options are ones the learner might plausibly have learnt. The filter
  /// widens to the level alone, then to the whole catalog, because a question
  /// with two options is worse than one with a slightly easy third.
  List<VocabEntry> forMeaning(
    VocabEntry entry, {
    required Locale locale,
    int count = distractorCount,
  }) {
    final taken = entry.meanings.resolve(locale).toSet();
    bool usable(VocabEntry other) {
      if (other.id == entry.id) return false;
      final meanings = other.meanings.resolve(locale);
      if (meanings.isEmpty) return false;
      // A word that shares a meaning is not a wrong answer.
      return !meanings.any(taken.contains);
    }

    final pos = entry.partsOfSpeech.isEmpty ? null : entry.partsOfSpeech.first;
    return _widen([
      if (pos != null)
        (v) =>
            usable(v) &&
            v.level == entry.level &&
            v.partsOfSpeech.isNotEmpty &&
            v.partsOfSpeech.first == pos &&
            v.common,
      if (pos != null)
        (v) =>
            usable(v) &&
            v.level == entry.level &&
            v.partsOfSpeech.isNotEmpty &&
            v.partsOfSpeech.first == pos,
      (v) => usable(v) && v.level == entry.level,
      usable,
    ], count);
  }

  /// Purpose: Find words whose written form could be confused with this one's.
  /// Inputs: `entry`, and how many.
  /// Returns: `List<VocabEntry>`.
  /// Side effects: None.
  /// Notes: Written-form questions are about recognising a shape, so the
  /// distractors are shapes: same level, then preferring words that share a
  /// character or have a reading of the same length. A three-kanji compound
  /// among two-kana words gives the answer away by its size alone.
  List<VocabEntry> forWriting(VocabEntry entry, {int count = distractorCount}) {
    final chars = entry.headword.split('').toSet();
    bool usable(VocabEntry other) =>
        other.id != entry.id &&
        other.hasKanji &&
        other.headword != entry.headword &&
        other.reading != entry.reading;

    return _widen([
      (v) =>
          usable(v) &&
          v.level == entry.level &&
          v.headword.split('').any(chars.contains),
      (v) =>
          usable(v) &&
          v.level == entry.level &&
          v.reading.length == entry.reading.length,
      (v) => usable(v) && v.level == entry.level,
      usable,
    ], count);
  }

  /// Purpose: Find kana that could be confused with this one.
  /// Inputs: `entry`, and how many.
  /// Returns: `List<KanaEntry>`.
  /// Side effects: None.
  /// Notes: The catalog already records which kana are confusable — シ and ツ,
  /// ソ and ン, ぬ and め — and those are exactly the wrong answers worth
  /// offering, because they are the mistake the learner is actually at risk of.
  /// After them, kana from the same row, which share a consonant.
  List<KanaEntry> forKana(KanaEntry entry, {int count = distractorCount}) {
    final all = allKanaEntries();
    final out = <KanaEntry>[];
    final seenRomaji = <String>{entry.romaji};

    void take(Iterable<KanaEntry> candidates) {
      for (final candidate in candidates) {
        if (out.length >= count) return;
        // Deduplicate by romaji: じ and ぢ are both "ji", and offering both
        // makes a romaji question unanswerable.
        if (!seenRomaji.add(candidate.romaji)) continue;
        out.add(candidate);
      }
    }

    final note = catalog.kanaNotes[entry.progressId];
    take(_confusable(note));
    take(_sameRow(entry).where((k) => k.progressId != entry.progressId));
    take(
      all.where((k) => k.progressId != entry.progressId).toList()
        ..shuffle(_random),
    );
    return out;
  }

  /// Purpose: Read the confusable kana a note names.
  /// Inputs: The `note`.
  /// Returns: `List<KanaEntry>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Not every kana has a
  /// note, and a note may name an id that no longer exists, so the lookups are
  /// null-aware rather than assumed.
  List<KanaEntry> _confusable(KanaNote? note) => [
    for (final id in note?.confusableWith ?? const <String>[])
      ?kanaEntryById(id),
  ];

  /// Purpose: Find the kana sharing a row with this one.
  /// Inputs: `entry`.
  /// Returns: `List<KanaEntry>`, shuffled.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Searches all three
  /// tables, because a kana appears in exactly one of them.
  List<KanaEntry> _sameRow(KanaEntry entry) {
    for (final rows in [kanaBasicRows, kanaVoicedRows, kanaYoonRows]) {
      for (final row in rows) {
        final present = row.entries.any(
          (e) => e != null && e.progressId == entry.progressId,
        );
        if (!present) continue;
        return [for (final e in row.entries) ?e]..shuffle(_random);
      }
    }
    return const [];
  }

  /// Purpose: Take candidates from progressively looser filters.
  /// Inputs: The `filters`, best first, and how many to take.
  /// Returns: `List<VocabEntry>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Each filter's matches
  /// are shuffled before being taken, so the same question does not always
  /// offer the same three wrong answers.
  List<VocabEntry> _widen(List<bool Function(VocabEntry)> filters, int count) {
    final out = <VocabEntry>[];
    final taken = <String>{};
    for (final filter in filters) {
      if (out.length >= count) break;
      final matches = catalog.vocab.where(filter).toList()..shuffle(_random);
      for (final match in matches) {
        if (out.length >= count) break;
        if (!taken.add(match.id)) continue;
        out.add(match);
      }
    }
    return out;
  }
}

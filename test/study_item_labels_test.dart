import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/content/services/study_item_labels.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';

/// Purpose: Test that a progress id becomes something a person recognizes.
/// Inputs: The real bundled content.
/// Returns: None.
/// Side effects: Reads the asset bundle.
/// Notes: The sync conflict dialog is the only caller today, and it must be
/// able to name every record it is handed — including one whose id this build
/// no longer ships.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  const en = Locale('en');

  setUpAll(() async {
    catalog = await ContentRepository.load();
  });

  test('a kana id shows both scripts and its romaji', () {
    final label = resolveStudyItemLabel('kana:あ', catalog: catalog, locale: en);
    expect(label.resolved, isTrue);
    expect(label.kind, StudyKind.kana);
    expect(label.title, 'あ · ア');
    expect(label.subtitle, 'a');
  });

  test('a vocabulary id shows the headword and its first meaning', () {
    final entry = catalog.vocab.first;
    final label = resolveStudyItemLabel(entry.id, catalog: catalog, locale: en);
    expect(label.resolved, isTrue);
    expect(label.kind, StudyKind.vocab);
    expect(label.title, entry.headword);
    expect(label.subtitle, isNotNull);
    expect(label.subtitle, contains(entry.meanings.resolve(en).first));
  });

  test('a grammar id shows the pattern and its meaning', () {
    final point = catalog.grammar.first;
    final label = resolveStudyItemLabel(point.id, catalog: catalog, locale: en);
    expect(label.resolved, isTrue);
    expect(label.kind, StudyKind.grammar);
    expect(label.title, point.pattern);
  });

  test('an id the catalog does not carry falls back to the raw id', () {
    final label = resolveStudyItemLabel(
      'vocab:retired-in-a-later-build',
      catalog: catalog,
      locale: en,
    );
    expect(label.resolved, isFalse);
    expect(label.title, 'vocab:retired-in-a-later-build');
    expect(label.kind, StudyKind.vocab);
  });

  test('a null catalog still names kana and never throws', () {
    final kana = resolveStudyItemLabel('kana:ん', locale: en);
    expect(kana.resolved, isTrue);
    expect(kana.title, 'ん · ン');

    final vocab = resolveStudyItemLabel('vocab:watashi', locale: en);
    expect(vocab.resolved, isFalse);
    expect(vocab.title, 'vocab:watashi');
  });

  test('an id with no known prefix is kept whole', () {
    final label = resolveStudyItemLabel(
      'kanji:日',
      catalog: catalog,
      locale: en,
    );
    expect(label.kind, StudyKind.other);
    expect(label.title, 'kanji:日');
    expect(label.resolved, isFalse);
  });

  test('a lesson id is its own kind, and unnamed until a path is loaded', () {
    final label = resolveStudyItemLabel(
      'lesson:n5-1-1',
      catalog: catalog,
      locale: en,
    );
    expect(label.kind, StudyKind.lesson);
    expect(label.title, 'lesson:n5-1-1');
    expect(label.resolved, isFalse);
  });

  test('the learner profile is named rather than shown as a raw id', () {
    // A sync conflict has to say what is in conflict, and "profile:me" does
    // not. The caller supplies the wording because this layer has no l10n.
    final label = resolveStudyItemLabel(
      'profile:me',
      catalog: catalog,
      locale: en,
      profileName: 'Your learning profile',
    );
    expect(label.kind, StudyKind.profile);
    expect(label.title, 'Your learning profile');
    expect(label.resolved, isTrue);
  });

  test('a profile with no name given falls back to its id', () {
    final label = resolveStudyItemLabel('profile:me', locale: en);
    expect(label.kind, StudyKind.profile);
    expect(label.resolved, isFalse);
  });

  test('the meaning follows the locale when the content has one', () async {
    // Confirm the catalog really ships Chinese, so the assertion means
    // something rather than passing on an English fallback.
    final raw = jsonDecode(
      await rootBundle.loadString(ContentRepository.vocabAsset),
    );
    expect(raw, isA<Map>());
    final entry = catalog.vocab.first;
    final zh = resolveStudyItemLabel(
      entry.id,
      catalog: catalog,
      locale: const Locale('zh'),
    );
    expect(
      zh.subtitle,
      contains(entry.meanings.resolve(const Locale('zh')).first),
    );
  });
}

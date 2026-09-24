import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Purpose: Test that every ARB catalog stays in step with the template.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the ARB files.
/// Notes: `AGENTS.md` says every user-facing string goes through the ARB
/// files and that `app_en.arb` is the template. `flutter gen-l10n` only warns
/// about a missing translation, and a warning in a build log is not a promise
/// — this fails the build instead. Placeholders are compared too, because a
/// translation that renames one compiles and then throws at runtime.
void main() {
  const template = 'lib/l10n/app_en.arb';
  // Enumerated rather than listed, as content_zh_tw_test does: gen-l10n picks
  // up any app_*.arb on its own, and a catalog added without being named here
  // would ship with none of the checks below run on it.
  final translations = [
    for (final file in Directory('lib/l10n').listSync())
      if (file is File &&
          file.path.endsWith('.arb') &&
          !file.path.replaceAll(r'\', '/').endsWith(template))
        file.path.replaceAll(r'\', '/'),
  ]..sort();

  Map<String, dynamic> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Set<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  Set<String> placeholdersOf(Map<String, dynamic> arb, String key) {
    final meta = arb['@$key'];
    if (meta is! Map) return const {};
    final placeholders = meta['placeholders'];
    if (placeholders is! Map) return const {};
    return placeholders.keys.map((k) => k.toString()).toSet();
  }

  test('every catalog carries exactly the template\'s keys', () {
    final expected = keysOf(read(template));
    expect(expected, isNotEmpty);
    for (final path in translations) {
      final actual = keysOf(read(path));
      expect(
        actual.difference(expected),
        isEmpty,
        reason: '$path has keys the template does not',
      );
      expect(
        expected.difference(actual),
        isEmpty,
        reason: '$path is missing keys',
      );
    }
  });

  test('every catalog declares the same placeholders', () {
    final english = read(template);
    for (final path in translations) {
      final other = read(path);
      for (final key in keysOf(english)) {
        expect(
          placeholdersOf(other, key),
          placeholdersOf(english, key),
          reason: '$path disagrees about $key',
        );
      }
    }
  });

  test('every catalog names its own locale', () {
    expect(read(template)['@@locale'], 'en');
    expect(read('lib/l10n/app_zh.arb')['@@locale'], 'zh');
    expect(read('lib/l10n/app_zh_TW.arb')['@@locale'], 'zh_TW');
    if (File('lib/l10n/app_ja.arb').existsSync()) {
      expect(read('lib/l10n/app_ja.arb')['@@locale'], 'ja');
    }
    expect(translations, hasLength(greaterThanOrEqualTo(2)));
  });

  test('the Traditional catalog is not a copy of the Simplified one', () {
    // A file that was added and never translated would pass every check
    // above. These four are words Taiwan and the mainland write differently.
    final simplified = read('lib/l10n/app_zh.arb');
    final traditional = read('lib/l10n/app_zh_TW.arb');
    for (final key in ['navVocab', 'navSettings', 'settingsData', 'save']) {
      expect(
        traditional[key],
        isNot(simplified[key]),
        reason: '$key is identical in both Chinese catalogs',
      );
    }
  });

  test('the Japanese catalog is written in Japanese', () {
    // The counterpart of the Traditional-is-not-a-copy check: a catalog that
    // was added as a copy of the English template would pass the key and
    // placeholder checks. Brand names, level labels and bare placeholders
    // are the only values allowed to carry no kana or kanji.
    final file = File('lib/l10n/app_ja.arb');
    if (!file.existsSync()) return;
    final ja = read(file.path);
    final values = [
      for (final entry in ja.entries)
        if (!entry.key.startsWith('@')) '${entry.value}',
    ];
    final japanese = values
        .where((v) => RegExp(r'[぀-ヿ一-鿿]').hasMatch(v))
        .length;
    expect(japanese / values.length, greaterThanOrEqualTo(0.9));
  });
}

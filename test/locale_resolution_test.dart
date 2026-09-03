import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/locale_resolution.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test how a device's language list picks one of the three UI
/// languages.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The load-bearing cases are the Chinese ones. Flutter's own
/// resolution matches language and country, so `zh-Hant-HK` — a Hong Kong
/// phone asking for Traditional characters — would land on Simplified Chinese
/// without the normalization this file covers.
void main() {
  final supported = AppLocalizations.supportedLocales;
  const traditional = Locale('zh', 'TW');
  const simplified = Locale('zh');
  const english = Locale('en');

  Locale resolve(List<Locale>? preferred) =>
      resolveAppLocale(preferred, supported);

  test('a Traditional Chinese device gets Traditional Chinese', () {
    for (final locale in [
      const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      const Locale('zh', 'HK'),
      const Locale('zh', 'MO'),
    ]) {
      expect(resolve([locale]), traditional, reason: '$locale');
    }
  });

  test('a Simplified Chinese device gets Simplified Chinese', () {
    for (final locale in [
      const Locale('zh'),
      const Locale('zh', 'CN'),
      const Locale('zh', 'SG'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
      // Simplified script in a Traditional region is still Simplified: the
      // script is what the user asked for.
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'HK',
      ),
    ]) {
      expect(resolve([locale]), simplified, reason: '$locale');
    }
  });

  test('English regions get English', () {
    expect(resolve([const Locale('en', 'GB')]), english);
    expect(resolve([const Locale('en')]), english);
  });

  test('an unsupported language falls back to the template', () {
    expect(resolve([const Locale('ja', 'JP')]), english);
    expect(resolve([const Locale('de')]), english);
  });

  test('no preference at all falls back to the template', () {
    expect(resolve(null), english);
    expect(resolve(const []), english);
  });

  test('a later entry is used when the first is unsupported', () {
    expect(
      resolve([
        const Locale('ja'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        ),
      ]),
      traditional,
    );
  });

  test('normalizeChinese leaves other languages alone', () {
    expect(normalizeChinese(const Locale('ja', 'JP')), const Locale('ja', 'JP'));
    expect(normalizeChinese(const Locale('en')), const Locale('en'));
  });
}

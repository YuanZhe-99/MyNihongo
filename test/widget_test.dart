import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/kana/views/kana_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Smoke-test that a real page renders in both shipped languages.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The kana page is the one page with no disk or provider dependency,
/// so it stands in for "the app boots". Chinese is pumped too because CJK
/// glyphs are square in the test font, which makes the Chinese run measure the
/// real production layout — see `doc/en-us/adaptive-layout.md`. Both Chinese
/// locales are pumped: they are separate string catalogs, and a locale that
/// resolves to the wrong one still renders perfectly well.
void main() {
  Future<void> pumpKana(WidgetTester tester, Locale locale) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915); // Pixel 9
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const KanaPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Per locale: text that must be on the page, and text that must not, so a
  // locale that quietly fell back to another catalog fails.
  final ja = lookupAppLocalizations(const Locale('ja'));
  final cases =
      <String, ({Locale locale, List<String> present, List<String> absent})>{
        'English': (
          locale: const Locale('en'),
          present: ['Kana', 'あ'],
          absent: [],
        ),
        'Simplified Chinese': (
          locale: const Locale('zh'),
          present: ['五十音速查', '清音五十音'],
          absent: [],
        ),
        // A heading the two Chinese catalogs write differently.
        'Traditional Chinese': (
          locale: const Locale('zh', 'TW'),
          present: ['五十音速查', '發音規則'],
          absent: ['发音规则'],
        ),
        // Not the English catalog wearing a Japanese locale.
        'Japanese': (
          locale: const Locale('ja'),
          present: [ja.kanaTitle, ja.kanaRulesSection],
          absent: ['Kana'],
        ),
      };
  for (final entry in cases.entries) {
    testWidgets('kana page renders in ${entry.key}', (tester) async {
      await pumpKana(tester, entry.value.locale);
      for (final text in entry.value.present) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final text in entry.value.absent) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

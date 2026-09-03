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

  testWidgets('kana page renders in English', (tester) async {
    await pumpKana(tester, const Locale('en'));
    expect(find.text('Kana'), findsOneWidget);
    expect(find.text('あ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kana page renders in Simplified Chinese', (tester) async {
    await pumpKana(tester, const Locale('zh'));
    expect(find.text('五十音速查'), findsOneWidget);
    expect(find.text('清音五十音'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kana page renders in Traditional Chinese', (tester) async {
    await pumpKana(tester, const Locale('zh', 'TW'));
    expect(find.text('五十音速查'), findsOneWidget);
    // A heading the two Chinese catalogs write differently, so this fails if
    // the Traditional locale quietly fell back to the Simplified strings.
    expect(find.text('發音規則'), findsOneWidget);
    expect(find.text('发音规则'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

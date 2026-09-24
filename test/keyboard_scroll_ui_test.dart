import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/grammar/views/grammar_page.dart';
import 'package:my_nihongo/features/kana/views/kana_page.dart';
import 'package:my_nihongo/features/vocab/views/vocab_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test that the reference lists scroll from the keyboard on desktop.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates a temporary app directory; reads the content assets.
/// Notes: On desktop a scroll view does not attach to the route's primary
/// scroll controller unless it asks to, and PageDown with nothing focused
/// reaches a list only through that controller. The arrow keys are not
/// scroll keys on desktop — they move focus between items, and a focused item
/// is scrolled into view — so they are not asserted here. Each page is pumped
/// at the Windows window's own size with nothing focused inside the list —
/// the state a learner is in after clicking a tab.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    ContentRepository.parseInIsolate = false;
    temp = await Directory.systemTemp.createTemp('mynihongo_keyscroll_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });

  tearDown(() async {
    ContentRepository.parseInIsolate = true;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1000, 720);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: page,
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.byType(ListView).evaluate().isNotEmpty) break;
      }
    });
    await tester.pump();
  }

  double offset(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .pixels;

  for (final (name, page) in [
    ('vocabulary', const VocabPage()),
    ('grammar', const GrammarPage()),
    ('kana', const KanaPage()),
  ]) {
    testWidgets('PageDown and PageUp scroll the $name list', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await pumpPage(tester, page);
        expect(offset(tester), 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();
        final paged = offset(tester);
        expect(paged, greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
        await tester.pumpAndSettle();
        expect(offset(tester), lessThan(paged));
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

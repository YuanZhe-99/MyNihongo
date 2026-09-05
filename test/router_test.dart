import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/router.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/widgets/shell_scaffold.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test that the app opens on the tab it is told to.
/// Inputs: None.
/// Returns: None.
/// Side effects: Pumps the shell, which reads the content assets.
/// Notes: `main()` reads the last tab before `runApp` and passes it here, so
/// the app opens where the user left it with no visible jump from Learn. The
/// router is built once and kept, because a `GoRouter` owns navigation history
/// and rebuilding one on a theme change would send the app back to its initial
/// tab. Driven in Simplified Chinese for the same font reason as the other
/// layout tests.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    temp = await Directory.systemTemp.createTemp('mynihongo_router_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });

  tearDownAll(() async {
    ContentRepository.parseInIsolate = true;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    // The Learn tab reads the progress file through real dart:io, so the
    // first frames have to run outside the binding's fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            routerConfig: buildAppRouter(initialLocation: location),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  testWidgets('the default is Learn', (tester) async {
    await pumpAt(tester, '/learn');
    expect(find.text('学习'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('built with /kana it opens on the kana chart', (tester) async {
    await pumpAt(tester, '/kana');
    expect(find.text('あ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('built with /grammar it opens on the grammar browser', (
    tester,
  ) async {
    await pumpAt(tester, '/grammar');
    expect(find.text('〜です'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the shell and the router declare the same five tabs', () {
    expect(ShellScaffold.routes, [
      '/learn',
      '/kana',
      '/vocab',
      '/grammar',
      '/settings',
    ]);
  });

  testWidgets('the results history opens outside the shell too', (
    tester,
  ) async {
    await pumpAt(tester, '/exam-history');
    expect(find.text('JLPT 成绩记录'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sentence lab opens on its own route, outside the shell', (
    tester,
  ) async {
    await pumpAt(tester, '/lab');
    expect(find.text('句子实验室'), findsOneWidget);
    // Outside the shell: no navigation bar or rail is drawn around it, which
    // is what gives a long sentence the whole window.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

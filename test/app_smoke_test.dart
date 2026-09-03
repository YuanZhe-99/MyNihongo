import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/app.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Walk the whole app once, the way a person opening it would.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app directory; reads the
/// content assets.
/// Notes: The other tests each pin one page or one rule. This one is the
/// end-to-end check that the real root widget, the real router and the real
/// providers start together and that every tab renders with the shipped
/// content — the closest thing to launching the app that this host can run,
/// since it has no emulator and no attached device.
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
    temp = await Directory.systemTemp.createTemp('mynihongo_smoke_');
    Directory(p.join(temp.path, 'MyNihongo')).createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    PackageInfo.setMockInitialValues(
      appName: 'MyNihongo',
      packageName: 'com.yuanzhe.my_nihongo',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDownAll(() {
    ContentRepository.parseInIsolate = true;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  /// Pump frames outside the fake-async zone, so the real file reads the app
  /// does on startup can actually complete.
  Future<void> settle(WidgetTester tester, {int frames = 6}) async {
    await tester.runAsync(() async {
      for (var i = 0; i < frames; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  Future<void> launch(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: MyNihongoApp()));
    });
    await settle(tester);
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(label).last);
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  testWidgets('every tab renders with the shipped content on a phone', (
    tester,
  ) async {
    await launch(tester, 412, 915);

    // Learn, the default tab.
    expect(find.text('Welcome to MyNihongo!!!!!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Kana');
    expect(find.text('あ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Vocabulary');
    expect(find.text('会う'), findsOneWidget, reason: 'the generated catalog');
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Grammar');
    expect(find.text('〜です'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Settings');
    expect(find.text('WebDAV Sync'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the shell switches to a rail on an unfolded foldable', (
    tester,
  ) async {
    await launch(tester, 933, 704);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a word opens its detail sheet with its cross-links', (
    tester,
  ) async {
    await launch(tester, 412, 915);
    await openTab(tester, 'Vocabulary');
    await tester.runAsync(() async {
      await tester.tap(find.text('会う'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
    // The sheet repeats the headword, so it is on screen twice.
    expect(find.text('会う'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

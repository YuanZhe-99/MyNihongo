import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/settings/views/settings_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/services/backup_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the settings page's list-detail layout on wide windows, now
/// that the Data section leads to two more second-level pages.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app storage directory.
/// Notes: Driven in Simplified Chinese, as the sibling app's equivalent test
/// is: `flutter_test`'s default font draws every glyph as a full em square, so
/// long English labels overflow the settings rows in the test environment and
/// nowhere else. The distinguishing assertion for two-pane mode is not that
/// the detail page appeared — it appears in both modes — but whether the
/// first-level list is still on screen beside it.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  const theme = '主题'; // a row that only ever lives in the first-level list
  const privacy = '隐私政策';
  const webdav = 'WebDAV 同步';
  const backup = '备份';
  const placeholder = '从左侧列表中选择一项';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mynihongo_settings_ui');
    final docsDir = Directory(p.join(tempDir.path, 'docs'))
      ..createSync(recursive: true);
    final appDir = Directory(p.join(docsDir.path, 'MyNihongo'))
      ..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(docsDir.path);
    BackupService.appDirProvider = () async => appDir;
    PackageInfo.setMockInitialValues(
      appName: 'MyNihongo',
      packageName: 'com.yuanzhe.my_nihongo',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDownAll(() {
    BackupService.appDirProvider = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    // The page and its detail pages read through real dart:io, so the first
    // frames have to run outside the binding's fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: SettingsPage(),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String title) async {
    final row = find.widgetWithText(ListTile, title).first;
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(row);
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('the Data section lists sync, backup, export and import', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text(webdav), findsOneWidget);
    expect(find.text(backup), findsOneWidget);
    expect(find.text('导出为 ZIP'), findsOneWidget);
    expect(find.text('从 ZIP 导入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Z Fold 8 unfolded shows the placeholder until a pick', (
    tester,
  ) async {
    await pumpAt(tester, 933, 704);
    expect(find.text(placeholder), findsOneWidget);
    expect(find.text(theme), findsOneWidget);
  });

  testWidgets('picking WebDAV sync hosts it beside the list', (tester) async {
    await pumpAt(tester, 933, 704);
    await openRow(tester, webdav);
    // In one pane the pushed page covers the list and the title is found once;
    // here the list is still beside it, so the row and the pane's own app bar
    // both carry the title.
    expect(find.text(webdav), findsNWidgets(2));
    expect(find.text(placeholder), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('picking backup hosts it beside the list', (tester) async {
    await pumpAt(tester, 933, 704);
    await openRow(tester, backup);
    expect(find.text(backup), findsNWidgets(2));
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the privacy policy still opens in the pane', (tester) async {
    await pumpAt(tester, 933, 704);
    await openRow(tester, privacy);
    expect(find.text(privacy), findsNWidgets(2));
  });

  testWidgets('a phone in portrait pushes full-screen instead', (tester) async {
    await pumpAt(tester, 412, 915);
    await openRow(tester, webdav);
    // The pushed page covers the list: the row is gone, the app bar remains.
    expect(find.text(webdav), findsOneWidget);
    expect(find.text(theme), findsNothing);
  });

  testWidgets('a folded Z Fold 8 stays on one pane', (tester) async {
    await pumpAt(tester, 704, 933);
    expect(find.text(placeholder), findsNothing);
  });
}

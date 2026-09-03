import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/settings/views/backup_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/services/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the backup page: an empty history, creating a bundle, a
/// damaged bundle, and the module picker.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app storage directory and
/// writes backup bundles inside it.
/// Notes: `BackupService.appDirProvider` points the engine at the temp
/// directory. Driven in Simplified Chinese for the same font reason as the
/// other layout tests.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory appDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mynihongo_backup_ui');
    appDir = Directory(p.join(tempDir.path, 'MyNihongo'))
      ..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    BackupService.appDirProvider = () async => appDir;
    BackupService.autoBackupEnabled = false;
    BackupService.retentionDays = 0;
    File(p.join(appDir.path, progressDataFileName)).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'records': [
          {
            'id': 'kana:あ',
            'correct': 1,
            'wrong': 0,
            'streak': 1,
            'intervalDays': 1,
            'ease': 2.5,
            'createdAt': '2026-07-01T00:00:00.000Z',
            'modifiedAt': '2026-07-01T00:00:00.000Z',
          },
        ],
      }),
    );
  });

  tearDown(() {
    BackupService.appDirProvider = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: BackupPage(),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> tapAsync(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('an empty history says so and keeps the controls', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('暂无备份'), findsOneWidget);
    expect(find.text('自动备份'), findsOneWidget);
    expect(find.text('保留期限'), findsOneWidget);
    expect(find.textContaining('备份仅保存在本机'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a backup adds one entry to the history', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tapAsync(tester, find.widgetWithText(ListTile, '创建备份'));
    expect(find.text('暂无备份'), findsNothing);
    expect(find.byIcon(Icons.restore), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('a damaged bundle is flagged and cannot be restored', (
    tester,
  ) async {
    final backupDir = Directory(p.join(appDir.path, 'backups'))
      ..createSync(recursive: true);
    File(
      p.join(backupDir.path, 'backup_20260701_000000.json'),
    ).writeAsStringSync('{not json');

    await pumpAt(tester, 412, 915);
    expect(find.textContaining('已损坏'), findsOneWidget);
    final restore = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.restore),
    );
    expect(restore.onPressed, isNull, reason: 'a damaged bundle is unusable');
    final delete = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(delete.onPressed, isNotNull, reason: 'but it can still be deleted');
  });

  testWidgets('the restore picker names the progress module', (tester) async {
    await pumpAt(tester, 412, 915);
    await tapAsync(tester, find.widgetWithText(ListTile, '创建备份'));
    await tapAsync(tester, find.byIcon(Icons.restore));
    expect(find.text('还原内容'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);
    expect(find.text('学习进度'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '学习进度'),
    );
    expect(tile.value, isTrue, reason: 'every module starts selected');
  });

  testWidgets('a Z Fold 8 unfolded renders the page without errors', (
    tester,
  ) async {
    await pumpAt(tester, 933, 704);
    expect(find.text('暂无备份'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

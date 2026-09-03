import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/views/webdav_config_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the WebDAV configuration page's form and its gating.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app storage directory, and
/// writes a `webdav_config.json` inside it.
/// Notes: No network is touched: the sync controls are only shown once a
/// configuration is saved, and these cases stop at that boundary. Driven in
/// Simplified Chinese for the same font reason as the settings tests.
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
    tempDir = await Directory.systemTemp.createTemp('mynihongo_webdav_ui');
    appDir = Directory(p.join(tempDir.path, 'MyNihongo'))
      ..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: WebDAVConfigPage(),
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

  void writeConfig() {
    File(p.join(appDir.path, 'webdav_config.json')).writeAsStringSync('''
{
  "serverUrl": "https://example.test/dav",
  "username": "u",
  "password": "p",
  "remotePath": "/MyNihongo",
  "autoSync": false
}
''');
  }

  for (final geometry in const [
    (412.0, 915.0, 'a phone in portrait'),
    (933.0, 704.0, 'a Z Fold 8 unfolded'),
    (704.0, 933.0, 'a Z Fold 8 folded'),
  ]) {
    testWidgets('${geometry.$3} renders the form without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('服务器地址'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('远程路径'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the sync controls stay hidden until a server is configured', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('立即同步'), findsNothing);
    expect(find.text('强制上传'), findsNothing);
    expect(find.text('断开连接'), findsNothing);
  });

  testWidgets('a stored configuration fills the form and shows the controls', (
    tester,
  ) async {
    writeConfig();
    await pumpAt(tester, 412, 915);
    expect(find.text('https://example.test/dav'), findsOneWidget);
    expect(find.text('立即同步'), findsOneWidget);
    expect(find.text('强制上传'), findsOneWidget);
    expect(find.text('强制下载'), findsOneWidget);
    expect(find.text('自动同步'), findsOneWidget);
    expect(find.text('断开连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Nextcloud preset fills the URL and the remote path', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.text('Nextcloud 预设'));
    await tester.pumpAndSettle();
    expect(
      find.text('https://your-nextcloud-host/remote.php/dav/files/USERNAME'),
      findsOneWidget,
    );
    // The remote path field now holds the default, which is also its hint, so
    // the string is on screen twice.
    expect(find.text('/MyNihongo'), findsNWidgets(2));
  });

  testWidgets('disconnecting clears the form and hides the controls', (
    tester,
  ) async {
    writeConfig();
    await pumpAt(tester, 412, 915);
    await tester.runAsync(() async {
      await tester.tap(find.text('断开连接'));
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('立即同步'), findsNothing);
    expect(find.text('https://example.test/dav'), findsNothing);
  });
}

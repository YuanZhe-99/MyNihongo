import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/settings/views/settings_page.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
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
  const storageLocation = '存储位置';

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

  /// Purpose: Bring a settings row into view before asserting on it.
  /// Inputs: `tester`, the row `title`.
  /// Returns: None.
  /// Side effects: Scrolls the settings list.
  /// Notes: Internal helper used within this file only. General, Learning,
  /// Speech and On-device AI together are taller than a phone screen, so the
  /// Data section has to be scrolled to. The finder may legitimately match
  /// nothing while the row is still unbuilt below the fold, which is why it is
  /// a bare `find.text` rather than `.first`.
  Future<void> scrollTo(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String title) async {
    // Scroll with a finder that may match nothing: `scrollUntilVisible` asks
    // the finder whether it is empty on every step, and a `.first` finder
    // throws instead of answering while the row is still unbuilt below the
    // fold. The Speech section pushed the About rows past the cache extent.
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final row = find.widgetWithText(ListTile, title).first;
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
    await scrollTo(tester, webdav);
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

  testWidgets('a phone hides the storage location row', (tester) async {
    // Reset inside the body, not in a tear-down: the framework asserts every
    // foundation debug variable is unset before tear-downs run.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pumpAt(tester, 412, 915);
    await scrollTo(tester, webdav);
    expect(find.text(storageLocation), findsNothing);
    expect(find.text(webdav), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the language picker offers all three UI languages', (
    tester,
  ) async {
    await pumpAt(tester, 933, 704);
    await tester.tap(find.byType(DropdownButton<Locale?>));
    await tester.pumpAndSettle();

    // The open menu lists every language the app ships, so a reader can find
    // Traditional Chinese without knowing it exists.
    expect(find.text('English'), findsWidgets);
    expect(find.text('简体中文'), findsWidgets);
    expect(find.text('繁體中文'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop shows the storage location row', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await pumpAt(tester, 1000, 720);
    await tester.scrollUntilVisible(
      find.text(storageLocation),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(storageLocation), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  group('the eight-tap unlock', () {
    // Android's own gesture, copied exactly on purpose: somebody who needs the
    // diagnostics already knows how to do this, and nobody else finds it by
    // accident. What it reveals — model variants, AICore builds — is the first
    // thing a bug report needs and the last thing a learner wants to read.

    /// Purpose: Tap the version row a number of times.
    /// Inputs: `tester` and how many `times`.
    /// Returns: None.
    /// Side effects: Pumps frames; may write the preference.
    /// Notes: Internal helper used within this test file only.
    Future<void> tapVersion(WidgetTester tester, int times) async {
      await scrollTo(tester, '版本');
      for (var i = 0; i < times; i++) {
        await tester.tap(find.text('版本'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    setUp(() async {
      await NihongoStorage.setDebugMode(false);
    });

    tearDown(() async {
      await NihongoStorage.setDebugMode(false);
    });

    testWidgets('is not offered until it has been unlocked', (tester) async {
      await pumpAt(tester, 412, 915);
      await scrollTo(tester, '版本');
      expect(
        find.text('开发者选项'),
        findsNothing,
        reason: 'a row that says "off" is an invitation',
      );
    });

    testWidgets('seven taps are not enough', (tester) async {
      await pumpAt(tester, 412, 915);
      await tapVersion(tester, 7);
      expect(find.text('开发者选项'), findsNothing);
    });

    testWidgets('the eighth tap unlocks it and says so', (tester) async {
      await pumpAt(tester, 412, 915);
      await tapVersion(tester, 8);
      expect(find.text('开发者选项已开启。'), findsOneWidget);
      await scrollTo(tester, '开发者选项');
      expect(find.text('开发者选项'), findsOneWidget);
    });

    testWidgets('the countdown starts three taps out, not at the first', (
      tester,
    ) async {
      // An accidental double-tap should say nothing; a deliberate run should
      // tell the person doing it that it is working.
      await pumpAt(tester, 412, 915);
      await tapVersion(tester, 2);
      expect(find.textContaining('再点'), findsNothing);

      await tapVersion(tester, 3);
      expect(find.textContaining('再点'), findsWidgets);
    });

    testWidgets('once unlocked it can be turned off again', (tester) async {
      await pumpAt(tester, 412, 915);
      await tapVersion(tester, 8);
      await scrollTo(tester, '开发者选项');
      await tester.tap(find.byType(SwitchListTile).last);
      await tester.pumpAndSettle();
      expect(find.text('开发者选项'), findsNothing);
    });

    test('the preference lives in the device-local config file', () async {
      // Device-local, unlike almost every other preference: what it reveals is
      // the diagnosis of *this* phone, and carrying it to another would turn
      // diagnostics on where nobody asked and where every number would be
      // about a different device. `storage_config.json` is the file that does
      // not sync.
      //
      // A plain test rather than a widget one: the notifier starts the write
      // and does not await it, and a future created inside `testWidgets`'
      // fake-async zone never completes there — so a widget test asserting
      // that the file had been written would be asserting something it cannot
      // observe.
      await NihongoStorage.setDebugMode(true);
      expect(await NihongoStorage.getDebugMode(), isTrue);
      expect((await NihongoStorage.readConfig())['debugMode'], true);

      await NihongoStorage.setDebugMode(false);
      expect(await NihongoStorage.getDebugMode(), isFalse);
      expect(
        (await NihongoStorage.readConfig()).containsKey('debugMode'),
        isFalse,
        reason: 'off is an absent key, like every other default',
      );
    });
  });
}

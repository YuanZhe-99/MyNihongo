import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/learn/views/learn_page.dart';
import 'package:my_nihongo/features/learn/widgets/learning_settings_tiles.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the Learn tab's today card and the Learning settings rows at
/// the geometries the app supports.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the shipped content assets; writes a temporary progress
/// file.
/// Notes: Driven in Simplified Chinese, like the other layout tests: square CJK
/// glyphs measure the real layout, while the test font inflates Latin text and
/// would report overflows that do not happen on a device. The today card is the
/// one thing a returning learner reads first, so it is checked at every named
/// foldable geometry rather than only on a phone.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File dataFile;

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_today_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final appDir = Directory(p.join(temp.path, 'MyNihongo'));
    await appDir.create(recursive: true);
    dataFile = File(p.join(appDir.path, progressDataFileName));
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Purpose: Seed a progress file before the page reads it.
  /// Inputs: `records`, and optionally the `profile` payload.
  /// Returns: None.
  /// Side effects: Writes the progress file.
  /// Notes: Internal helper used within this file only.
  void seed(List<Map<String, dynamic>> records) {
    dataFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'records': records}),
    );
  }

  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    double height, {
    Widget home = const LearnPage(),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    // The page reads the progress file and the catalog through real dart:io,
    // which never completes inside the binding's fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: home,
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  for (final geometry in const [
    (412.0, 915.0, 'a phone in portrait'),
    (915.0, 412.0, 'a phone in landscape'),
    (933.0, 704.0, 'a Z Fold 8 unfolded'),
    (704.0, 933.0, 'a Z Fold 8 folded'),
    (791.0, 820.0, 'a Pixel 10 Pro Fold'),
    (659.0, 791.0, 'a Z Fold 5'),
    (1024.0, 768.0, 'a tablet in landscape'),
    (768.0, 1024.0, 'a tablet in portrait'),
  ]) {
    testWidgets('${geometry.$3} renders the today card without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('今日'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a learner with nothing studied is told the streak has not started', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('还没有连续记录——答一题就开始'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an overdue item is counted on the today card', (tester) async {
    final past = DateTime.now().toUtc().subtract(const Duration(days: 3));
    seed([
      {
        'id': 'kana:あ',
        'correct': 2,
        'wrong': 0,
        'streak': 2,
        'intervalDays': 6,
        'ease': 2.5,
        'dueAt': past.toIso8601String(),
        'lastReviewedAt': past.toIso8601String(),
        'createdAt': past.toIso8601String(),
        'modifiedAt': past.toIso8601String(),
      },
    ]);

    await pumpAt(tester, 412, 915);
    expect(find.text('1 项待复习'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an item due tomorrow is not counted as due today', (
    tester,
  ) async {
    final soon = DateTime.now().toUtc().add(const Duration(days: 3));
    seed([
      {
        'id': 'kana:あ',
        'correct': 2,
        'wrong': 0,
        'streak': 2,
        'intervalDays': 6,
        'ease': 2.5,
        'dueAt': soon.toIso8601String(),
        'lastReviewedAt': DateTime.now().toUtc().toIso8601String(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'modifiedAt': DateTime.now().toUtc().toIso8601String(),
      },
    ]);

    await pumpAt(tester, 412, 915);
    expect(find.text('没有待复习的内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the learning settings offer a level and two daily limits', (
    tester,
  ) async {
    await pumpAt(
      tester,
      412,
      915,
      home: const Scaffold(
        body: SingleChildScrollView(child: LearningSettingsTiles()),
      ),
    );

    expect(find.text('目标级别'), findsOneWidget);
    expect(find.text('每日新内容'), findsOneWidget);
    expect(find.text('每日复习量'), findsOneWidget);
    expect(find.text('N5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the target level writes it to the progress file', (
    tester,
  ) async {
    await pumpAt(
      tester,
      412,
      915,
      home: const Scaffold(
        body: SingleChildScrollView(child: LearningSettingsTiles()),
      ),
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('N5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('N4').last);
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    // Read the file rather than the widget: the point is that a synced record
    // was written, not that a dropdown redrew.
    final json = jsonDecode(dataFile.readAsStringSync()) as Map<String, dynamic>;
    final records = json['records'] as List;
    final profile = records.firstWhere((r) => r['id'] == 'profile:me') as Map;
    expect((profile['profile'] as Map)['targetLevel'], 'N4');
    expect(tester.takeException(), isNull);
  });
}

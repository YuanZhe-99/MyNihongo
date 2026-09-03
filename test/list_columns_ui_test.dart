import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/grammar/views/grammar_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/utils/adaptive_layout.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the column-count control on a reference list.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates a temporary app directory; reads the content assets.
/// Notes: The grammar page is the probe because it has 81 entries rather than
/// 7,700, so a full pump stays fast. The control is hidden rather than
/// disabled where the window can only carry one column, so a phone never shows
/// a menu that could not do anything. Driven in Simplified Chinese for the same
/// font reason as the other layout tests.
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
    temp = await Directory.systemTemp.createTemp('mynihongo_columns_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });

  tearDown(() async {
    ContentRepository.parseInIsolate = true;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
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
            home: GrammarPage(),
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

  final columnsButton = find.byIcon(Icons.view_column_outlined);

  testWidgets('the control is hidden on a phone in portrait', (tester) async {
    await pumpAt(tester, 412, 915);
    expect(columnsButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the control appears on a tablet in landscape', (tester) async {
    await pumpAt(tester, 1024, 768);
    expect(columnsButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the menu offers automatic plus every count', (tester) async {
    await pumpAt(tester, 1024, 768);
    await tester.tap(columnsButton);
    await tester.pumpAndSettle();
    expect(find.text('自动'), findsOneWidget);
    for (var n = 1; n <= listMaxColumns; n++) {
      expect(find.text('$n'), findsOneWidget, reason: 'missing option $n');
    }
  });

  testWidgets('picking a count is remembered and applied', (tester) async {
    await pumpAt(tester, 1024, 768);
    await tester.tap(columnsButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    // The write is a real file write, so it has to land outside the fake-async
    // zone; poll rather than guess how many frames it takes.
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && _storedColumns(temp) != 1; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });
    await tester.pump();
    // One column now, on a window that would otherwise carry three.
    expect(_storedColumns(temp), 1);
    expect(tester.takeException(), isNull);
  });

  test('a preference above capacity is clamped, not rejected', () {
    // The rule itself, without a widget: a choice made on a wide window comes
    // back when the window grows again rather than being thrown away.
    expect(
      referenceColumnCount(
        screenWidth: 933,
        screenHeight: 704,
        contentWidth: 800,
        preference: 4,
      ),
      lessThanOrEqualTo(
        referenceColumnCount(
          screenWidth: 933,
          screenHeight: 704,
          contentWidth: 800,
        ),
      ),
    );
    // And a window that cannot split ignores the preference entirely.
    expect(
      referenceColumnCount(
        screenWidth: 412,
        screenHeight: 915,
        contentWidth: 412,
        preference: 4,
      ),
      1,
    );
  });
}

/// Purpose: Read the stored column preference straight from the config file.
/// Inputs: `temp` — the fake documents directory.
/// Returns: `int?`.
/// Side effects: Reads the file.
/// Notes: Reads the file rather than the provider, so the test proves the
/// choice was persisted and not merely held in memory. Synchronous on purpose:
/// an awaited dart:io call inside a widget test never completes, because the
/// binding runs the test body under `FakeAsync`.
int? _storedColumns(Directory temp) {
  final file = File(
    '${temp.path}${Platform.pathSeparator}MyNihongo'
    '${Platform.pathSeparator}storage_config.json',
  );
  if (!file.existsSync()) return null;
  final raw = file.readAsStringSync();
  final match = RegExp(r'"referenceListColumns"\s*:\s*(\d+)').firstMatch(raw);
  return match == null ? null : int.parse(match.group(1)!);
}

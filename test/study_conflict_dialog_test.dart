import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/study_item_labels.dart';
import 'package:my_nihongo/features/progress/models/history_entry.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/services/sync_merge.dart';
import 'package:my_nihongo/shared/widgets/study_conflict_dialog.dart';

/// Purpose: Test the sync conflict dialog: both versions are shown, the choice
/// comes back to the caller, and the Chinese layout does not overflow.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Layout assertions run in `zh`, the wider of the two languages for
/// these labels. The dialog is checked at a phone size because it is the
/// tightest place it renders.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  StudyRecord record(String id, String modifiedAt, int correct) => StudyRecord(
    id: id,
    correct: correct,
    wrong: 1,
    streak: correct,
    intervalDays: 3,
    ease: 2.5,
    lastReviewedAt: DateTime.parse(modifiedAt),
    createdAt: DateTime.parse('2026-07-01T00:00:00.000Z'),
    modifiedAt: DateTime.parse(modifiedAt),
  );

  final conflict = RecordConflict<StudyRecord>(
    id: 'kana:あ',
    localRecord: record('kana:あ', '2026-07-05T10:00:00.000Z', 4),
    remoteRecord: record('kana:あ', '2026-07-06T11:00:00.000Z', 9),
    displayName: 'kana:あ',
  );

  const label = StudyItemLabel(
    title: 'あ · ア',
    subtitle: 'a',
    kind: StudyKind.kana,
  );

  Future<StudyRecord?> open(
    WidgetTester tester, {
    required double width,
    required double height,
    StudyItemLabel dialogLabel = label,
    RecordConflict<StudyRecord>? pair,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);

    StudyRecord? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  chosen = await showStudyConflictDialog(
                    context,
                    pair ?? conflict,
                    dialogLabel,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return chosen;
  }

  testWidgets('shows both versions with their timestamps', (tester) async {
    await open(tester, width: 412, height: 915);
    expect(find.text('本地版本'), findsOneWidget);
    expect(find.text('远程版本'), findsOneWidget);
    // Two counter lines, one per version, with different values.
    expect(find.text('正确 4 · 错误 1'), findsOneWidget);
    expect(find.text('正确 9 · 错误 1'), findsOneWidget);
    expect(find.textContaining('修改时间'), findsNWidgets(2));
    expect(find.textContaining('上次复习'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeping the remote version returns the remote record', (
    tester,
  ) async {
    StudyRecord? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  chosen = await showStudyConflictDialog(
                    context,
                    conflict,
                    label,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保留远程'));
    await tester.pumpAndSettle();
    expect(chosen, isNotNull);
    expect(chosen!.correct, 9);
  });

  testWidgets('an unresolved item says so instead of hiding the record', (
    tester,
  ) async {
    await open(
      tester,
      width: 412,
      height: 915,
      dialogLabel: const StudyItemLabel(
        title: 'vocab:gone',
        kind: StudyKind.vocab,
        resolved: false,
      ),
    );
    expect(find.textContaining('vocab:gone'), findsOneWidget);
    expect(find.text('当前内容库中没有这一项。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a folded phone', (tester) async {
    await open(tester, width: 412, height: 915);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a short landscape window', (
    tester,
  ) async {
    await open(tester, width: 915, height: 412);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a remembered sentence shows its text, not empty counters', (
    tester,
  ) async {
    // A history record has none of the counter fields, so the ordinary block
    // would describe every version as "correct 0 · wrong 0, stage fresh" and
    // the learner would be choosing between two identical descriptions.
    final at = DateTime.parse('2026-09-04T10:00:00.000Z');
    final local = HistoryEntry(
      id: 'lab:abc',
      kind: HistoryKind.lab,
      text: 'これは本です。',
      at: at,
    ).toRecord(null, at);
    final remote = HistoryEntry(
      id: 'lab:abc',
      kind: HistoryKind.lab,
      text: 'それは本です。',
      at: at.add(const Duration(hours: 1)),
    ).toRecord(null, at.add(const Duration(hours: 1)));

    await open(
      tester,
      width: 412,
      height: 915,
      pair: RecordConflict<StudyRecord>(
        id: 'lab:abc',
        localRecord: local,
        remoteRecord: remote,
        displayName: 'lab:abc',
      ),
      dialogLabel: const StudyItemLabel(
        title: 'これは本です。',
        subtitle: '历史记录',
        kind: StudyKind.history,
      ),
    );

    expect(find.text('これは本です。'), findsWidgets);
    expect(find.text('それは本です。'), findsOneWidget);
    expect(
      find.textContaining('答对'),
      findsNothing,
      reason: 'a remembered sentence has no answers to report',
    );
    expect(tester.takeException(), isNull);
  });
}

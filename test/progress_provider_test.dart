import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/shared/providers/progress_provider.dart';
import 'package:my_nihongo/shared/services/auto_sync_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test that the progress provider reads the file and re-reads it
/// when something outside the UI writes one.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app directory.
/// Notes: The provider is the single subscriber to `AutoSyncService`'s
/// local-data-changed callback, so the sync, restore and ZIP import paths all
/// arrive here; this is what proves that seam works.
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

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_progress_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final appDir = Directory(p.join(temp.path, 'MyNihongo'));
    await appDir.create(recursive: true);
    dataFile = File(p.join(appDir.path, progressDataFileName));
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<void> write(List<String> ids) async {
    await dataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'records': [
          for (final id in ids)
            {
              'id': id,
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
  }

  Future<ProgressData> settled(ProviderContainer container) async {
    // riverpod 1.x has no `future` on a StateNotifierProvider, so poll the
    // state until the first read lands.
    for (var i = 0; i < 200; i++) {
      final value = container.read(progressDataProvider);
      if (value is AsyncData<ProgressData>) return value.value;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('the provider never left the loading state');
  }

  test('reads the progress file on first watch', () async {
    await write(['kana:あ', 'vocab:watashi']);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = await settled(container);
    expect(data.records.map((r) => r.id), ['kana:あ', 'vocab:watashi']);
  });

  test(
    'a local-data-changed notification re-reads without a loading flash',
    () async {
      await write(['kana:あ']);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await settled(container);

      final states = <AsyncValue<ProgressData>>[];
      final removeListener = container.listen<AsyncValue<ProgressData>>(
        progressDataProvider,
        (previous, next) => states.add(next),
        fireImmediately: false,
      );
      addTearDown(removeListener.close);

      await write(['kana:あ', 'grammar:desu']);
      AutoSyncService.instance.notifyLocalDataChangedNow();

      for (var i = 0; i < 200 && states.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(states, isNotEmpty, reason: 'the reload must publish a new state');
      expect(
        states.whereType<AsyncLoading<ProgressData>>(),
        isEmpty,
        reason: 'a background reload must not blank pages already showing data',
      );
      final data = container.read(progressDataProvider);
      expect(data, isA<AsyncData<ProgressData>>());
      expect(
        (data as AsyncData<ProgressData>).value.records.map((r) => r.id),
        contains('grammar:desu'),
      );
    },
  );

  test('a missing file reads as an empty dataset, not an error', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = await settled(container);
    expect(data.records, isEmpty);
  });
}

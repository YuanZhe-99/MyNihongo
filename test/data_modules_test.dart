import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:myapps_data/myapps_data.dart';

/// Purpose: Pin the compatibility contract the shared engines see.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The file name, module id, and pretty-printed output are what a
/// second device and an old backup depend on. Changing any of them strands
/// installs in the field, so they are asserted literally here.
void main() {
  test('the registry describes exactly one module with stable names', () {
    expect(nihongoModuleRegistry.modules, hasLength(1));
    final module = nihongoModuleRegistry.modules.single;
    expect(module.fileName, 'nihongo_progress.json');
    expect(module.moduleId, 'progress');
    expect(nihongoModuleRegistry.byFileName['nihongo_progress.json'], module);
    expect(nihongoModuleRegistry.byModuleId['progress'], module);
    expect(module.referencedImages, isNull);
  });

  test('constants match the registry', () {
    expect(progressDataFileName, 'nihongo_progress.json');
    expect(progressModuleId, 'progress');
    expect(nihongoDefaultRemotePath, '/MyNihongo');
    expect(nihongoArchiveNamePrefix, 'mynihongo_export_');
  });

  test('validation accepts progress data and rejects anything else', () {
    validateProgressJson('{"records": []}');
    validateProgressJson('{"records": [], "future": 1}');
    expect(() => validateProgressJson('[]'), throwsA(anything));
    expect(() => validateProgressJson('not json'), throwsA(anything));
  });

  test('a clean merge yields pretty-printed JSON in storage format', () async {
    const base = '{"records": []}';
    final local = jsonEncode({
      'records': [
        {
          'id': 'kana:あ',
          'correct': 1,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'modifiedAt': '2026-01-02T00:00:00.000Z',
        },
      ],
    });
    final outcome = await nihongoModuleRegistry.modules.single.merge(
      localJson: local,
      remoteJson: base,
      baseJson: base,
      autoResolve: false,
    );
    expect(outcome.conflicts, isEmpty);
    final merged = outcome.mergedJson!;
    // Two-space indentation, the same as NihongoStorage.save writes.
    expect(merged, startsWith('{\n  "records": [\n    {\n'));
    expect(
      merged,
      encodeProgressData(
        ProgressData.fromJson(jsonDecode(merged) as Map<String, dynamic>),
      ),
    );
  });

  test(
    'a conflicting merge surfaces app-neutral conflicts and resolves',
    () async {
      Map<String, dynamic> record(int correct, String modified) => {
        'id': 'grammar:desu',
        'correct': correct,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'modifiedAt': modified,
      };
      final base = jsonEncode({
        'records': [record(0, '2026-01-01T00:00:00.000Z')],
      });
      final local = jsonEncode({
        'records': [record(3, '2026-01-02T00:00:00.000Z')],
      });
      final remote = jsonEncode({
        'records': [record(8, '2026-01-03T00:00:00.000Z')],
      });

      final outcome = await nihongoModuleRegistry.modules.single.merge(
        localJson: local,
        remoteJson: remote,
        baseJson: base,
        autoResolve: false,
      );
      expect(outcome.mergedJson, isNull);
      expect(outcome.conflicts, hasLength(1));
      final conflict = outcome.conflicts.single;
      expect(conflict.id, 'grammar:desu');
      expect(conflict.localRecord, isA<StudyRecord>());
      expect(conflict.remoteRecord, isA<StudyRecord>());

      final resolved = await outcome.resolve({
        conflict.resolutionKey: conflict.remoteRecord,
      });
      final data = ProgressData.fromJson(
        jsonDecode(resolved) as Map<String, dynamic>,
      );
      expect(data.recordById('grammar:desu')!.correct, 8);
    },
  );

  test('the adapter can be constructed without touching storage', () {
    const adapter = NihongoStorageAdapter();
    expect(adapter, isA<StorageAdapter>());
  });
}

// Golden (characterization) harness for MyNihongo!!!!!.
//
// Drives the real `WebDAVService` / `BackupService` / `ImportExportService`
// against an in-memory fake WebDAV server and records the exact request
// sequence and on-disk formats into golden files. The sibling apps run the
// same scenarios, which is how the series' wire format stays interoperable
// (myapps_data invariants I1-I3). Re-run / re-record with:
//   flutter test test/golden/webdav_golden_test.dart                                    (verify)
//   flutter test --dart-define=GOLDEN_RECORD=true test/golden/webdav_golden_test.dart   (record)
// (must be literally `true` — bool.fromEnvironment treats `1` as false, so the
// run silently stays in verify mode.)
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:http/src/client.dart' show runWithClient;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/shared/services/backup_service.dart';
import 'package:my_nihongo/shared/services/import_export_service.dart';
import 'package:my_nihongo/shared/services/webdav_service.dart';

import 'fake_webdav_server.dart';
import 'request_recorder.dart';

/// Whether to rewrite goldens instead of verifying them.
const bool _record = bool.fromEnvironment('GOLDEN_RECORD', defaultValue: false);

/// Fake application-documents provider, as in the app's other io tests.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// Fixed WebDAV config pointing at the fake server.
WebDAVConfig _config() => const WebDAVConfig(
  serverUrl: 'https://golden.test/dav/files/u',
  username: 'u',
  password: 'p',
  remotePath: nihongoDefaultRemotePath,
);

/// One scenario sandbox: a fresh temp dir, fake server and recorder.
class _Sandbox {
  _Sandbox(this.dir, this.server, this.recorder);
  final Directory dir;
  final FakeWebDAVServer server;
  final RequestRecorder recorder;

  String get appDir => p.join(dir.path, 'MyNihongo');

  /// Remote path for a data file (the server keys on the full request path).
  String remote(String name) => '/dav/files/u/MyNihongo/$name';

  File dataFile() => File(p.join(appDir, progressDataFileName));

  Future<void> writeLocalData(String json) async {
    await Directory(appDir).create(recursive: true);
    await dataFile().writeAsString(json);
  }

  Future<void> writeBase(String json) async {
    final baseDir = Directory(p.join(appDir, '.sync_base'));
    await baseDir.create(recursive: true);
    await File(p.join(baseDir.path, progressDataFileName)).writeAsString(json);
  }

  String transcript() => GoldenTranscript(recorder.exchanges).render();
}

/// A `nihongo_progress.json` payload, written the way the app writes it.
String _progressData(List<Map<String, dynamic>> records) =>
    const JsonEncoder.withIndent('  ').convert({'records': records});

Map<String, dynamic> _record_(
  String id,
  String modifiedAt, {
  int correct = 1,
  int wrong = 0,
}) => {
  'id': id,
  'correct': correct,
  'wrong': wrong,
  'streak': correct,
  'intervalDays': 1,
  'ease': 2.5,
  'createdAt': modifiedAt,
  'modifiedAt': modifiedAt,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final goldensDir = Directory(
    p.join('test', 'golden', 'goldens', 'mynihongo'),
  );

  Future<_Sandbox> newSandbox() async {
    final dir = await Directory.systemTemp.createTemp('mynihongo_golden_');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final server = FakeWebDAVServer();
    final recorder = RequestRecorder(server);
    return _Sandbox(dir, server, recorder);
  }

  Future<void> expectGolden(_Sandbox sb, String name) async {
    final file = File(p.join(goldensDir.path, '$name.txt'));
    final mismatch = await GoldenMatcher(
      file,
      record: _record,
    ).check(sb.transcript());
    expect(mismatch, isNull, reason: 'golden "$name" mismatch:\n$mismatch');
  }

  /// Run `body` against the fake server inside the recording zone.
  Future<T> zone<T>(_Sandbox sb, Future<T> Function() body) =>
      runWithClient(body, () => sb.recorder);

  group('webdav sync request-sequence goldens', () {
    test('first sync (local data, empty remote)', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(
        _progressData([_record_('kana:あ', '2026-07-01T00:00:00.000Z')]),
      );
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_first');
      expect(
        sb.server.readText(sb.remote(progressDataFileName)),
        contains('kana:あ'),
      );
      await sb.dir.delete(recursive: true);
    });

    test('no-change sync (local == remote == base)', () async {
      final sb = await newSandbox();
      final data = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      await sb.writeLocalData(data);
      sb.server.seed(sb.remote(progressDataFileName), data);
      await sb.writeBase(data);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_no_change');
      await sb.dir.delete(recursive: true);
    });

    test('local-only change (upload merged)', () async {
      final sb = await newSandbox();
      final base = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      final local = _progressData([
        _record_('kana:あ', '2026-07-02T00:00:00.000Z', correct: 2),
        _record_('vocab:watashi', '2026-07-02T00:00:00.000Z'),
      ]);
      await sb.writeLocalData(local);
      sb.server.seed(sb.remote(progressDataFileName), base);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_local_change');
      expect(
        sb.server.readText(sb.remote(progressDataFileName)),
        contains('vocab:watashi'),
      );
      await sb.dir.delete(recursive: true);
    });

    test('remote-only change (download)', () async {
      final sb = await newSandbox();
      final base = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      final remote = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
        _record_('grammar:desu', '2026-07-03T00:00:00.000Z'),
      ]);
      await sb.writeLocalData(base);
      sb.server.seed(sb.remote(progressDataFileName), remote);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_remote_change');
      expect(sb.dataFile().readAsStringSync(), contains('grammar:desu'));
      await sb.dir.delete(recursive: true);
    });

    test('both-changed-identical (no conflict)', () async {
      final sb = await newSandbox();
      final base = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      final both = _progressData([
        _record_('kana:あ', '2026-07-05T00:00:00.000Z', correct: 3),
      ]);
      await sb.writeLocalData(both);
      sb.server.seed(sb.remote(progressDataFileName), both);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      expect(
        result.pending,
        isNull,
        reason: 'identical content must not conflict',
      );
      await expectGolden(sb, 'sync_both_identical');
      await sb.dir.delete(recursive: true);
    });

    test('true conflict then finalize', () async {
      final sb = await newSandbox();
      final base = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      final local = _progressData([
        _record_('kana:あ', '2026-07-05T00:00:00.000Z', correct: 5),
      ]);
      final remote = _progressData([
        _record_('kana:あ', '2026-07-06T00:00:00.000Z', correct: 9),
      ]);
      await sb.writeLocalData(local);
      sb.server.seed(sb.remote(progressDataFileName), remote);
      await sb.writeBase(base);

      final syncResult = await zone(sb, () => WebDAVService.sync(_config()));
      expect(
        syncResult.pending,
        isNotNull,
        reason: 'both-changed-different must conflict',
      );

      final conflict = syncResult.pending!.allConflicts.single;
      expect(
        conflict.displayName,
        conflict.id,
        reason: 'the engine has no catalog; the UI resolves the label',
      );
      final resolutions = {conflict.id: conflict.remoteRecord};
      final fin = await zone(
        sb,
        () => WebDAVService.finalizePendingSync(
          _config(),
          syncResult.pending!,
          resolutions,
        ),
      );
      expect(fin, isTrue);
      await expectGolden(sb, 'sync_conflict_finalize');
      expect(
        sb.server.readText(sb.remote(progressDataFileName)),
        contains('"correct": 9'),
      );
      await sb.dir.delete(recursive: true);
    });

    test('force upload', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(
        _progressData([_record_('kana:あ', '2026-07-01T00:00:00.000Z')]),
      );
      sb.server.seed(
        sb.remote(progressDataFileName),
        _progressData([_record_('kana:ん', '2020-01-01T00:00:00.000Z')]),
      );
      final result = await zone(sb, () => WebDAVService.forceUpload(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'force_upload');
      final uploaded = sb.server.readText(sb.remote(progressDataFileName));
      expect(uploaded, contains('kana:あ'));
      expect(uploaded, isNot(contains('kana:ん')));
      await sb.dir.delete(recursive: true);
    });

    test('force download', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(
        _progressData([_record_('kana:ん', '2020-01-01T00:00:00.000Z')]),
      );
      sb.server.seed(
        sb.remote(progressDataFileName),
        _progressData([_record_('kana:あ', '2026-07-01T00:00:00.000Z')]),
      );
      final result = await zone(
        sb,
        () => WebDAVService.forceDownload(_config()),
      );
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'force_download');
      expect(sb.dataFile().readAsStringSync(), contains('kana:あ'));
      await sb.dir.delete(recursive: true);
    });

    test('interrupted upload recovery (leftover local lock)', () async {
      final sb = await newSandbox();
      final local = _progressData([
        _record_('kana:あ', '2026-07-01T00:00:00.000Z'),
      ]);
      await sb.writeLocalData(local);
      sb.server.seed(sb.remote(progressDataFileName), local);
      // A previous interrupted upload left a local lock whose remote lock is
      // gone: it must be cleared and the sync must proceed cleanly.
      final baseDir = Directory(p.join(sb.appDir, '.sync_base'));
      await baseDir.create(recursive: true);
      await File(p.join(baseDir.path, 'upload_lock.json')).writeAsString(
        jsonEncode({
          'clientId': 'dead-client',
          'token': 'dead-token',
          'startedAt': '2026-07-01T00:00:00.000Z',
          'updatedAt': '2026-07-01T00:00:00.000Z',
          'ttlSeconds': 60,
        }),
      );
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_interrupted_recovery');
      await sb.dir.delete(recursive: true);
    });
  });

  group('backup goldens (on-disk format)', () {
    test('v2 create bundle layout', () async {
      final sb = await newSandbox();
      BackupService.appDirProvider = () async => Directory(sb.appDir);
      BackupService.autoBackupEnabled = false;
      await sb.writeLocalData(
        _progressData([_record_('kana:あ', '2026-07-01T00:00:00.000Z')]),
      );

      final backup = await BackupService.createBackup();
      expect(backup, isNotNull);
      expect(await backup!.exists(), isTrue);

      final bundle =
          jsonDecode(await backup.readAsString()) as Map<String, dynamic>;
      final golden = StringBuffer()
        ..writeln('backupFormat: ${bundle['_backupFormat']}')
        ..writeln('topLevelKeys: ${(bundle.keys.toList()..sort()).join(',')}')
        ..writeln('hasImageRefs: ${bundle.containsKey('_imageRefs')}')
        ..writeln(
          'imageRefKeys: '
          '${((bundle['_imageRefs'] as Map?)?.keys.toList() ?? [])}',
        )
        ..writeln('dataIsString: ${bundle[progressDataFileName] is String}');
      final file = File(p.join(goldensDir.path, 'backup_v2_create.txt'));
      final mismatch = await GoldenMatcher(
        file,
        record: _record,
      ).check(golden.toString());
      expect(mismatch, isNull, reason: mismatch);
      BackupService.appDirProvider = null;
      await sb.dir.delete(recursive: true);
    });

    test('corrupt bundle flagged in listBackups', () async {
      final sb = await newSandbox();
      BackupService.appDirProvider = () async => Directory(sb.appDir);
      final backupDir = Directory(p.join(sb.appDir, 'backups'));
      await backupDir.create(recursive: true);
      await File(
        p.join(backupDir.path, 'backup_20260701_000000.json'),
      ).writeAsString('{corrupt not json');
      final list = await BackupService.listBackups();
      expect(list.single.corrupt, isTrue);
      BackupService.appDirProvider = null;
      await sb.dir.delete(recursive: true);
    });
  });

  group('zip goldens', () {
    test('export entry list', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(
        _progressData([_record_('kana:あ', '2026-07-01T00:00:00.000Z')]),
      );
      final outDir = await Directory.systemTemp.createTemp('mynihongo_zip_');
      final zipPath = await ImportExportService.exportZIP(outDir.path);
      expect(zipPath, isNotNull);
      final entries = _zipEntries(File(zipPath!));
      final name = p
          .basename(zipPath)
          .replaceAll(RegExp(r'\d{8}_\d{6}'), '<stamp>');
      final file = File(p.join(goldensDir.path, 'zip_export_entries.txt'));
      final mismatch = await GoldenMatcher(
        file,
        record: _record,
      ).check('${entries.join('\n')}\narchiveName: $name\n');
      expect(mismatch, isNull, reason: mismatch);
      expect(name, startsWith(nihongoArchiveNamePrefix));
      await sb.dir.delete(recursive: true);
      await outDir.delete(recursive: true);
    });

    test('import rejects path traversal', () async {
      final sb = await newSandbox();
      final zip = _buildZip({
        '../../evil.txt': [1, 2, 3],
        progressDataFileName: utf8.encode('{"records":[]}'),
      });
      final zipFile = File(p.join(sb.dir.path, 'evil.zip'));
      await zipFile.writeAsBytes(zip);
      final ok = await ImportExportService.importZIP(zipFile.path);
      // The shared engine classifies every entry before writing any, so an
      // archive holding a traversal entry is rejected whole rather than
      // half-applied.
      expect(ok, isFalse);
      expect(
        await File(p.join(sb.appDir, '..', 'evil.txt')).exists(),
        isFalse,
        reason: 'traversal entry must not be written outside appDir',
      );
      expect(
        await File(p.join(sb.appDir, progressDataFileName)).exists(),
        isFalse,
        reason: 'a rejected archive must not write any of its entries',
      );
      await sb.dir.delete(recursive: true);
    });
  });
}

/// Read entry names from a ZIP file.
List<String> _zipEntries(File zipFile) {
  final bytes = zipFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final names = archive.map((f) => f.name).toList()..sort();
  return names;
}

/// Build a ZIP in memory from a name to bytes map.
List<int> _buildZip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

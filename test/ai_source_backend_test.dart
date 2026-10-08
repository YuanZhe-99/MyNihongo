import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapps_ai/myapps_ai.dart';
import 'package:myapps_data/myapps_data.dart';
import 'package:my_nihongo/features/ai/services/ai_source_backend.dart';

class _Storage implements StorageAdapter {
  _Storage(this.dir);
  final Directory dir;
  Map<String, dynamic> config = {'unrelated': 'keep'};
  @override
  Future<Directory> getAppDir() async => dir;
  @override
  Future<Map<String, dynamic>> readConfig() async => Map.of(config);
  @override
  Future<void> writeConfig(Map<String, dynamic> value) async =>
      config.addAll(value);
}

class _System extends CapabilityGenAiBackend {
  final calls = <String>[];
  @override
  Future<List<String>> proofread(String text) async {
    calls.add('proofread:$text');
    return ['ok'];
  }

  @override
  Future<GenAiStatusReport> capabilityReport(
    GenAiFeature feature, {
    bool force = false,
    bool preferFast = false,
  }) async {
    calls.add('report:${feature.name}');
    return const GenAiStatusReport(GenAiStatus.available);
  }

  @override
  Future<bool> downloadCapability(
    GenAiFeature feature, {
    void Function(int, int)? onProgress,
  }) async {
    calls.add('download:${feature.name}');
    return true;
  }

  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'missing selected model is unavailable without downloading or overwriting config',
    () async {
      final dir = await Directory.systemTemp.createTemp('source_test');
      addTearDown(() => dir.delete(recursive: true));
      final storage = _Storage(dir);
      final backend = createAiSourceRouter(storage: storage);
      await backend.initialize();
      expect(await Directory('${dir.path}/ai_models').exists(), isFalse);
      await backend.select('local:qwen3.5-0.8b');
      expect((await backend.statusReport()).status, GenAiStatus.unavailable);
      expect(storage.config['unrelated'], 'keep');
      expect(await Directory('${dir.path}/ai_models').exists(), isFalse);
      final restored = createAiSourceRouter(storage: storage);
      await restored.initialize();
      expect(restored.selection.global, 'local:qwen3.5-0.8b');
      expect(restored.catalog.length, 3);
      expect(
        restored.sourceName('local:qwen3.5-0.8b'),
        'Qwen: Qwen3.5 0.8B (Q4_K_M)',
      );
      final report = await restored.diagnostics();
      expect(report.sections.map((s) => s.id), contains('llama.cpp'));
      expect(
        report.sections.last.rows,
        isEmpty,
        reason: 'MyNihongo includes no online sources',
      );
    },
  );
  test('proofreading stays on the system backend for any selection', () async {
    final dir = await Directory.systemTemp.createTemp('source_proofread');
    addTearDown(() => dir.delete(recursive: true));
    final system = _System();
    final backend = createAiSourceRouter(
      storage: _Storage(dir),
      system: system,
    );
    await backend.select('local:qwen3.5-0.8b');
    expect(await backend.proofread('text'), ['ok']);
    final report = await backend.capabilityReport(GenAiFeature.proofread);
    expect(report.status, GenAiStatus.available);
    expect(await backend.downloadCapability(GenAiFeature.proofread), isTrue);
    expect(system.calls, [
      'proofread:text',
      'report:proofread',
      'download:proofread',
    ]);
  });
}

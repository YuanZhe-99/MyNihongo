import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the reference preferences in `storage_config.json`.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temporary app directory.
/// Notes: Two properties matter beyond the round trip. A default is removed
/// rather than written, so the file stays small and a future change of default
/// reaches devices that never touched the setting. And a value of the wrong
/// type reads as unset rather than throwing: the file is plain JSON in a folder
/// the user can point anywhere, so it can be hand-edited.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File configFile;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_prefs_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final appDir = Directory(p.join(temp.path, 'MyNihongo'));
    await appDir.create(recursive: true);
    configFile = File(p.join(appDir.path, 'storage_config.json'));
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<Map<String, dynamic>> config() async =>
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;

  test('the last tab round trips', () async {
    expect(await NihongoStorage.getLastTab(), isNull);
    await NihongoStorage.setLastTab('vocab');
    expect(await NihongoStorage.getLastTab(), 'vocab');
    expect((await config())['lastTab'], 'vocab');
  });

  test('the two level filters are independent', () async {
    await NihongoStorage.setVocabLevel('N5');
    await NihongoStorage.setGrammarLevel('N3');
    expect(await NihongoStorage.getVocabLevel(), 'N5');
    expect(await NihongoStorage.getGrammarLevel(), 'N3');
  });

  test(
    'clearing a preference removes its key rather than writing a null',
    () async {
      await NihongoStorage.setVocabLevel('N5');
      await NihongoStorage.setVocabLevel(null);
      expect(await NihongoStorage.getVocabLevel(), isNull);
      expect((await config()).containsKey('vocabLevel'), isFalse);
    },
  );

  test('hiragana is stored as an absent key', () async {
    await NihongoStorage.setKanaScript('katakana');
    expect((await config())['kanaScript'], 'katakana');
    await NihongoStorage.setKanaScript(null);
    expect((await config()).containsKey('kanaScript'), isFalse);
    expect(await NihongoStorage.getKanaScript(), isNull);
  });

  test('the column count round trips as an integer', () async {
    await NihongoStorage.setReferenceListColumns(3);
    expect(await NihongoStorage.getReferenceListColumns(), 3);
    expect((await config())['referenceListColumns'], 3);
    await NihongoStorage.setReferenceListColumns(null);
    expect((await config()).containsKey('referenceListColumns'), isFalse);
  });

  test('a hand-edited value of the wrong type reads as unset', () async {
    await configFile.writeAsString(
      jsonEncode({'vocabLevel': 5, 'referenceListColumns': 'three'}),
    );
    expect(await NihongoStorage.getVocabLevel(), isNull);
    expect(await NihongoStorage.getReferenceListColumns(), isNull);
  });

  test('preferences do not disturb each other', () async {
    await NihongoStorage.setThemeMode('dark');
    await NihongoStorage.setLastTab('kana');
    await NihongoStorage.setReferenceListColumns(2);
    final saved = await config();
    expect(saved['themeMode'], 'dark');
    expect(saved['lastTab'], 'kana');
    expect(saved['referenceListColumns'], 2);
  });
}

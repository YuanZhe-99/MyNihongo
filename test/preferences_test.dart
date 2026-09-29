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

  test(
    'the speaking rate round trips, clears and reads a whole number',
    () async {
      expect(await NihongoStorage.getTtsRate(), isNull);
      await NihongoStorage.setTtsRate(0.8);
      expect(await NihongoStorage.getTtsRate(), 0.8);
      expect((await config())['ttsRate'], 0.8);
      await NihongoStorage.setTtsRate(null);
      expect((await config()).containsKey('ttsRate'), isFalse);
      // A whole number written by hand still reads; a string reads as unset.
      await configFile.writeAsString('{"ttsRate": 1}');
      expect(await NihongoStorage.getTtsRate(), 1.0);
      await configFile.writeAsString('{"ttsRate": "fast"}');
      expect(await NihongoStorage.getTtsRate(), isNull);
    },
  );

  test('the chosen voice round trips', () async {
    expect(await NihongoStorage.getTtsVoice(), isNull);
    await NihongoStorage.setTtsVoice('Kyoko');
    expect(await NihongoStorage.getTtsVoice(), 'Kyoko');
    await NihongoStorage.setTtsVoice(null);
    expect((await config()).containsKey('ttsVoice'), isFalse);
  });

  test('the chosen speech engine round trips and clears', () async {
    expect(await NihongoStorage.getTtsEngine(), isNull);
    await NihongoStorage.setTtsEngine('com.samsung.SMT');
    expect(await NihongoStorage.getTtsEngine(), 'com.samsung.SMT');
    await NihongoStorage.setTtsEngine(null);
    expect((await config()).containsKey('ttsEngine'), isFalse);
  });

  test('the engine and the voice are stored independently', () async {
    await NihongoStorage.setTtsEngine('com.google.android.tts');
    await NihongoStorage.setTtsVoice('ja-jp-x-jab#male_1-local');
    expect(await NihongoStorage.getTtsEngine(), 'com.google.android.tts');
    expect(await NihongoStorage.getTtsVoice(), 'ja-jp-x-jab#male_1-local');
  });

  test('kana over kanji is on before anything is stored', () async {
    // The one inverted preference in the app: absent means on, because a
    // learner who has never opened Settings is the one who needs the readings.
    expect(await NihongoStorage.getShowFurigana(), isTrue);
  });

  test('turning kana over kanji off writes false', () async {
    await NihongoStorage.setShowFurigana(false);
    expect(await NihongoStorage.getShowFurigana(), isFalse);
    expect((await config())['furigana'], isFalse);
  });

  test('turning it back on removes the key', () async {
    await NihongoStorage.setShowFurigana(false);
    await NihongoStorage.setShowFurigana(true);
    expect((await config()).containsKey('furigana'), isFalse);
    expect(await NihongoStorage.getShowFurigana(), isTrue);
  });

  test('a hand-edited string leaves kana over kanji on', () async {
    await configFile.writeAsString('{"furigana": "false"}');
    expect(await NihongoStorage.getShowFurigana(), isTrue);
  });

  // The four preferences that are off until someone turns them on. Each is
  // stored as a key only while on, and only a real JSON boolean counts.
  final offByDefault =
      <
        String,
        ({Future<bool> Function() get, Future<void> Function(bool) set})
      >{
        'speechNetworkFallback': (
          get: NihongoStorage.getSpeechNetworkFallback,
          set: NihongoStorage.setSpeechNetworkFallback,
        ),
        'aiAssistEnabled': (
          get: NihongoStorage.getAiAssistEnabled,
          set: NihongoStorage.setAiAssistEnabled,
        ),
        'preferFastModel': (
          get: NihongoStorage.getPreferFastModel,
          set: NihongoStorage.setPreferFastModel,
        ),
        'debugMode': (
          get: NihongoStorage.getDebugMode,
          set: NihongoStorage.setDebugMode,
        ),
      };
  for (final entry in offByDefault.entries) {
    test(
      '${entry.key} is off until turned on, and off removes the key',
      () async {
        final key = entry.key;
        expect(await entry.value.get(), isFalse);
        await entry.value.set(true);
        expect(await entry.value.get(), isTrue);
        expect((await config())[key], isTrue);
        await entry.value.set(false);
        expect((await config()).containsKey(key), isFalse);
        expect(await entry.value.get(), isFalse);
        // A hand-edited string must not switch it on.
        await configFile.writeAsString('{"$key": "true"}');
        expect(await entry.value.get(), isFalse);
      },
    );
  }

  test('a locale with a country round trips', () async {
    // Traditional and Simplified Chinese differ only by the country here, so
    // a tag written without one would move a reader to the other language.
    expect(await NihongoStorage.getLocaleTag(), isNull);
    await NihongoStorage.setLocaleTag('zh_TW');
    expect(await NihongoStorage.getLocaleTag(), 'zh_TW');
    expect((await config())['locale'], 'zh_TW');
    await NihongoStorage.setLocaleTag(null);
    expect((await config()).containsKey('locale'), isFalse);
  });

  test('developer options are off until they are unlocked', () async {
    expect(await NihongoStorage.getDebugMode(), isFalse);
    await NihongoStorage.setDebugMode(true);
    expect(await NihongoStorage.getDebugMode(), isTrue);
    expect((await config())['debugMode'], isTrue);
  });

  test('turning developer options off removes the key', () async {
    await NihongoStorage.setDebugMode(true);
    await NihongoStorage.setDebugMode(false);
    expect((await config()).containsKey('debugMode'), isFalse);
    expect(await NihongoStorage.getDebugMode(), isFalse);
  });

  test('a hand-edited string does not unlock developer options', () async {
    await configFile.writeAsString('{"debugMode": "true"}');
    expect(await NihongoStorage.getDebugMode(), isFalse);
  });

  test('a damaged config file reads as unset instead of throwing', () async {
    // The getters run before the first frame, so a config that is not JSON, or
    // is JSON but not an object, must not stop the app opening. `readConfig`
    // itself stays strict: the sync adapter and every setter go through it and
    // must not write over a file they could not read.
    for (final damaged in ['{not json', '[1]', '"text"', '  ']) {
      await configFile.writeAsString(damaged);
      expect(await NihongoStorage.getLastTab(), isNull, reason: damaged);
      expect(await NihongoStorage.getThemeMode(), isNull, reason: damaged);
      expect(await NihongoStorage.getLocaleTag(), isNull, reason: damaged);
      expect(await NihongoStorage.getTtsRate(), isNull, reason: damaged);
      expect(await NihongoStorage.getShowFurigana(), isTrue, reason: damaged);
      expect(await NihongoStorage.getDebugMode(), isFalse, reason: damaged);
      expect(NihongoStorage.readConfig(), throwsA(anything), reason: damaged);
    }
  });

  test('a wrong-typed theme or locale reads as unset', () async {
    await configFile.writeAsString('{"themeMode": 3, "locale": true}');
    expect(await NihongoStorage.getThemeMode(), isNull);
    expect(await NihongoStorage.getLocaleTag(), isNull);
  });

  test('two preferences set at once both survive', () async {
    // Every setter reads the whole file, changes one key and writes it back.
    // Two of those running at once used to read the same file and write two
    // different successors, so whichever finished second erased the other's
    // key — and on Windows the second write renamed its temporary file over
    // one the first still had open, which threw rather than losing quietly.
    // The Settings page fires these without awaiting, so "at once" is what
    // a person toggling two switches actually does.
    await Future.wait([
      NihongoStorage.setThemeMode('dark'),
      NihongoStorage.setLastTab('kana'),
      NihongoStorage.setDebugMode(true),
      NihongoStorage.setReferenceListColumns(3),
    ]);
    final saved = await config();
    expect(saved['themeMode'], 'dark');
    expect(saved['lastTab'], 'kana');
    expect(saved['debugMode'], isTrue);
    expect(saved['referenceListColumns'], 3);
  });
}

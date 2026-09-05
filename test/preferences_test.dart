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

  test('the speaking rate round trips as a number', () async {
    expect(await NihongoStorage.getTtsRate(), isNull);
    await NihongoStorage.setTtsRate(0.8);
    expect(await NihongoStorage.getTtsRate(), 0.8);
    expect((await config())['ttsRate'], 0.8);
  });

  test('a whole-number rate written by hand still reads', () async {
    await configFile.writeAsString('{"ttsRate": 1}');
    expect(await NihongoStorage.getTtsRate(), 1.0);
  });

  test('clearing the rate removes the key', () async {
    await NihongoStorage.setTtsRate(0.8);
    await NihongoStorage.setTtsRate(null);
    expect((await config()).containsKey('ttsRate'), isFalse);
  });

  test('a rate of the wrong type reads as unset', () async {
    await configFile.writeAsString('{"ttsRate": "fast"}');
    expect(await NihongoStorage.getTtsRate(), isNull);
  });

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

  test('network speech recognition is off unless it was turned on', () async {
    expect(await NihongoStorage.getSpeechNetworkFallback(), isFalse);
    await NihongoStorage.setSpeechNetworkFallback(true);
    expect(await NihongoStorage.getSpeechNetworkFallback(), isTrue);
    expect((await config())['speechNetworkFallback'], isTrue);
  });

  test('turning the network fallback off removes the key', () async {
    await NihongoStorage.setSpeechNetworkFallback(true);
    await NihongoStorage.setSpeechNetworkFallback(false);
    expect((await config()).containsKey('speechNetworkFallback'), isFalse);
    expect(await NihongoStorage.getSpeechNetworkFallback(), isFalse);
  });

  test('a hand-edited string does not switch the fallback on', () async {
    await configFile.writeAsString('{"speechNetworkFallback": "true"}');
    expect(await NihongoStorage.getSpeechNetworkFallback(), isFalse);
  });

  test('on-device AI is off until it is turned on', () async {
    expect(await NihongoStorage.getAiAssistEnabled(), isFalse);
    await NihongoStorage.setAiAssistEnabled(true);
    expect(await NihongoStorage.getAiAssistEnabled(), isTrue);
    expect((await config())['aiAssistEnabled'], isTrue);
  });

  test('turning on-device AI off removes the key', () async {
    await NihongoStorage.setAiAssistEnabled(true);
    await NihongoStorage.setAiAssistEnabled(false);
    expect((await config()).containsKey('aiAssistEnabled'), isFalse);
    expect(await NihongoStorage.getAiAssistEnabled(), isFalse);
  });

  test('a hand-edited string does not switch on-device AI on', () async {
    await configFile.writeAsString('{"aiAssistEnabled": "true"}');
    expect(await NihongoStorage.getAiAssistEnabled(), isFalse);
  });

  test(
    'the faster on-device model is not preferred until it is asked for',
    () async {
      expect(await NihongoStorage.getPreferFastModel(), isFalse);
      await NihongoStorage.setPreferFastModel(true);
      expect(await NihongoStorage.getPreferFastModel(), isTrue);
      expect((await config())['preferFastModel'], isTrue);
    },
  );

  test('going back to the larger model removes the key', () async {
    await NihongoStorage.setPreferFastModel(true);
    await NihongoStorage.setPreferFastModel(false);
    expect((await config()).containsKey('preferFastModel'), isFalse);
    expect(await NihongoStorage.getPreferFastModel(), isFalse);
  });

  test('a hand-edited string does not switch the faster model on', () async {
    await configFile.writeAsString('{"preferFastModel": "true"}');
    expect(await NihongoStorage.getPreferFastModel(), isFalse);
  });

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
}

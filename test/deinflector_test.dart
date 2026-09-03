import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/models/function_word.dart';
import 'package:my_nihongo/features/sentence/services/deinflector.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';

/// Purpose: Test de-inflection against the shipped catalog.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Run against the real catalog on purpose. The whole design rests on
/// proposing several lemmas per stem and letting the dictionary reject the ones
/// that are not words — 飲ん proposes 飲ぬ, 飲ぶ and 飲む — and a fixture
/// dictionary would make that step vacuous.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Deinflector deinflector;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    final catalog = await ContentRepository.load();
    final words = await loadFunctionWords();
    deinflector = Deinflector(Lexicon.build(catalog, functionWords: words));
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  List<String> lemmas(String stem, StemShape shape) =>
      deinflector.stemsFor(stem, shape).map((s) => s.entry.lemma).toList();

  test('an ichidan masu-stem recovers its verb', () {
    expect(lemmas('食べ', StemShape.masuStem), contains('食べる'));
  });

  test('a godan masu-stem shifts the i-row back to the u-row', () {
    expect(lemmas('行き', StemShape.masuStem), contains('行く'));
    expect(lemmas('話し', StemShape.masuStem), contains('話す'));
    expect(lemmas('飲み', StemShape.masuStem), contains('飲む'));
  });

  test('a godan nai-stem shifts the a-row back, with wa for u-verbs', () {
    expect(lemmas('行か', StemShape.naiStem), contains('行く'));
    expect(lemmas('買わ', StemShape.naiStem), contains('買う'));
  });

  test('a voiced te-stem proposes three rows and keeps the real one', () {
    final found = lemmas('飲ん', StemShape.teStemVoiced);
    expect(found, contains('飲む'));
    expect(found, isNot(contains('飲ぬ')));
    expect(found, isNot(contains('飲ぶ')));
  });

  test('the small tsu te-stem covers u, tsu, ru and 行く', () {
    expect(lemmas('行っ', StemShape.teStem), contains('行く'));
    expect(lemmas('買っ', StemShape.teStem), contains('買う'));
  });

  test('an e-stem recovers a godan verb', () {
    expect(lemmas('行け', StemShape.eStem), contains('行く'));
  });

  test('する and 来る are recovered from their exact stems only', () {
    expect(lemmas('し', StemShape.masuStem), contains('する'));
    expect(lemmas('き', StemShape.masuStem), contains('来る'));
    // The bug this guards: an endsWith test made 映画を見まし de-inflect to
    // する, one edge swallowing half a sentence at the price of one verb.
    expect(lemmas('映画を見まし', StemShape.masuStem), isEmpty);
  });

  test('an adjective stem is recovered separately from verbs', () {
    expect(
      deinflector.adjectiveStemsFor('高').map((s) => s.entry.lemma),
      contains('高い'),
    );
    expect(
      deinflector.adjectiveStemsFor('忙し').map((s) => s.entry.lemma),
      contains('忙しい'),
    );
  });

  test('a stem that is not a word recovers nothing', () {
    expect(lemmas('ざざざ', StemShape.masuStem), isEmpty);
    expect(deinflector.adjectiveStemsFor('ざざざ'), isEmpty);
  });

  test('an empty stem recovers nothing', () {
    expect(lemmas('', StemShape.masuStem), isEmpty);
  });
}

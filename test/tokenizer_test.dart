import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/tokenizer.dart';

/// Purpose: Test the tokenizer against the shipped catalog.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Driven against the real 7,700-entry catalog rather than a fixture,
/// because the interesting failures are the ones a small dictionary cannot
/// produce: a particle that is also a noun, a verb stem that is also a word,
/// a conjugation whose de-inflection proposes three lemmas of which one is
/// real. A fixture catalog would pass while the app failed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Lexicon lexicon;
  late Tokenizer tokenizer;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    final catalog = await ContentRepository.load();
    final words = await loadFunctionWords();
    lexicon = Lexicon.build(catalog, functionWords: words);
    tokenizer = Tokenizer(lexicon);
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  List<String> surfaces(String text) =>
      tokenizer.tokenize(text).map((t) => t.surface).toList();

  List<String> lemmas(String text) =>
      tokenizer.tokenize(text).map((t) => t.lemma).toList();

  test('the function-word table loaded', () {
    expect(lexicon.functionWordsAt('は'), isNotEmpty);
    expect(lexicon.functionWordsAt('を'), isNotEmpty);
    expect(lexicon.functionWordTable.set('time-past'), contains('昨日'));
  });

  test('a plain noun-copula sentence splits into three', () {
    expect(surfaces('これは本です。'), ['これ', 'は', '本', 'です', '。']);
  });

  test('a particle wins over the noun that shares its surface', () {
    final tokens = tokenizer.tokenize('私は学生です。');
    final wa = tokens.firstWhere((t) => t.surface == 'は');
    expect(wa.category, TokenCategory.particleBinding);
    expect(wa.refId, 'fw:wa');
  });

  test('a polite past verb is a stem plus its auxiliary', () {
    final tokens = tokenizer.tokenize('映画を見ました。');
    expect(tokens.map((t) => t.surface), ['映画', 'を', '見', 'ました', '。']);
    final verb = tokens[2];
    expect(verb.category, TokenCategory.verb);
    expect(verb.lemma, '見る');
    expect(verb.forms, contains(InflectionForm.masuStem));
  });

  test('a polite negative past recovers the dictionary form', () {
    expect(lemmas('食べませんでした'), ['食べる', 'ます']);
  });

  test('a godan negative recovers the right row', () {
    expect(lemmas('行かなかった'), ['行く', 'ない']);
  });

  test('a voiced te-form picks the only real lemma of three', () {
    // ん + で proposes 飲ぬ, 飲ぶ and 飲む; only 飲む is a word.
    expect(lemmas('飲んで'), ['飲む', 'て']);
  });

  test('an i-adjective negative is adjectival, not verbal', () {
    final tokens = tokenizer.tokenize('高くないです');
    expect(tokens.first.lemma, '高い');
    expect(tokens.first.category, TokenCategory.iAdjective);
  });

  test('an unknown katakana run is one token, not a failure', () {
    final tokens = tokenizer.tokenize('スミスさんです。');
    expect(tokens.first.surface, 'スミス');
    expect(tokens.first.category, TokenCategory.katakanaUnknown);
    expect(tokens.any((t) => t.category == TokenCategory.unknown), isFalse);
  });

  test('a number and its counter are separate tokens in order', () {
    final tokens = tokenizer.tokenize('三時');
    expect(tokens.first.category, TokenCategory.number);
  });

  test('a kana-only sentence still finds its words', () {
    expect(surfaces('わたしはがくせいです'), ['わたし', 'は', 'がくせい', 'です']);
  });

  test('full-width ASCII is normalized before tokenizing', () {
    expect(Tokenizer.normalize('ＡＢＣ１２３'), 'ABC123');
  });

  test('empty input yields no tokens', () {
    expect(tokenizer.tokenize('   '), isEmpty);
  });
}

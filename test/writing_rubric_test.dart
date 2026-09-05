import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';
import 'package:my_nihongo/features/writing/services/writing_rubric.dart';

/// Purpose: Test what the app says it measured about a piece of writing.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets to build a real analyser.
/// Notes: Run against the **real** analyser rather than a fixture, because the
/// whole value of the rubric is that it counts what the parser found: a word
/// used in an inflected form counts, and a hand-written fixture would let that
/// claim rot without any test noticing.
///
/// Nothing here asserts a total or a mark, because the rubric produces
/// neither. 作文 is not on the JLPT, and a score would be the app inventing an
/// exam nobody sits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late SentenceAnalyzer analyzer;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    analyzer = SentenceAnalyzer(
      lexicon: Lexicon.build(
        catalog,
        functionWords: await loadFunctionWords(),
      ),
      catalog: catalog,
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  WritingRubric rubricFor(
    List<String> sentences, {
    LessonUnit? unit,
    JlptLevel level = JlptLevel.n5,
  }) => WritingRubric.build(
    analyses: [for (final one in sentences) analyzer.analyze(one)],
    unit: unit,
    catalog: catalog,
    level: level,
  );

  test('nothing written is an empty rubric', () {
    expect(rubricFor(const []).isEmpty, isTrue);
    expect(rubricFor(const []).promptLines('N5'), isEmpty);
  });

  test('sentences are counted', () {
    final rubric = rubricFor(['本を読みます。', '毎日勉強します。']);
    expect(rubric.sentences, 2);
    expect(rubric.isEmpty, isFalse);
  });

  test('a word counts through its inflection, not its spelling', () {
    final entry = catalog.vocab.firstWhere((v) => v.reading == 'たべる');
    final unit = LessonUnit(
      id: 'unit:test',
      title: const LocalizedStrings({
        'en': ['test'],
      }),
      vocab: [entry.id],
    );
    final rubric = rubricFor(['ご飯を食べました。'], unit: unit);
    expect(
      rubric.wordsUsed,
      contains(entry.id),
      reason: 'somebody who wrote 食べました used 食べる',
    );
    expect(rubric.wordsWanted, 1);
  });

  test('the level share is measured against the target, not the hardest '
      'word', () {
    final easy = rubricFor(['本を読みます。'], level: JlptLevel.n5);
    expect(
      easy.levelShare,
      1,
      reason: 'every word here is N5, and the target is N5',
    );

    // The same sentence judged against N1 is still all at or below N1: the
    // measurement is "within your means", not "as hard as your level".
    final generous = rubricFor(['本を読みます。'], level: JlptLevel.n1);
    expect(generous.levelShare, 1);
  });

  test('nothing the catalog could place is a full share, not a zero', () {
    final rubric = WritingRubric.build(
      analyses: [analyzer.analyze('本を読みます。')],
      level: JlptLevel.n5,
    );
    expect(
      rubric.levelShare,
      1,
      reason: 'with no catalog it is the catalog that is missing, '
          'not the learner who is wrong',
    );
  });

  test('the prompt lines say what was measured and never give a mark', () {
    final lines = rubricFor(['本を読みます。']).promptLines('N5');
    expect(lines, isNotEmpty);
    expect(lines.first, contains('sentence'));
    for (final line in lines) {
      expect(
        line.toLowerCase(),
        isNot(anyOf(contains('score'), contains('mark'), contains('grade'))),
      );
    }
  });

  test('the word target is the one the writing page shows', () {
    expect(writingRubricWordTarget, 3);
    final rubric = WritingRubric.build(
      analyses: [analyzer.analyze('本を読みます。')],
      level: JlptLevel.n5,
    );
    expect(
      rubric.metWordTarget,
      isTrue,
      reason: 'an exercise with no unit asks for no words, so it is met',
    );
  });
}

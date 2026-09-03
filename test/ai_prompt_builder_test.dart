import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/prompt_builder.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/models/sentence_analysis.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

/// Purpose: Test what the on-device model is actually asked.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content and prompt assets.
/// Notes: Driven against the **shipped** templates and the shipped catalog, not
/// fixtures, for the same reason the analyser tests are: a prompt that works
/// against a fixture and not against the real content is a prompt that is
/// broken on every device. The properties that matter are that the issue text
/// goes in exactly as the app worded it, that the catalog's own grammar
/// explanation is what grounds the answer, and that every cap holds — a prompt
/// over the API's input limit fails on the device, where it is hardest to see.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  late PromptTemplates templates;
  late PromptBuilder builder;
  late ContentCatalog catalog;
  late SentenceAnalyzer analyzer;

  setUpAll(() async {
    templates = await loadPromptTemplates();
    builder = PromptBuilder(templates);
    catalog = await ContentRepository.load();
    final lexicon = await _lexicon(catalog);
    analyzer = SentenceAnalyzer(lexicon: lexicon, catalog: catalog);
  });

  test('the shipped templates load and carry every UI language', () {
    expect(templates.schemaVersion, greaterThan(0));
    for (final task in ['issue', 'sentence']) {
      expect(templates.tasks[task], isNotNull, reason: task);
      expect(templates.tasks[task]!.keys, containsAll(['en', 'zh', 'zh_TW']));
      for (final language in ['en', 'zh', 'zh_TW']) {
        expect(templates.tasks[task]![language]!.rules, isNotEmpty,
            reason: '$task/$language');
      }
    }
    expect(templates.labels.keys, containsAll(['en', 'zh', 'zh_TW']));
  });

  test('an issue prompt carries the sentence, the split and the message', () {
    final analysis = analyzer.analyze('私は昨日映画を見ます。');
    expect(analysis.issues, isNotEmpty, reason: 'the tense check should fire');

    const message = '昨日 points at another time than the verb form.';
    final prompt = builder.forIssue(
      analysis,
      analysis.issues.first,
      message,
      catalog,
      const Locale('en'),
    )!;

    expect(prompt, contains('私は昨日映画を見ます。'));
    expect(prompt, contains(message), reason: 'worded once, by the UI');
    expect(prompt, contains('昨日'));
    expect(prompt, contains('Rules'));
    expect(prompt, contains('Answer in English.'));
  });

  test('a Chinese prompt asks for Chinese', () {
    final analysis = analyzer.analyze('これは本です。');
    final prompt = builder.forSentence(analysis, catalog, const Locale('zh'))!;

    expect(prompt, contains('用简体中文回答。'));
    expect(prompt, isNot(contains('Answer in English.')));
  });

  test('a Traditional Chinese prompt asks for Traditional Chinese', () {
    final analysis = analyzer.analyze('これは本です。');
    final prompt = builder.forSentence(
      analysis,
      catalog,
      const Locale('zh', 'TW'),
    )!;

    expect(prompt, contains('用繁體中文回答。'));
    expect(prompt, isNot(contains('用简体中文回答。')));
  });

  test('a Traditional Chinese prompt quotes the Traditional grammar note', () {
    // The grounding has to follow the UI language all the way down: a prompt
    // that asks for Traditional Chinese while handing the model the Simplified
    // note is asking it to translate, which is not what it was told to do.
    final analysis = analyzer.analyze('これは本です。');
    final prompt = builder.forSentence(
      analysis,
      catalog,
      const Locale('zh', 'TW'),
    )!;
    final point = catalog.grammarById(analysis.grammar.first.pointId)!;
    final traditional = point.explanation.resolveJoined(
      const Locale('zh', 'TW'),
    );
    final simplified = point.explanation.resolveJoined(const Locale('zh'));

    expect(traditional, isNot(simplified), reason: 'the fixture must differ');
    expect(prompt, contains(traditional.substring(0, 12)));
  });

  test('an unknown language falls back to English rather than failing', () {
    final analysis = analyzer.analyze('これは本です。');
    final prompt = builder.forSentence(analysis, catalog, const Locale('de'));

    expect(prompt, isNotNull);
    expect(prompt, contains('Answer in English.'));
  });

  test('the prompt is grounded in the catalog own grammar explanation', () {
    final analysis = analyzer.analyze('これは本です。');
    expect(analysis.grammar, isNotEmpty, reason: 'です should match a point');
    final point = catalog.grammarById(analysis.grammar.first.pointId)!;

    final prompt = builder.forSentence(analysis, catalog, const Locale('en'))!;

    expect(prompt, contains(point.pattern));
    final explanation = point.explanation.resolveJoined(const Locale('en'));
    expect(
      prompt,
      contains(explanation.substring(0, explanation.length.clamp(0, 40))),
      reason: 'the app teaching text is what the model must not contradict',
    );
  });

  test('no catalog still produces a usable prompt', () {
    final analysis = analyzer.analyze('これは本です。');
    final prompt = builder.forSentence(analysis, null, const Locale('en'));

    expect(prompt, isNotNull);
    expect(prompt, contains('これは本です。'));
  });

  test('at most three grammar points are quoted, each capped', () {
    final analysis = analyzer.analyze('私は昨日本を読みましたが、まだ終わっていません。');
    final prompt = builder.forSentence(analysis, catalog, const Locale('en'))!;

    final quoted = '\n'.allMatches(prompt).length;
    expect(quoted, greaterThan(0));
    final maxPoints = templates.limit('maxGrammarPoints', 3);
    final bulletLines = prompt
        .split('\n')
        .where((line) => line.startsWith('- ') && line.contains(': '))
        .toList();
    // The rules are bullets too, so the grammar bullets are what is left after
    // removing them; the count that matters is that it cannot run away.
    expect(bulletLines.length, lessThanOrEqualTo(maxPoints + 8));
    for (final line in bulletLines) {
      expect(
        line.length,
        lessThanOrEqualTo(templates.limit('maxGrammarExcerptChars', 300) + 60),
      );
    }
  });

  test('every prompt stays inside the input cap', () {
    final cap = templates.limit('maxPromptChars', 4000);
    for (final sentence in [
      'これは本です。',
      '私は昨日映画を見ました。',
      '毎朝六時に起きて、コーヒーを飲みながら新聞を読みます。',
      '学生です。' * 40,
    ]) {
      final analysis = analyzer.analyze(sentence);
      for (final prompt in [
        builder.forSentence(analysis, catalog, const Locale('en')),
        builder.forSentence(analysis, catalog, const Locale('zh')),
      ]) {
        expect(prompt!.length, lessThanOrEqualTo(cap + 1), reason: sentence);
      }
    }
  });

  test('proofreading refuses a sentence that is too long to send', () {
    final cap = templates.limit('maxProofreadChars', 200);
    expect(builder.forProofreading('これは本です。'), 'これは本です。');
    expect(builder.forProofreading('  '), isNull);
    expect(builder.forProofreading('あ' * (cap + 1)), isNull);
    expect(builder.forProofreading('あ' * cap), isNotNull);
  });

  test('empty templates produce no prompt at all', () {
    const empty = PromptBuilder(PromptTemplates.empty);
    final analysis = analyzer.analyze('これは本です。');

    expect(empty.forSentence(analysis, catalog, const Locale('en')), isNull);
    expect(
      empty.forIssue(
        analysis,
        const Issue(kind: IssueKind.missingCopula, first: 0, last: 0),
        'message',
        catalog,
        const Locale('en'),
      ),
      isNull,
    );
  });
}

/// Purpose: Build the lexicon the analyser needs.
/// Inputs: The `catalog`.
/// Returns: `Future<Lexicon>`.
/// Side effects: Reads the function-word asset.
/// Notes: Test-only helper; the real app gets this from `lexiconProvider`.
Future<Lexicon> _lexicon(ContentCatalog catalog) async =>
    Lexicon.build(catalog, functionWords: await loadFunctionWords());

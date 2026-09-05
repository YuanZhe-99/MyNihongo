import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/ai_assist_service.dart';
import 'package:my_nihongo/features/ai/services/ai_practice_service.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';
import 'package:my_nihongo/features/ai/services/practice_prompt_builder.dart';
import 'package:my_nihongo/features/ai/services/practice_response_parser.dart';
import 'package:my_nihongo/features/ai/services/prompt_builder.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';

/// Purpose: Test the practice prompts, the replies they are given, and the
/// order two features take turns in.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled prompt asset and content assets.
/// Notes: The model itself is not tested — it cannot be. What is tested is
/// everything around it: that a prompt is grounded in something the app
/// already computed, that a reply which ignored the format is refused rather
/// than half-read, and that a background job gets out of an interactive one's
/// way. **A refusal is the important case.** A half-parsed rewrite or a
/// mangled example sentence is shown beside the catalog's own and looks
/// exactly as authoritative.
class _FakeBackend extends GenAiBackend {
  _FakeBackend();

  String reply = 'ok';
  int calls = 0;

  /// The answer length the last call asked the platform for.
  int? lastMaxOutputTokens;
  int busyFor = 0;
  final order = <String>[];

  @override
  Future<GenAiStatus> status(GenAiFeature feature) async =>
      GenAiStatus.available;

  @override
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  }) async => true;

  @override
  Future<String> explain(String prompt, {int maxOutputTokens = 256}) async {
    calls++;
    lastMaxOutputTokens = maxOutputTokens;
    order.add(prompt.split('\n').first);
    if (busyFor > 0) {
      busyFor--;
      throw const GenAiException(GenAiFailure.busy);
    }
    return reply;
  }

  @override
  Future<List<String>> proofread(String text) async => const [];

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PromptTemplates templates;
  late ContentCatalog catalog;
  const en = Locale('en');

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    templates = PromptTemplates.fromJson(
      jsonDecode(File(practicePromptAsset).readAsStringSync()),
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  group('the prompts', () {
    late PracticePromptBuilder builder;
    setUp(() => builder = PracticePromptBuilder(templates));

    test('a writing prompt carries the learner text and the unit words', () {
      final prompt = builder.forWriting(
        '毎日日本語を勉強します。',
        unitWords: catalog.vocab.take(3).toList(),
        grammarNotes: const ['ます makes a polite statement.'],
        locale: en,
      );
      expect(prompt, isNotNull);
      expect(prompt, contains('毎日日本語を勉強します。'));
      expect(prompt, contains('ます makes a polite statement.'));
      expect(prompt, contains('Rewrite: '));
    });

    test('writing too long is refused rather than cut', () {
      // A rewrite of half a paragraph is not a rewrite, and a learner who
      // cannot see where it was cut cannot tell why the feedback stops.
      final long = 'あ' * (templates.limit('maxWritingChars', 600) + 1);
      expect(builder.forWriting(long, locale: en), isNull);
      expect(builder.forWriting('   ', locale: en), isNull);
    });

    test('a why-wrong prompt carries the question exactly as worded', () {
      final prompt = builder.forWhyWrong(
        question: 'これ＿＿本です。',
        chosen: 'が',
        correct: 'は',
        grammarNote: 'は marks the topic.',
        locale: en,
      );
      expect(prompt, contains('これ＿＿本です。'));
      expect(prompt, contains('が'));
      expect(prompt, contains('は marks the topic.'));
    });

    test('a grading prompt refuses an answer that is not one', () {
      expect(builder.forGrading('', 'x', locale: en), isNull);
      expect(builder.forGrading('x' * 500, 'y', locale: en), isNull);
      expect(builder.forGrading('はい', 'ええ', locale: en), isNotNull);
    });

    test('an examples prompt names the word, its reading and its level', () {
      final entry = catalog.vocab.firstWhere((v) => v.hasKanji);
      final prompt = builder.forExamples(entry, locale: en)!;
      expect(prompt, contains(entry.headword));
      expect(prompt, contains(entry.reading));
      expect(prompt, contains(entry.level.label));
    });

    test('no templates means no prompts, not empty ones', () {
      const empty = PracticePromptBuilder(PromptTemplates.empty);
      expect(empty.forWriting('あ', locale: en), isNull);
      expect(empty.forGrading('あ', 'い', locale: en), isNull);
      expect(
        empty.forWhyWrong(question: 'q', chosen: 'a', correct: 'b', locale: en),
        isNull,
      );
    });

    test('Chinese asks in Chinese', () {
      final prompt = builder.forWriting('毎日走ります。', locale: const Locale('zh'))!;
      expect(prompt, contains('简体中文'));
    });
  });

  group('the replies', () {
    test('a rewrite and its notes are read', () {
      final feedback = PracticeResponseParser.writing(
        'Rewrite: 毎日日本語を勉強しています。\n'
        'Note: 〜ています fits an ongoing habit better.\n'
        'Note: The particle is right.\n',
      )!;
      expect(feedback.rewrite, '毎日日本語を勉強しています。');
      expect(feedback.notes, hasLength(2));
    });

    test('a reply with no rewrite line is refused', () {
      expect(
        PracticeResponseParser.writing('Here is what I think about it.'),
        isNull,
        reason: 'the rewrite is the only part a learner can act on',
      );
    });

    test('more notes than the cap are trimmed to the first few', () {
      final feedback = PracticeResponseParser.writing(
        'Rewrite: あ\nNote: 1\nNote: 2\nNote: 3\nNote: 4\nNote: 5',
      )!;
      expect(feedback.notes, hasLength(PracticeResponseParser.maxNotes));
    });

    test('a full-width colon is still a label', () {
      expect(
        PracticeResponseParser.writing('Rewrite：毎日走ります。')?.rewrite,
        '毎日走ります。',
      );
    });

    test('a verdict is read from the first line only', () {
      expect(PracticeResponseParser.grade('SAME\nClose enough.')?.same, isTrue);
      expect(
        PracticeResponseParser.grade('DIFFERENT\nThe tense differs.')?.same,
        isFalse,
      );
      expect(
        PracticeResponseParser.grade('DIFFERENT\nThe tense differs.')?.comment,
        'The tense differs.',
      );
    });

    test('a verdict that hedges into a paragraph is refused', () {
      expect(
        PracticeResponseParser.grade('Well, it depends on what you mean.'),
        isNull,
        reason: 'the learner marks it themselves rather than being guessed at',
      );
    });

    test('example lines need exactly three fields', () {
      final examples = PracticeResponseParser.examples(
        '本を読みます。|ほんをよみます。|I read a book.\n'
        'broken line with no bars\n'
        'a|b|c|d\n'
        '水を飲みます。|みずをのみます。|I drink water.\n',
        language: 'en',
      );
      expect(examples, hasLength(2));
      expect(examples.first.ja, '本を読みます。');
      expect(examples.first.reading, 'ほんをよみます。');
      expect(
        examples.first.translations.resolve(en),
        contains('I read a book.'),
      );
    });

    test('a full-width bar works too, and the limit is honoured', () {
      final examples = PracticeResponseParser.examples(
        'あ｜あ｜a\nい｜い｜b\nう｜う｜c\nえ｜え｜d\n',
        language: 'en',
        limit: 2,
      );
      expect(examples, hasLength(2));
    });
  });

  group('taking turns', () {
    test('nothing is asked while the switch is off', () async {
      final backend = _FakeBackend();
      final assist = AiAssistService(backend: backend);
      final practice = AiPracticeService(assist: assist);
      await expectLater(
        practice.run('anything'),
        throwsA(isA<GenAiException>()),
      );
      expect(backend.calls, 0, reason: 'off means nothing was asked');
    });

    test('two interactive requests both get an answer', () async {
      final backend = _FakeBackend();
      final assist = AiAssistService(backend: backend);
      await assist.setEnabled(true);
      final practice = AiPracticeService(assist: assist);
      final first = practice.run('first\nbody');
      final second = practice.run('second\nbody');
      expect(await first, 'ok');
      expect(await second, 'ok');
      expect(backend.order, ['first', 'second']);
    });

    test('a background job retries when the model is busy', () async {
      final backend = _FakeBackend()..busyFor = 1;
      final assist = AiAssistService(backend: backend);
      await assist.setEnabled(true);
      final practice = AiPracticeService(assist: assist);
      expect(await practice.runInBackground('bg\nbody'), 'ok');
      expect(backend.calls, 2);
    });

    test(
      'a background job gives up quietly rather than failing loudly',
      () async {
        final backend = _FakeBackend()..busyFor = 99;
        final assist = AiAssistService(backend: backend);
        await assist.setEnabled(true);
        final practice = AiPracticeService(assist: assist);
        expect(
          await practice.runInBackground('bg\nbody'),
          isNull,
          reason: 'nobody is waiting for it, so there is nobody to tell',
        );
      },
    );
  });

  group('the answer budget', () {
    test('the prompt asset decides how long an answer may be', () async {
      final backend = _FakeBackend();
      final assist = AiAssistService(backend: backend);
      await assist.setEnabled(true);
      final practice = AiPracticeService(assist: assist);
      await practice.run('ask', maxOutputTokens: 320);
      expect(backend.lastMaxOutputTokens, 320);
    });

    test('a background job carries the same budget', () async {
      final backend = _FakeBackend();
      final assist = AiAssistService(backend: backend);
      await assist.setEnabled(true);
      final practice = AiPracticeService(assist: assist);
      await practice.runInBackground('ask', maxOutputTokens: 320);
      expect(backend.lastMaxOutputTokens, 320);
    });
  });
  group('the shipped prompt asset', () {
    // Nothing checked this file for completeness, and that is how `forExamples`
    // came to ask for the labels `sentence` and `expected` — which exist, so
    // nothing fell back and nothing failed, and the prompt announced a single
    // word as "Sentence:" and its gloss as "The model answer:".
    test('every task is written in all three languages', () {
      for (final task in const [
        'writing',
        'grade',
        'whyWrong',
        'examples',
        'quiz',
      ]) {
        for (final language in const ['en', 'zh', 'zh_TW']) {
          final template = templates.tasks[task]?[language];
          expect(
            template?.instruction,
            isNotNull,
            reason: '$task has no $language instruction',
          );
          expect(
            template?.rules,
            isNotEmpty,
            reason: '$task has no $language rules',
          );
        }
      }
    });

    test('every label a builder asks for exists in all three languages', () {
      // The list the builders actually index. A key missing here is invisible
      // at run time — the `??` fallbacks hide it — so it has to be checked.
      for (final label in const [
        'sentence',
        'words',
        'note',
        'grammar',
        'rules',
        'learner',
        'expected',
        'vocabulary',
        'question',
        'chosen',
        'correct',
        'options',
        'topic',
        'word',
        'meaning',
        'level',
      ]) {
        for (final language in const ['en', 'zh', 'zh_TW']) {
          expect(
            templates.labels[language]?[label],
            isNotNull,
            reason: '$language is missing the label "$label"',
          );
        }
      }
    });

    test('an example prompt calls a word a word', () {
      final builder = PracticePromptBuilder(templates);
      final entry = catalog.vocab.firstWhere((v) => v.hasKanji);
      final prompt = builder.forExamples(entry, locale: en)!;
      expect(prompt, contains('Word: '));
      expect(prompt, contains('What it means: '));
      expect(
        prompt,
        isNot(contains('The model answer')),
        reason: 'a word gloss is not a model answer to anything',
      );
    });
  });

  group('packaging around an example line', () {
    List<ContentExample> parse(String raw) =>
        PracticeResponseParser.examples(raw, language: 'en');

    test('a Markdown table row is read, not refused', () {
      // The shape a model reaches for when asked for bar-separated fields, and
      // the reason this returned nothing at all on a Pixel 10 while the model
      // was answering perfectly well.
      final out = parse('| 本を読みます。 | ほんをよみます。 | I read a book. |');
      expect(out, hasLength(1));
      expect(out.first.ja, '本を読みます。');
      expect(out.first.reading, 'ほんをよみます。');
    });

    test('numbering, bullets and quotes are stripped', () {
      final out = parse(
        '1. 本を読みます。|ほんをよみます。|I read a book.\n'
        '- 水を飲みます。|みずをのみます。|I drink water.\n'
        '「山を見ます。|やまをみます。|I see a mountain.」',
      );
      expect(out, hasLength(3));
      expect(out.first.ja, '本を読みます。');
      expect(out.last.ja, '山を見ます。');
    });

    test('a code fence contributes nothing', () {
      final out = parse(
        '```\n本を読みます。|ほんをよみます。|I read a book.\n```',
      );
      expect(out, hasLength(1), reason: 'the fence lines are not examples');
    });

    test('an empty reading field means no reading, not a broken line', () {
      // Dropping an *outer* empty is unpacking a table row. A middle one is a
      // field that is really there and really empty, and the reading is the
      // one field this widget can do without.
      final out = parse('本を読みます。||I read a book.');
      expect(out, hasLength(1));
      expect(out.first.reading, isNull);
    });

    test('a line with four real fields is still refused', () {
      expect(parse('a|b|c|d'), isEmpty);
    });
  });
}

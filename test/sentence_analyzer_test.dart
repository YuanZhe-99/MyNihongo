import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/models/sentence_analysis.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

/// Purpose: Test the whole sentence pipeline against the shipped content.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: The load-bearing test is the last one: **every example sentence the
/// app ships has to parse without an unknown token.** Those sentences are the
/// ones a learner reads on the vocabulary and grammar pages, so a gap there is
/// a gap the learner will hit. It is also the test that catches a missing
/// function word, a wrong conjugation class and a lattice cost that stopped
/// preferring real words — none of which a hand-written fixture would notice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late SentenceAnalyzer analyzer;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    final words = await loadFunctionWords();
    analyzer = SentenceAnalyzer(
      lexicon: Lexicon.build(catalog, functionWords: words),
      catalog: catalog,
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  group('chunking', () {
    test('particles stay with the word before them', () {
      final result = analyzer.analyze('私は本を読みます。');
      final chunks = result.chunks.map(
        (c) => result.tokens
            .sublist(c.first, c.last + 1)
            .map((t) => t.surface)
            .join(),
      );
      expect(chunks, ['私は', '本を', '読みます']);
    });

    test('every chunk but the last attaches to a later one', () {
      final result = analyzer.analyze('私は昨日友達と映画を見ました。');
      for (var i = 0; i < result.chunks.length - 1; i++) {
        final target = result.chunks[i].dependsOn;
        expect(target, isNotNull);
        expect(target, greaterThan(i));
      }
      expect(result.chunks.last.dependsOn, isNull);
    });

    test('an adjective before a noun modifies the noun, not the verb', () {
      final result = analyzer.analyze('新しい映画を見ました。');
      final adjective = result.chunks.first;
      expect(result.tokens[adjective.head].lemma, '新しい');
      final target = result.chunks[adjective.dependsOn!];
      expect(result.tokens[target.head].surface, '映画');
    });

    test('a te-form auxiliary verb joins the verb before it', () {
      final result = analyzer.analyze('勉強しています。');
      expect(result.chunks.length, 1);
    });
  });

  group('grammar matching', () {
    test('a taught point in a plain sentence is found', () {
      final result = analyzer.analyze('これは本です。');
      expect(result.grammar.map((g) => g.pointId), contains('grammar:desu'));
    });

    test('a match has to fall on token boundaries', () {
      // はな contains は, but not as a particle, so 〜は must not match.
      final result = analyzer.analyze('はなを買いました。');
      final wa = result.grammar.where((g) => g.pointId == 'grammar:wa-topic');
      expect(wa, isEmpty);
    });

    test('a contained match is dropped in favour of the longer one', () {
      final result = analyzer.analyze('食べてもいいです。');
      final ids = result.grammar.map((g) => g.pointId).toList();
      expect(ids, isNotEmpty);
      // Whatever matched, no two matches may cover the same span.
      for (var i = 0; i < result.grammar.length; i++) {
        for (var j = i + 1; j < result.grammar.length; j++) {
          final a = result.grammar[i];
          final b = result.grammar[j];
          final contained = a.first <= b.first && a.last >= b.last;
          expect(contained && a.span > b.span, isFalse);
        }
      }
    });
  });

  group('checks', () {
    test('a correct sentence raises nothing', () {
      expect(analyzer.analyze('私は学生です。').issues, isEmpty);
      expect(analyzer.analyze('昨日映画を見ました。').issues, isEmpty);
      expect(analyzer.analyze('明日行きます。').issues, isEmpty);
    });

    test('a past time word with a non-past predicate is flagged', () {
      final result = analyzer.analyze('昨日映画を見ます。');
      expect(
        result.issues.map((i) => i.kind),
        contains(IssueKind.tenseTimeWord),
      );
    });

    test('a たい form is exempt from the tense check', () {
      final result = analyzer.analyze('明日映画を見たいです。');
      expect(
        result.issues.map((i) => i.kind),
        isNot(contains(IssueKind.tenseTimeWord)),
      );
    });

    test('a statement ending on a bare noun is flagged', () {
      final result = analyzer.analyze('私は学生');
      expect(
        result.issues.map((i) => i.kind),
        contains(IssueKind.missingCopula),
      );
    });

    test('a bare noun on its own is not flagged', () {
      expect(analyzer.analyze('学生').issues, isEmpty);
    });
  });

  test('the fixture line survives a round trip', () {
    final line = analyzer.analyze('これは本です。').toFixtureString();
    expect(line.split(' | ').length, 4);
    expect(line, contains('本'));
  });

  test('every shipped example sentence parses without an unknown token', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/sentence/allowed_unknown.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final allowed = {
      for (final entry in fixture['allowed'] as List)
        (entry as Map)['surface'] as String,
    };
    expect(
      allowed.length,
      lessThanOrEqualTo(fixture['max'] as int),
      reason: 'the allowed-unknown list may not grow past its own cap',
    );

    final failures = <String>[];
    var checked = 0;

    void check(String sentence, String id) {
      if (sentence.trim().isEmpty) return;
      checked++;
      final result = analyzer.analyze(sentence);
      final unknown = result.tokens
          .where(
            (t) =>
                t.category == TokenCategory.unknown &&
                !allowed.contains(t.surface),
          )
          .map((t) => t.surface)
          .join();
      if (unknown.isNotEmpty) failures.add('$id: $sentence → "$unknown"');
    }

    for (final point in catalog.grammar) {
      for (var i = 0; i < point.examples.length; i++) {
        check(point.examples[i].ja, '${point.id}#$i');
      }
    }
    for (final entry in catalog.vocab) {
      for (var i = 0; i < entry.examples.length; i++) {
        check(entry.examples[i].ja, '${entry.id}#$i');
      }
    }

    expect(checked, greaterThan(150), reason: 'the examples should be found');
    expect(
      failures,
      isEmpty,
      reason:
          'These sentences contain characters no catalog word, function word '
          'or katakana run explains. Each is a gap in the vocabulary or the '
          'function-word table:\n${failures.take(30).join('\n')}',
    );
  });
}

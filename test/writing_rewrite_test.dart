import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/genai_backend.dart';
import 'package:my_nihongo/features/ai/services/writing_rewrite.dart';
import 'package:my_nihongo/features/sentence/models/sentence_analysis.dart';

/// Purpose: Test the proofreader path writing practice takes on a device whose
/// only on-device model is the proofreader.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; the enhancer is a fake.
/// Notes: Two properties matter. The requests are **sequential**, because AICore
/// serves one inference at a time and a parallel batch would fail every sentence
/// after the first; and a piece of writing the model left alone comes back as
/// null rather than as itself, because offering an unchanged rewrite tells the
/// learner their correct writing was wrong.
class _FakeEnhancer implements SentenceEnhancer {
  _FakeEnhancer(this.answers, {this.throwFor});

  /// Keyed by the normalized sentence; a missing or null value means the model
  /// suggested nothing different.
  final Map<String, String?> answers;

  /// A sentence that makes the model fail.
  final String? throwFor;

  /// How many requests were in flight at once, at the highest.
  int peakConcurrency = 0;
  int _inFlight = 0;
  final List<String> asked = [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> explain(
    SentenceAnalysis analysis,
    Issue? issue,
    String? issueMessage,
    Locale locale,
  ) async => throw UnimplementedError('the Prompt API is not available here');

  @override
  Future<String?> suggestCorrection(SentenceAnalysis analysis) async {
    _inFlight++;
    peakConcurrency = _inFlight > peakConcurrency ? _inFlight : peakConcurrency;
    asked.add(analysis.normalized);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _inFlight--;
    if (analysis.normalized == throwFor) {
      throw const GenAiException(GenAiFailure.tooLong);
    }
    return answers[analysis.normalized];
  }
}

SentenceAnalysis analysisOf(String text) => SentenceAnalysis(
  input: text,
  normalized: text,
  tokens: const [],
  chunks: const [],
  grammar: const [],
  issues: const [],
);

void main() {
  test('an empty list asks nothing and answers nothing', () async {
    final enhancer = _FakeEnhancer(const {});
    expect(await proofreadSentences(enhancer, const []), isNull);
    expect(enhancer.asked, isEmpty);
  });

  test('a corrected sentence comes back, joined in order', () async {
    final enhancer = _FakeEnhancer({
      '私は学生です。': '私は学生です。',
      'これわ本です。': 'これは本です。',
    });
    final out = await proofreadSentences(enhancer, [
      analysisOf('私は学生です。'),
      analysisOf('これわ本です。'),
    ]);
    expect(out, '私は学生です。これは本です。');
  });

  test('a sentence the model left alone is carried through unchanged', () async {
    final enhancer = _FakeEnhancer({'これわ本です。': 'これは本です。'});
    final out = await proofreadSentences(enhancer, [
      analysisOf('私は学生です。'),
      analysisOf('これわ本です。'),
    ]);
    expect(out, '私は学生です。これは本です。');
  });

  test('nothing changed anywhere answers null, not the input', () async {
    final enhancer = _FakeEnhancer(const {});
    final out = await proofreadSentences(enhancer, [
      analysisOf('私は学生です。'),
      analysisOf('これは本です。'),
    ]);
    expect(out, isNull);
  });

  test('a blank suggestion counts as no suggestion', () async {
    final enhancer = _FakeEnhancer({'私は学生です。': '   '});
    expect(
      await proofreadSentences(enhancer, [analysisOf('私は学生です。')]),
      isNull,
    );
  });

  test('the sentences are proofread one at a time', () async {
    final enhancer = _FakeEnhancer(const {});
    await proofreadSentences(enhancer, [
      analysisOf('一つ。'),
      analysisOf('二つ。'),
      analysisOf('三つ。'),
    ]);
    expect(enhancer.peakConcurrency, 1);
    expect(enhancer.asked, ['一つ。', '二つ。', '三つ。']);
  });

  test('a failure is passed up rather than swallowed', () async {
    final enhancer = _FakeEnhancer(const {}, throwFor: '長すぎる。');
    expect(
      () => proofreadSentences(enhancer, [analysisOf('長すぎる。')]),
      throwsA(
        isA<GenAiException>().having(
          (e) => e.failure,
          'failure',
          GenAiFailure.tooLong,
        ),
      ),
    );
  });
}

/// Purpose: Turn a catalog item into a question, in whichever mode fits it.
/// Inputs: The catalog, the function-word table, an optional sentence analyser,
/// and a random source.
/// Returns: A `QuizQuestion`, or null when this item cannot support this mode.
/// Side effects: None.
/// Notes: **Returning null is the normal case, not an error.** Most words have
/// no kanji, so the two written-form modes do not apply; most have no example
/// sentence, so the grammar modes do not; and a word whose level is thin may not
/// have three plausible distractors. The caller asks for what it wants and takes
/// what it gets, which is why every mode is attempted per item rather than
/// chosen up front.
library;

import 'dart:math';
import 'dart:ui';

import '../../content/models/content_catalog.dart';
import '../../content/models/grammar_point.dart';
import '../../content/models/localized_strings.dart';
import '../../content/models/vocab_entry.dart';
import '../../kana/models/kana.dart';
import '../../kana/models/kana_text.dart';
import '../../kana/models/romaji.dart';
import '../../progress/models/study_record.dart';
import '../../sentence/models/sentence_analysis.dart';
import '../../sentence/models/token.dart';
import '../../sentence/services/conjugator.dart';
import '../../sentence/services/lexicon.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../content/services/furigana_aligner.dart';
import '../models/quiz_question.dart';
import 'distractors.dart';

/// The character a blanked-out particle is replaced with.
const particleBlank = '＿＿';

/// How many fragments an ordering question needs to be worth asking.
const minOrderFragments = 3;

/// Builds questions from catalog items.
class QuestionGenerator {
  /// Purpose: Create a generator.
  /// Inputs: `catalog`; `analyzer` — needed only for the grammar modes;
  /// `random`.
  /// Returns: A new `QuestionGenerator` instance.
  /// Side effects: None.
  /// Notes: The analyser is optional because it is expensive to build and three
  /// of the four grammar modes are the only things that need it. Without one,
  /// those modes simply produce nothing.
  QuestionGenerator({required this.catalog, this.analyzer, Random? random})
    : _random = random ?? Random(),
      _distractors = Distractors(catalog, random: random);

  /// The bundled content.
  final ContentCatalog catalog;

  /// The sentence analyser, or null where the grammar modes are unavailable.
  final SentenceAnalyzer? analyzer;

  final Random _random;
  final Distractors _distractors;
  final Conjugator _conjugator = const Conjugator();

  /// Purpose: Build one question about one item in one mode.
  /// Inputs: `itemId`, `mode`, `locale`, and `script` for kana questions.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: The mode and the item have to agree — a kana mode asked about a
  /// word returns null rather than guessing what was meant.
  QuizQuestion? generate(
    String itemId,
    QuizMode mode, {
    required Locale locale,
    KanaScript script = KanaScript.hiragana,
  }) {
    final kind = studyKindOf(itemId);
    if (kanaQuizModes.contains(mode)) {
      if (kind != StudyKind.kana) return null;
      final entry = kanaEntryById(itemId);
      return entry == null ? null : _kana(entry, mode, script);
    }
    if (vocabQuizModes.contains(mode)) {
      if (kind != StudyKind.vocab) return null;
      final entry = catalog.vocabById(itemId);
      return entry == null ? null : _vocab(entry, mode, locale);
    }
    if (grammarQuizModes.contains(mode)) {
      if (kind != StudyKind.grammar) return null;
      final point = catalog.grammarById(itemId);
      return point == null ? null : _grammar(point, mode, locale);
    }
    return null;
  }

  /// Purpose: Build a question about an item in whichever enabled mode works.
  /// Inputs: `itemId`, the `modes` enabled, `locale`, `script`.
  /// Returns: `QuizQuestion?` — null when no enabled mode fits this item.
  /// Side effects: None.
  /// Notes: The modes are tried in a shuffled order so the same word is not
  /// always asked the same way, and the first that produces a question wins.
  QuizQuestion? forItem(
    String itemId,
    Set<QuizMode> modes, {
    required Locale locale,
    KanaScript script = KanaScript.hiragana,
  }) {
    final candidates = modes.toList()..shuffle(_random);
    for (final mode in candidates) {
      final question = generate(itemId, mode, locale: locale, script: script);
      if (question != null) return question;
    }
    return null;
  }

  // ── Kana ──

  /// Purpose: Build a kana question.
  /// Inputs: `entry`, `mode`, `script`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Romaji options are
  /// deduplicated by the distractor picker, because じ and ぢ share "ji" and a
  /// question offering both has two correct answers.
  QuizQuestion? _kana(KanaEntry entry, QuizMode mode, KanaScript script) {
    final wrong = _distractors.forKana(entry);
    if (wrong.length < distractorCount) return null;
    final shown = entry.kana(script);

    switch (mode) {
      case QuizMode.kanaToRomaji:
        return _choice(
          itemId: entry.progressId,
          mode: mode,
          prompt: shown,
          correct: entry.romaji,
          wrong: wrong.map((k) => k.romaji).toList(),
          speakText: entry.hiragana,
        );
      case QuizMode.romajiToKana:
        return _choice(
          itemId: entry.progressId,
          mode: mode,
          prompt: entry.romaji,
          correct: shown,
          wrong: wrong.map((k) => k.kana(script)).toList(),
        );
      case QuizMode.kanaListening:
        return _choice(
          itemId: entry.progressId,
          mode: mode,
          // Nothing to read: the question is what was heard.
          prompt: '',
          correct: shown,
          wrong: wrong.map((k) => k.kana(script)).toList(),
          speakText: entry.hiragana,
        );
      default:
        return null;
    }
  }

  // ── Vocabulary ──

  /// Purpose: Build a vocabulary question.
  /// Inputs: `entry`, `mode`, `locale`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The two written-form
  /// modes are skipped for a word with no kanji, where the question would show
  /// the same string as its answer.
  QuizQuestion? _vocab(VocabEntry entry, QuizMode mode, Locale locale) {
    final meaning = entry.meanings.resolve(locale);
    if (meaning.isEmpty) return null;

    switch (mode) {
      case QuizMode.vocabJaToMeaning:
      case QuizMode.vocabListening:
        final wrong = _distractors.forMeaning(entry, locale: locale);
        if (wrong.length < distractorCount) return null;
        final listening = mode == QuizMode.vocabListening;
        return _choice(
          itemId: entry.id,
          mode: mode,
          prompt: listening ? '' : entry.headword,
          // The reading is printed over the word when it aligns; the subtitle
          // is the fallback for a word it cannot be aligned with, so the
          // reading is shown exactly once either way.
          promptReading: listening ? null : entry.reading,
          promptSubtitle:
              listening ||
                  entry.reading == entry.headword ||
                  alignFurigana(entry.headword, entry.reading) != null
              ? null
              : entry.reading,
          correct: meaning.first,
          wrong: [
            for (final other in wrong) other.meanings.resolve(locale).first,
          ],
          speakText: entry.reading,
        );

      case QuizMode.vocabMeaningToJa:
        final wrong = _distractors.forMeaning(entry, locale: locale);
        if (wrong.length < distractorCount) return null;
        return _choice(
          itemId: entry.id,
          mode: mode,
          prompt: meaning.first,
          correct: entry.headword,
          wrong: [for (final other in wrong) other.headword],
          speakText: entry.reading,
        );

      case QuizMode.vocabReadingToKanji:
        if (!entry.hasKanji) return null;
        final wrong = _distractors.forWriting(entry);
        if (wrong.length < distractorCount) return null;
        return _choice(
          itemId: entry.id,
          mode: mode,
          prompt: entry.reading,
          promptSubtitle: meaning.first,
          correct: entry.headword,
          wrong: [for (final other in wrong) other.headword],
          speakText: entry.reading,
        );

      case QuizMode.vocabKanjiToReading:
        if (!entry.hasKanji) return null;
        final wrong = _distractors.forWriting(entry);
        if (wrong.length < distractorCount) return null;
        return _choice(
          itemId: entry.id,
          mode: mode,
          prompt: entry.headword,
          correct: entry.reading,
          wrong: [for (final other in wrong) other.reading],
          speakText: entry.reading,
        );

      case QuizMode.vocabTypeReading:
        return QuizQuestion(
          itemId: entry.id,
          mode: mode,
          kind: AnswerKind.typed,
          prompt: entry.headword,
          promptSubtitle: meaning.first,
          speakText: entry.reading,
          // Both scripts of the answer are accepted: a learner typing on a
          // Japanese keyboard produces kana, one without an IME produces
          // romaji, and neither is a wrong answer to "how is this read".
          acceptedAnswers: {
            toHiragana(entry.reading),
            romajiFromKana(entry.reading),
          },
          options: [entry.reading],
          answerIndex: 0,
        );

      default:
        return null;
    }
  }

  // ── Grammar ──

  /// Purpose: Build a grammar question.
  /// Inputs: `point`, `mode`, `locale`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Three of the four modes
  /// need a parsed example sentence, so they need the analyser and an example;
  /// the pattern mode needs neither beyond the example itself.
  QuizQuestion? _grammar(GrammarPoint point, QuizMode mode, Locale locale) {
    if (point.examples.isEmpty) return null;
    final example = point.examples[_random.nextInt(point.examples.length)];
    final translation = example.translations.resolveJoined(locale);

    if (mode == QuizMode.grammarPattern) {
      return _pattern(point, example, translation);
    }

    final analysis = analyzer?.analyze(example.ja);
    if (analysis == null) return null;

    return switch (mode) {
      QuizMode.grammarParticle => _particle(
        point,
        analysis,
        example,
        translation,
      ),
      QuizMode.grammarConjugation => _conjugation(
        point,
        analysis,
        example,
        translation,
      ),
      QuizMode.grammarOrder => _order(point, analysis, translation),
      _ => null,
    };
  }

  /// Purpose: Blank out a particle and ask which one belongs there.
  /// Inputs: `point`, the parsed `analysis`, the `translation`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A particle the grammar
  /// point itself is about is preferred, so the question is about what the
  /// lesson taught rather than about whichever particle came first. The wrong
  /// options come from the function-word table, which is the app's own list of
  /// particles and therefore never offers something that is not one.
  QuizQuestion? _particle(
    GrammarPoint point,
    SentenceAnalysis analysis,
    ContentExample example,
    String translation,
  ) {
    final particles = analysis.tokens
        .where((t) => t.isParticle && t.surface.isNotEmpty)
        .toList();
    if (particles.isEmpty) return null;

    final preferred = particles
        .where((t) => point.matchForms.contains(t.surface))
        .toList();
    final target =
        (preferred.isEmpty ? particles : preferred)[_random.nextInt(
          (preferred.isEmpty ? particles : preferred).length,
        )];

    final wrong = _particleOptions(target.surface);
    if (wrong.length < distractorCount) return null;

    final blanked = analysis.normalized.replaceRange(
      target.start,
      target.end,
      particleBlank,
    );
    return _choice(
      itemId: point.id,
      mode: QuizMode.grammarParticle,
      prompt: blanked,
      promptReading: _blankedReading(
        analysis,
        example,
        target.start,
        target.end,
      ),
      promptSubtitle: translation.isEmpty ? null : translation,
      correct: target.surface,
      wrong: wrong,
    );
  }

  /// Purpose: List particles that are not this one.
  /// Inputs: The `correct` particle's surface.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Drawn from a fixed
  /// list of the particles an N5 learner meets rather than from the whole
  /// function-word table: a rare particle as a wrong option is not a mistake
  /// anybody would make, so it gives the answer away.
  List<String> _particleOptions(String correct) {
    const common = [
      'は',
      'が',
      'を',
      'に',
      'へ',
      'で',
      'と',
      'も',
      'の',
      'か',
      'から',
      'まで',
      'より',
      'ね',
      'よ',
    ];
    return (common.where((p) => p != correct).toList()..shuffle(_random))
        .take(distractorCount)
        .toList();
  }

  /// Purpose: Ask which inflected form belongs in a sentence.
  /// Inputs: `point`, `analysis`, `translation`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **An inflected form is
  /// several tokens, not one.** The analyser splits 食べます into 食べ, carrying
  /// the recovered masu-stem, and ます as its own auxiliary — that split is what
  /// makes parsing tractable — so the written form is the verb token plus every
  /// auxiliary that attaches behind it. The distractors are other real forms of
  /// the same word, built by the conjugator, so every option is Japanese and
  /// only one fits. A word whose class the lexicon does not know, or whose
  /// written form the conjugator cannot reproduce, is skipped: a question whose
  /// "correct" answer is not what the sentence says would teach the wrong thing.
  QuizQuestion? _conjugation(
    GrammarPoint point,
    SentenceAnalysis analysis,
    ContentExample example,
    String translation,
  ) {
    for (var i = 0; i < analysis.tokens.length; i++) {
      final head = analysis.tokens[i];
      if (head.forms.isEmpty || head.lemma.isEmpty) continue;
      final conj = _classOf(head);
      if (conj == null || conj == ConjClass.none) continue;

      // Take the auxiliaries that attach behind the verb; together they are the
      // written form the learner would have to produce.
      var last = i;
      final buffer = StringBuffer(head.surface);
      while (last + 1 < analysis.tokens.length) {
        final next = analysis.tokens[last + 1];
        if (next.category != TokenCategory.auxiliary &&
            next.category != TokenCategory.copula) {
          break;
        }
        buffer.write(next.surface);
        last++;
      }
      final written = buffer.toString();

      final forms = _conjugator.allForms(head.lemma, conj);
      if (forms.length < distractorCount + 1) continue;
      final match = forms.entries.where((e) => e.value == written).firstOrNull;
      if (match == null) continue;

      final wrong = forms.values.where((v) => v != match.value).toList()
        ..shuffle(_random);
      if (wrong.length < distractorCount) continue;

      final blanked = analysis.normalized.replaceRange(
        head.start,
        analysis.tokens[last].end,
        particleBlank,
      );
      return _choice(
        itemId: point.id,
        mode: QuizMode.grammarConjugation,
        prompt: blanked,
        promptReading: _blankedReading(
          analysis,
          example,
          head.start,
          analysis.tokens[last].end,
        ),
        promptSubtitle: translation.isEmpty ? null : translation,
        correct: match.value,
        wrong: wrong.take(distractorCount).toList(),
        formLabel: match.key.name,
      );
    }
    return null;
  }

  /// Purpose: Break a sentence into chunks and ask for their order.
  /// Inputs: `point`, `analysis`, `translation`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The fragments are the
  /// analyser's **bunsetsu**, which are the units a sentence is actually built
  /// from. Splitting on the reading would be wrong: kana readings have no word
  /// boundaries, so the pieces would not be pieces of anything.
  QuizQuestion? _order(
    GrammarPoint point,
    SentenceAnalysis analysis,
    String translation,
  ) {
    final fragments = <String>[];
    for (final chunk in analysis.chunks) {
      final text = analysis.tokens
          .sublist(chunk.first, chunk.last + 1)
          .map((t) => t.surface)
          .join();
      final trimmed = text.replaceAll(RegExp(r'[。、！？]$'), '');
      if (trimmed.isNotEmpty) fragments.add(trimmed);
    }
    if (fragments.length < minOrderFragments) return null;
    if (translation.isEmpty) return null;

    final order = List<int>.generate(fragments.length, (i) => i);
    final shuffled = [...order];
    // Shuffle until it is actually shuffled: a "puzzle" already in order is
    // solved by not touching it.
    for (var attempt = 0; attempt < 8; attempt++) {
      shuffled.shuffle(_random);
      if (!_sameOrder(shuffled, order)) break;
    }
    if (_sameOrder(shuffled, order)) return null;

    return QuizQuestion(
      itemId: point.id,
      mode: QuizMode.grammarOrder,
      kind: AnswerKind.order,
      prompt: translation,
      options: [for (final index in shuffled) fragments[index]],
      // Where each shuffled fragment belongs in the finished sentence.
      answerOrder: [for (final index in shuffled) index],
      speakText: analysis.normalized,
    );
  }

  /// Purpose: Show a sentence and ask which grammar point it uses.
  /// Inputs: `point`, the `example`, the `translation`.
  /// Returns: `QuizQuestion?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The wrong options are
  /// same-level points **whose own forms do not appear in the sentence**.
  /// Without that check a sentence ending in です would offer 〜です as a wrong
  /// answer to a question about something else in it, and be unanswerable.
  QuizQuestion? _pattern(
    GrammarPoint point,
    ContentExample example,
    String translation,
  ) {
    final sentence = example.ja;
    final wrong =
        catalog.grammar
            .where(
              (other) =>
                  other.id != point.id &&
                  other.level == point.level &&
                  other.matchForms.isNotEmpty &&
                  !other.matchForms.any(sentence.contains),
            )
            .toList()
          ..shuffle(_random);
    if (wrong.length < distractorCount) return null;

    return _choice(
      itemId: point.id,
      mode: QuizMode.grammarPattern,
      prompt: sentence,
      promptReading: example.reading,
      promptSubtitle: translation.isEmpty ? null : translation,
      correct: point.pattern,
      wrong: [for (final other in wrong.take(distractorCount)) other.pattern],
      speakText: example.reading ?? example.ja,
    );
  }

  // ── Shared ──

  /// Purpose: Blank the same span out of a sentence's reading as was blanked
  /// out of the sentence.
  /// Inputs: The parsed `analysis`, the `example` it came from, and the span
  /// `start`–`end` that the blank replaced.
  /// Returns: `String?` — the reading with the blank in it, or null.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Furigana over a
  /// fill-in-the-blank sentence needs the reading blanked at the same place,
  /// or the kana above the sentence would answer the question. Returns null
  /// whenever that cannot be done exactly — no reading in the content, a
  /// sentence the normalizer changed, or a span that cuts a kanji run in half
  /// — and the question is then shown without ruby, which is what it looked
  /// like before furigana existed.
  String? _blankedReading(
    SentenceAnalysis analysis,
    ContentExample example,
    int start,
    int end,
  ) {
    final reading = example.reading;
    if (reading == null) return null;
    final segments = alignFurigana(analysis.normalized, reading);
    if (segments == null) return null;
    final range = readingRangeFor(segments, start, end);
    if (range == null) return null;
    return reading.replaceRange(range.start, range.end, particleBlank);
  }

  /// Purpose: Assemble a multiple-choice question with its options shuffled.
  /// Inputs: The item, mode, prompt, the correct option and the wrong ones.
  /// Returns: `QuizQuestion?` — null when an option is duplicated.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The duplicate check is
  /// the last line of defence: two identical options mean two correct answers,
  /// and no distractor rule can rule that out on its own for every mode.
  QuizQuestion? _choice({
    required String itemId,
    required QuizMode mode,
    required String prompt,
    required String correct,
    required List<String> wrong,
    String? promptReading,
    String? promptSubtitle,
    String? speakText,
    String? formLabel,
  }) {
    final options = [correct, ...wrong];
    if (options.toSet().length != options.length) return null;
    if (options.any((o) => o.isEmpty)) return null;
    options.shuffle(_random);
    return QuizQuestion(
      itemId: itemId,
      mode: mode,
      kind: AnswerKind.choice,
      prompt: prompt,
      promptReading: promptReading,
      promptSubtitle: promptSubtitle,
      speakText: speakText,
      options: options,
      answerIndex: options.indexOf(correct),
      formLabel: formLabel,
    );
  }

  /// Purpose: Find a token's conjugation class through the lexicon.
  /// Inputs: `token`.
  /// Returns: `ConjClass?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The token records the
  /// catalog entry it came from, and the analyser's own lexicon is what knows
  /// how that entry conjugates — so the quiz and the parser cannot disagree.
  ConjClass? _classOf(Token token) {
    final refId = token.refId;
    if (refId == null || !refId.startsWith('vocab:')) return null;
    final entries = analyzer?.lexicon.entriesAt(token.lemma) ?? const [];
    for (final entry in entries) {
      if (entry.vocabId == refId) return entry.conj;
    }
    return entries.isEmpty ? null : entries.first.conj;
  }

  /// Purpose: Compare two orderings.
  /// Inputs: `a`, `b`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool _sameOrder(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

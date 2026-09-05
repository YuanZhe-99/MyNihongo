/// Reads what the model wrote back, and refuses what it cannot read.
///
/// Every parser here returns null rather than a best guess. A model that
/// ignored the format is a model whose content cannot be trusted either, and
/// the caller's fallback — the deterministic answer, or nothing at all — is
/// better than a half-parsed one.
library;

import '../../content/models/localized_strings.dart';
import 'response_parser.dart';

/// What the model said about a piece of writing.
class WritingFeedback {
  /// Purpose: Hold one piece of writing feedback.
  /// Inputs: `rewrite`, `notes`.
  /// Returns: A new `WritingFeedback` instance.
  /// Side effects: None.
  /// Notes: None.
  const WritingFeedback({required this.rewrite, this.notes = const []});

  /// The whole text rewritten as a native speaker would.
  final String rewrite;

  /// What changed, one point per entry, at most three.
  final List<String> notes;
}

/// Whether a free answer meant the same as the model answer.
class GradeVerdict {
  /// Purpose: Hold one grading verdict.
  /// Inputs: `same`, `comment`.
  /// Returns: A new `GradeVerdict` instance.
  /// Side effects: None.
  /// Notes: **This is a suggestion, not a mark.** What reaches the scheduler
  /// is the button the learner pressed; see `ai-assist.md`.
  const GradeVerdict({required this.same, this.comment});

  /// Whether the model thought the two mean the same.
  final bool same;

  /// Its one sentence about the difference.
  final String? comment;
}

/// Parses the practice tasks' replies.
/// What the model made of a generated question: its own answer, and whether
/// it thinks the question is sound at all.
///
/// Two facts rather than one, because either alone is weak. "Is this a good
/// question?" invites agreement; an answer with nothing to compare it to
/// proves nothing. A question is kept only when the model both re-derives the
/// generator's answer and says the question stands.
class QuizVerdict {
  /// Purpose: Hold one judgement of a generated question.
  /// Inputs: `answerIndex` — the option the judge chose, 0-3; `sound`.
  /// Returns: A new `QuizVerdict` instance.
  /// Side effects: None.
  /// Notes: None.
  const QuizVerdict({required this.answerIndex, required this.sound});

  /// Which option the model itself picked.
  final int answerIndex;

  /// Whether the model thinks the question is worth asking.
  final bool sound;
}

class PracticeResponseParser {
  /// Purpose: Prevent construction.
  /// Inputs: None.
  /// Returns: Never.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  PracticeResponseParser._();

  /// How many notes a piece of feedback may carry.
  static const maxNotes = 3;

  /// Purpose: Read a rewrite and its notes.
  /// Inputs: The model's `raw` reply.
  /// Returns: `WritingFeedback?` — null without a rewrite line.
  /// Side effects: None.
  /// Notes: The rewrite is the only required part, because it is the only part
  /// a learner can act on directly. Notes are taken in order and capped; a
  /// model that produced ten has stopped following the instruction, and the
  /// first three are the ones it thought of first.
  static WritingFeedback? writing(String raw) {
    String? rewrite;
    final notes = <String>[];
    for (final line in raw.split('\n')) {
      final text = line.trim();
      if (text.isEmpty) continue;
      final rewritten = _after(text, 'Rewrite:');
      if (rewritten != null && rewrite == null) {
        rewrite = rewritten;
        continue;
      }
      final note = _after(text, 'Note:');
      if (note != null && notes.length < maxNotes) notes.add(note);
    }
    if (rewrite == null || rewrite.isEmpty) return null;
    return WritingFeedback(rewrite: rewrite, notes: notes);
  }

  /// Purpose: Read a same-or-different verdict.
  /// Inputs: The model's `raw` reply.
  /// Returns: `GradeVerdict?` — null when the first line is neither word.
  /// Side effects: None.
  /// Notes: The first line has to be one of the two words, and a reply that
  /// hedges into a paragraph is refused. The learner then marks it themselves,
  /// which is what happens on a device with no model anyway.
  static GradeVerdict? grade(String raw) {
    final lines = [
      for (final line in raw.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    if (lines.isEmpty) return null;
    final head = lines.first.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (head != 'SAME' && head != 'DIFFERENT') return null;
    return GradeVerdict(
      same: head == 'SAME',
      comment: lines.length > 1 ? lines.sublist(1).join(' ') : null,
    );
  }

  /// Purpose: Read a verdict on a generated question.
  /// Inputs: The model's `raw` reply.
  /// Returns: `QuizVerdict?` — null when the reply is not one.
  /// Side effects: None.
  /// Notes: Two lines, a letter and a word, and anything else is refused. The
  /// caller keeps the question only when the letter matches the one the
  /// generator proposed **and** the word is `SOUND`, so a refusal here and a
  /// disagreement there have the same effect: the question is dropped, which
  /// costs nothing, while a wrong question shown to a learner costs trust.
  static QuizVerdict? quizCheck(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;
    final letter = lines[0].toUpperCase().replaceAll(RegExp('[^A-D]'), '');
    if (letter.length != 1) return null;
    final word = lines[1].toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (word != 'SOUND' && word != 'UNSOUND') return null;
    return QuizVerdict(answerIndex: letter.codeUnitAt(0) - 65, sound: word == 'SOUND');
  }

  /// Purpose: Read generated example sentences.
  /// Inputs: The model's `raw` reply and how many to keep.
  /// Returns: `List<ContentExample>` — empty when none parsed.
  /// Side effects: None.
  /// Notes: Three fields separated by vertical bars, and a line that does not
  /// hold exactly three is dropped rather than guessed at. A generated example
  /// is shown beside the catalog's own, so a mangled one would look exactly as
  /// authoritative as a real one.
  ///
  /// What *is* tolerated is packaging, because a model wraps the same three
  /// fields in whatever its training says a list looks like: a code fence, a
  /// number or bullet in front, or the leading and trailing bars of a Markdown
  /// table row. Stripping those changes no field's content. Not stripping them
  /// is why this returned nothing at all on a Pixel 10 on 2026-09-04, while the
  /// model was answering perfectly well.
  static List<ContentExample> examples(
    String raw, {
    required String language,
    int limit = 3,
  }) {
    final out = <ContentExample>[];
    for (final raw in raw.split('\n')) {
      if (out.length >= limit) break;
      final line = _unwrap(raw);
      if (line.isEmpty) continue;
      final parts = line.split(RegExp('[|｜]')).map((p) => p.trim()).toList();
      // A Markdown table row is `| a | b | c |`, which splits into five with an
      // empty at each end. Dropping those leaves the three fields that were
      // always there; dropping a *middle* empty would be guessing, so it is
      // not done and the line is refused below.
      if (parts.length > 1 && parts.first.isEmpty) parts.removeAt(0);
      if (parts.length > 1 && parts.last.isEmpty) parts.removeLast();
      if (parts.length != 3) continue;
      final ja = parts[0];
      final reading = parts[1];
      final translation = parts[2];
      if (ja.isEmpty || translation.isEmpty) continue;
      out.add(
        ContentExample(
          ja: ja,
          reading: reading.isEmpty ? null : reading,
          translations: LocalizedStrings({
            language: [translation],
          }),
        ),
      );
    }
    return out;
  }

  /// Purpose: Strip the packaging a model puts around a line.
  /// Inputs: One `line` of the reply.
  /// Returns: `String` — the line without fences, list markers or quotes.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Deliberately removes
  /// only what carries no meaning: a fence line becomes empty, a leading `1.`,
  /// `-`, `*`, `・` or `>` goes, and matching quotes around the whole line go.
  /// Nothing inside a field is touched, so no content is ever rewritten.
  static String _unwrap(String line) {
    var out = line.trim();
    if (out.startsWith('```')) return '';
    out = out.replaceFirst(RegExp(r'^(?:[-*>・•]|\d+[.、)])\s*'), '');
    if (out.length > 1 &&
        ((out.startsWith('"') && out.endsWith('"')) ||
            (out.startsWith("'") && out.endsWith("'")) ||
            (out.startsWith('「') && out.endsWith('」')))) {
      out = out.substring(1, out.length - 1);
    }
    return out.trim();
  }

  /// Purpose: Read a plain explanation.
  /// Inputs: The model's `raw` reply and the `prompt` it answered.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: The same cleaning the sentence lab already does — fences stripped,
  /// echoes of the prompt rejected, capped at a sentence boundary — because a
  /// "why was this wrong" answer is an explanation like any other.
  static String? explanation(String raw, {String? prompt}) =>
      ResponseParser.explanation(raw, prompt: prompt);

  /// Purpose: Take what follows a label, if the line carries it.
  /// Inputs: `line`, `label`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The label is matched
  /// case-insensitively and with either kind of colon, because a model asked
  /// to write in Chinese frequently writes the full-width one.
  static String? _after(String line, String label) {
    final pattern = RegExp(
      '^${RegExp.escape(label.replaceAll(':', ''))}\\s*[:：]\\s*',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(line);
    if (match == null) return null;
    return line.substring(match.end).trim();
  }
}

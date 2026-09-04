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

  /// Purpose: Read generated example sentences.
  /// Inputs: The model's `raw` reply and how many to keep.
  /// Returns: `List<ContentExample>` — empty when none parsed.
  /// Side effects: None.
  /// Notes: Three fields separated by vertical bars, and a line with any other
  /// number of them is dropped rather than guessed at. A generated example is
  /// shown beside the catalog's own, so a mangled one would look exactly as
  /// authoritative as a real one.
  static List<ContentExample> examples(
    String raw, {
    required String language,
    int limit = 3,
  }) {
    final out = <ContentExample>[];
    for (final line in raw.split('\n')) {
      if (out.length >= limit) break;
      final parts = line.trim().split(RegExp('[|｜]'));
      if (parts.length != 3) continue;
      final ja = parts[0].trim();
      final reading = parts[1].trim();
      final translation = parts[2].trim();
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

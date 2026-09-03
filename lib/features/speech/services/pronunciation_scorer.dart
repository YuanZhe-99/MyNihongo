import '../../kana/models/kana_text.dart';
import '../../sentence/services/lexicon.dart';

/// What happened to one mora when the attempt is lined up with the target.
enum MoraOp {
  /// The learner said this mora, in this place.
  correct,

  /// The learner said something else here.
  substituted,

  /// The target has this mora and the attempt does not.
  missing,

  /// The attempt has a mora the target does not.
  extra,
}

/// One aligned mora, as the practice sheet shows it.
class MoraDiff {
  const MoraDiff({required this.op, this.target, this.heard});

  /// What happened here.
  final MoraOp op;

  /// The mora the item says; null for an [MoraOp.extra].
  final String? target;

  /// The mora the recognizer heard; null for an [MoraOp.missing].
  final String? heard;

  @override
  String toString() => '${op.name}(${target ?? '-'}/${heard ?? '-'})';
}

/// The result of comparing one attempt with one target.
class PronunciationResult {
  const PronunciationResult({
    required this.score,
    required this.diff,
    required this.targetKana,
    required this.heardKana,
  });

  /// 0 to 100. Secondary to [diff]: it is a summary, not a judgement.
  final int score;

  /// The mora-by-mora alignment, which is what the learner is shown.
  final List<MoraDiff> diff;

  /// The target reduced to hiragana morae, as it was compared.
  final String targetKana;

  /// The attempt reduced the same way.
  final String heardKana;

  /// Whether every mora lined up.
  bool get isPerfect => score == 100;
}

/// Compares a spoken attempt with what the item says, in morae.
///
/// The algorithm is written up in
/// `doc/en-us/algorithms/pronunciation-scoring.md`. In short: reduce both
/// sides to hiragana morae, align them with a Levenshtein edit path, and
/// report the path. The diff is the output that matters; the score is a
/// one-number summary of the same alignment.
///
/// What this measures is **recognisability**, not accent: the recognizer has
/// already decided what it heard, and this only compares that decision with
/// the target. The UI says so.
class PronunciationScorer {
  const PronunciationScorer(this._lexicon);

  /// Used to rewrite a kanji answer into kana; null skips that step.
  final Lexicon? _lexicon;

  /// Purpose: Score one attempt against one target.
  /// Inputs: `target` — the item's kana reading; `heard` — what the recognizer
  /// returned, in whatever script it chose.
  /// Returns: `PronunciationResult`.
  /// Side effects: None.
  /// Notes: Both sides go through `toHiragana`, and the attempt additionally
  /// through the lexicon, because Android answers in kanji where the item is
  /// written in kanji. An empty attempt scores 0 with every target mora
  /// missing, which is what the learner should see when nothing was heard.
  PronunciationResult score({required String target, required String heard}) {
    final targetKana = toHiragana(target);
    final heardKana = _resolve(heard);
    final targetMorae = splitMorae(targetKana);
    final heardMorae = splitMorae(heardKana);
    final diff = _align(targetMorae, heardMorae);
    final edits = diff.where((d) => d.op != MoraOp.correct).length;
    final denominator = targetMorae.isEmpty ? 1 : targetMorae.length;
    final raw = 100 * (1 - edits / denominator);
    return PronunciationResult(
      score: raw.round().clamp(0, 100),
      diff: diff,
      targetKana: targetKana,
      heardKana: heardKana,
    );
  }

  /// Purpose: Reduce a recognizer answer to comparable hiragana.
  /// Inputs: `heard`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Without a lexicon the
  /// answer is only normalized, so the scorer still works before the catalog
  /// has loaded — it just cannot resolve kanji.
  String _resolve(String heard) {
    final lexicon = _lexicon;
    if (lexicon == null) return toHiragana(heard);
    return toHiragana(lexicon.toKana(heard));
  }

  /// Purpose: Line up two mora sequences and report every operation.
  /// Inputs: `target`, `heard`.
  /// Returns: `List<MoraDiff>` in target order.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A standard Levenshtein
  /// matrix with a backtrace, which is small enough here — a long example
  /// sentence is a few dozen morae. Ties in the backtrace prefer a
  /// substitution over an insert or delete, so a learner who said the wrong
  /// mora sees one wrong mora rather than a deletion followed by an addition.
  static List<MoraDiff> _align(List<String> target, List<String> heard) {
    final rows = target.length;
    final columns = heard.length;
    final cost = List.generate(
      rows + 1,
      (i) => List<int>.filled(columns + 1, 0),
      growable: false,
    );
    for (var i = 0; i <= rows; i++) {
      cost[i][0] = i;
    }
    for (var j = 0; j <= columns; j++) {
      cost[0][j] = j;
    }
    for (var i = 1; i <= rows; i++) {
      for (var j = 1; j <= columns; j++) {
        final same = target[i - 1] == heard[j - 1];
        final substitute = cost[i - 1][j - 1] + (same ? 0 : 1);
        final delete = cost[i - 1][j] + 1;
        final insert = cost[i][j - 1] + 1;
        cost[i][j] = substitute < delete
            ? (substitute < insert ? substitute : insert)
            : (delete < insert ? delete : insert);
      }
    }

    final diff = <MoraDiff>[];
    var i = rows;
    var j = columns;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final same = target[i - 1] == heard[j - 1];
        if (cost[i][j] == cost[i - 1][j - 1] + (same ? 0 : 1)) {
          diff.add(
            MoraDiff(
              op: same ? MoraOp.correct : MoraOp.substituted,
              target: target[i - 1],
              heard: heard[j - 1],
            ),
          );
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && cost[i][j] == cost[i - 1][j] + 1) {
        diff.add(MoraDiff(op: MoraOp.missing, target: target[i - 1]));
        i--;
        continue;
      }
      diff.add(MoraDiff(op: MoraOp.extra, heard: heard[j - 1]));
      j--;
    }
    return diff.reversed.toList(growable: false);
  }
}

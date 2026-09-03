# lib/features/speech/services/pronunciation_scorer.dart

Compares a spoken attempt with what an item says, in morae. Pure, deterministic and offline; the
recognizer has already decided what it heard before any of this runs.

The full derivation — why morae, why the target length is the denominator, why the diff leads and
the score follows — is in
[../../../../algorithms/pronunciation-scoring.md](../../../../algorithms/pronunciation-scoring.md).
This page documents the declarations.

Consumers: `pronunciation_practice_sheet.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `MoraOp` | enum | B | What happened to one mora: correct, substituted, missing, extra. |
| `MoraDiff` | class | B | One aligned mora, as the practice sheet shows it. |
| `PronunciationResult` | class | B | The score, the diff, and both sides as they were compared. |
| `PronunciationScorer` | class | B | Compare an attempt with a target. |
| [`score`](#score) | method | A | Score one attempt against one target. |
| `_resolve` | method | B | Reduce a recognizer answer to comparable hiragana, through the lexicon. |
| [`_align`](#align) | static method | A | Line up two mora sequences and report every operation. |

## Documentation

### `PronunciationResult score({required String target, required String heard})` <a id="score"></a>

- **Kind:** method
- **Purpose:** Produce the diff and the score for one attempt.
- **Inputs:** `target` — the item's kana reading; `heard` — the recognizer's answer, in whatever
  script it chose.
- **Returns:** `PronunciationResult`.
- **Side effects:** None.
- **Algorithm:** Normalize the target with `toHiragana`; put the attempt through the lexicon first,
  because Android answers in kanji where the item is written in kanji. Split both into morae, align
  them, then `round(100 x (1 - edits / max(targetMorae, 1)))` clamped to 0…100.
- **Usage:** The practice sheet, once the recognizer delivers a final result.
- **Notes:** The denominator is the **target** length, so extra morae cost without letting a long
  ramble exceed zero — the clamp handles that. An empty attempt scores 0 with every target mora
  missing, though in practice the service reports a `noMatch` failure before this is reached.

### `static List<MoraDiff> _align(List<String> target, List<String> heard)` <a id="align"></a>

- **Kind:** static method
- **Purpose:** Produce the per-mora alignment the learner is shown.
- **Inputs:** Two mora lists.
- **Returns:** `List<MoraDiff>` in target order.
- **Side effects:** None.
- **Algorithm:** A Levenshtein matrix and a backtrace. Sizes are tiny — a long example sentence is a
  few dozen morae — so the quadratic matrix is not worth optimizing.
- **Usage:** `score`.
- **Notes:** **Ties in the backtrace prefer a substitution** over a delete followed by an insert, so
  a learner who said one wrong mora sees one wrong mora rather than a deletion next to an addition.
  That preference is what makes the diff readable, and it is the reason the backtrace is written out
  rather than taken from a library.

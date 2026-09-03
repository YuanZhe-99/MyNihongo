# Pronunciation scoring

How a spoken attempt is compared with what an item says. Everything here is deterministic, offline
and unit-tested; the only non-deterministic part of the feature is the platform recognizer, which
has already decided what it heard before any of this runs.

**What this measures is recognisability, not accent.** The recognizer produced a transcription; this
compares that transcription with the target. A learner whose pitch accent is wrong but whose morae
are right scores 100, and the UI says so in as many words. Pitch-accent feedback would need a pitch
dictionary and f0 analysis, and is a Phase 3+ candidate in `PLAN.md`.

## Pipeline

```
target reading ─→ toHiragana ──────────────────┐
                                                ├─→ splitMorae ─→ align ─→ diff ─→ score
recognizer text ─→ Lexicon.toKana ─→ toHiragana ┘
```

### 1. Resolve kanji (the attempt only)

`Lexicon.toKana` (`lib/features/sentence/services/lexicon.dart`) walks the recognizer's answer left
to right, taking the **longest** catalog headword that matches at each position and writing that
entry's reading in its place. Android's recognizer answers 東京 where the item says とうきょう;
comparing those character by character would score a perfect reading at zero.

A span the catalog does not know is **copied through unchanged**. It then survives into the mora
list as its own entry and costs an edit, which is the honest outcome: the app could not read it, and
pretending otherwise would inflate the score.

Normalization is applied to the whole result afterwards, never inside the loop — `ー` takes its
vowel from the mora before it, so per-character normalization would drop it.

### 2. Normalize both sides — `toHiragana`

`lib/features/kana/models/kana_text.dart`:

| Input | Becomes | Why |
|---|---|---|
| katakana | hiragana | the recognizer picks a script; the learner did not |
| `ー` (and `－`, `—`) | the previous mora's vowel | コーヒー and こおひい are the same word said the same way |
| full-width ASCII | ASCII | recognizers differ on width for Latin and digits |
| whitespace, `。、・？！` and Western punctuation | dropped | punctuation is the recognizer's decision, not something the learner said |
| kanji | unchanged | this function cannot read them; step 1 is where that happens |

### 3. Split into morae — `splitMorae`

The mora is the unit Japanese rhythm is counted in, and it is the unit a learner is actually judged
on by a listener.

- A small kana (`ゃゅょぁぃぅぇぉゎ`) joins the mora before it: `きょ` is **one** mora, not two.
- `っ` and `ん` stand alone. Both are full morae, and dropping either is exactly the mistake the
  score exists to show — `がっこう` said as `がこう` has to cost something.
- Anything left that is not kana becomes its own entry, so it still costs an edit.

### 4. Align — Levenshtein with a backtrace

A standard edit-distance matrix over the two mora lists, then a backtrace that records what happened
at each step: `correct`, `substituted`, `missing` (in the target, not in the attempt) or `extra` (in
the attempt, not in the target). Sizes are tiny — a long example sentence is a few dozen morae — so
the quadratic matrix is not worth optimizing.

**Ties in the backtrace prefer a substitution** over a delete followed by an insert. A learner who
said one wrong mora should see one wrong mora, not a deletion next to an addition.

### 5. Score

```
score = round(100 × (1 − edits / max(targetMorae, 1))) clamped to 0…100
```

where `edits` is every diff entry that is not `correct`. Deliberate properties:

- **The denominator is the target length**, so extra morae are penalised without making a long
  ramble score above zero — the clamp handles that.
- **An empty attempt scores 0** with every target mora reported missing. That is what "nothing was
  heard" should look like; the recognition service turns a final empty result into a `noMatch`
  failure before this is reached, so in practice the learner sees the message rather than the zero.
- The number is **secondary output**. The diff is what the practice sheet leads with; the score is a
  one-number summary of the same alignment, and is only shown when the attempt was imperfect
  (a perfect attempt gets a sentence instead).

## Worked example

Target `がくせい`, attempt heard as `がくせえ`:

| # | target | heard | op |
|---|---|---|---|
| 1 | が | が | correct |
| 2 | く | く | correct |
| 3 | せ | せ | correct |
| 4 | い | え | substituted |

One edit over four target morae → `round(100 × (1 − 1/4))` = **75**.

## Tests

- `test/kana_text_test.dart` — normalization and mora splitting, including `ー`, small kana, `っ`,
  `ん` and unresolved characters.
- `test/lexicon_test.dart` — longest-match resolution and the unchanged pass-through.
- `test/pronunciation_scorer_test.dart` — identical, substituted, missing, extra, katakana input,
  kanji resolved through the catalog, kanji the catalog does not know, and an empty attempt.

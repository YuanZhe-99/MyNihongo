# Content authoring

How the catalog grows: what is written by hand, what is written by a model, what
checks each of them, and what none of it can promise.

[`content-catalog.md`](content-catalog.md) says what the files are. This says how
new ones are made.

## The problem this solves

The vocabulary is generated from JMdict and the JLPT lists, so it arrived whole:
7,744 words across all five levels. Everything else did not. Grammar was written
by hand and reached N5. Chinese glosses were machine-authored and reached N5.
Example sentences existed for 24 words out of 7,744.

The work left is not hard, it is large: roughly 600 grammar points, 7,000
glosses, 7,700 sentences. That is written in batches by model agents.

## The loop

```
draft_inputs.dart  →  an agent writes a draft  →  content_gate_test  →  merge_drafts.dart
```

1. **`dart run tool/draft_inputs.dart <kind> --level N4 [--batch 300]`** writes
   batch files under `tool/content/drafts/`. Each batch **is** the list of what
   is still missing, so two agents cannot collide and re-running after a merge
   simply produces fewer batches.
2. **An agent writes the draft** beside its input, `n4-01.input.json` →
   `n4-01.json`. It never runs a build and never runs a test.
3. **`CONTENT_DRAFT=<path> flutter test test/content_gate_test.dart`** judges
   the draft and prints **every** problem in it at once, each naming the id, the
   sentence and what to do. A batch is normally fixed in one pass.
4. **`dart run tool/merge_drafts.dart <kind> [--level N4] <drafts...>`** folds
   the batches into the shipped files. It makes no judgements: everything was
   decided in step 3.

For the two vocabulary overlays, merging is followed by
`dart run tool/import_vocab.dart --overlay-only`, which folds them into the
generated catalog without needing the 117 MB JMdict body. Then
`dart run tool/convert_zh_tw.dart` writes the Traditional text, always, because
Traditional is generated and never authored.

A new grammar file also has to be added to `ContentRepository.grammarAssets`.
Nothing else in the app needs touching.

## The kinds

| Kind | Batch | Written into |
|---|---|---|
| `gloss` | 300 words | `vocab_zh.json`, the Chinese overlay |
| `examples` | 150 words | `vocab_examples.json`, the example overlay |
| `grammar` | 25 points | `grammar/<level>.json` |
| `units` | one level, whole | `lessons/<level>.json` |
| `drills` | one 大問 at a time | `drills/<level>-<section>.json` |
| `gloss-ja` | 100 words | `vocab_ja.json`, the Japanese overlay |
| `ja` | by target; see *The Japanese streams* | a `ja` key in the shipped file it names |

**Grammar ids are settled before anything is written.** `grammar-inventory`
produces the level's list of ids and patterns in one pass, checked against every
id already shipped. Ids are a compatibility contract — a progress record is
keyed by one — so two batches inventing the same slug for different points, or
two slugs for the same point, is the one mistake that cannot be fixed later.

**A level's units are planned whole**, not in batches, because the property that
makes the path a path is that every grammar point of the level belongs to exactly
one unit. Batches that cannot see each other cannot satisfy that.

**A drill batch is one 大問 or a few, never half of one.** The batch generator
splits by question count but never across a 大問, because the questions of one
大問 share a style and, for reading and listening, share passages: two agents
writing half each would produce two halves that do not match.

A drill batch is also the only kind whose input is **two** files. The level's
vocabulary and grammar go in a separate `<level>-<section>.resources.json` that
each batch names, rather than being copied into every batch: a level's common
vocabulary is a few thousand rows, and repeating it per batch would turn a
thirty-question ask into a megabyte of the same list.

The `drills` merge **appends** to the shipped file rather than skipping what is
already there — a section is filled up over several releases, and each batch is
new questions rather than a better version of old ones. A duplicate id is fatal
rather than skipped: a question id is what "already asked" is remembered by, and
two questions under one id would make that mean whichever the file happened to
list first.

**A scenario is written into a unit that already exists**, not merged as a draft
of its own: `merge_drafts units` writes a whole level's file, so re-running it
would be a bigger change than adding one conversation. To gate a scenario added
that way, turn the shipped file back into a draft — strip the generated `zh_TW`
and wrap it as `{"kind": "units", ...}` — and run the gate on that.

## The Japanese streams

A learner who sets the app to Japanese needs Japanese where everyone else gets English or Chinese:
a definition under each word, a description of each grammar point, the unit and drill instructions.
None of it has a source to translate from — the JMdict edition is English-only — so all of it is
written by model agents through the same loop, as two kinds.

| Kind | What is written | Batch | Agent | Written into |
|---|---|---|---|---|
| `gloss-ja` | a monolingual definition per sense, 国語辞典-style, with a hiragana reading for each | 100 words | `content-gloss-ja` (`sonnet`) | `vocab_ja.json`, the Japanese overlay |
| `ja --kind grammar` | a one-line `meaning` with its reading, and an `explanation` | 25 points | `content-grammar-ja` (`opus`) | a `ja` key beside `en`, `zh` and `zh_TW` in `grammar/<level>.json`, plus the point's `meaningJaReading` |
| `ja --kind function-words` | a one-line gloss | 50 words | `content-ja` (`sonnet`) | `function_words.json` |
| `ja --kind units` | unit title, writing prompt, scenario title, question prompts and explanations | 3 units | `content-ja` (`sonnet`) | `lessons/<level>.json` |
| `ja --kind drills` | question prompts and explanations | 60 questions | `content-ja` (`sonnet`) | `drills/<level>-<section>.json` |

The 21 kana hints and the `ja` blocks of the two prompt assets are hand-written, as the `zh_TW`
prompt blocks were.

**What the text is, per kind, decides the model.** Unit, drill and function-word text is a
translation of authored English and Chinese — mechanical, so `sonnet`. A grammar explanation is
re-authored in plain Japanese — judgement, so `opus`. **The vocabulary definitions are the
exception**: they are re-authored with no source, and a wrong or circular definition passes every
gate rule, which is the case AGENTS.md puts on the capable model. They run on `sonnet` by the
user's decision, for volume, recorded as an exception in `PLAN.md`'s decisions log. The
mitigation was a sample: 30 definitions from each level re-read by `opus` for wrong, circular,
misleading and missing-sense definitions. It found 8 problems in 150 — none circular, at most 3 at
any level, none at N1 — and all 8 were corrected in the overlay. No level crossed the threshold
(more than three wrong) that would have sent it back to `opus` whole.

**The two definition fields carry readings; the prose does not.** A Japanese definition in a list
row, and a grammar point's one-line meaning, are exactly where a learner reading Japanese meets
kanji, so each carries a hiragana reading the gate aligns and the app draws as furigana.
`LocalizedStrings` holds lists of strings and cannot carry a reading, so the readings live beside
it: `jaReading` on a vocabulary entry, one per sense, and `meaningJaReading` on a grammar point.
Explanations, prompts and glosses stay plain text, like every other language's.

**`gloss-ja` rides the importer like the Chinese overlay does.** `vocab_ja.json` is the source of
truth; `import_vocab.dart` writes `meanings.ja` and `jaReading` into `vocab.json` in **both** of
its modes, because a full JMdict import rebuilds every entry and would otherwise delete them. A
`ja` merge appends the key to the shipped block without rewriting it, so `convert_zh_tw.dart` has
nothing to do afterwards: after every merge it is run twice, and the second run must say it is up
to date.

**A file's `source` stays true.** `vocab_ja.json` says model-authored. A hand-written file that
gains a model-authored `ja` key — the N5 grammar file, the function words — says
`hand-written; ja model-authored (Claude), unreviewed`. The kana notes stay hand-written, because
their `ja` hints are.

**The UI language lands last.** Until `lib/l10n/app_ja.arb` exists, Japanese cannot be chosen,
and every `ja` key is inert. The coverage tests in `content_catalog_test` are written against the
content and skipped while the ARB is absent; the commit that adds it turns them on, so a Japanese
UI can never ship over English glosses.

## What the gate checks

Each rule is one a shipped test already enforces on the catalog, moved earlier so
a batch fails before it is merged rather than after:

- **The Japanese parses** with the words the app ships, with no unknown token.
  This is `sentence_analyzer_test`'s rule, and it is the strongest one: a
  sentence using a word outside the catalog cannot be tokenized, so the sentence
  lab, the quizzes and the cross-links all fail on it.
- **Nothing leans on a harder level.** `content_links_test`'s rule: an N4
  sentence may not need an N2 word.
- **The reading lines up with the sentence**, through the furigana aligner. This
  is both a display requirement and the cheapest check that the reading actually
  belongs to this sentence rather than to an earlier draft of it.
- **All of `en` and `zh`**, and **never `zh_TW`** — that is generated, and a
  hand-written one fails `content_zh_tw_test`.
- **Ids are new, well formed, and unique** within the batch and against
  everything shipped.
- **A grammar point can be found in its own examples**, or the analyser cannot
  match it and the quiz cannot ask about it.
- **A question has four distinct options and a valid answer index**, because two
  identical options are two right answers.
- **A scenario's branch lands inside its own script** — `after` is a count of
  lines shown, so it has to be between 1 and the length of the conversation —
  **and exactly one of its choices is marked correct**, because the tally at the
  end counts exactly one.
- **A gloss is Chinese**: no kana, no leftover English, short enough for a list
  row.
- **A Japanese definition is short, Japanese, not the word itself, and readable.** At most 24
  characters, one to three per word, no run of three Latin letters, and every definition goes
  through the analyser: no character the catalog cannot explain, except the handful
  `allowed_unknown.json` already tolerates for the shipped examples. What this proves is that
  the app's own dictionary can read the definition and that its reading is really its reading.
  It does not prove the definition is right; a wrong one reads just as well. It also shapes the
  writing: 事, 母, 父 and 顔 are not catalog words, so a definition says こと and writes around the
  others.
- **A `ja` string belongs to the file it names**, is Japanese, and fits its place: a grammar
  meaning at most 30 characters with an aligned reading, an explanation 20 to 240, a unit or drill
  prompt at most 80 or 100, and every question of a unit covered. An unknown id is refused, and
  the merge refuses it too.

## What nothing checks

**Whether the Japanese is natural, and whether the translation is faithful.**

No test can. The gate proves a sentence is *parseable, level-appropriate and
correctly read*; it cannot prove it is *idiomatic*. A model-authored sentence
that passes every rule above may still be something no native speaker would say.

So the files say so. Every model-authored file carries
`"source": "model-authored (Claude), unreviewed"`, `vocab_zh.json` and
`vocab_ja.json` keep `reviewed: false` on every row, and `content-catalog.md`'s rule about Japanese
being checked by a person is written as the aspiration it is rather than as a
claim about what shipped.

This was a deliberate decision, taken because the alternative was shipping N5 and
nothing else. It is recorded in `PLAN.md`'s decisions log, and the open question
about who reviews the content stays open.

## Licensing

Model-authored content is GPL-3.0 with the app, like everything else written for
it. It is not derived from a copyrighted source, and the prompts do not ask for
one to be reproduced. The `source` field in each file records how it was made,
which is what the licensing table in `content-catalog.md` needs.

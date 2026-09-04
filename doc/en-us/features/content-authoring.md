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

## The four kinds

| Kind | Batch | Written into |
|---|---|---|
| `gloss` | 300 words | `vocab_zh.json`, the Chinese overlay |
| `examples` | 150 words | `vocab_examples.json`, the example overlay |
| `grammar` | 25 points | `grammar/<level>.json` |
| `units` | one level, whole | `lessons/<level>.json` |

**Grammar ids are settled before anything is written.** `grammar-inventory`
produces the level's list of ids and patterns in one pass, checked against every
id already shipped. Ids are a compatibility contract — a progress record is
keyed by one — so two batches inventing the same slug for different points, or
two slugs for the same point, is the one mistake that cannot be fixed later.

**A level's units are planned whole**, not in batches, because the property that
makes the path a path is that every grammar point of the level belongs to exactly
one unit. Batches that cannot see each other cannot satisfy that.

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
- **A gloss is Chinese**: no kana, no leftover English, short enough for a list
  row.

## What nothing checks

**Whether the Japanese is natural, and whether the translation is faithful.**

No test can. The gate proves a sentence is *parseable, level-appropriate and
correctly read*; it cannot prove it is *idiomatic*. A model-authored sentence
that passes every rule above may still be something no native speaker would say.

So the files say so. Every model-authored file carries
`"source": "model-authored (Claude), unreviewed"`, `vocab_zh.json` keeps its
`reviewed: false` on every row, and `content-catalog.md`'s rule about Japanese
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

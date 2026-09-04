# Sentence analysis

How a typed Japanese sentence becomes words, structure, grammar points and possible issues.
Everything here is deterministic, offline and unit-tested. There is no model and no network; the
only inputs are the bundled vocabulary, the bundled function-word table, and a few pages of rules.

The pipeline is `tokenize → chunk → match grammar → check`, wired together by `SentenceAnalyzer`.
Each stage is a separate file and a separate test.

## 1. Tokenizing — a lattice, not a split

Japanese has no spaces, so segmentation is a search. At every character position the tokenizer
proposes every reading it can, gives each a cost, and takes the cheapest path through the sentence
by dynamic programming.

**Why not greedy longest-match.** Greedy is wrong on sentences the catalog's own examples contain:
whether ここではなして splits as ここ/で/はなして or ここ/では/なして depends on what comes after, and a
left-to-right pass cannot know. Costs also make the tie-breaks explicit and testable instead of
hiding them in the order of a loop.

### What is proposed

| Edge | From |
|---|---|
| a function word | the bundled table — particles, copula forms, auxiliaries, formal nouns |
| a catalog word | the vocabulary, matched by how it is written **or** by its kana reading |
| an auxiliary **plus the stem before it** | de-inflection, see §2 — this is one edge covering both |
| a bare masu-stem | de-inflection, for 食べに行く and 話し方 |
| a numeral run | digits, full-width digits, or 〇一二三四五六七八九十百千万 |
| a katakana run | any maximal run, when nothing else covers it |
| punctuation | a fixed set |
| a single unknown character | always, so the path always reaches the end |

### Costs

Integers, so a fixture cannot drift on a rounding change. Lower is better.

| Edge | Cost | Why |
|---|---|---|
| function word | 8 | a surface that is both — は, に, から — is the function word far more often |
| catalog word | 10 | the baseline |
| … via its kana reading | +4 | ます is 増す's reading; reading it that way in 勉強しています costs the sentence its verb |
| … counter after a number | −3 | that is what a counter is for |
| … counter with no number | +5 | 本 is a book far more often than it is the counter for long thin things |
| stem + auxiliary | 12 | the word's cost plus 2 for the auxiliary |
| bare masu-stem | 14 | above a real word, so one is never displaced by a stem that happens to fit |
| numeral run | 6 | |
| katakana run | 15 | a loanword or a name: not free, but far cheaper than leaving kanji unexplained |
| punctuation | 1 | |
| unknown kana | 30 | probably part of a word the catalog has |
| unknown kanji | 40 | a real gap |

An edge that covers a stem **starts at the stem**, not at the auxiliary that proposed it, so the
shortest path weighs the whole verb against the alternatives. Getting that wrong was the first bug
this pipeline had: 見ました parsed as an unknown 見 followed by an unexplained ました.

### Normalization

Full-width ASCII becomes ASCII and the ideographic space becomes a space, so an input method cannot
change the answer. **Kana and kanji are otherwise untouched** — unlike pronunciation scoring, the
analyser needs the script it was given, because kanji are where most word boundaries are visible.

## 2. De-inflection — backwards, and confirmed against the dictionary

Every auxiliary in the function-word table declares the stem shape it attaches to: ます takes a
masu-stem, た a te-stem, ば an e-stem, かった an adjective stem. Given the shape and the characters
before it, the de-inflector answers which catalog entries could have produced them.

Running backwards keeps the tables small. Forwards, every class has a dozen forms; backwards, each
shape is one row transformation per class — and **the lexicon rejects everything that is not a
word**, so the rules can be generous.

| Shape | Rule | Example |
|---|---|---|
| masu-stem | ichidan +る; godan i-row → u-row | 行き → 行く |
| nai-stem | ichidan +る; godan a-row → u-row, with わ for う-verbs | 買わ → 買う |
| te-stem | ichidan +る; っ → う/つ/る **and く** (行って); し → す; い → く | 買っ → 買う |
| te-stem (voiced) | ん → ぬ/ぶ/む; い → ぐ | 飲ん → 飲ぬ, 飲ぶ, 飲む → only 飲む is a word |
| e-stem | ichidan; godan e-row → u-row | 行け → 行く |
| o-stem | godan o-row → u-row | 帰ろ → 帰る |
| adjective stem | the lemma minus い; いい inflects from よ- | 忙し → 忙しい |

する and 来る have no row, so they are matched from an exact stem list. **Exact** matters: an earlier
version tested `endsWith`, and 映画を見まし then de-inflected to する — one edge swallowing half the
sentence at the price of one verb, which the shortest path duly preferred.

### The voice system arrives as surfaces, not as a chain

Passive, potential, causative and causative-passive are **enumerated in the
function-word table**, one entry per combined surface: られます, させました,
せられて, and sixty more. It looks redundant beside the row tables above, and
it is the right shape anyway.

The reason is that this de-inflector recovers *one* stem behind *one*
auxiliary. It has no notion of an auxiliary that itself takes an auxiliary,
and 食べられませんでした is four of them. Teaching the lattice to chain would
mean modelling られる as a verb in its own right and letting the search compose
morphemes — a different algorithm, and one where a wrong path costs the whole
sentence rather than one edge.

Enumerating is the other end of the same trade. The table grows by a hundred
rows that a script writes; each row still says exactly which stem shape it
attaches to, so nothing else changes; and the forms a token reports are the
whole chain, because the entry names them. What it costs is that a form nobody
enumerated is not recognised at all rather than being assembled from parts.

**How this was found:** 行かせます parsed with no unknown token before any of
this, as 行 + か + せ + 増す — four real words and complete nonsense. The
authoring gate only rejects unknown tokens, so it passed. A wrong parse made of
known words is the failure mode neither the gate nor
`sentence_analyzer_test` can see, and it is why the N4 content was probed by
hand before it was merged.

A noun tagged `suru-verb` followed by し is **not** looked up here. The catalog has 勉強, not
勉強する, so inventing the compound would put a word in the lexicon the catalog cannot open; the
chunker rejoins them instead.

## 3. Chunking — bunsetsu and a right-headed guess

A bunsetsu is a content word plus everything leaning on it. A token joins the open chunk when it is
a particle, the copula, an auxiliary or a suffix; or a counter after a number; or する after a
`suru-verb` noun; or a verb behind a て-form, which is the one place an ordinary verb acts as an
auxiliary.

Attachment is the standard right-headed rule, looking rightwards:

1. A chunk that modifies a noun — の, an adnominal, a plain-form adjective, な, a number with a
   counter — attaches to the next **nominal** chunk.
2. Anything else attaches to the next **predicate** chunk.
3. Failing both, to the next chunk. The last chunk is the root.

A chunk that modifies a noun is **not** a predicate, even when its head is an adjective:
新しい映画を見ました has one predicate, and it is not 新しい. Without that rule the tense check fired
on 私は昨日…新しい映画を見ました, because 昨日 attached to 新しい.

Clause boundaries are not modelled. A chunk may attach across a て-form or a から, which is usually
right and occasionally not — the UI presents the result as a guess, and nothing else in the app
depends on it.

## 4. Grammar matching — on token boundaries

Phase 1 matched a grammar point's `match` strings as substrings of the raw sentence, which is what
`content_links.dart` still does for the reference pages. That is wrong often enough to notice: 〜は
matches every は inside a longer word.

The matcher uses the same strings against the **token sequence**: a match has to start and end on a
token boundary. So 〜は matches where the tokenizer decided there is a particle は, and not inside
はな. A one-character match form is allowed through only when the sentence really contains a particle
token spelled that way.

Overlaps: a match strictly contained in a longer one is dropped, so 〜てもいいです is reported once
rather than as itself plus です. Equal spans both survive — at that point there is no basis for
preferring either.

**No content change was needed.** The grammar schema stays at version 2 and the existing `match`
lists become useful as they stand.

## 5. Checks — five, each written to stay quiet

Every finding is a **possible** issue and the UI says so. The analyser has no model of what the
writer meant: it can see that a pattern is unusual, not that it is wrong. A learner told they are
wrong when they are not stops reading the section, and the true findings are wasted with it.

| Check | Fires when | Stays quiet when |
|---|---|---|
| particle frame | an を-marked chunk depends on a verb the catalog tags `intransitive` and not `transitive` | the verb is tagged both (many are), or is in the `path-verbs` set — 公園を歩く is correct |
| な/の confusion | a na-adjective takes の, or a noun takes な, before a noun | the word is tagged both noun and na-adjective, or is a `no-adjective` |
| tense vs time word | a `time-past` word depends on a non-past predicate, or a `time-future` word on a past one | the predicate is volitional, たい or て-form; the time word carries から or まで |
| missing copula | the last chunk is a bare nominal, in a sentence of ≥ 2 chunks with a は or が chunk | a single noun — a title, a label, an answer to a question |
| adjective as verb | reserved; the lattice makes 高いません unreachable rather than parseable, so it currently reports an unknown token instead | — |

At most three issues are reported: a sentence that trips more is likelier to be tokenized badly than
to be that wrong.

## Known gaps

- **Vocabulary the catalog lacks.** 母, 顔, 東京, 鞄 in kanji and 速い are not in the JLPT lists the
  catalog is generated from, so example sentences using them keep an unknown token. They are listed
  in `test/fixtures/sentence/allowed_unknown.json`, capped at 20, each citing the example that needs
  it. Fixing one means adding the word to the source lists and regenerating `vocab.json`.
- **Nothing above N4.** The table covers what N5 and N4 teach. N3 and above
  add forms — 〜ざるを得ない, 〜ようがない, the humble and honorific paradigms
  in full — that are not enumerated and will arrive as unknown tokens.
- **A wrong parse is not a failed parse.** Every automated check here asks
  whether a sentence produced an unknown token. A sentence that parsed into
  four real words in a nonsensical arrangement passes all of them. The only
  defence is reading the token chips, which is one reason the sentence lab
  exists.
- **No morphological analyser model.** `PLAN.md` M2.3 proposed a TinySegmenter port for boundary
  hints. It was not needed: at 7,700 entries plus the function-word table, the lattice reaches every
  shipped example sentence on its own, and the port would have added a model to maintain for a
  tie-break bonus. Recorded in the decisions log.
- **No token/POS rule schema on grammar points.** Also proposed, also not needed — see §4.

## Tests

- `test/tokenizer_test.dart` — segmentation against the real catalog: particles beating homographs,
  conjugations, katakana runs, kana-only input.
- `test/deinflector_test.dart` — every row shift, both irregular verbs, and the exact-stem rule.
- `test/function_words_test.dart` — the table as content: unique prefixed ids, both languages, every
  auxiliary declaring its stem shape, the named sets present.
- `test/sentence_analyzer_test.dart` — chunking, grammar matching, each check firing and staying
  quiet, and **every shipped example sentence parsing without an unknown token**.
- `test/sentence_lab_ui_test.dart` — the page at the named geometries.

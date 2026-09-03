# Sentence lab

Type a Japanese sentence and see what it is made of: the words, what attaches to what, which taught
grammar points it uses, and anything that looks unusual. The analysis is deterministic and offline —
a dictionary and a set of rules, not a translator and not a model. The algorithm is derived in
[`../algorithms/sentence-analysis.md`](../algorithms/sentence-analysis.md); this page describes the
feature.

## Where it lives

A full-screen route at `/lab`, **outside** the navigation shell. The five tabs are the reference the
app is built around; the lab is something you do *to* a sentence you already have, and a sixth tab
would have crowded the bottom bar for a page that is always entered with a purpose.

It is reached from four places:

| From | How |
|---|---|
| Learn | a quick-start link, pushed so the back button returns to the dashboard |
| Vocabulary, Grammar | an app-bar action |
| any example sentence, in either detail sheet | **Analyse this sentence** in the row's overflow menu |
| itself | typing into the field |

An example opened from a sheet is passed as the route's `extra` and analysed on arrival. The
sentence handed over is the one **as written**, not its kana reading: the analyser reads kanji, and
the kanji are where most word boundaries are visible.

## What it shows

Four sections, in order, each referring to the one above it. That chain is why the page is one
column at every window size — putting the reference beside the referent would make the reading order
ambiguous. Recorded in [`../adaptive-layout.md`](../adaptive-layout.md).

### Words

The sentence as a row of chips, one per word, wrapping onto more lines rather than scrolling
sideways — seeing the whole sentence at once is the point. Each chip shows the word as written, the
grammatical forms recovered from it (`masuStem + polite + past`), and the kind of word it is.

Colour groups the chips by kind and **the label under each names the group in words**, so colour is
never the only carrier of meaning. Six names cover twenty internal categories on purpose: a learner
wants to know a word is a particle, not that it is a binding particle rather than a conjunctive one.

Tapping a chip opens the vocabulary detail sheet for a catalog word — the same sheet the Vocabulary
page opens, so a word looked up here is the same page as a word looked up there. A function word has
no catalog entry, because it is grammar rather than vocabulary, so its own gloss is shown instead.

A word that is in no dictionary is drawn in the error colour and labelled as such, and a banner
above the sections says that parts of the analysis may be wrong. Being told which part is unreliable
is worth more than a clean-looking answer.

### Structure

One row per bunsetsu, in sentence order, each naming what it attaches to; the last says *main
predicate*. Sentence order rather than tree order, because the learner is reading a sentence they
just wrote and reordering it would make rows harder to find than the relationship is worth.

Attachment is a **guess** — the standard right-headed rule, with clause boundaries unmodelled. The
page's closing note says so.

### Grammar used

Every taught point the sentence uses, with the span that matched, opening the same detail sheet the
Grammar page opens. When nothing matched it says so rather than rendering nothing: a learner who
used no taught pattern should get that answer, not an absence to interpret.

### Possible issues

Five checks, each written to stay quiet when it is unsure — the exemptions are listed in the
algorithm page. Each row quotes the part of the sentence it is about and says what looks unusual, in
one sentence, as a possibility. At most three are shown: a sentence that trips more is likelier to
have been tokenized badly than to be that wrong.

## The function-word table

`assets/content/function_words.json` — about ninety particles, copula forms, auxiliaries and formal
nouns, each with an `fw:` id, an English and a Chinese gloss, the stem shape it attaches to and the
grammatical forms it contributes. Ids are a compatibility contract, as catalog ids are.

The table is **authoritative over the vocabulary** for the same surface: は is the topic marker far
more often than it is 歯, and an analyser that weighed those equally would be wrong in most
sentences. It also carries the named word sets the checks read — `time-past`, `time-future`,
`path-verbs`, `transitivity-pairs`.

It is loaded separately from the catalog, because it is a few kilobytes and only this page needs it;
loading it with the 2 MB catalog would make every page pay for a page that may never be opened.

## Limits, stated in the page

- It is a dictionary and a set of rules, not a translator.
- The structure is a best guess.
- Possible issues are worth checking, not trusting.
- Words the bundled dictionary lacks are called out where they occur.

## Not built

`PLAN.md` M2.3 keeps an on-device model (AICore / Gemini Nano through ML Kit GenAI) as an optional
enhancement that never becomes the source of truth. Nothing implements it: `SentenceEnhancer` is an
abstract class with no implementation, so the shape is settled before the pressure to add one
exists, and the analyser has somewhere to put it that is not the middle of the pipeline.

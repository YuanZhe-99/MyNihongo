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

Four sections, in order, each referring to the one above it. That chain is why the sections are one
column at every window size — putting the reference beside the referent would make the reading order
ambiguous. On a window wide enough to split, the *input* moves into a pane of its own beside them,
which changes nothing about the chain. Recorded in
[`../adaptive-layout.md`](../adaptive-layout.md).

Writing practice shows the same four sections, through the same widget, once per sentence. A learner
who has met one page is reading a familiar answer on the other; see
[`writing-practice.md`](writing-practice.md).

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

## History

Every analysed sentence is remembered, newest first, and tapping one puts it back in the field and
analyses it again. On a wide window the list sits under the input; on a narrow one it is behind the
app-bar button.

**Only the sentence is stored** — never the analysis, which is recomputed from the text and the
shipped catalog, and never anything a model generated. Storing an analysis would freeze an answer
that the next release improves; storing generated text would keep a wrong answer to be re-read.

Entries are `lab:<hash>` records in the progress file, so they sync with everything else and reach
the conflict dialog like any other record. The id is **derived from the sentence**, which is what
makes analysing the same sentence twice update one entry rather than add a second, and what lets two
devices that analysed the same sentence merge into one. A hundred are kept per page; past that the
oldest goes. Deleting one is a real deletion, and the merge propagates it. The format is in
[`../data-formats.md`](../data-formats.md).

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

## The optional on-device model

`PLAN.md` M2.4 fills the `SentenceEnhancer` seam with Android AICore, as an optional enhancement
that never becomes the source of truth. Turned on in **Settings › On-device AI** — off until then —
it adds an **Explain** button beside each possible issue, and **Explain this sentence** and **Suggest
a correction** below them. Everything it produces is drawn in a card labelled as generated, under the
deterministic finding it comments on, and none of it is stored — including in the history.

Each button is gated on the feature it uses: the explanations on the Prompt API, the rewrite on
Proofreading. A device with one and not the other gets the half that works.

With the switch off, or on any platform but Android, the page is exactly what this document
otherwise describes. See [`ai-assist.md`](ai-assist.md).

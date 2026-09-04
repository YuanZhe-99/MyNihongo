# Writing practice

Write a few sentences to a prompt, and have them checked. The check is the sentence lab's own
analysis, run once per sentence: the words, the structure, the grammar used, and anything that looks
unusual. On a device with an on-device model there is also a rewrite. The analysis is described in
[`sentence-lab.md`](sentence-lab.md) and derived in
[`../algorithms/sentence-analysis.md`](../algorithms/sentence-analysis.md); this page describes the
exercise.

## Where it lives

A full-screen route at `/writing`, **outside** the navigation shell, like the sentence lab and for
the same reason: it is something done to a piece of work, always entered with a purpose.

It is reached from a lesson unit that has a `writingPrompt` — a unit without one shows no button. The
prompt and the unit travel as the route's `extra`, and the unit is what lets the check ask whether
the learner used the words the unit teaches.

## What it shows

**The prompt, in the learner's own language**, then a field, then **Check my sentences**.

Checking splits what was written on the Japanese full stop and analyses each sentence on its own —
the analyser is built for one sentence at a time. For each one it draws the same four headed
sections the sentence lab draws, through the same widget, numbered when there is more than one.

Above them, when the exercise came from a unit, a count of **how many of the unit's words were
used**, against a target of three. The count comes from the **parse**, not from searching the text,
so an inflected form counts: somebody who wrote 食べました used 食べる.

Until `v0.3.2` this page showed only unlabelled word chips and a bare issue list — no headings, no
structure, no grammar section. The pipeline was the same one; only the presentation was thinner, so
a learner who had met the sentence lab met a second, worse version of an answer they already knew
how to read. There is now one widget, and the two pages cannot drift apart.

## Nothing here is graded

**No progress record is written about how well the writing did.** A piece of writing is not an item
with a recall interval, and a learner grading their own paragraph is not something the scheduler
should act on. The word count is shown and forgotten; the checkpoint that unlocks the next unit is
the unit's practice session, not this.

What *is* written is the text itself, to the history.

## History

Every piece of writing that is checked is remembered, newest first, and tapping one puts it back in
the field and checks it again. On a window wide enough to split, the list sits under the field; on a
narrow one it is behind the app-bar button.

The entries are **per unit**: the history beside a prompt is what was written for *that* exercise,
because the same sentence written for two prompts is two pieces of work. Only the text is stored,
never the analysis and never anything generated. The format, the content-addressed ids and the
hundred-entry cap are in [`../data-formats.md`](../data-formats.md).

## The optional on-device model

With **Settings › On-device AI** on, one more button offers a rewrite. Which model answers depends on
what the device has, and the two say different amounts:

| Feature available | Button | What comes back |
|---|---|---|
| Prompt | Rewrite more naturally | a rewritten version and a few notes about it |
| Proofreading only | Suggest a rewrite | the rewritten sentences, and nothing else |
| Neither | no button | the deterministic check, which is the whole exercise |

The proofreading path is `v0.3.2`. Before it, the button was gated on the Prompt API alone, so a
device with a working proofreader — most non-Pixel hardware, the Galaxy Z Fold 8 included — was
offered nothing. It corrects each analysed sentence **in turn**, because AICore serves one inference
at a time, and carries a sentence the model left alone through unchanged. When nothing changed
anywhere it says so rather than offering the learner their own writing back as a correction.

Everything generated is drawn in a card labelled as generated, below the deterministic sections, and
none of it is stored. See [`ai-assist.md`](ai-assist.md).

## Layout

Two panes when the window can split: the prompt, the field, the buttons and the history on the left
at `labInputPaneWidth`, the feedback in the rest. The analysis sections stay one column inside that
pane at every size. Recorded in [`../adaptive-layout.md`](../adaptive-layout.md).

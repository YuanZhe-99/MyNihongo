# On-device AI assistance

An optional layer over the sentence lab: the app can explain one of its own findings in more words,
explain a whole sentence, and suggest a rewrite. It runs on the phone through Android AICore, it is
**off until the learner turns it on**, and it never changes the analysis it comments on.

The platform facts — what AICore is, which APIs exist, what they require and how to check a device —
are in [`../android-aicore.md`](../android-aicore.md), which is written to be useful outside this
project. This page is what MyNihongo!!!!! does with them.

## The policy

Six rules, and each one is enforced in code rather than by convention:

1. **Off by default.** `aiAssistEnabled` is absent from `storage_config.json` until the learner
   turns the switch on. A device that never touched the setting never runs a model.
2. **The switch is a gate, not a filter.** `AiAssistService` refuses every generating call before it
   reads any status. While the switch is off, the method channel is never touched at all — which is
   the first thing `test/ai_assist_service_test.dart` asserts.
3. **Capability is re-checked before every use.** The system can remove a model between two
   requests; a remembered "ready" would turn that into an error the learner cannot interpret.
4. **Everything generated is labelled.** All of it is rendered inside `AiExplanationCard`, which
   carries "Generated on this device — may be wrong" above the text, never below it.
5. **Generated text never replaces a deterministic result.** A card is drawn under the finding it is
   about. Nothing generated is stored, synced, backed up, or written into the catalog — it is gone
   when the sentence changes or the page closes.
6. **Nothing is asked for on the learner's behalf.** The only network activity is the model
   download, it is performed by the AICore system service rather than by the app, and it starts only
   when the learner taps **Download** in Settings.

## What it can do

| Action | Where | API | Without it |
|---|---|---|---|
| **Explain** one possible issue | beside each issue row | Prompt | the deterministic one-sentence message, which is always shown |
| **Explain this sentence** | below the issues | Prompt | the words, structure and grammar sections, which are always shown |
| **Suggest a correction** | below the issues | Proofreading | nothing; the checks already say what looks unusual |

Every row of that last column is the point: **the fallback is the app**. Removing the AI removes
three buttons, not a feature the learner depends on.

## What the model is asked

`PromptBuilder` assembles the prompt from what the deterministic pipeline already produced:

- the normalized sentence,
- the token split, with the forms recovered by de-inflection,
- for an issue, the message **exactly as the app worded it on screen**,
- the catalog's own explanation of up to three matched grammar points, each excerpt capped,
- rules: answer in the UI language, at most four sentences, hedge, **do not contradict the notes
  above**, no headings or greetings.

Handing the model the app's own teaching text and forbidding contradiction is what keeps an
explanation consistent with what the Grammar page says about the same point. Asking about the issue
message the learner is reading — rather than re-deriving one — is what stops the answer explaining a
question they cannot see.

The prompts live in `assets/content/prompts/sentence_explain.json`, versioned like every other
content asset, with `en` and `zh` instruction blocks and the caps as data. They are deliberately not
in the ARB files: nothing there is ever rendered.

## What comes back

`ResponseParser` decides whether an answer is worth showing. It strips code fences, headings,
bullets, numbering and inline emphasis; collapses blank runs; caps the text at a sentence boundary;
and returns **null** for two cases that would teach something false:

- an answer that merely echoes the prompt — a model that echoes has not answered;
- a "correction" identical to what the learner wrote, ignoring whitespace — offering it would say a
  correct sentence was wrong. The UI then says the model suggested nothing different.

## Settings

**Settings › On-device AI**, shown on Android only — the section is omitted entirely elsewhere,
because a section whose every row reads "not available" is noise.

The switch carries a plain-language body. Under it, one row per feature (Explanations, Correction
suggestions) with its own status and, when the system says it can fetch the model, its own
**Download** button and progress. Progress is shown in megabytes rather than as a percentage,
because the system does not always report a total, and a percentage that has to disappear halfway
through is worse than a number that only grows.

The note under the buttons says who performs the download and when. It is not a footnote: it is the
sentence that makes the switch an informed choice.

## In the sentence lab

With the switch off, the lab is exactly what it was before — no buttons, no hints, nothing.

With it on and a model ready, each issue row gains **Explain**, and two whole-sentence actions appear
below the issues. Cards render under the deterministic content, one at a time (AICore serves one
inference per app), each dismissible once it has finished. Leaving the page cancels anything running,
so a model is not left working on an answer nobody will read.

With the switch on but no model downloaded, the actions are replaced by one line pointing at
Settings. A button that always fails teaches the learner to distrust the feature rather than to fix
it. On a device that simply cannot run a model, there is no line either — there is nothing to fix.

## Limits, stated plainly

- The model is small. It is wrong sometimes, and the label says so every time.
- Output language follows the UI language by instruction, not by guarantee.
- Proofreading takes short input; a long sentence is refused rather than truncated, because
  proofreading half a sentence would suggest a correction to a sentence nobody wrote.
- A first inference after a cold start is slow. There is a 45-second timeout so a wedged request
  cannot leave a spinner on screen forever.
- This is Android-only, and only on devices AICore serves.

## Verified on a device

Unlike the rest of Phase 2, this was checked on real hardware: a **Pixel 10, Android 17**, on
2026-09-03. What was exercised, in a release build:

- the switch off — nothing AI-related anywhere, and the method channel never called;
- the switch on — both features reported, both models downloaded from Settings;
- **Explain this sentence**, **Explain** on one flagged issue, and **Suggest a correction**, all
  answering correctly and in the UI language, in **both English and Simplified Chinese**;
- proofreading a correct sentence, which returns the sentence unchanged and is reported as "the
  model did not suggest a different sentence" rather than as a correction;
- the loading state, with the other actions disabled while one answer is generating.

An answer takes roughly 20–30 seconds. Two bugs the test host could never have shown were found and
fixed in the same change: R8 shrinking ML Kit into a failure that looked like an unsupported device,
and Settings raising the microphone prompt on open (see
[`pronunciation.md`](pronunciation.md)). Both are written up in
[`../android-aicore.md`](../android-aicore.md).

## Not built

The rest of the AICore work in `PLAN.md` — writing practice, free-response grading, a scenario
dialogue partner, "why was this wrong" (M3.4), and the Phase 4 drill helpers — is Phase 3 and later.
The pieces here are the ones those will reuse: the service and its switch, the prompt asset, the
parser, and the labelled card.

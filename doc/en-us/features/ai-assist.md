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
| **Why was this wrong** | under a wrong quiz answer | Prompt | the catalog's own explanation of the grammar point, or the question's own note, which is always shown first |
| **More examples** | in a word's detail sheet | Prompt | the catalog's own examples, which most words do not have |
| **A second opinion on a typed answer** | after Check, on a typed question the string comparison rejected | Prompt | the string comparison alone, which is what marked it before |
| **A rewrite of what you wrote** | in writing practice | Prompt, or Proofreading when Prompt is unavailable | the parse: which unit words were used, how each sentence was read, what looked unusual |
| **An extra question** | inside a unit practice session, labelled | Prompt | the question bank itself, which is a full session on its own |

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
content asset, with `en`, `zh` and `zh_TW` instruction blocks and the caps as data. They are
deliberately not in the ARB files: nothing there is ever rendered. The block is chosen by the same
fallback order the content uses, so a Traditional Chinese reader is asked for Traditional Chinese
and the grammar notes handed to the model are the Traditional ones — asking in one script while
grounding in the other would be asking the model to translate, which is not what it was told to do.
**The Traditional Chinese block has not been checked on a device:** if the model ignores it the
answer comes back in Simplified Chinese, which is what it did before this existed.

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

### When a row says the feature is not available

The two features have **separate device lists**, and the Prompt API's is the narrower one, so a
device can have one model and not the other. That is why there is a row per feature rather than one
"AI" state, and why **every button is gated on the feature it actually uses**.

Until `v0.3.2` that last part was not true: the rewrite button in the sentence lab and the one in
writing practice were both hidden whenever explanations were unavailable. A Galaxy Z Fold 8, which
had proofreading ready, was shown no AI at all while Settings correctly reported one feature as
usable. Each button now appears with its own feature.

`v0.3.2` also raised `genai-prompt` to `1.0.0-beta4`, which is what the Prompt API needs to run on a
Gemini Nano v4 device — the Z Fold8 family among them. An older client throws `FEATURE_NOT_FOUND`
there, which reads as an unsupported device and is not one. The story is in
[`../android-aicore.md`](../android-aicore.md).

A row that cannot offer the feature says which of two different things happened:

| Row | Meaning | Diagnostic line under it |
|---|---|---|
| Not available on this device | AICore was asked and refused | the raw `FeatureStatus` value |
| The AI service could not be reached | the call itself failed | the exception class and message |

The diagnostic line is deliberately untranslated: it is an identifier to quote in a bug report, not
prose to read. Under the section, one more line names the installed AICore build and the device, or
says AICore is not installed at all.

Both failing rows carry a **Check again** button, because availability changes without the app doing
anything: AICore provisions itself after device setup or an update, sometimes only after a restart.
Without it the only way to re-ask was to toggle the switch off and on.

This exists because of a report from a Galaxy Z Fold 8 with AICore installed where both rows read
"not available", and nothing in the app could say whether the device was off a published list, the
service was too old, or the call had thrown. `doc/en-us/android-aicore.md` carries the full
diagnosis procedure.

## In the sentence lab

With the switch off, the lab is exactly what it was before — no buttons, no hints, nothing.

With it on and a model ready, each issue row gains **Explain**, and two whole-sentence actions appear
below the issues. Cards render under the deterministic content, one at a time (AICore serves one
inference per app), each dismissible once it has finished. Leaving the page cancels anything running,
so a model is not left working on an answer nobody will read.

With the switch on but no model downloaded, the actions are replaced by one line pointing at
Settings. A button that always fails teaches the learner to distrust the feature rather than to fix
it. On a device that simply cannot run a model, there is no line either — there is nothing to fix.

## Marking a typed answer

This is the one place a model's output reaches the progress file, and it is
worth being exact about how.

The deterministic check runs first and **owns the word "correct"**. If the
answer matches what the catalog says — the kana, the romaji, either — no model
is asked and none could take that away.

Only when that check says no, and only for a typed answer, and only with the
switch on, is the model asked whether the two mean the same thing. **A yes
raises the verdict; a no changes nothing**, because the answer was already
wrong. A reply that hedges rather than starting with SAME or DIFFERENT is
refused by the parser and the answer stays wrong.

So the model can turn a wrong into a right and never the reverse, and the
learner is told which happened: the comment appears under the verdict, prefixed
to say the on-device model accepted it.

This is a deliberate exception to "generated text never writes a progress
record", and the reason it is safe is the asymmetry. The failure mode of a
string comparison is marking a correct answer wrong, which teaches the learner
that the app is not listening. The failure mode of this is being generous once.

## Taking turns

There is one model on the device and `AiAssistService` allows one generation at
a time, so two features that both want it have to queue. `AiPracticeService`
does the queueing, and the rule is that **the learner's request wins**.

Interactive requests queue behind each other rather than failing with "busy" —
somebody who taps two buttons quickly should get two answers, not an error. A
background job waits for whatever is interactive, retries a few times if the
model is busy, and then gives up **silently**: nothing is waiting for it, so
there is nobody to tell.

`AiPracticeService` imports no storage and no progress provider, and a test
asserts that by reading the file's own imports. Nothing generated writes a
record.

## Reading what came back

Every parser refuses rather than guessing.

- A writing reply with no `Rewrite:` line is dropped whole. The rewrite is the
  only part a learner can act on.
- A grading reply whose first line is not `SAME` or `DIFFERENT` is dropped, and
  the learner marks it themselves — which is what a device with no model does
  anyway.
- An example line without exactly three bar-separated fields is dropped. A
  generated sentence is drawn beside the catalog's own and would otherwise look
  exactly as authoritative as one somebody wrote.

A model that ignored the format is a model whose content cannot be trusted
either, so a half-parsed answer is worse than none.

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

## Generated questions

With the switch on, a **unit practice session** asks the model for up to three extra questions
about the unit's own grammar points. Four things bound what that can cost:

- The session is built and shown first; generation runs after it, through
  `AiPracticeService.runInBackground`, which yields to any interactive request. **Waiting on a
  model never delays the first question.**
- A generated question is `QuizQuestion.generated`, so answering it **never reaches the SM-2
  scheduler**. It cannot move a review interval, right or wrong.
- Every reply is checked before it becomes a question: a blank must be present, four distinct
  non-empty options, and an `Answer:` that names one of them. Anything else is dropped in silence.
  See [`ai_question_generator.md`](../functions/features/quiz/services/ai_question_generator.md).
- The question carries the generated label **above it**, before it is read, not after it is
  answered.

## Not built

The free-response translation mode and the scenario dialogue partner in `PLAN.md` are not written.
The scripted half of a scenario is — see [`lesson-path.md`](lesson-path.md) — and a partner would
attach to the end of it. The Phase 4 drill helpers are Phase 4.

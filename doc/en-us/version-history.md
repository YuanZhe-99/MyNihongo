# Version history

Release-by-release summary of MyNihongo!!!!!. Useful for understanding *why* a behavior exists
before changing it.

## Repository caveat

The repository's branch is `main`. The `origin` remote existed before the first commit; the
`github` remote was added at initialization. The `myapps_data` submodule was first pinned to
`54fa8d7`, two documentation-only commits after the package's `v1.0.1` tag. It is now pinned to
the `v1.0.2` tag, which carries the UTF-8 download fix this app needed.

## Releases

- `0.4.7` — 2026-09-05. The paper on a clock, and N4.

  **A mock exam you can put down.** Three blocks for N5, each opening on a start
  card that names the part, its sections, its minutes and its question count —
  because starting a clock somebody has not looked at is not a test of Japanese,
  and the real thing has a break between parts. Nothing is marked until the
  paper is in: no verdict, no explanation, no Continue button. Answering
  advances. A listening item plays once, which is the exam's rule and not a
  design choice.

  **The clock measures attention, not hours.** Time counts only while the block
  is on screen and the app is in the foreground. A learner who takes a phone
  call has not spent that time on the paper; one who leaves it overnight has not
  lost the paper. Leaving writes it down and coming back picks it up with the
  same time left — after re-checking the deadline, because a phone that slept
  past it has to find out on waking rather than resume a block that ended hours
  ago.

  Started and running turned out to be different states, and the device is what
  said so. The clock stops whenever a dialog opens, and the first version fell
  back to the start card each time — so leaving the exam looked, for the second
  the dialog took to appear, exactly like losing it. The widget test had passed.

  **One saved paper, and it stays on this phone.** Not synced, not backed up,
  not exported: an unfinished exam on another device is meaningless, because the
  clock belongs to the sitting. The save holds question **ids** and what was
  chosen, never the questions, so resuming re-marks against the files as they
  are now and a content fix corrects the resumed paper too. Ids the shipped
  files no longer have are dropped and the paper is that many questions shorter,
  rather than refusing to open; a save from a newer build is refused outright
  rather than half-read.

  The Learn card offers **Continue** — level, part, minutes left — before it
  offers a new one, and asks before replacing it, because there is one saved
  paper per device and it is the only thing here that cannot be recovered.
  Discarding says what survives: every answer already given went through the
  review schedule as it happened.

  A block that runs out of time is handed in with whatever is left recorded as
  **unanswered**, not wrong. A block whose questions are all answered is handed
  in early, and the recorded time is the time actually spent.

  **N4 ships complete** at the official composition — 85 questions and 35
  passages across all four sections.

  One more thing the device found: the Learn card read the speech engine before
  it had been asked, so a fresh install said listening needed a Japanese voice
  on a phone that has one, and never took it back. `TtsService` now says when it
  has actually checked, and the card waits for that rather than reporting a
  limitation it has not verified. 948 tests.

- `0.4.6` — 2026-09-05. Settings written for the person reading it, with the
  diagnosis moved behind a door.

  **Reported plainly: the explanations were too long and not aimed at a
  learner.** They were right. The on-device AI section had drifted into being
  written for whoever had to debug it — `stable/full · nano-v4 · 4096 tok` under
  a working feature, `FeatureStatus=0 · refused: …` under a broken one, an
  AICore build number, and a row that said "the device reported a status this
  version does not recognise". Every one of those was added for a reason, and
  the reason was real: two wrong diagnoses in a row came from a Settings page
  that could not say *why* a device had said no. But that audience is one person
  with a cable, and the page was being read by everybody else.

  So the rows now say what the feature does, whether it works, and what to do
  next. "Off by default. When it is on, the app can explain an answer in more
  detail, suggest a correction, and write extra practice questions. Everything
  runs on this phone — nothing you write is sent anywhere." The size switch,
  which used to explain what a model variant is, now says "Answers come sooner,
  and are usually shorter."

  **The diagnosis is not gone, it is behind eight taps on the version row** in
  Settings › About — Android's own gesture, copied exactly, because somebody who
  needs it already knows how to do it and nobody else will find it by accident.
  The countdown appears as the version row's own subtitle from three taps out. A
  snack bar was tried first and was wrong: the About section sits at the bottom
  of a long list, and the snack bar covered the row the next tap had to land on.

  One thing genuinely changed rather than moved. An unrecognised status now
  reads as "Not available on this device" unless developer options are on. The
  distinction matters — treating a status this build has never seen as a refusal
  is exactly how a working device gets told it is broken — but it is not a
  distinction a learner can act on, and both lead to the same next step.

  The preference is device-local and **not synced**. What it reveals is the
  diagnosis of *this* phone; carrying it to another would turn diagnostics on
  where nobody asked, and every number in them would be about a different
  device. 905 tests.

- `0.4.5` — 2026-09-05. Every JLPT section you finish is now recorded, synced,
  and — the part that matters more — used to stop the app asking you the same
  questions again.

  **An attempt is a record in the progress file**, not a second data module. It
  gets the per-record three-way merge, the conflict dialog, sync and backup for
  free, where a module of its own would have meant a second remote file, a
  second backup entry and eleven golden transcripts re-recorded.

  **Only the input is stored.** Which questions were asked and what the first
  answer to each was: right, wrong, or never answered. Not the question text,
  not the options, not the explanation — all of that is read back from the
  shipped files when the results are opened, so a content update that corrects
  an answer key corrects the history with it rather than leaving a frozen score
  the files no longer agree with. A question the files no longer have says so in
  one line instead of quietly disappearing from the attempt it was part of.

  Unanswered is its own value rather than a wrong answer. Calling it wrong would
  make every timed score look worse than the learner did; dropping it would make
  every timed score look better. Nothing in this release is timed yet — that is
  the next one — but the record has to be able to say it before the clock exists.

  **The no-repeat rule now has something to read.** The sampler's asked and
  least-recently-asked tiers were pure functions with nothing in them; they now
  draw on the **synced** attempts, so two devices avoid each other's questions
  rather than each grinding through the same first twenty. The cap on how many
  attempts are kept is therefore also the point at which a question becomes
  askable again, which is a reasonable definition of forgetting it.

  Pruning is **per mode** — forty mock attempts, eighty practice — because a
  learner who practises daily and sits a mock once a month would otherwise lose
  every mock to the practice runs, and the mocks are the ones worth looking back
  at.

  The results page lists every attempt newest first with its per-section score,
  opens into what was got wrong with the right answer and the explanation, and
  deletes for real: the merge treats a record deleted on one side and untouched
  on the other as deleted, so an attempt removed here is removed everywhere on
  the next sync. It says at the top, in words, that a score there is over the
  questions this app asked and is not a JLPT score — a screen showing "48 of 67"
  beside those four letters will be read as one otherwise.

  Two things the sync layer had to learn: the conflict dialog describes an
  attempt by its paper — level, mode, when it was sat, what it scored — rather
  than by counters that would say the same thing twice; and an attempt counts as
  a study day on the calendar, which is the clearest case there is of a day
  something was studied. 891 tests.

- `0.4.4` — 2026-09-05. The JLPT practice the Learn tab has been promising since
  the first release, at N5, one section at a time.

  **Questions in the shape of the paper, not copies of it.** The past papers are
  © The Japan Foundation and JEES and nothing here is taken from one. What is
  taken is the shape, all of it published: twenty-one 大問, how many questions
  each one has, the timed blocks and their minutes, and the scoring groups —
  encoded as one content asset, `drills/structure.json`, which carries the
  jlpt.jp pages it was read from in its own `source` field. The counts are a
  composition target rather than a promise, because JEES says they vary from
  session to session.

  Three deviations, each stated rather than quietly made: 即時応答 gets four
  options where the paper gives three, because every answer pane and the gate
  assume four; 発話表現 describes its scene in words, because the app has no
  pictures; and a mock will play each listening item once, because that is the
  paper's rule and practising against a gentler one teaches a habit the exam
  punishes.

  **A drill question is scored under its own id.** A paper asks several
  genuinely different questions about one word, and everything the app had built
  before scored by item — under which the second and third question about 会う
  would never have counted. The review schedule still hears about each item
  once, on the first question that asked about it, because SM-2 grades one
  recall and the second question was primed by the first.

  That change surfaced two latent bugs that had been sitting in the
  generated-question path, invisible because no session had ever asked two
  questions about one item in a row: the answer pane was keyed by item and mode,
  so the first question's selection carried into the second, and the re-speak
  check compared the same pair, so the second question played no audio. Both now
  compare the question.

  **Passages are drawn whole.** A 中文 carries three questions; drawing
  questions independently would have put one question from each of three
  passages on a short paper — three texts to read for three marks, three times
  the work of the paper it imitates. Within a 大問 the draw is three tiers:
  never asked first, then least recently asked, then the rest, shuffled inside
  each tier rather than across the pool, so an unseen question is never as
  likely as yesterday's.

  **A section that cannot be practised says why.** No content for that level
  yet, or no Japanese voice on the device — both are shown disabled with the
  reason beside them rather than hidden, because a learner who cannot find 読解
  practice has no way to tell whether it exists.

  The "coming next" card is gone from the Learn tab, replaced by the thing it
  advertised. Its Mock exam and Results buttons are present and disabled with a
  line saying they arrive in the next update: a card that grows two buttons
  silently is a card whose new buttons nobody finds.

  N5 ships complete at the official composition — 67 questions and 29 passages
  across all four sections, model-authored and unreviewed like the rest of the
  catalog, and every file says so. The content pipeline gains its fifth stream,
  `drills`, with its own agent, its own batch generator and thirteen new rules
  in the content gate. 856 tests.

- `0.4.3` — 2026-09-04. Generated material stops being taken on trust: a
  question the model writes is asked back to it, a question you doubt can be
  declined, and the word examples work at all.

  **Every generated quiz question is now asked twice.** The first call writes
  it; the second hands it back **without** its proposed answer and asks the
  model to work it out and to say whether the question stands. It is kept only
  when the model reaches the same option *and* calls it sound. A model shown an
  answer and asked to approve it agrees, so the second pass deliberately does
  not see the first: two derivations that must match is a check, a rubber stamp
  is not. Silence drops the question, which costs a question nobody asked for.

  **A generated question can be declined.** Next to the label that says it may
  be wrong, there is now a Skip button. Skipping records nothing, re-queues
  nothing, and shortens the session by one, so the progress line keeps counting
  what will actually be asked. An authored question has no skip: skipping the
  syllabus is not what this is for.

  **The word examples produce examples again.** Three faults, and the first
  explains a button that appeared to do nothing. The widget read the AI status
  through a provider that never rebuilds, inside a sheet that never rebuilds
  either, so a word opened while the device was still being probed showed no
  action at all until it was closed and reopened. It follows the service now.
  The prompt asked for the labels `sentence` and `expected`, both of which
  exist — so nothing fell back and nothing failed, and the model was told a
  single word was "Sentence:" and its meaning was "The model answer:". And the
  parser refused any line that was not exactly three bar-separated fields, which
  threw away a Markdown table row, a numbered line and a fenced block: the same
  three fields in the packaging a model reaches for. Packaging is now stripped;
  what a field contains is still never rewritten.

  Nothing checked the prompt asset for completeness, which is how a wrong label
  key shipped invisibly. A test now asserts every task exists in all three
  languages and every label a builder indexes is defined.

  Verified on a Pixel 10 in a release build: the examples arrive, and a practice
  session grew from 13 questions to 15 as generated questions passed the second
  opinion — one of the three was refused, which is the check doing its work.
  The two function pages this feature never had are written. 773 tests.

- `0.4.2` — 2026-09-04. The reading stopped landing on top of its own kanji.

  **A guess about font metrics, held for two releases.** Each piece of furigana
  reserves two slots: a line for the reading over a line for the word. The
  word's slot forces a strut, so it is exactly as tall as it claims. The
  reading's did not — it was reserved as `rubyScale × 1.15`, a number that
  assumed a font's ascent plus descent fits in 1.15 em, and a
  `TextHeightBehavior` had switched off the clamp that would have held it there.
  The app ships no font, so Japanese is drawn in the system CJK face, which
  needs about 1.4. A `SizedBox` constrains without clipping and a paragraph
  paints from the top, so the surplus went straight down onto the word. Both
  slots now force a strut, and the arithmetic agrees with the engine by
  construction rather than by luck.

  **And the whole widget now reads the viewer's text scale.** `fontSize` is what
  a style asks for; the engine paints the scaled value. Reserving from the
  nominal number meant a raised system font size grew the text and not the box.

  Reported from a Pixel 10's vocabulary list, and fixed with the screen rather
  than the test suite: the widget-test font has 1.0 em metrics, so it never
  overflows the old reservation and every existing test passed throughout. Two
  tests were still added — the reading's box must end at or above the word's, at
  three text scales, which is the half of the bug a test can hold — and the test
  file says plainly which half it cannot.

  Docs: the function page for this widget described an implementation replaced
  two releases ago; it now describes the one that is there. 753 tests.

- `0.4.1` — 2026-09-04. The Z Fold 8 serves a model, and answering that raised
  three more questions: which models does it serve, can you pick one, and where
  does the downloaded one live.

  **`0.4.0` worked.** On the device the model downloaded and the Prompt API
  serves `stable/fast`, `nano-v4-fast`. The probe was the fix; the beta4 bump
  alone was not, and `0.3.2` said otherwise.

  **The probe now asks every variant instead of stopping at the first.**
  Whether a learner has a choice of model size is itself a fact to report, and a
  loop that returns at the first success cannot know it. All four are tried, the
  first that serves is kept, the rest are closed at once, and the reply carries
  the whole served list. Re-probing happens on a deliberate refresh — the switch
  going on, Settings opening, Check again — while a generation trusts the model
  already serving, so the extra round trips are never paid mid-sentence.

  **A model-size switch, on the devices that have something to switch.** Where a
  device serves both a larger and a faster model, Settings offers *Prefer the
  faster model*: the larger one writes better explanations and stays the
  default, the faster one answers sooner. Changing it re-probes immediately, so
  the line underneath names the model serving now rather than promising one at
  the next launch. Where a device serves one size — the Z Fold 8 offers only the
  faster model — **no switch appears**, because a control that cannot change
  what is serving teaches the learner to distrust the page.

  **No Remove button, and a line saying why.** The obvious question after a
  download is how to undo it. The model belongs to the Android AICore system
  service, is shared with every app that uses the same model, and neither ML Kit
  client exposes any way to delete one — checked with `javap`, not assumed. A
  Remove button could only do nothing or take away a model another app is using,
  so Settings says where the model actually lives and points at Android's own
  settings for AICore.

  **A release stopped building itself twice.** Pushing the commit and then the
  tag ran the same analyze, test, APK and AAB twice on the same tree. The tag
  run now supersedes the branch run; an ordinary push is unaffected.

  **A release build could not download the model, and only a device could say
  so.** On a Pixel 10, tapping Download threw `NoSuchMethodError` for
  `kotlinx.coroutines.Job.cancel$default` from inside ML Kit. Kotlin compiles a
  call that omits a default argument into a synthetic bridge; ML Kit calls the
  one on `Job`, this app never does, so R8 removed it. The download completed
  anyway — AICore does that work — but the app reported a failure. This is the
  second R8 failure in this one feature, and the same lesson as the first: keep
  what the library calls, not what your own code calls.

  **The refusal line stopped appearing where nothing was refused.** A model that
  simply has not been downloaded is a normal state, and `refused: …` printed
  under "Not downloaded yet" reads as a fault. It now appears only on a row that
  cannot serve at all.

  Measured on the Pixel 10: it serves `stable/full` and refuses the other three
  — the exact mirror of the Z Fold 8, which serves `stable/fast` and refuses
  `stable/full`. No single fixed variant could have served both phones, which is
  the whole argument for probing. Neither is offered the size switch, because
  neither serves two sizes.

  Docs: `android-aicore.md` gains who owns a downloaded model and why an app
  cannot delete one, the probe section says why it enumerates, and three field
  notes record what the Pixel 10 answered. Both language trees. 751 tests.

- `0.4.0` — 2026-09-04. The device answered again, and the answer was no: the
  app was asking for one model out of four and reporting the refusal as the
  device's.

  **The Prompt API now probes for a model instead of assuming one.**
  `Generation.getClient()` with no configuration is not "the model on this
  phone". It is one request — the stable release stage at the full size
  preference — and a device that does not serve that exact combination answers
  `UNAVAILABLE`, which looks identical to having no on-device model at all. The
  app now builds a client for each of `stable/full`, `stable/fast`,
  `preview/full` and `preview/fast`, keeps the first that is not `UNAVAILABLE`,
  and remembers it for the download and the generation. Nothing names a device,
  a client version or a model: a variant the list does not yet know is one line,
  and a model AICore starts serving tomorrow is picked up with no change at all.

  **A refusal now says what was refused.** The row reads
  `FeatureStatus=0 · refused: stable/full, stable/fast, preview/full,
  preview/fast`. A working row says the opposite half: which variant is serving,
  which model is behind it and what its token limit is. Under the section, one
  more line reports whether AICore itself considers this device serviceable —
  which separates "AICore is absent or too old here" from "AICore is fine, this
  model is not offered", two facts with different fixes that no public API
  distinguishes. A status value this build does not know is now `unknown` rather
  than a refusal, because that enumeration has grown before.

  **Errors are read from the library's own code**, not by matching English
  substrings of a message that a reworded release could have changed silently.

  **Erratum for `0.3.2`.** That release said the Z Fold 8's `FEATURE_NOT_FOUND`
  was caused by a client library too old to talk to a Gemini Nano v4 device, and
  that bumping `genai-prompt` to `1.0.0-beta4` was the fix. The first half was
  true; the second was not. On the device the exception became a plain
  `FeatureStatus=0`, because a current client still asks for only one variant.
  The bump is a floor for what the app can *ask*, and `build.gradle.kts` now
  says so instead of claiming a device works. Both wrong diagnoses are kept in
  `doc/en-us/android-aicore.md`, with the rule they cost: two wrong diagnoses in
  a row means the instrumentation is the bug.

  **The answer length is the prompt asset's decision.** `practice.json` has
  carried a `maxOutputTokens` since the practice prompts landed and nothing read
  it. It now travels from the asset through to the platform call, so rewording a
  task to ask for more does not also need a code change.

  Docs: a **Choosing a model** section in `android-aicore.md` covering the four
  variants, the developer-preview stage an app cannot enrol a device in, the
  per-capability probes and the error-code table; a rewritten diagnosis
  procedure; a third Z Fold 8 field note. Five statements that were wrong or
  stale — including a `platform-notes.md` line still naming `beta2` — corrected.
  740 tests.

- `0.3.2` — 2026-09-04. What a Galaxy Z Fold 8 found: an AI feature that was
  never broken, a button that hid itself, and two pages that had never been
  given a foldable.

  **On-device explanations work on a Z Fold 8, and the earlier diagnosis was
  wrong.** `0.3.1` reported `FEATURE_NOT_FOUND` there and recorded the cause as
  "this hardware is not on the Prompt API's device list". It is on the list —
  under Gemini Nano v4, alongside the Z Flip8, the Z Fold8 Ultra and the Pixel 11
  family. What was too old was the **client library**: `genai-prompt` before
  `1.0.0-beta4` throws exactly that error on a nano-v4 device, and the fix is one
  line of Gradle. The Kotlin needed no change, checked with `javap` against both
  published archives rather than assumed. Not confirmed on the device, because
  there is no Samsung hardware here.

  **A rewrite is offered whenever the proofreader works.** The two on-device
  features have separate device lists, and the app knew that — Settings has said
  so per feature since `0.3.0`. The pages did not: the sentence lab's rewrite
  button sat inside a block that returned early when *explanations* were
  unavailable, and writing practice's rewrite asked the Prompt API only. On a
  Fold 8 that meant no AI at all, while Settings correctly reported one feature
  as ready. Every button now follows the feature it actually uses. Writing
  practice gains a proofreader path that corrects each sentence in turn, because
  the system serves one request at a time.

  **Writing practice shows what the sentence lab shows.** It drew unlabelled word
  chips and a bare list of issues; it now draws the same four headed sections —
  words, structure, grammar used, possible issues — through the same widget, one
  per sentence. It was always the same analysis underneath. Only the presentation
  was thinner, so anyone who had used the sentence lab met a worse version of an
  answer they already knew how to read.

  **Both pages remember what you typed.** A history list, newest first: tap to
  bring a sentence back, tap to forget it. It syncs with everything else, because
  the entries are ordinary progress records. **Only the text is stored** — the
  analysis is recomputed each time, so it improves with the app, and nothing a
  model generated is ever kept. An entry's identity is its own content, so
  analysing the same sentence twice updates one row instead of adding another,
  and two devices that analysed the same sentence merge rather than collide. A
  hundred are kept per page; deleting one deletes it everywhere.

  **Both pages use a foldable's width.** Unfolded, the prompt, the field and the
  history move into a pane of their own beside the analysis. The analysis itself
  stays one column at every size, which was always the point of the rule: the
  four sections are a chain, and only the chain needed protecting — not the text
  field sitting above it.

  726 tests pass, up from 667. Writing practice had none before this release.

- `0.3.1` — 2026-09-04. The three things Phase 3 had designed and never written,
  and a catalog that is finally complete.

  **Scenario lessons.** A unit may end with a scripted conversation: six to
  eight lines with a speaker each, and one or two points where the script stops
  and asks the learner what to say. Every line and every candidate reply can be
  read aloud. Written for N5 units 1–4 and N4 units 1–2; a unit without one
  shows no button.

  A wrong reply does not end the conversation and does not fork it. The script
  is linear, and what the learner said changes the tally at the end and nothing
  else — a conversation that stops when you say the wrong thing teaches nothing
  about what to say instead. Nothing here reaches the scheduler: picking one of
  three is not recall, and the unit's practice session already measures that.

  **AI-generated questions**, with the switch on. A unit session asks the model
  for up to three extra questions about its own grammar points, **after** the
  session is on screen, so waiting on a model never delays question one. They
  are labelled above the prompt, before being read; and answering one never
  reaches SM-2, because a question that may be wrong must not move a real
  review interval. The parser refuses six ways — no `Q:` line, no blank in the
  sentence, not four options, a blank option, two identical options, an
  `Answer:` naming none of them — since a guessed question looks exactly as
  authoritative on screen as an authored one.

  **Writing practice is reachable.** The page shipped in `0.3.0` and nothing
  opened it; a unit's writing prompt now does.

  **The catalog is complete.** N2 grammar (170 points) and N1 grammar (158)
  fill the last two levels of chips; every one of the 7,744 words has a Chinese
  gloss and, with one exception, an example sentence; and every level has its
  units, 65 in all.

  | Level | Grammar points | Lesson units | Chinese glosses | Example sentences |
  |---|---|---|---|---|
  | N5 | 81 | 9 | 667 of 667 | 667 of 667 |
  | N4 | 100 | 12 | 630 of 630 | 630 of 630 |
  | N3 | 150 | 14 | 1,650 of 1,650 | 1,650 of 1,650 |
  | N2 | 170 | 15 | 1,737 of 1,737 | 1,737 of 1,737 |
  | N1 | 158 | 15 | 3,060 of 3,060 | 3,059 of 3,060 |

  The one gap is left in rather than papered over: ＯＫ is written in fullwidth
  Latin and read オーケー, and the lexicon indexes a surface by its headword, so
  the analyser reaches it by neither spelling and no example for it could be
  checked.

  Twenty-six N1 points were **dropped rather than renamed** when their slug
  collided with an N2 point. Renaming keeps the count at the price of teaching
  the same pattern twice under two ids; the count is a number in a table, and
  the duplicate is what a learner would meet.

  Getting N1 to parse at all meant teaching the analyser the classical layer:
  ぬ, ざる, べからざる, べからず, んとする, んばかり, や否や, すべ, こととて,
  〜つ〜つ, 極まりない, 極み, の至り, 同然, 関の山, ぐるみ, 三昧, やら〜やら.
  Each of those **is** an N1 grammar point, so no example can avoid it and the
  function-word table had to grow; ordinary words the dictionary happens to lack
  went the other way, by rewriting the sentence. Two failures were silent and
  cost a while: `needs` on a function word means "attach me to a stem", so it is
  wrong for a form that follows a finished dictionary form, and `particle-conj`
  is not a category name the loader knows. Both dropped the entry with no error
  anywhere, and the only symptom was a sentence that would not parse.

  Also here: ヶ and ヵ now align. They sit in the katakana block but are not
  katakana — 三ヶ月 is read さんかげつ — and anchored as kana they demanded a ヶ
  the reading never contains, so every counted-month sentence failed.

  **Content authoring is now four committed subagent definitions**, one per
  draft kind, so the model and the reasoning effort belong to the stream rather
  than to whichever prompt was typed. `AGENTS.md` says to revisit both keys
  whenever the available models change.

  Everything past N5 remains **model-authored and unreviewed**, which every such
  file records in its `source` field.

  Two things the device found that no test could. **Generated questions never
  arrived at all**: the prompt asset is a `FutureProvider`, nothing on the way
  into a session touches it, and the code read its `.value` — which is null
  until it loads. There was no error anywhere; the feature simply did nothing,
  and a second attempt would have worked. The same read was in all four
  practice callers, so all four now go through one helper that awaits it.

  And **the reply the learner chose vanished from the scenario transcript**,
  which made the conversation read as if the other speaker had carried on
  alone. It is now shown in place, marked right or wrong.

  Verified: 667 tests, `flutter analyze` clean, and on a Pixel 10 (Android 17,
  release build): the scenario page end to end — furigana over each line, the
  branch, a wrong reply kept in the transcript, the conversation continuing,
  and the tally; writing practice opened from a unit with its prompt and both
  actions; and a unit session growing from 12 questions to 15 as the generated
  ones arrived, with AICore called for each.

  **Not verified on a device:** the generated question's own label, which needs
  answering twelve questions to reach.

- `0.3.0` — 2026-09-04. The learning engine: spaced repetition, quizzes, a lesson
  path, kana over kanji, a daily reminder, and a catalog that finally reaches
  past N5.

  **Study, not just browse.** SM-2 over the record fields Phase 1 shipped and
  nothing had ever written, with two departures from the textbook that are
  derived rather than assumed. Thirteen ways of asking about the same catalog,
  then three more. A learner profile, a review queue judged by local calendar
  day, and a daily new-item allowance derived from the records rather than
  stored.

  **A lesson path.** Nine N5 units, each a topic. A unit builds its whole
  question pool and draws twelve from it, weighted by what has not been got
  right yet, at most one per item — which is what makes a rare mode as likely
  as a common one rather than as likely as its items are. A checkpoint at seven
  in ten opens the next unit, and **a locked unit's checkpoint can still be
  taken**, because that is how somebody who already knows the material skips
  ahead.

  **Kana over kanji**, on by default. The catalog stores one reading per word
  and none per character, so the alignment is recovered from the two strings —
  and refused, rather than guessed, when nothing fits. A wrong alignment is not
  an uglier layout; it prints kana over the wrong character.

  **A daily reminder**, off until turned on, saying how many items are due or
  which unit is next. Permission is requested by the switch and nowhere else, a
  rule with a test behind it because M2.4 shipped a build that asked for the
  microphone when Settings opened.

  **On-device AI gains two more uses**: why a chosen answer was wrong, grounded
  in the catalog's own explanation and forbidden to contradict it, and extra
  example sentences on request. Both off unless the switch is on, both labelled,
  neither stored.

  **The catalog grew past N5, and how it grew is stated plainly.** N4 grammar
  (100 points) and N3 grammar (150) fill chips that had been empty since Phase
  1. Chinese now covers every word at N5, N4 and N3 — 2,947 of the 7,744 in the
  catalog, against 669 before. 517 N5 words have an example sentence, against
  24 before.

  All of that beyond N5 was written by model agents against an authoring gate
  and **has not been read by a Japanese or Chinese speaker**. The gate proves a
  sentence parses against the app's own dictionary, is read the way its reading
  says, and uses ids that exist; it cannot prove the Japanese is natural. Every
  such file says `"source": "model-authored (Claude), unreviewed"`, every gloss
  keeps `reviewed: false`, and `content-authoring.md` says what the checks
  cannot promise. The alternative was shipping N5 and nothing else.

  Making that content possible meant teaching the sentence analyser N4 and N3:
  the passive, potential, causative and causative-passive had never parsed, and
  some of them appeared to — 行かせます came out as four real words in a
  nonsensical arrangement, which no automated check here can see. About 130
  function words later, 20 of 21 N4 probe sentences parse, and a rare word now
  costs more in the lattice than a common one.

  **Coverage as released**, because a table is more honest than a claim:

  | Level | Grammar points | Chinese glosses | Example sentences |
  |---|---|---|---|
  | N5 | 81 | 667 of 667 | 517 of 667 |
  | N4 | 100 | 630 of 630 | 0 of 630 |
  | N3 | 150 | 1,650 of 1,650 | 2 of 1,650 |
  | N2 | 0 | 0 of 1,737 | 0 of 1,737 |
  | N1 | 0 | 0 of 3,060 | 0 of 3,060 |

  Also here: M2.5's Traditional Chinese, which was held back from `0.2.1` on
  purpose, and three device fixes found on a Z Fold 8 — text-to-speech reading
  Japanese in the device's own language, a voice picker with no way to hear
  anything, and on-device AI reporting one sentence for four different causes.

  Verified: 640 tests, `flutter analyze` clean, and a debug APK built to check
  the manifest merge.

  **Not verified on a device:** the reminder actually firing, the lesson path
  and the checkpoint, kana over kanji rendered on a phone screen, and the two
  new AI actions. Nothing in this release has been run on hardware.

- `0.2.1` — 2026-09-03. On-device AI assistance for the sentence lab, and the first release verified
  on a real phone.

  A **Pixel 10** became available, which is what made this release possible and what changes the
  honesty of the rest of this entry: `0.2.0` was verified only through test seams, and two of its
  behaviours turned out to be wrong the moment a device ran them.

  On-device AI (`PLAN.md` M2.4): with **On-device AI assistance** turned on in Settings — off until
  the learner turns it on — the sentence lab can explain one of its own findings in more words,
  explain a whole sentence, and suggest a rewrite. Explanations come from ML Kit's Prompt API and
  rewrites from its Proofreading API, both running on the phone through Android AICore. The switch is
  a **gate rather than a filter**: while it is off, the method channel is never called at all.
  Everything generated is shown in a card labelled as generated, under the deterministic finding it
  comments on, and none of it is stored, synced, or written into the catalog. The prompts are a
  versioned content asset grounded in the app's own analysis and the catalog's own grammar notes, so
  an explanation cannot drift from what the Grammar page teaches. The only network use is the model
  download, which the AICore system service performs when the learner taps Download; the privacy
  policy now says so. AICore is reached through the app's own Kotlin channel rather than a plugin,
  for the same Kotlin Gradle Plugin reason that pins `file_picker` and `speech_to_text`, and `minSdk`
  rises to 26.

  Two bugs the development host could not have shown, both found on the phone and fixed here:

  1. **R8 shrank ML Kit into a `NullPointerException`** in release builds, which the app reported as
     "not available on this device" — on a phone that supports it perfectly. Debug builds were fine,
     which is what made it invisible. `android/app/proguard-rules.pro` now keeps
     `com.google.mlkit.**`; keeping only the `genai` packages was not enough.
  2. **Opening Settings raised the microphone prompt**, a `0.2.0` defect: the recognition status row
     asked the recognizer whether it was available, and asking is what makes Android request the
     microphone — breaking `0.2.0`'s documented promise that the prompt never arrives unexplained.
     Settings now checks the permission first, and the status line has a third state for "not yet
     checked", which is a different claim from "this device has no recognizer".

  Verified: `flutter analyze` clean, 348 tests, release APK, and the whole AI feature exercised on the
  Pixel 10 in English and Simplified Chinese. **Still not verified on a device:** text-to-speech and
  speech recognition themselves — this release did not cover them — and macOS, which has still never
  been compiled.

- `0.2.0` — 2026-09-03. Phase 2: the app speaks, listens, and reads a sentence. Also the Windows
  and macOS projects, added early because the pronunciation work needs a machine that can run the
  app and the development host has no Android device.

  Verified on this host by `flutter analyze` (clean), 297 tests, and debug builds of both the
  Android APK and the Windows executable, the latter launched and checked. **Not verified on a
  device:** this host has no Japanese text-to-speech voice, no Japanese speech data and no Android
  phone, so the audio path and the recognizer itself are exercised only through their test seams —
  what the host actually shows is the no-voice and no-recognizer state, and that state is covered.
  macOS has never been compiled: there is no Mac here.

  Windows and macOS (`PLAN.md` Phase 5, landed early): the two projects, an `installer.iss` that
  builds both x64 and ARM64 from one script, an `msix_config`, desktop launcher icons, and a
  single-instance Windows runner opening at 1000×720 — wide enough that the reference lists are
  already two-column, which is the layout worth looking at on a desktop. CI stays Android-only on
  purpose; the desktop targets are for local development. `flutter_tts`'s Windows plugin needs
  `nuget.exe` on `PATH`, which is now a documented prerequisite. Settings shows the storage location
  on desktop only: on a phone the path names a sandbox the user can neither browse to nor act on.
  Every platform branch now lives in one file, `shared/utils/platform_capabilities.dart`, reading
  `defaultTargetPlatform` so an Android-only branch stays testable on a Windows host.

  Text to speech (`PLAN.md` M2.1): kana, headwords and every example sentence read aloud by the
  device's own engine, with a long-press on any kana chart cell. The kana reading is always
  preferred over the kanji surface, so the engine cannot guess a reading. One utterance at a time,
  published so the button that is playing shows a stop icon and the rest stay idle. A speed slider
  and a Japanese voice picker in Settings, both device-local. With no Japanese voice installed the
  buttons are disabled rather than hidden, and Settings offers a button that opens the system
  speech settings.

  Speech recognition and pronunciation feedback (`PLAN.md` M2.2): say a kana, word or sentence and
  see which morae matched. Recognition is **offline-only by default** — on Android that means the
  attempt fails rather than quietly reaching a server when no Japanese model is installed, and the
  sheet turns that failure into a message naming both fixes. A switch in Settings, off by default
  and stored as an absent key, is the only way anything is ever sent to the system speech service;
  it is the only setting besides WebDAV sync that lets anything leave the device. The microphone is
  requested at first use behind the app's own rationale, never at install. Scoring normalises both
  sides to hiragana morae and aligns them with an edit path whose ties prefer a substitution, so one
  wrong mora reads as one wrong mora; the attempt is first rewritten through a new catalog index,
  because the recognizer answers in kanji where the item is written in kanji. The per-mora diff is
  the primary output and the score is a summary of it. Own-voice playback is deferred: it needs the
  microphone at the same time as the recognizer, which cannot be verified without a device.

  Sentence lab (`PLAN.md` M2.3): type a sentence and see the words, what modifies what, the taught
  grammar it uses, and anything that looks unusual. Tokenizing is a cost lattice with a shortest
  path rather than greedy longest match, because whether a kana run splits one way or another
  depends on what follows it. De-inflection runs backwards — each auxiliary declares the stem shape
  it attaches to, and the bundled vocabulary rejects every proposal that is not a word, so a voiced
  te-stem can propose three verb classes and keep the one that exists. Grammar points are matched
  against the token sequence rather than the raw text, which needed no content change and stops a
  one-character particle matching inside a longer word. Four checks report **possible** issues, each
  carrying the exemptions that keep it quiet. New content: a function-word table of about ninety
  particles, copula forms, auxiliaries and formal nouns with `fw:` ids, authoritative over the
  vocabulary for the same surface. The load-bearing test is that every example sentence the app
  ships parses without an unknown token; the five words the vocabulary genuinely lacks are listed in
  a capped fixture, each citing the example that needs it. Three parts of the M2.3 design were
  dropped as unnecessary and one deferred, each recorded in `PLAN.md`'s decisions log: no
  TinySegmenter port, no new token/POS match schema, one column at every window size, and the
  AICore enhancement left as a `SentenceEnhancer` seam with no implementation.

- `0.1.0` — 2026-09-03. First release: the Phase 1 reference app. Built from M1.0 through M1.4 in
  one day; the four milestone paragraphs below are what shipped in it, in the order they landed.

  Verified on this host by `flutter analyze` (clean), 174 tests including a whole-app smoke test
  that walks every tab against the real generated catalog, and release builds of both the APK and
  the app bundle. **Not verified on a device:** the development host has no emulator and no
  attached phone, so the foldable screenshot pass and a sync against a real WebDAV server are
  outstanding. The golden transcripts cover the sync, backup and ZIP protocols against an in-memory
  server instead.

  Project skeleton (`PLAN.md` M1.0) — Android target, five-tab shell with the
  series' adaptive layout and navigation rail, kana chart ported from MyAnime!!!!! with its data
  extracted into a catalog model, bundled vocabulary and grammar seed content (24 N5 words, 8 N5
  grammar points, English and Simplified Chinese) with browser pages, the synced `StudyRecord`
  progress model with unknown-field preservation, the `nihongo_progress.json` data module and the
  four facades over `myapps_data`, settings with theme/language/storage/about in two panes on wide
  windows, English and Simplified Chinese UI, tests for layout rules, pages, JSON compatibility,
  the module contract and the content rules, bilingual documentation, an Android CI workflow that runs on every push to `main`, and the app icon
  with iOS default / dark / tinted variants (the `ios/` folder is scaffolded for the icon set only
  and is not built by CI).

  Sync and backup UI (`PLAN.md` M1.1): the WebDAV configuration page with manual sync, force
  upload and download, and a live status subtitle on its settings row; a conflict dialog that names
  each record through the content catalog and lets the user keep either version; the backup page
  with automatic backups, retention, restore by module and a post-restore force-upload offer; ZIP
  export and import; golden request transcripts covering all three engines. The progress provider
  became a `StateNotifierProvider` that subscribes to `AutoSyncService` once on every page's
  behalf. A shared-package fix landed with it: `WebDavClient.download` now decodes UTF-8 bytes
  instead of `response.body`, which `package:http` decodes as latin1 when the server sends no
  charset — it corrupted every downloaded record id containing kana.

  Content pipeline (`PLAN.md` M1.2): the vocabulary became 7,744 entries across N5 to N1, generated
  offline from JMdict and the JLPT lists by `tool/import_vocab.dart`, with the 24 hand-written seed
  ids kept as aliases so no progress is orphaned; 81 N5 grammar points; 21 kana teaching notes; a
  Hepburn romanizer; and machine-authored, unreviewed Chinese glosses for every N5 word. Parsing
  moved to a background isolate and the catalog lookups became maps.

  Reference polish (`PLAN.md` M1.3): a kana detail sheet with example words, cross-links between
  vocabulary and grammar examples, a remembered tab, level filter, script and column count per
  device, and a column-count control on the reference lists. The screenshot pass is still
  outstanding: no emulator runs on the development host.

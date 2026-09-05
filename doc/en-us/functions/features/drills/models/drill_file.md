# lib/features/drills/models/drill_file.dart

Parses one drill file and the structure file, and turns a drill question into the shape the quiz
runner already knows.

A malformed row costs the row, never the file — the same stance as `LessonPath`, and for the same
reason: these files are hand-written and hand-merged, and one bad question must not empty a level.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Parse a drill file and adapt its questions to the runner. |
| [`ExamScale`](#scale) | enum | A | How much of a paper an exam asks. |
| `DrillPassage` | class | B | One passage: a reading text, a listening script, or a 文章の文法 text. |
| `DrillPassage.fromJson` | static method | B | Parse one passage; null without an id, a known type or a line. |
| `ja` | getter | B | The whole passage as one string, for a reading text. |
| `DrillQuestion` | class | B | One question on a paper. |
| [`DrillQuestion.fromJson`](#qfromjson) | static method | A | Parse one question, refusing anything that could not be asked or marked. |
| `itemId` | getter | B | The catalog id the answer is recorded against — the first of `items`. |
| [`toQuizQuestion`](#toquiz) | method | A | Turn a paper's question into the one the quiz runner renders. |
| [`renderJa`](#renderja) | method | A | Render the Japanese the way this 大問 shows it. |
| `DrillFile` | class | B | One drill file: a level, a section, its passages and its questions. |
| `isEmpty` | getter | B | Whether this file has nothing to ask. |
| `passageById` | method | B | Find one passage; linear over at most a few dozen. |
| [`DrillFile.fromJson`](#ffromjson) | static method | A | Parse one drill file, checking its own level and section against the caller's. |
| `ScoringGroup` | class | B | One scoring group of a level, as JEES reports it. |
| `ExamBlockSpec` | class | B | One timed block of a paper: its sections and its minutes. |
| `LevelStructure` | class | B | One level's blocks, scoring groups and composition. |
| `fullCount` | getter | B | How many questions a full paper asks. |
| [`composition`](#composition) | method | A | How many questions of each type a paper at this scale asks. |
| `minutes` | method | B | How long each block runs at this scale, scaled the same way as the counts. |
| `groupFor` | method | B | Find the scoring group one section is marked under. |
| `LevelStructure.fromJson` | static method | B | Parse one level; null without blocks or types, dropping unknown type keys. |
| `JlptStructure` | class | B | The whole structure file: every level's paper, and where the numbers came from. |
| `empty` | constant | B | An instance with no levels, for a build whose asset failed to load. |
| `forLevel` | method | B | Look one level up. |
| `JlptStructure.fromJson` | static method | B | Parse the structure file; `empty` for anything unreadable. |
| `BlankStyle` | enum | B | How a 大問 shows the part of the sentence it is about: none, gap or marked. |
| `DrillTypeRendering` | extension | B | The rendering and reading rules each 大問 follows. |
| `blankStyle` | getter | B | Whether the span is shown whole, replaced by `（　　）`, or wrapped in `【…】`. |
| `hidesReading` | getter | B | Whether furigana must be withheld because the reading is the answer. |
| `needsPassage` | getter | B | Whether this type needs a passage on screen or in the ear. |
| `_list`, `_text`, `_nullIfEmpty`, `_int`, `_sameOrder` | functions | B | JSON-reading helpers used within this file only. |

## Documentation

### `enum ExamScale` <a id="scale"></a>

- **Kind:** enum
- **Purpose:** Say how much of a paper an exam asks: about a third of each 大問, or the official
  composition.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None; `LevelStructure.composition` and `LevelStructure.minutes` read it.
- **Usage:** `DrillSource.scale`, and the exam page.
- **Notes:** Here rather than beside the exam session because it is the *structure* that knows how to
  scale — the composition of a short paper is a fact about the paper, not about the session running
  it. `short` is the default: a full N1 paper is 165 minutes, the point of practising is to do it
  often, and an exam nobody has an afternoon for is not practice.

### `static DrillQuestion? fromJson(Object? json)` <a id="qfromjson"></a>

- **Kind:** static method
- **Purpose:** Parse one question from a drill file.
- **Inputs:** `json`.
- **Returns:** `DrillQuestion?` — null when it could not be asked or answered.
- **Side effects:** None.
- **Algorithm:** Refuse a row with no id, no known type, no `items`, an unknown `kind`, fewer than two
  options or an empty option. Then refuse an ordering question whose `answerOrder` is not a
  permutation of its fragments, and a choice question whose `answer` is not an index into `options`.
- **Usage:** `DrillFile.fromJson`.
- **Notes:** The refusals mirror `AuthoredQuestion.fromJson` and add the two this shape makes
  possible. Not a permutation means two fragments claim one position, or one position is claimed by
  none — either way the sentence cannot be rebuilt, so there is nothing to mark against. A question
  with no `items` cannot be recorded against anything. `items` is never empty and the **first** id is
  the one the scheduler sees; the rest are what the weakness report joins on, because a sentence can
  turn on two points and only one of them can own the review interval.

### `QuizQuestion toQuizQuestion(Locale locale)` <a id="toquiz"></a>

- **Kind:** method
- **Purpose:** Turn this into the question the quiz runner already renders.
- **Inputs:** The `locale` to resolve the written text in.
- **Returns:** `QuizQuestion`, with `mode: QuizMode.drill`.
- **Side effects:** None.
- **Algorithm:** The big line is `renderJa()` where the question shows Japanese and the localized
  question otherwise; the small line is the paper's instruction, carried only when there is Japanese
  above it; the reading is passed through unless the type hides it; `speakText` is always null.
- **Usage:** `quiz_page.dart`, per drawn question.
- **Notes:** The adapter `QuestionBank` never had a public equivalent of, and the one place the
  paper's conventions are turned into the app's. A reading question's question is the thing to
  answer, so making it a grey instruction under an empty prompt would bury it. The instruction is
  written per question because a paper writes it per 大問 and two 大問 that look identical ask for
  different things. The reading is withheld for the two types where the reading **is** the answer:
  printing furigana over 公園 in a 漢字読み question would answer it. `speakText` is null for every
  drill question — a listening drill is played by `ListeningScriptPlayer`, line by line, and a speak
  button that read the localized question aloud in a Japanese voice would be worse than none.

### `String renderJa()` <a id="renderja"></a>

- **Kind:** method
- **Purpose:** Render the Japanese the way this 大問 shows it.
- **Inputs:** None; reads `ja`, `blank` and the type's blank style.
- **Returns:** `String`; empty when there is no Japanese.
- **Side effects:** None.
- **Algorithm:** Return `ja` unchanged when there is no `blank` or it does not occur; otherwise
  replace the first occurrence with `（　　）` for a gap type, or wrap it in `【…】` for a marked type.
- **Usage:** `toQuizQuestion`.
- **Notes:** A gap is `（　　）` and a marked span is `【…】`, both full-width, because that is what the
  paper does and what a learner sitting the real thing will see. Only the **first** occurrence is
  touched: a sentence that says the word twice is asking about one of them, and blanking both would
  change the question.

### `static DrillFile fromJson(Object? json, {required JlptLevel level, required DrillSection section})` <a id="ffromjson"></a>

- **Kind:** static method
- **Purpose:** Parse one drill file.
- **Inputs:** `json`, and the `level` and `section` the caller asked for.
- **Returns:** `DrillFile` — empty when the JSON is not a file of that shape.
- **Side effects:** None.
- **Algorithm:** Return empty unless the JSON is a map whose own `level` and `section` both parse to
  what the caller asked for; then parse passages and questions, dropping any row that will not parse.
- **Usage:** `DrillRepository.load`.
- **Notes:** The level and section come from the caller and the file's own are checked against them.
  A file that says it is N4 grammar under the N5 vocabulary name is a merge accident, and loading it
  anyway would score N4 grammar as N5 vocabulary. One file per level per section, flat, so a section
  can be written and reviewed without touching another and `pubspec.yaml` gains one line for the
  whole of Phase 4.

### `Map<DrillType, int> composition(ExamScale scale)` <a id="composition"></a>

- **Kind:** method
- **Purpose:** Say how many questions of each type a paper at this scale asks.
- **Inputs:** `scale`.
- **Returns:** `Map<DrillType, int>`, unmodifiable.
- **Side effects:** None.
- **Algorithm:** `full` returns the official counts; `short` returns a third of each, rounded up,
  never below one.
- **Usage:** `quiz_page.dart` when drawing a paper, and the exam page.
- **Notes:** Rounding up rather than down is what keeps every 大問 on the paper: a third of a 大問
  with one question is a third of a question, and dropping it would quietly stop examining 情報検索
  at all. `minutes` scales the same way, so a short paper is under the same time pressure per
  question as a full one — and that pressure is most of what makes a mock different from practice.

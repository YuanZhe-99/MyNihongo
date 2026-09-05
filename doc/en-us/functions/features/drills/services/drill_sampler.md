# lib/features/drills/services/drill_sampler.dart

Draws one paper's worth of questions from the shipped files without asking the same thing twice.

Pure on purpose, with the randomness injected so a test can pin it. Sampling is the part of an exam
most likely to be wrong in a way nobody notices — a paper that quietly asks the same six questions
every time still looks like a paper — so it is testable in isolation rather than reachable only
through a page.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Draw one paper's questions without repeating what was already asked. |
| `DrillSampler` | class | B | Draws questions for one paper. |
| `DrillSampler._` | constructor | B | Prevent construction; every member is static. |
| [`draw`](#draw) | static method | A | Draw the questions for one section, in paper order. |
| [`drawByPassage`](#bypassage) | static method | A | Draw whole passages rather than questions scattered across them. |
| `_pick` | static method | B | Take the best `want` of a pool. |
| [`_order`](#order) | static method | A | Put never-asked members first, then least recently asked. |
| `sectionsWithContent` | static method | B | Say which sections a paper at this level actually has content for. |

## Documentation

### `static List<DrillQuestion> draw(DrillFile file, {required Map<DrillType, int> counts, Set<String> asked, Map<String, int> lastAsked, Random? random})` <a id="draw"></a>

- **Kind:** static method
- **Purpose:** Draw the questions for one section.
- **Inputs:** The `file`; `counts` per type; `asked` — every question id the learner has already been
  given; `lastAsked` — when each was last asked, as milliseconds since the epoch; a `random` for the
  shuffle.
- **Returns:** `List<DrillQuestion>` in the order the paper asks them, which is the order the types
  are declared in `DrillType`.
- **Side effects:** None.
- **Algorithm:** Bucket the file's questions by type, then walk `DrillType.values` in order, taking
  `_pick(pool, want, …)` from each type the composition asks for.
- **Usage:** A section drawn without passages; `drawByPassage` is what `quiz_page.dart` calls.
- **Notes:** `DrillType.values` order is the paper's order, so iterating it rather than `counts.keys`
  puts 漢字読み before 文脈規定 whatever order the structure file happened to write its type map in.
  A type with fewer questions than asked for yields what it has: the results screen says how many
  were asked, so a short section is visible rather than silently padded from another type.

### `static List<DrillQuestion> drawByPassage(DrillFile file, {…})` <a id="bypassage"></a>

- **Kind:** static method
- **Purpose:** Draw whole passages rather than questions scattered across them.
- **Inputs:** The same as `draw`.
- **Returns:** `List<DrillQuestion>`.
- **Side effects:** None.
- **Algorithm:** Per type, split the pool into questions with a passage and questions without. With
  no passages at all, fall back to `_pick` over the loose ones. Otherwise order the passage groups
  the same way individual questions are ordered and take whole groups until the count is met or
  passed, topping up from the loose questions if the groups ran out first.
- **Usage:** `quiz_page.dart`, for every section of a drawn paper.
- **Notes:** A reading or listening 大問 asks several questions about one text. Drawing questions
  independently would put one question from each of four passages on a short paper, which is four
  texts to read for four marks — four times the work of the paper it is imitating. So the unit drawn
  is the passage, and its questions come with it. A passage counts as "already asked" when every
  question on it is, and its recency is that of its most recently asked question: the learner
  remembers the text, not the individual questions about it. A question with no passage is drawn
  singly, which is what makes this safe to use for every section — 文章の文法 has a passage,
  文の文法1 does not, and both live in the grammar file.

### `static List<T> _order<T>(List<T> pool, bool Function(T) seen, int Function(T) when, Random rng)` <a id="order"></a>

- **Kind:** static method
- **Purpose:** Put never-asked members first, then least recently asked.
- **Inputs:** The `pool`; `seen` and `when` read one member; the `rng`.
- **Returns:** A new list; the input is not touched.
- **Side effects:** None.
- **Algorithm:** Split into fresh and used, shuffle each, then sort the used tier by timestamp.
- **Usage:** `_pick`, and `drawByPassage` over passage groups.
- **Notes:** Internal helper used within this file only. **Never-asked first, then least recently
  asked, then whatever is left** — the three tiers matter in that order: a learner who has seen forty
  of a level's sixty questions should be shown the twenty they have not, and once the pool is
  exhausted the oldest is the one they are most likely to have forgotten. The shuffle happens
  **within** each tier rather than across the whole pool, which is the whole point: a plain shuffle
  would show a question the learner saw yesterday as readily as one they have never seen. A stable
  sort would keep the shuffle inside equal timestamps; Dart's `sort` is not stable, so the shuffle is
  what breaks ties and the sort only has to get the order of distinct timestamps right.

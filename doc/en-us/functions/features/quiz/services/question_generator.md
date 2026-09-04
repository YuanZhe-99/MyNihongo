# lib/features/quiz/services/question_generator.dart

Turns a catalog item into a question, in whichever of the thirteen modes fits it.

**Returning null is the normal case, not an error.** Most words have no kanji, so
the two written-form modes do not apply; most have no example sentence, so the
grammar modes do not; and a word at a thin level may have no three plausible
distractors. The caller asks for what it wants and takes what it gets, which is
why every mode is attempted per item rather than chosen up front.

Behaviour is described in [`../../../../features/quizzes.md`](../../../../features/quizzes.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Turn a catalog item into a question. |
| `particleBlank` | top-level constant | B | The character a blanked-out token is replaced with. |
| `minOrderFragments` | top-level constant | B | How many pieces an ordering question needs. |
| `QuestionGenerator` | class | B | Build questions from catalog items. |
| `generate` | method | B | Build one question about one item in one mode. |
| [`forItem`](#foritem) | method | A | Build a question in whichever enabled mode works. |
| `_kana` | method | B | Build a kana question. |
| `_vocab` | method | B | Build a vocabulary question. |
| `_grammar` | method | B | Build a grammar question. |
| `_particle` | method | B | Blank out a particle and ask which one belongs. |
| `_particleOptions` | method | B | List particles that are not the answer. |
| [`_conjugation`](#conjugation) | method | A | Ask which inflected form belongs in a sentence. |
| `_order` | method | B | Break a sentence into chunks and ask for their order. |
| `_pattern` | method | B | Ask which grammar point a sentence uses. |
| [`_choice`](#choice) | method | A | Assemble a choice question with its options shuffled. |
| `_classOf` | method | B | Find a token's conjugation class through the lexicon. |
| `_sameOrder` | method | B | Compare two orderings. |

## Documentation

### `QuizQuestion? forItem(String itemId, Set<QuizMode> modes, {required Locale locale, KanaScript script})` <a id="foritem"></a>

- **Kind:** method
- **Purpose:** Build a question about an item in whichever enabled mode works.
- **Inputs:** The item, the modes the learner has left on, the locale, the script.
- **Returns:** `QuizQuestion?` — null when no enabled mode fits this item.
- **Side effects:** None.
- **Algorithm:** Shuffle the enabled modes, try each, return the first that produces a question.
- **Usage:** `QuizPage`, once per candidate item until the session is full.
- **Notes:** Shuffled rather than ordered so the same word is not always asked the same way. Trying
  every mode and taking what works is what lets one enabled-mode set serve kana, vocabulary and
  grammar items without the caller knowing which is which.

### `QuizQuestion? _conjugation(GrammarPoint point, SentenceAnalysis analysis, String translation)` <a id="conjugation"></a>

- **Kind:** method
- **Purpose:** Ask which inflected form belongs in a sentence.
- **Inputs:** The point, its parsed example, the translation.
- **Returns:** `QuizQuestion?`.
- **Side effects:** None.
- **Algorithm:** Find a token with recovered forms and a known conjugation class; extend across every
  auxiliary attached behind it to get the written form; ask the conjugator for all four forms of the
  lemma; keep the question only if one of them is exactly what the sentence says.
- **Usage:** `_grammar`.
- **Notes:** **An inflected form is several tokens.** The analyser splits 食べます into 食べ, carrying
  the recovered masu stem, and ます as its own auxiliary — that split is what makes parsing tractable
  — so the form has to be reassembled here. The match against the sentence's own text is what keeps
  the question honest: a "correct" answer that is not what the sentence says would teach the wrong
  thing, so a word the conjugator cannot reproduce is skipped rather than approximated.

### `QuizQuestion? _choice({...})` <a id="choice"></a>

- **Kind:** method
- **Purpose:** Assemble a multiple-choice question with its options shuffled.
- **Inputs:** The item, mode, prompt, the correct option and the wrong ones.
- **Returns:** `QuizQuestion?` — null when an option is duplicated or empty.
- **Side effects:** None.
- **Algorithm:** Combine, reject duplicates and blanks, shuffle, record where the answer landed.
- **Usage:** Every choice-shaped mode.
- **Notes:** The duplicate check is the last line of defence, and it is here rather than in each mode
  because no distractor rule can rule out a collision for every mode on its own. Two identical
  options mean two correct answers, and a question with two correct answers is worse than a question
  that was never asked.

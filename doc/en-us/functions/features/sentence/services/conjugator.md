# lib/features/sentence/services/conjugator.dart

Builds an inflected form from a dictionary form — the opposite direction from
`Deinflector`, which runs backwards because parsing does.

Only the four forms the conjugation quiz needs: polite, negative, past and te.
Deliberately **not** a general conjugation engine — a dozen more forms would each
need their own exceptions, and nothing yet asks for them.

Both directions share the row tables in [`godan_rows.md`](godan_rows.md), so a
quiz can never grade against a table the parser disagrees with.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Build an inflected form from a dictionary form. |
| `conjugatableForms` | top-level constant | B | The forms this can write, in teaching order. |
| `Conjugator` | class | B | Write inflected forms. |
| [`conjugate`](#conjugate) | method | A | Write one inflected form. |
| `allForms` | method | B | Write every form it can build for a word. |
| [`_godan`](#godan) | method | A | Inflect a godan verb. |
| `_godanTeStem` | method | B | Write the te or past ending, with 行く's exception. |
| `_ichidan` | method | B | Inflect an ichidan verb. |
| `_suru` | method | B | Inflect する and the compounds built on it. |
| `_kuru` | method | B | Inflect 来る, whose reading changes with the form. |
| `_iAdjective` | method | B | Inflect an i-adjective, including いい. |
| `_naAdjective` | method | B | Inflect the copula after a na-adjective. |

## Documentation

### `String? conjugate(String lemma, ConjClass conj, InflectionForm form)` <a id="conjugate"></a>

- **Kind:** method
- **Purpose:** Write one inflected form.
- **Inputs:** The dictionary form, its conjugation class, and the form wanted.
- **Returns:** `String?` — null when the class cannot take that form, or when the lemma does not look
  like a word of that class.
- **Side effects:** None.
- **Algorithm:** Dispatch on the class; each branch checks the lemma's ending before transforming it.
- **Usage:** `QuestionGenerator._conjugation`, through `allForms`.
- **Notes:** **Returning null rather than guessing is what keeps the quiz honest.** A distractor that
  is not a real form of the word teaches the wrong thing, and a question with no correct answer is
  worse still, so every caller drops the question when it cannot build enough forms. The ending check
  is not defensive clutter: a mis-classified entry would otherwise produce Japanese-looking strings
  that are not words.

### `String? _godan(String lemma, ConjClass conj, InflectionForm form)` <a id="godan"></a>

- **Kind:** method
- **Purpose:** Inflect a godan verb.
- **Inputs:** The lemma, its class, the form.
- **Returns:** `String?`.
- **Side effects:** None.
- **Algorithm:** Confirm the lemma ends in its class's u-row kana, drop it, and attach the i-row plus
  ます, the a-row plus ない, or the te/past ending.
- **Usage:** `conjugate`.
- **Notes:** The te and past forms are where the irregularity lives: the final kana decides the sound
  change, the voiced classes take だ and で rather than た and て, and **行く is a く verb that behaves
  like a つ one** — 行って, 行った, never 行いて. That check is on the lemma's ending rather than on the
  whole word, so compounds like 持って行く inherit it.

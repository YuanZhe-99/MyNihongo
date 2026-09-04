# lib/features/sentence/services/godan_rows.dart

The five kana rows a godan verb inflects through, shared by the de-inflector that
reads them backwards and the conjugator that writes them forwards.

Pulled out of `deinflector.dart` when M3.2 needed forward conjugation. **One
copy**, because two would eventually disagree and a quiz grading against a
different table from the one the analyser parses with would mark correct Japanese
wrong.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The kana rows a godan verb inflects through. |
| `godanURow` | top-level constant | B | The dictionary form's final kana: 行く, 話す, 飲む. |
| `godanIRow` | top-level constant | B | The row ます attaches to: 行き, 話し, 飲み. |
| [`godanARow`](#godanarow) | top-level constant | B | The row ない attaches to: 行か, 話さ, 飲ま. |
| `godanERow` | top-level constant | B | The potential and imperative stem: 行け, 話せ, 飲め. |
| `godanClasses` | top-level constant | B | Every godan class, so a caller can ask whether one is. |

## Documentation

### `godanARow` <a id="godanarow"></a>

`う` verbs take **わ**, not あ — 買わない, never 買あない. That single irregularity
is why these are tables rather than an offset computed from the u-row.

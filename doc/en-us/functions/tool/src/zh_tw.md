# tool/src/zh_tw.dart

The rule for where generated Traditional Chinese goes in a content file.

One small library, shared by `convert_zh_tw.dart` and its tests, holding the two content keys and the
walk that adds a `zh_TW` beside every `zh`. It is separate from the converter itself because the
*placement* rule and the *conversion* are different things: OpenCC decides what the characters
become, and this decides where they are written and when they are removed.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `zhTwKey` | constant | B | The content key the Traditional Chinese text is written under. |
| `zhKey` | constant | B | The content key the Simplified Chinese text is authored under. |
| [`withTraditional`](#with) | function | A | Add a generated Traditional string beside every Simplified one. |
| `_convertValue` | function | B | Convert one `zh` value, whether it is a string or a list of them. |
| `openCcDirectory` | constant | B | Where the OpenCC dictionaries live, relative to the repository root. |

## Documentation

### `Object? withTraditional(Object? json, String Function(String) convert)` <a id="with"></a>

- **Kind:** function
- **Purpose:** Add a generated Traditional Chinese string beside every Simplified one in a decoded
  content file.
- **Inputs:** `json` — anything `jsonDecode` returned; `convert` — the Simplified to Traditional
  conversion.
- **Returns:** The same structure with `zh_TW` set wherever `zh` exists.
- **Side effects:** None — a new structure is built, the input is not mutated.
- **Algorithm:** Walk the decoded structure. At every map, rebuild it in order, and immediately after
  a `zh` key write the converted `zh_TW`; drop any existing `zh_TW` that no longer has a `zh` in
  front of it. Recurse into lists and maps.
- **Usage:** `convert_zh_tw.dart`, once per content file.
- **Notes:** `zh_TW` is written **immediately after** `zh`, and any existing one is replaced. That is
  what makes the tool idempotent: re-running it on its own output produces a byte-identical file, so
  a rebuild with unchanged inputs leaves an empty `git diff` — which is what makes "did anyone forget
  to run it" an answerable question.

  A `zh_TW` whose `zh` has since been deleted goes with it, because **generated text may never
  outlive its source**. Left behind, it would be Traditional Chinese with nothing to check it
  against, and `content_zh_tw_test.dart` would have nothing to compare.

  `_convertValue` handles both shapes because the content stores a gloss as a list and an explanation
  as a string. Both go through the same place so neither is silently skipped.

  One string names the locale everywhere — the ARB file is `app_zh_TW.arb`, the stored preference is
  `zh_TW`, and this is the content key — so a reader who learns the tag in one place has learned it
  in all three.

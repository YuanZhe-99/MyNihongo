# lib/features/content/models/localized_strings.dart

Two value types the content models share. `LocalizedStrings` is a map of language code to a list
of strings — how content files store glosses, explanations and example translations — with a
locale-aware `resolve`, a display-only `resolveTranslation` that shows a Japanese reader nothing
rather than a foreign line under Japanese text, a `resolvedKey` that says which language `resolve`
drew from, and a cross-language `matches`. `ContentExample` is one Japanese sentence
with an optional kana reading and its translations; every JSON key other than `ja` and `reading` is
taken as a language. See [../../../../data-formats.md](../../../../data-formats.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LocalizedStrings.new` | constructor | B | Create a localized strings instance. |
| `LocalizedStrings.fromJson` | factory constructor | B | Parse a map of language code to a string or list of strings, or a bare string taken as English; non-string members are dropped. |
| `LocalizedStrings.isEmpty` | getter | B | Report whether no language has any string. |
| [`LocalizedStrings.lookupOrder`](#lookuporder) | static method | A | List the content keys to try for a locale, best first. |
| [`LocalizedStrings.resolve`](#resolve) | method | A | Pick the strings for a locale with English and then any-language fallback. |
| `LocalizedStrings.resolveJoined` | method | B | Pick the strings for a locale and join them for display. |
| [`LocalizedStrings.resolveTranslation`](#resolvetranslation) | method | A | Pick the translation of a Japanese text for a reader; a Japanese reader gets only `ja`, or nothing. |
| `LocalizedStrings.resolvedKey` | method | B | Say which language key `resolve` draws from for a locale (null when there are no values), so a display site can draw a Japanese definition with furigana. |
| `LocalizedStrings.resolveTranslationJoined` | method | B | Pick a translation for a reader and join it for display; empty when a Japanese reader has nothing to be shown. |
| `LocalizedStrings.matches` | method | B | Test whether any string in any language contains a lowercased query. |
| `ContentExample.new` | constructor | B | Create a content example instance. |
| `ContentExample.fromJson` | static method | B | Parse `{ja, reading?, <lang>: …}`; null when there is no Japanese sentence. |
| `ContentExample.listFromJson` | static method | B | Parse a list of examples, skipping malformed members. |

## Documentation

### `static List<String> lookupOrder(Locale locale)` <a id="lookuporder"></a>

- **Kind:** static method of `LocalizedStrings`
- **Source:** `lib/features/content/models/localized_strings.dart`
- **Purpose:** Say which content keys a locale should read, in order.
- **Inputs:** `locale`.
- **Returns:** `['zh_TW', 'zh', 'en']` for Traditional Chinese, `['zh', 'en']` for Simplified,
  `['en']` for English.
- **Side effects:** None.
- **Algorithm:** The full `language_COUNTRY` tag when there is a country, then the bare language,
  then `en` unless that is already the language.
- **Usage:** `resolve`, the function-word gloss dialog in `token_chips.dart`, and the prompt
  builder's choice of instruction block.
- **Notes:** The full tag comes first and the bare language second, which is the whole point:
  Traditional Chinese falls back to the Simplified text rather than to English, because every
  `zh_TW` string in the content is generated from the `zh` beside it and a missing one means there
  was no Chinese at all. It is public because the prompt templates and the function-word glosses
  are plain maps rather than `LocalizedStrings`, and three places deciding this separately is how
  they come to disagree.

### `List<String> resolve(Locale locale)` <a id="resolve"></a>

- **Kind:** method of `LocalizedStrings`
- **Source:** `lib/features/content/models/localized_strings.dart`
- **Purpose:** Pick the strings to show for the UI locale.
- **Inputs:** `locale` — normally `Localizations.localeOf(context)`.
- **Returns:** The list for the first key of [`lookupOrder`](#lookuporder) that is present; else
  the first language present; else an empty list.
- **Side effects:** None.
- **Algorithm:** Walk [`lookupOrder`](#lookuporder), then fall back to the first language there is.
- **Usage:**
  ```dart
  entry.meanings.resolveJoined(locale)
  ```
  (from the vocabulary tile in `vocab_page.dart`)
- **Notes:** The English fallback is why every entry must carry `en`; the any-language fallback
  exists so a partial entry still shows something rather than a blank. A display site showing the
  translation *of Japanese text* calls [`resolveTranslation`](#resolvetranslation) instead.

### `List<String> resolveTranslation(Locale locale)` <a id="resolvetranslation"></a>

- **Kind:** method of `LocalizedStrings`
- **Source:** `lib/features/content/models/localized_strings.dart`
- **Purpose:** Pick the translation of a Japanese text for a reader.
- **Inputs:** `locale`.
- **Returns:** `List<String>`; empty when there is nothing to show.
- **Side effects:** None.
- **Algorithm:** For a `ja` locale, the `ja` entry or an empty list; for every other locale,
  exactly [`resolve`](#resolve).
- **Usage:** Display sites only, through `resolveTranslationJoined` or an `isNotEmpty` test that
  hides the line: the translation under a catalog example (`exampleList` in `reference_widgets.dart`),
  a drill passage and its lines (`drill_passage_view.dart`), a scenario's dialogue lines and reply
  choices (`scenario_page.dart`), a generated example (`generated_examples.dart`), and the cloze
  subtitle in `question_generator.dart`.
- **Notes:** A Japanese reader is shown the `ja` entry when there is one (a generated example's
  easier-Japanese paraphrase) and **nothing** otherwise: an English line under a Japanese sentence,
  in a Japanese UI, is noise, and `resolve`'s last-resort first value could even be Chinese. Question
  logic that uses a translation as *material* must not call this; it decides separately what to do
  without one (see `_materialTranslation` in `question_generator.dart` and `translationQuizModes`
  in `quiz_question.dart`).

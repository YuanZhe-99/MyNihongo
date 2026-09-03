# lib/features/ai/services/prompt_builder.dart

The versioned prompt templates, and the builder that turns a deterministic analysis into the text
sent to the on-device model.

The prompts are a content asset rather than string literals for the reason every other content file
is one: a change to what the model is asked changes what the learner reads, and it should be
reviewable as a diff of data. They are **not** in the ARB files — nothing here is ever rendered.

Consumers: `aicore_sentence_enhancer.dart`, `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PromptTemplates` | class | B | The loaded templates. |
| `PromptTemplates.empty` | constant | B | The set used when the asset cannot be read. |
| `PromptTemplates.limit` | method | B | Look up a named cap, with a fallback. |
| `PromptTemplates.fromJson` | factory | B | Parse the template file, tolerantly. |
| `PromptTask` | class | B | One task's instruction and rules, in one language. |
| `PromptBuilder` | class | B | Builds the text sent to the model. |
| [`forIssue`](#forissue) | method | A | The prompt asking about one flagged issue. |
| `forSentence` | method | B | The prompt asking about the sentence as a whole. |
| [`forProofreading`](#forproofreading) | method | A | Prepare a sentence for the proofreading model. |
| [`_build`](#build) | method | A | Assemble one prompt. |
| `_words` | method | B | Render the token split as one line. |
| [`_grammar`](#grammar) | method | A | Quote the catalog's own explanation of each matched point. |
| `_span` | method | B | Quote a span of the sentence. |
| `_cap` | static method | B | Cut a string to a maximum length. |
| `loadPromptTemplates` | function | B | Read and parse the template asset. |

## Documentation

### `String? forIssue(SentenceAnalysis, Issue, String message, ContentCatalog?, String languageCode)` <a id="forissue"></a>

- **Kind:** method
- **Purpose:** Ask the model about one thing the checks flagged.
- **Inputs:** The analysis, the issue, **its already-worded message**, the catalog and the UI
  language.
- **Returns:** `String?` — null when the templates are missing.
- **Side effects:** None.
- **Algorithm:** Delegates to `_build` with the quoted span and the message as the note.
- **Usage:** `AiCoreSentenceEnhancer.explain`.
- **Notes:** `message` is passed in from the widget rather than re-derived here, and that is
  deliberate: it is the sentence on the learner's screen. A prompt that worded the issue differently
  would get an answer to a question they cannot see, sitting directly under the question they can.

### `String? forProofreading(String sentence)` <a id="forproofreading"></a>

- **Kind:** method
- **Purpose:** Decide whether a sentence can be proofread, and hand it over.
- **Inputs:** The `sentence`.
- **Returns:** `String?` — null when empty or too long.
- **Side effects:** None.
- **Algorithm:** Trim, reject empty, reject over the character cap.
- **Usage:** `AiCoreSentenceEnhancer.suggestCorrection`.
- **Notes:** Too long is a **refusal, not a truncation**. Proofreading half a sentence would offer a
  correction to a sentence the learner never wrote, which is worse than offering none. The cap is in
  characters against an API limit of 256 tokens, set low because Japanese tokenizes to more tokens
  per character than English.

### `String? _build({required String task, ...})` <a id="build"></a>

- **Kind:** method
- **Purpose:** Assemble one prompt from the templates and the analysis.
- **Inputs:** The task name, language code, analysis, catalog and an optional note.
- **Returns:** `String?`.
- **Side effects:** None.
- **Algorithm:** Pick the task's block for the language, falling back to English; write the sentence,
  the token split, the note, the grammar excerpts and the rules; cap the whole thing.
- **Usage:** `forIssue`, `forSentence`.
- **Notes:** Internal helper used within this file only. Every part is capped **before** the whole is,
  so a runaway grammar excerpt cannot push the rules off the end — losing the rules would silently
  turn a constrained request into an open one. The English fallback means an unsupported UI language
  still gets a working prompt rather than no feature at all.

### `List<String> _grammar(SentenceAnalysis, ContentCatalog?, String languageCode)` <a id="grammar"></a>

- **Kind:** method
- **Purpose:** Quote what the app itself teaches about each matched grammar point.
- **Inputs:** The analysis, the catalog and the language.
- **Returns:** At most the configured number of lines, each capped.
- **Side effects:** None.
- **Algorithm:** Walk the matches, resolve each point, prefer its explanation over its meaning, cap.
- **Usage:** `_build`.
- **Notes:** Internal helper used within this file only. **This is the grounding.** The model is
  handed the app's own teaching text and told not to contradict it, which is what stops an
  explanation drifting away from what the Grammar page says about the same point — the rule
  `AGENTS.md` states as generated text never replacing a deterministic result.

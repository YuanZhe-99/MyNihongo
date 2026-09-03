# lib/features/sentence/widgets/issue_list.dart

The possible issues the checks raised: the last section of the sentence lab.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `IssueList` | class | B | The findings, each quoting the part of the sentence it is about. |
| `build` | method | B | Build the issue list, or the "nothing looked unusual" line. |
| `_span` | method | B | Quote the part of the sentence an issue is about. |
| [`_message`](#message) | method | A | Word one issue. |

## Documentation

### `String _message(AppLocalizations l10n, Issue issue)` <a id="message"></a>

- **Kind:** method
- **Purpose:** Turn a finding into a sentence a learner can act on.
- **Inputs:** The localizations and the issue.
- **Returns:** One sentence.
- **Side effects:** None.
- **Algorithm:** A switch on the kind, choosing between two forms for the particle-frame case
  depending on whether a replacement can be named.
- **Usage:** `build`.
- **Notes:** Every message is worded as a possibility, because the analyser has no model of what the
  writer meant. The particle-frame case has two forms on purpose: naming a replacement verb is
  useful when the transitivity-pair table knows one, and inventing a suggestion when it does not
  would be worse than offering none.

# Reference preferences

Five small choices the app remembers per device, so the reference pages open
where the user left them. All of them live in `storage_config.json` alongside
theme and locale; none of them syncs, because a phone and a tablet want
different column counts and a device is where a habit lives.

| Key | Values | Default |
|---|---|---|
| `lastTab` | `learn`, `kana`, `vocab`, `grammar`, `settings` | Learn |
| `vocabLevel` | a JLPT label | all levels |
| `grammarLevel` | a JLPT label | all levels |
| `kanaScript` | `katakana` | hiragana |
| `referenceListColumns` | 1 to 4 | automatic |

A default is **removed** from the file rather than written as a value. The file
stays small, and a future change of default reaches every device that never
touched the setting. A value of the wrong type — the file is plain JSON in a
folder the user chooses, so it can be hand-edited — reads as unset rather than
throwing on launch.

## How a page reads them

`AppSettings` carries all five, and `appSettingsProvider` loads them once at
startup. Pages read them synchronously from the provider rather than starting
their own async read, so a filter tapped before the first load has landed is
not overwritten by it. `NihongoStorage` owns the typed getters and setters; the
notifier owns the in-memory state.

## The last tab

`main()` reads `lastTab` **before** `runApp` and hands it to
`buildAppRouter(initialLocation:)`, so the app opens on that tab rather than
showing Learn and jumping. An unknown value falls back to Learn. The router is
built once and kept in the root widget's state: a `GoRouter` owns navigation
history, so rebuilding one on a theme or locale change would send the user back
to the initial tab mid-session.

`ShellScaffold` writes the key on every tab switch, fire and forget. Losing that
write to a crash costs nothing more than starting on Learn.

## The two level filters

Vocabulary and grammar keep separate filters on purpose: a learner reading N3
grammar is often still looking up N5 words.

## The column count

One preference for both reference lists, because they use the same tile width
and the same rule; two settings would only ever disagree by accident. The
control is a popup menu in each list's header, hidden rather than disabled
where the window can only carry one column — a phone should not show a menu
that could not do anything.

The stored value is the choice, not the result. `referenceColumnCount` clamps
it to what actually fits, so a 4 chosen on a tablet renders as 2 on a folded
phone and comes back as 4 when the window grows again. See
[`../adaptive-layout.md`](../adaptive-layout.md).

# Store listing

The text for a Google Play listing and a GitHub release, kept here so it is
reviewed like anything else and so the two stay in step. Nothing here claims a
feature the build does not have.

## App name

MyNihongo!!!!!

## Short description (80 characters)

Kana, vocabulary and grammar reference. Offline, no ads, syncs to your own server.

## Full description

MyNihongo!!!!! is a Japanese reference you can open on the train and read on a
folded phone. It is offline, it has no account, and it never sends anything
anywhere except to a WebDAV server you configure yourself.

**What is in it**

- The full kana chart in both scripts, with the confusable pairs called out and
  example words for every kana.
- 7,700 words from N5 to N1, built from JMdict and the openly licensed JLPT
  lists, with readings, parts of speech and meanings.
- 81 N5 grammar points, each with a pattern, how it attaches, an explanation
  and example sentences with readings.
- Cross-links between all three: tap a word to see the grammar its examples
  use, tap a grammar point to see the words in its examples.
- Everything read aloud by your device's own speech engine, and pronunciation
  practice that compares what you said with the reading, mora by mora.
- A sentence lab: paste a sentence and see the words, what modifies what, which
  taught grammar it uses, and anything that looks unusual. Offline, no model.
- English and Simplified Chinese throughout. Chinese glosses cover N5; the rest
  show English.

**Your data is yours**

- No analytics, no ads, no crash reporting, no accounts.
- Sync is optional and goes to a WebDAV server you own — Nextcloud, or anything
  else that speaks WebDAV. Nothing is uploaded until you set one up.
- When the same word is studied on two devices, the app asks which version to
  keep rather than picking one silently.
- Local backups with a retention setting, and a ZIP export you can take
  anywhere.

**Built for foldables**

Every page decides its own layout: two kana tables side by side when the window
is wide enough, a settings list and detail pane together, and a column count
you can set yourself on the word and grammar lists.

**Not yet**

Pronunciation practice, spaced-repetition review and lessons are planned. The
app does not pretend to have them — the Learn tab says what is coming.

Free software under the GPLv3.

## What is new (0.2.0)

Everything can be read aloud, and pronunciation practice compares what you said
with the reading, mora by mora. A new sentence lab breaks a sentence into words,
structure and grammar points. Recognition runs on your device; a switch, off by
default, is the only way anything is ever sent to the system speech service.
Windows and macOS builds exist for development.

## What is new (0.1.0)

First release. Kana, vocabulary and grammar reference; WebDAV sync with
conflict resolution; local backup and ZIP transfer; English and Simplified
Chinese.

## Categories and tags

Education. Japanese, JLPT, kana, hiragana, katakana, vocabulary, grammar,
offline, WebDAV.

## Assets still needed

- Feature graphic, 1024 x 500.
- Phone screenshots, at least two, and tablet screenshots for the tablet
  listing. See [`../../tool/screenshots.md`](../../tool/screenshots.md) — these
  need real hardware, which the development host does not have.
- The launcher icon is already generated from `assets/icon/app_icon.png`.

## Data safety declaration

No data collected, no data shared. WebDAV sync is user-configured transfer to
the user's own server and is not collection by Google Play's definition; the
listing says so in the description rather than leaving it to be inferred.

The microphone is declared. It is used only while the learner is recording a
pronunciation attempt, no audio is stored, and recognition is offline unless the
learner turns on the network fallback — which the description and the privacy
policy both state.

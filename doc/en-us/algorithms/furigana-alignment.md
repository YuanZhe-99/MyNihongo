# Furigana alignment

Printing かな over かんじ needs to know which kana belong to which characters.
The catalog does not say. It carries one reading per word and one per sentence
— see [`../data-formats.md`](../data-formats.md) — and nothing that maps 学生 to
がくせい character by character. This is how that mapping is recovered from the
two strings, and, more importantly, when it refuses to.

## The problem

A reading is a flat string. A surface is a mix of characters that read
themselves and characters that do not:

```
私は学生です          わたしはがくせいです
```

は, で, す read themselves. 私 and 学生 do not. The kana in the surface are
therefore **anchors**: each must appear in the reading, in order, exactly where
the reading has got to. Everything between two anchors belongs to the kanji
between them. That is the whole algorithm, and for most words one pass answers
it.

## Why one pass is not enough

```
母は                  ははは
```

Taking the first は for 母 leaves はは after the anchor, and the anchor only
consumes one of them. The alignment is wrong and the leftover is what says so.
Taking two gives 母 = はは and the anchor consumes the last one exactly. The
reverse case exists too:

```
花は                  はなは
```

Here one kana is right, because 花 is はな and not はなは. Nothing local
distinguishes the two — the reading has to be consumed **completely** before an
alignment counts, so the search tries the shortest reading for each kanji run
first and backtracks when the rest does not fit.

## The rules

- **A run, not a character.** 東京 asks for one reading, not one per kanji.
  Per-character furigana would need per-character data, which does not exist;
  and 東 alone is not とう in every word.
- **At least one kana per character.** No reading is shorter than the
  characters it covers, which bounds the search from below.
- **At most what the runs after it can leave.** Every later run still needs its
  own minimum, which bounds it from above.
- **Katakana fold to hiragana for the comparison only.** テレビを見る reads
  てれびをみる in the content, and the surface still shows テレビ. Nothing else
  is folded: this is [`toHiragana`](../functions/features/kana/models/kana_text.md)'s
  job elsewhere, but that function drops punctuation and rewrites the
  long-vowel mark, and an aligner is matching positions rather than sounds.
- **Punctuation, spaces and the quiz blank anchor like kana.** They appear in
  both strings unchanged.
- **々, 〆, 〇, digits and Latin letters need a reading.** 日々 is ひび and
  ３時 is さんじ; both would otherwise anchor against kana that are not there.

## Failing is a result

`alignFurigana` returns null whenever no alignment consumes the whole reading:
a word with no reading in the content, a reading that belongs to a different
form of the word, a sentence the normalizer changed. Every caller then falls
back to what the app did before furigana existed — the reading on its own line,
or in brackets, or not at all.

**This is the important property.** A wrong alignment is not an uglier layout;
it prints kana over the wrong character, which teaches a reading that does not
exist. Refusing costs a line of screen. Guessing costs the learner.

## Cost

The state that decides the rest of the search is only *(which run, how far into
the reading)*, so a pair that has failed once can never succeed later. Failed
pairs are remembered, and the search is bounded by runs × reading length rather
than being exponential in the number of kanji runs. A sentence with a dozen of
them is drawn in a frame; without this it hangs.

## An inflected word is a special case

`Token.reading` from the sentence analyser is the **dictionary form's** reading:
食べ carries たべる, because that is what the lexicon stores and what
de-inflection matches against. Printing it over 食べ would show a る the
sentence does not contain. So `surfaceReadingOfToken` takes the kanji reading
from the lemma's own alignment and the kana tail from the surface as written.

来る is the one common word whose kanji changes reading as it inflects — き, こ,
く — and the kana that would say which are usually in the **next** token, since
来ます is split into 来 and ます. The recovered forms decide it, and a chain
that does not decide it leaves the chip unread rather than printing く where the
learner is about to say き.

## Blanking a sentence

A fill-in-the-blank question replaces a span of the sentence with `＿＿`. Its
reading has to lose the same span, or the kana above the sentence would answer
the question. `readingRangeFor` maps a span of the surface onto a span of the
reading: kana runs map one code unit to one, so a span may start or end inside
one, while a span that cuts a kanji run in half has no answer — half of
とうきょう is not the reading of 東 — and the question is shown without ruby.

## Where it is used

| Shown | Reading from |
|---|---|
| A word in the vocabulary list and its sheet | `VocabEntry.reading` |
| A word chip under a grammar point or a kana | `VocabEntry.reading` |
| An example sentence anywhere | `ContentExample.reading` |
| A quiz prompt, except where the reading is the answer | the entry, or the blanked sentence reading |
| A chip in the sentence lab | the token, corrected for its form |

The switch is **Settings › General › Kana over kanji**, on by default and stored
only when it is off — the one inverted preference in the app, because a learner
who has never opened Settings is the one who most needs the readings.

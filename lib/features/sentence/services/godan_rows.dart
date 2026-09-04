/// Purpose: The five kana rows a godan verb inflects through, shared by the
/// de-inflector that reads them backwards and the conjugator that writes them
/// forwards.
/// Inputs: None; these are tables.
/// Returns: Maps from conjugation class to the row kana.
/// Side effects: None.
/// Notes: Pulled out of `deinflector.dart` when M3.2 needed forward
/// conjugation for the "choose the form" quiz. One copy, because two would
/// eventually disagree and a quiz that grades against a different table from
/// the one the analyser parses with would mark correct Japanese wrong.
library;

import 'lexicon.dart';

/// The dictionary form's final kana: 行く, 話す, 飲む.
const godanURow = {
  ConjClass.godanU: 'う',
  ConjClass.godanKu: 'く',
  ConjClass.godanGu: 'ぐ',
  ConjClass.godanSu: 'す',
  ConjClass.godanTsu: 'つ',
  ConjClass.godanNu: 'ぬ',
  ConjClass.godanBu: 'ぶ',
  ConjClass.godanMu: 'む',
  ConjClass.godanRu: 'る',
};

/// The i-row, which ます attaches to: 行き, 話し, 飲み.
const godanIRow = {
  ConjClass.godanU: 'い',
  ConjClass.godanKu: 'き',
  ConjClass.godanGu: 'ぎ',
  ConjClass.godanSu: 'し',
  ConjClass.godanTsu: 'ち',
  ConjClass.godanNu: 'に',
  ConjClass.godanBu: 'び',
  ConjClass.godanMu: 'み',
  ConjClass.godanRu: 'り',
};

/// The a-row, which ない attaches to: 行か, 話さ, 飲ま.
///
/// `う` verbs take わ rather than あ — 買わない, never 買あない. That single
/// irregularity is why this is a table and not an offset.
const godanARow = {
  ConjClass.godanU: 'わ',
  ConjClass.godanKu: 'か',
  ConjClass.godanGu: 'が',
  ConjClass.godanSu: 'さ',
  ConjClass.godanTsu: 'た',
  ConjClass.godanNu: 'な',
  ConjClass.godanBu: 'ば',
  ConjClass.godanMu: 'ま',
  ConjClass.godanRu: 'ら',
};

/// The e-row, the potential and imperative stem: 行け, 話せ, 飲め.
const godanERow = {
  ConjClass.godanU: 'え',
  ConjClass.godanKu: 'け',
  ConjClass.godanGu: 'げ',
  ConjClass.godanSu: 'せ',
  ConjClass.godanTsu: 'て',
  ConjClass.godanNu: 'ね',
  ConjClass.godanBu: 'べ',
  ConjClass.godanMu: 'め',
  ConjClass.godanRu: 'れ',
};

/// Every godan class, so a caller can ask whether a class is one.
const godanClasses = {
  ConjClass.godanU,
  ConjClass.godanKu,
  ConjClass.godanGu,
  ConjClass.godanSu,
  ConjClass.godanTsu,
  ConjClass.godanNu,
  ConjClass.godanBu,
  ConjClass.godanMu,
  ConjClass.godanRu,
};

/// The o-row, which the plain volitional attaches to: 行こ, 話そ, 飲も.
///
/// Added with the N4 content, which is where the plain volitional first
/// appears: ましょう is polite and is one function word, but 帰ろう has to be
/// taken apart. An ichidan verb has no o-row — 食べよう is the ない-stem plus
/// よう — which is why the table is godan only, like every other row here.
const godanORow = {
  ConjClass.godanU: 'お',
  ConjClass.godanKu: 'こ',
  ConjClass.godanGu: 'ご',
  ConjClass.godanSu: 'そ',
  ConjClass.godanTsu: 'と',
  ConjClass.godanNu: 'の',
  ConjClass.godanBu: 'ぼ',
  ConjClass.godanMu: 'も',
  ConjClass.godanRu: 'ろ',
};

/// Purpose: Build an inflected form from a dictionary form, the opposite
/// direction from the de-inflector.
/// Inputs: A lemma, its conjugation class, and the form wanted.
/// Returns: The written form, or null where the combination does not exist.
/// Side effects: None.
/// Notes: Only the four forms the conjugation quiz needs — polite, negative,
/// past and te. Going forwards is what a quiz needs and what the analyser never
/// did: `Deinflector` runs backwards because parsing does, and the two share the
/// row tables in `godan_rows.dart` so a quiz can never grade against a table the
/// parser disagrees with. Deliberately **not** a general conjugation engine: a
/// dozen more forms would each need their own exceptions, and nothing yet asks
/// for them.
library;

import '../models/token.dart';
import 'godan_rows.dart';
import 'lexicon.dart';

/// The forms this conjugator can write, in teaching order.
const conjugatableForms = [
  InflectionForm.polite,
  InflectionForm.negative,
  InflectionForm.past,
  InflectionForm.te,
];

/// Writes inflected forms from dictionary forms.
class Conjugator {
  /// Purpose: Create a conjugator.
  /// Inputs: None.
  /// Returns: A new `Conjugator` instance.
  /// Side effects: None.
  /// Notes: Stateless; `const` so a widget can hold one without ceremony.
  const Conjugator();

  /// Purpose: Write one inflected form.
  /// Inputs: `lemma` — the dictionary form; `conj` — its class; `form`.
  /// Returns: `String?` — null when the class cannot take that form, or when
  /// the lemma does not look like a word of that class.
  /// Side effects: None.
  /// Notes: Returning null rather than guessing is what keeps the quiz honest:
  /// a distractor that is not a real form of the word teaches the wrong thing,
  /// and a question with no correct answer is worse still. Every caller drops
  /// the question when it cannot build enough forms.
  String? conjugate(String lemma, ConjClass conj, InflectionForm form) {
    if (lemma.isEmpty) return null;
    if (godanClasses.contains(conj)) return _godan(lemma, conj, form);
    return switch (conj) {
      ConjClass.ichidan => _ichidan(lemma, form),
      ConjClass.suru => _suru(lemma, form),
      ConjClass.kuru => _kuru(lemma, form),
      ConjClass.iAdjective || ConjClass.iiAdjective => _iAdjective(lemma, form),
      ConjClass.naAdjective => _naAdjective(lemma, form),
      _ => null,
    };
  }

  /// Purpose: Write every form this conjugator can build for a word.
  /// Inputs: `lemma`, `conj`.
  /// Returns: A map from form to written form, skipping any that are null.
  /// Side effects: None.
  /// Notes: What a question generator wants: one call, then pick a correct
  /// answer and distractors from the same set.
  Map<InflectionForm, String> allForms(String lemma, ConjClass conj) {
    final out = <InflectionForm, String>{};
    for (final form in conjugatableForms) {
      final written = conjugate(lemma, conj, form);
      if (written != null) out[form] = written;
    }
    return out;
  }

  /// Purpose: Inflect a godan verb.
  /// Inputs: `lemma`, `conj`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The past and te forms
  /// are the irregular ones: the final kana decides the sound change (行く is
  /// the famous exception, 行った not 行いた), and the voiced classes take だ
  /// and で rather than た and て.
  String? _godan(String lemma, ConjClass conj, InflectionForm form) {
    final expected = godanURow[conj];
    if (expected == null || !lemma.endsWith(expected)) return null;
    final stem = lemma.substring(0, lemma.length - 1);
    return switch (form) {
      InflectionForm.polite => '$stem${godanIRow[conj]}ます',
      InflectionForm.negative => '$stem${godanARow[conj]}ない',
      InflectionForm.past => '$stem${_godanTeStem(lemma, conj, past: true)}',
      InflectionForm.te => '$stem${_godanTeStem(lemma, conj, past: false)}',
      _ => null,
    };
  }

  /// Purpose: Write the te or past ending of a godan verb.
  /// Inputs: `lemma`, `conj`, and whether the past is wanted.
  /// Returns: `String` — the part that replaces the final kana.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. 行く is checked before
  /// the class, because it is a く verb that behaves like a つ one: 行って,
  /// 行った. The check is on the lemma's ending so 持って行く inflects too.
  String _godanTeStem(String lemma, ConjClass conj, {required bool past}) {
    final te = past ? 'た' : 'て';
    final de = past ? 'だ' : 'で';
    if (lemma.endsWith('行く') || lemma == 'いく') return 'っ$te';
    return switch (conj) {
      ConjClass.godanU || ConjClass.godanTsu || ConjClass.godanRu => 'っ$te',
      ConjClass.godanNu || ConjClass.godanBu || ConjClass.godanMu => 'ん$de',
      ConjClass.godanKu => 'い$te',
      ConjClass.godanGu => 'い$de',
      ConjClass.godanSu => 'し$te',
      _ => te,
    };
  }

  /// Purpose: Inflect an ichidan verb.
  /// Inputs: `lemma`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The easy class: drop
  /// る and attach.
  String? _ichidan(String lemma, InflectionForm form) {
    if (!lemma.endsWith('る')) return null;
    final stem = lemma.substring(0, lemma.length - 1);
    return switch (form) {
      InflectionForm.polite => '$stemます',
      InflectionForm.negative => '$stemない',
      InflectionForm.past => '$stemた',
      InflectionForm.te => '$stemて',
      _ => null,
    };
  }

  /// Purpose: Inflect する and the compound verbs built on it.
  /// Inputs: `lemma`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. 勉強する inflects like
  /// する with its noun in front, so the ending is what is matched.
  String? _suru(String lemma, InflectionForm form) {
    final stem = lemma.endsWith('する')
        ? lemma.substring(0, lemma.length - 2)
        : null;
    if (stem == null) return null;
    return switch (form) {
      InflectionForm.polite => '$stemします',
      InflectionForm.negative => '$stemしない',
      InflectionForm.past => '$stemした',
      InflectionForm.te => '$stemして',
      _ => null,
    };
  }

  /// Purpose: Inflect 来る.
  /// Inputs: `lemma`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The reading changes
  /// with the form — き, こ — which the kanji hides, so the kana forms are
  /// written out and the kanji ones spelled explicitly rather than derived.
  String? _kuru(String lemma, InflectionForm form) {
    final kanji = lemma.endsWith('来る');
    final kana = lemma.endsWith('くる');
    if (!kanji && !kana) return null;
    final prefix = lemma.substring(0, lemma.length - 2);
    final (masu, nai, ta, te) = kanji
        ? ('来ます', '来ない', '来た', '来て')
        : ('きます', 'こない', 'きた', 'きて');
    return switch (form) {
      InflectionForm.polite => '$prefix$masu',
      InflectionForm.negative => '$prefix$nai',
      InflectionForm.past => '$prefix$ta',
      InflectionForm.te => '$prefix$te',
      _ => null,
    };
  }

  /// Purpose: Inflect an i-adjective.
  /// Inputs: `lemma`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. いい is irregular and
  /// inflects as よい in every form but the dictionary one, which is why the
  /// lexicon classes it separately.
  String? _iAdjective(String lemma, InflectionForm form) {
    if (!lemma.endsWith('い')) return null;
    final head = lemma.substring(0, lemma.length - 1);
    // いい inflects as よい, but only where the い it replaces is written in
    // kana: 良い keeps its kanji and becomes 良かった, not よかった.
    final stem = lemma.endsWith('いい')
        ? '${lemma.substring(0, lemma.length - 2)}よ'
        : head;
    return switch (form) {
      // An adjective's polite form is the plain form plus です — there is no
      // ます — and that holds for いい too: いいです, never よいです.
      InflectionForm.polite => '$lemmaです',
      InflectionForm.negative => '$stemくない',
      InflectionForm.past => '$stemかった',
      InflectionForm.te => '$stemくて',
      _ => null,
    };
  }

  /// Purpose: Inflect a na-adjective.
  /// Inputs: `lemma`, `form`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A na-adjective does not
  /// inflect at all; the copula after it does, which is what the learner has to
  /// choose.
  String? _naAdjective(String lemma, InflectionForm form) => switch (form) {
    InflectionForm.polite => '$lemmaです',
    InflectionForm.negative => '$lemmaではない',
    InflectionForm.past => '$lemmaだった',
    InflectionForm.te => '$lemmaで',
    _ => null,
  };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';
import 'package:my_nihongo/features/sentence/services/conjugator.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';

/// Purpose: Test the forward conjugator the "choose the form" quiz grades with.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Every case here is a form a learner would be marked wrong on if the
/// table were wrong, so they are spelled out rather than generated. The te and
/// past forms carry the weight: the sound change depends on the class, the
/// voiced classes take だ and で, and 行く is a く verb that behaves like a つ
/// one. A quiz that offers 行いた as the correct answer is worse than no quiz.
void main() {
  const c = Conjugator();

  test('a godan verb takes its i-row before ます', () {
    expect(c.conjugate('飲む', ConjClass.godanMu, InflectionForm.polite), '飲みます');
    expect(c.conjugate('話す', ConjClass.godanSu, InflectionForm.polite), '話します');
    expect(c.conjugate('書く', ConjClass.godanKu, InflectionForm.polite), '書きます');
  });

  test('a godan verb takes its a-row before ない, and う becomes わ', () {
    expect(c.conjugate('飲む', ConjClass.godanMu, InflectionForm.negative), '飲まない');
    expect(
      c.conjugate('買う', ConjClass.godanU, InflectionForm.negative),
      '買わない',
      reason: 'never 買あない',
    );
  });

  test('the godan te form follows the final kana, not the meaning', () {
    expect(c.conjugate('待つ', ConjClass.godanTsu, InflectionForm.te), '待って');
    expect(c.conjugate('飲む', ConjClass.godanMu, InflectionForm.te), '飲んで');
    expect(c.conjugate('遊ぶ', ConjClass.godanBu, InflectionForm.te), '遊んで');
    expect(c.conjugate('書く', ConjClass.godanKu, InflectionForm.te), '書いて');
    expect(c.conjugate('泳ぐ', ConjClass.godanGu, InflectionForm.te), '泳いで');
    expect(c.conjugate('話す', ConjClass.godanSu, InflectionForm.te), '話して');
    expect(c.conjugate('帰る', ConjClass.godanRu, InflectionForm.te), '帰って');
  });

  test('行く is the exception every learner meets', () {
    expect(c.conjugate('行く', ConjClass.godanKu, InflectionForm.te), '行って');
    expect(c.conjugate('行く', ConjClass.godanKu, InflectionForm.past), '行った');
    expect(
      c.conjugate('持って行く', ConjClass.godanKu, InflectionForm.te),
      '持って行って',
      reason: 'the exception is on the ending, so compounds inherit it',
    );
  });

  test('the past form is the te form with た instead of て', () {
    expect(c.conjugate('飲む', ConjClass.godanMu, InflectionForm.past), '飲んだ');
    expect(c.conjugate('書く', ConjClass.godanKu, InflectionForm.past), '書いた');
    expect(c.conjugate('話す', ConjClass.godanSu, InflectionForm.past), '話した');
  });

  test('an ichidan verb drops る and attaches', () {
    expect(c.conjugate('食べる', ConjClass.ichidan, InflectionForm.polite), '食べます');
    expect(c.conjugate('食べる', ConjClass.ichidan, InflectionForm.negative), '食べない');
    expect(c.conjugate('食べる', ConjClass.ichidan, InflectionForm.past), '食べた');
    expect(c.conjugate('食べる', ConjClass.ichidan, InflectionForm.te), '食べて');
  });

  test('する compounds inflect on their ending', () {
    expect(c.conjugate('する', ConjClass.suru, InflectionForm.polite), 'します');
    expect(
      c.conjugate('勉強する', ConjClass.suru, InflectionForm.te),
      '勉強して',
    );
    expect(c.conjugate('する', ConjClass.suru, InflectionForm.past), 'した');
  });

  test('来る changes reading with the form, in kana and in kanji', () {
    expect(c.conjugate('来る', ConjClass.kuru, InflectionForm.polite), '来ます');
    expect(c.conjugate('来る', ConjClass.kuru, InflectionForm.negative), '来ない');
    expect(c.conjugate('くる', ConjClass.kuru, InflectionForm.polite), 'きます');
    expect(
      c.conjugate('くる', ConjClass.kuru, InflectionForm.negative),
      'こない',
      reason: 'the reading changes where the kanji hides it',
    );
  });

  test('an i-adjective takes です rather than ます', () {
    expect(c.conjugate('高い', ConjClass.iAdjective, InflectionForm.polite), '高いです');
    expect(c.conjugate('高い', ConjClass.iAdjective, InflectionForm.negative), '高くない');
    expect(c.conjugate('高い', ConjClass.iAdjective, InflectionForm.past), '高かった');
    expect(c.conjugate('高い', ConjClass.iAdjective, InflectionForm.te), '高くて');
  });

  test('いい inflects as よい, but 良い keeps its kanji', () {
    expect(c.conjugate('いい', ConjClass.iiAdjective, InflectionForm.negative), 'よくない');
    expect(c.conjugate('いい', ConjClass.iiAdjective, InflectionForm.past), 'よかった');
    expect(
      c.conjugate('良い', ConjClass.iiAdjective, InflectionForm.past),
      '良かった',
      reason: 'the reading changes; the writing does not',
    );
    expect(
      c.conjugate('いい', ConjClass.iiAdjective, InflectionForm.polite),
      'いいです',
      reason: 'よいです is not what anybody says',
    );
  });

  test('a na-adjective does not inflect; the copula after it does', () {
    expect(c.conjugate('静か', ConjClass.naAdjective, InflectionForm.polite), '静かです');
    expect(
      c.conjugate('静か', ConjClass.naAdjective, InflectionForm.negative),
      '静かではない',
    );
    expect(c.conjugate('静か', ConjClass.naAdjective, InflectionForm.past), '静かだった');
  });

  test('a word that does not fit its class produces nothing', () {
    // Better a missing question than a question whose answer is not Japanese.
    expect(c.conjugate('飲む', ConjClass.ichidan, InflectionForm.polite), isNull);
    expect(c.conjugate('食べる', ConjClass.godanMu, InflectionForm.polite), isNull);
    expect(c.conjugate('', ConjClass.ichidan, InflectionForm.polite), isNull);
  });

  test('a form outside the four supported ones produces nothing', () {
    expect(
      c.conjugate('飲む', ConjClass.godanMu, InflectionForm.causative),
      isNull,
    );
  });

  test('allForms gives the whole set a question can be built from', () {
    final forms = c.allForms('食べる', ConjClass.ichidan);
    expect(forms.keys, containsAll(conjugatableForms));
    expect(forms.values.toSet(), hasLength(4), reason: 'four distinct answers');
  });

  test('an unconjugable class yields an empty set rather than junk', () {
    expect(c.allForms('本', ConjClass.none), isEmpty);
  });
}

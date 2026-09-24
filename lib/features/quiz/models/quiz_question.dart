/// Purpose: One question, in a shape every mode and every answer widget can
/// share.
/// Inputs: Built by `QuestionGenerator` from the catalog.
/// Returns: An immutable value.
/// Side effects: None.
/// Notes: One class rather than a subclass per mode. The modes differ in what
/// they show and where the options come from, not in how they are answered —
/// there are only three answer shapes — so a sealed hierarchy would have put
/// thirteen classes behind three widgets.
library;

import 'dart:ui' show Locale;

/// Every way the app can ask about something.
///
/// The name of each value is persisted in the `quizModes` preference, so these
/// names are a compatibility contract: a renamed value silently turns a mode
/// the learner switched off back on.
enum QuizMode {
  /// Japanese word shown, pick the meaning.
  vocabJaToMeaning,

  /// Meaning shown, pick the Japanese word.
  vocabMeaningToJa,

  /// Reading shown, pick the word as written.
  vocabReadingToKanji,

  /// Word as written, pick its reading.
  vocabKanjiToReading,

  /// Word spoken, pick the meaning; the text stays hidden until answered.
  vocabListening,

  /// Word shown, type its reading.
  vocabTypeReading,

  /// A sentence with the word blanked out of it, pick which word belongs.
  vocabCloze,

  /// Kana shown, pick the romaji.
  kanaToRomaji,

  /// Romaji shown, pick the kana.
  romajiToKana,

  /// Kana spoken, pick which it was.
  kanaListening,

  /// A sentence with one particle blanked out.
  grammarParticle,

  /// A verb or adjective, pick the form asked for.
  grammarConjugation,

  /// A sentence in pieces, put them in order.
  grammarOrder,

  /// A sentence shown, pick the grammar point it uses.
  grammarPattern,

  /// A whole sentence shown, pick what it means.
  grammarSentenceToMeaning,

  /// A meaning shown, pick the sentence that says it.
  grammarMeaningToSentence,

  /// A meaning shown, type the Japanese sentence that says it.
  ///
  /// The one free-response mode: nothing on screen to choose from, so the
  /// learner has to produce the whole sentence. Marked against the catalog's
  /// own sentence and its reading; with on-device AI switched on, a different
  /// wording that means the same can be accepted by the model's second
  /// opinion, exactly as a typed reading can.
  grammarTypeSentence,

  /// A question a JLPT drill file asks, which says for itself what it wants.
  ///
  /// **Not selectable.** The other seventeen are ways this app can invent a
  /// question about a catalog entry, and the learner turns them on and off.
  /// This one means the question was written for a paper, so switching it off
  /// would only mean refusing to sit the paper — which is what not opening it
  /// already does.
  drill,
}

/// How a question is answered, which decides the widget that renders it.
enum AnswerKind {
  /// Pick one of several options.
  choice,

  /// Type the answer.
  typed,

  /// Put fragments in order.
  order,
}

/// The catalogs each mode draws from, so a source can say which modes apply.
const vocabQuizModes = {
  QuizMode.vocabJaToMeaning,
  QuizMode.vocabMeaningToJa,
  QuizMode.vocabReadingToKanji,
  QuizMode.vocabKanjiToReading,
  QuizMode.vocabListening,
  QuizMode.vocabTypeReading,
  QuizMode.vocabCloze,
};

/// The kana modes.
const kanaQuizModes = {
  QuizMode.kanaToRomaji,
  QuizMode.romajiToKana,
  QuizMode.kanaListening,
};

/// The grammar modes.
///
/// All but the four that work on a whole sentence need the sentence analyser,
/// which is why `sentenceQuizModes` is a separate set: a quiz that only asks
/// about whole sentences does not have to build the lexicon.
const grammarQuizModes = {
  QuizMode.grammarParticle,
  QuizMode.grammarConjugation,
  QuizMode.grammarOrder,
  QuizMode.grammarPattern,
  QuizMode.grammarSentenceToMeaning,
  QuizMode.grammarMeaningToSentence,
  QuizMode.grammarTypeSentence,
};

/// The modes that need the sentence analyser and are dropped without it.
const parsedQuizModes = {
  QuizMode.grammarParticle,
  QuizMode.grammarConjugation,
  QuizMode.grammarOrder,
  QuizMode.vocabCloze,
};

/// The modes that use the sentence analyser when it is there but still work
/// without it.
///
/// A typed sentence is marked more fairly with the lexicon — 私 typed where
/// the catalog wrote わたし reads the same once both are turned into kana — so
/// the quiz page loads the analyser for it; a session without one still asks
/// the question and marks it against the catalog's sentence and reading only.
const lexiconAidedQuizModes = {QuizMode.grammarTypeSentence};

/// The modes that speak rather than show, and so need a Japanese voice.
const listeningQuizModes = {QuizMode.vocabListening, QuizMode.kanaListening};

/// The modes whose material is a translation of a Japanese sentence, and so
/// are dropped for a Japanese reader.
///
/// A catalog example carries an English and a Chinese translation and no
/// Japanese one, because the sentence is already Japanese. Matching a sentence
/// to its English meaning, ordering fragments against an English gloss, or
/// typing the sentence an English meaning describes, is
/// not an exercise a Japanese UI can offer without showing the language the
/// learner chose not to read. They are shown as unavailable rather than
/// silently missing, the same rule listening modes follow without a voice.
const translationQuizModes = {
  QuizMode.grammarOrder,
  QuizMode.grammarSentenceToMeaning,
  QuizMode.grammarMeaningToSentence,
  QuizMode.grammarTypeSentence,
};

/// Purpose: Say whether a mode can be asked in this UI language.
/// Inputs: `mode`, `locale`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: False only for [translationQuizModes] under a Japanese UI.
bool quizModeWorksIn(QuizMode mode, Locale locale) =>
    locale.languageCode != 'ja' || !translationQuizModes.contains(mode);

/// The modes the learner may switch off, which is every mode the app invents.
///
/// `QuizMode.drill` is deliberately absent: see its own note. This set — not
/// `QuizMode.values` — is what "every mode is on" means in the preference, so
/// a learner who has switched nothing off keeps the empty-set default and
/// still gets any mode a later build adds.
const selectableQuizModes = {
  ...vocabQuizModes,
  ...kanaQuizModes,
  ...grammarQuizModes,
};

/// One question.
class QuizQuestion {
  /// Purpose: Create a question.
  /// Inputs: All fields; see each one.
  /// Returns: A new `QuizQuestion` instance.
  /// Side effects: None.
  /// Notes: `itemId` is the catalog id the answer is recorded against, which
  /// is not always what the question shows — a particle question shows a
  /// sentence but is about a grammar point.
  const QuizQuestion({
    required this.itemId,
    required this.mode,
    required this.kind,
    required this.prompt,
    this.promptReading,
    this.promptSubtitle,
    this.speakText,
    this.questionId,
    this.instruction,
    this.passageId,
    this.options = const [],
    this.optionReadings = const [],
    this.answerIndex,
    this.acceptedAnswers = const {},
    this.answerOrder = const [],
    this.formLabel,
    this.explanation,
    this.generated = false,
    this.authored = false,
  });

  /// The catalog id this question's answer is recorded against.
  final String itemId;

  /// Which way the question asks.
  final QuizMode mode;

  /// How it is answered.
  final AnswerKind kind;

  /// The main thing shown — a word, a reading, a meaning, or a sentence.
  ///
  /// Empty for a listening question until it has been answered: the whole
  /// point is that the learner hears it rather than reads it.
  final String prompt;

  /// The prompt's reading in kana, for printing over the kanji in it.
  ///
  /// Null for the modes where the reading **is** the answer, and for any
  /// prompt whose reading could not be aligned with what is shown.
  final String? promptReading;

  /// A smaller line under the prompt, such as a reading or a translation.
  final String? promptSubtitle;

  /// What the speak button says, or null when there is nothing to hear.
  ///
  /// Always the kana reading where the catalog has one, never the kanji: an
  /// engine handed 一日 has to guess between ついたち and いちにち.
  final String? speakText;

  /// The drill question's own id, where the question came from a drill file.
  ///
  /// Null for a generated question, because two questions built from one
  /// catalog entry are the same question asked twice. A drill question needs
  /// one because a paper asks several different questions about the same word,
  /// and the session scores each of them separately — see `QuizSession`.
  final String? questionId;

  /// What this particular question asks, when the mode label does not say it.
  ///
  /// A drill file writes its own instruction because a paper does: 「＿＿の
  /// ことばは　どう　よみますか」 is not the same request as 「（　）に　なにを
  /// いれますか」, and both are `QuizMode.grammarParticle` as far as the runner
  /// is concerned.
  final String? instruction;

  /// The passage this question is about, where there is one.
  ///
  /// Only an id: the passage itself belongs to the file, and several questions
  /// share one. The page joins it back.
  final String? passageId;

  /// The options for a choice question, or the fragments for an order one.
  final List<String> options;

  /// The reading of each option, where one is known.
  ///
  /// Empty when no option has one, and never partly filled: it is either the
  /// same length as [options] or empty, so an index into one is an index into
  /// the other. An entry may still be null for an option that is already kana.
  final List<String?> optionReadings;

  /// Which option is correct, for a choice question.
  final int? answerIndex;

  /// Every spelling accepted for a typed question, already normalized.
  final Set<String> acceptedAnswers;

  /// The correct order of [options], for an order question.
  final List<int> answerOrder;

  /// Which inflected form a conjugation question asks for, as an enum name the
  /// UI localizes.
  final String? formLabel;

  /// Why the right answer is right, when somebody wrote it down.
  ///
  /// Only a hand-written question has one. A generated question's reason is
  /// the catalog entry behind it, which the summary already links to.
  final String? explanation;

  /// Whether a model wrote this question rather than the catalog.
  ///
  /// A generated question is shown with the same label every other generated
  /// thing carries, and **its answer never reaches the scheduler**: the
  /// spacing of a word's reviews must not depend on a question that might be
  /// wrong about the word.
  final bool generated;

  /// Whether the question's own [prompt] is already the whole question.
  ///
  /// A unit file writes questions as a person would ask them — 「部屋に猫が
  /// ＿。」, 「哪一句是礼貌的说法？」 — so the mode's own line above it
  /// ("Which grammar point does this use?") describes a different question
  /// from the one on screen. Every authored unit question is filed under
  /// `QuizMode.grammarPattern` whatever it asks, which is why the mode cannot
  /// be trusted to introduce it and this flag suppresses the line instead.
  final bool authored;

  /// The correct option's text, for showing after a wrong answer.
  String? get answerText {
    final index = answerIndex;
    if (index == null || index < 0 || index >= options.length) return null;
    return options[index];
  }
}

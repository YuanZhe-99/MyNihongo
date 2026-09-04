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
};

/// The kana modes.
const kanaQuizModes = {
  QuizMode.kanaToRomaji,
  QuizMode.romajiToKana,
  QuizMode.kanaListening,
};

/// The grammar modes, every one of which needs the sentence analyser.
const grammarQuizModes = {
  QuizMode.grammarParticle,
  QuizMode.grammarConjugation,
  QuizMode.grammarOrder,
  QuizMode.grammarPattern,
};

/// The modes that speak rather than show, and so need a Japanese voice.
const listeningQuizModes = {QuizMode.vocabListening, QuizMode.kanaListening};

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
    this.context,
    this.options = const [],
    this.answerIndex,
    this.acceptedAnswers = const {},
    this.answerOrder = const [],
    this.formLabel,
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

  /// A sentence the question is about, with the blank already in it.
  final String? context;

  /// The options for a choice question, or the fragments for an order one.
  final List<String> options;

  /// Which option is correct, for a choice question.
  final int? answerIndex;

  /// Every spelling accepted for a typed question, already normalized.
  final Set<String> acceptedAnswers;

  /// The correct order of [options], for an order question.
  final List<int> answerOrder;

  /// Which inflected form a conjugation question asks for, as an enum name the
  /// UI localizes.
  final String? formLabel;

  /// The correct option's text, for showing after a wrong answer.
  String? get answerText {
    final index = answerIndex;
    if (index == null || index < 0 || index >= options.length) return null;
    return options[index];
  }
}

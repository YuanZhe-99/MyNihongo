import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../speech/widgets/speak_button.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../speech/services/tts_service.dart';
import '../models/quiz_question.dart';
import 'why_wrong.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../services/answer_checker.dart';
import '../services/quiz_session.dart';
import 'answer_panes.dart';

/// Runs one session on screen: the question, the answer controls, and the
/// feedback between them.
///
/// Splits into two panes when the window is the right shape — question fixed on
/// the left, answers on the right — and stacks otherwise. The gate is
/// [canSplitLayout], the same one every other split in the app uses; see
/// `doc/en-us/adaptive-layout.md`.
class QuizRunner extends ConsumerStatefulWidget {
  /// Purpose: Create the runner.
  /// Inputs: The `session` to run, and `onFinished`.
  /// Returns: A new `QuizRunner` instance.
  /// Side effects: None.
  /// Notes: The session is owned by the page above, which disposes it.
  const QuizRunner({
    super.key,
    required this.session,
    required this.onFinished,
  });

  /// The session being run.
  final QuizSession session;

  /// Called once the last question has been answered and dismissed.
  final VoidCallback onFinished;

  @override
  ConsumerState<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends ConsumerState<QuizRunner> {
  /// The answer the learner has composed but not submitted yet.
  QuizAnswer? _pending;
  String? _aiComment;
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Purpose: Redraw when the session moves on.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only.
  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  /// Purpose: Submit the composed answer.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Marks the answer, which records it and may reschedule.
  /// Notes: Internal helper used within this file only. Does nothing without a
  /// composed answer, so the button being enabled is the only gate.
  Future<void> _submit() async {
    final answer = _pending;
    final question = widget.session.current;
    if (answer == null || question == null) return;

    // The deterministic check first, because it is the one that decides
    // "correct" and it costs nothing.
    if (const AnswerChecker().check(question, answer)) {
      widget.session.answer(answer);
      return;
    }
    // A typed answer can be right in words the catalog does not list. With
    // on-device AI switched on, ask whether it means the same, and take a yes.
    // Nothing else is asked: a wrong multiple-choice answer is wrong.
    final second = await _secondOpinion(question, answer);
    if (!mounted) return;
    setState(() => _aiComment = second?.comment);
    widget.session.answer(answer, acceptedAnyway: second?.same ?? false);
  }

  /// Purpose: Ask the on-device model whether a typed answer means the same.
  /// Inputs: The `question` and the learner's `answer`.
  /// Returns: `GradeVerdict?` — null when nothing was asked or nothing came
  /// back that could be read.
  /// Side effects: Runs a model on the device; shows a spinner while it does.
  /// Notes: Internal helper used within this file only. Only for typed
  /// answers, only with the switch on, and only after the deterministic check
  /// has already said no. A model that hedges is refused by the parser and the
  /// answer stays wrong, which is where it started.
  Future<GradeVerdict?> _secondOpinion(
    QuizQuestion question,
    QuizAnswer answer,
  ) async {
    if (answer is! TypedAnswer) return null;
    if (!ref.read(aiAssistServiceProvider).canExplain) return null;
    final expected = question.acceptedAnswers.firstOrNull;
    if (expected == null) return null;
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return null;
    final prompt = builder.forGrading(
      answer.text,
      expected,
      locale: Localizations.localeOf(context),
    );
    if (prompt == null) return null;

    setState(() => _grading = true);
    try {
      final raw = await AiPracticeService.instance.run(prompt);
      return PracticeResponseParser.grade(raw);
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _grading = false);
    }
  }

  /// Purpose: Move past the feedback to the next question.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Advances the session, or finishes it.
  /// Notes: Internal helper used within this file only.
  void _continue() {
    setState(() {
      _pending = null;
      _aiComment = null;
    });
    widget.session.next();
    if (widget.session.isFinished) widget.onFinished();
  }

  /// Purpose: Build the question and its answer controls.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final question = widget.session.current;
    if (question == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final screen = MediaQuery.sizeOf(context);
    final outcome = widget.session.lastOutcome;
    final answered = outcome != null;

    final prompt = _QuestionPane(
      question: question,
      revealed: answered,
      progress: l10n.quizProgress(
        widget.session.answeredCount + (answered ? 0 : 1),
        widget.session.total,
      ),
    );
    final answers = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnswerPane(
          question: question,
          locked: answered,
          onChanged: (answer) => setState(() => _pending = answer),
          onSubmit: _submit,
        ),
        const SizedBox(height: 12),
        if (answered) _feedback(context, l10n, outcome, question),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _grading
              ? null
              : answered
              ? _continue
              : (_pending == null ? null : _submit),
          child: _grading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(answered ? l10n.quizContinue : l10n.quizCheck),
        ),
      ],
    );

    if (!canSplitLayout(screen.width, screen.height)) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + screen.height * 0.02),
        children: [prompt, const SizedBox(height: 20), answers],
      );
    }

    final content = referenceContentWidth(screen.width);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: quizQuestionPaneWidth(content),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
            child: prompt,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: answers,
          ),
        ),
      ],
    );
  }

  /// Purpose: Say whether the answer was right, and what the answer was.
  /// Inputs: `context`, `l10n`, the `outcome`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The right answer is
  /// always shown after a wrong one: an item re-queued without being told the
  /// answer is guessed at again rather than learnt.
  Widget _feedback(
    BuildContext context,
    AppLocalizations l10n,
    QuizOutcome outcome,
    QuizQuestion question,
  ) {
    // The option they picked, for the explanation to be about. Held until
    // Continue clears it, which is exactly as long as the feedback is shown.
    final pending = _pending;
    final chosen = pending is ChoiceAnswer ? pending.index : null;
    final theme = Theme.of(context);
    final color = outcome.correct
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              outcome.correct ? Icons.check_circle_outline : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              outcome.correct ? l10n.quizCorrect : l10n.quizWrong,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ],
        ),
        if (!outcome.correct && outcome.expected != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.quizExpected(outcome.expected!),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (_aiComment case final comment?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              outcome.correct ? l10n.quizAcceptedByAi(comment) : comment,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (!outcome.correct) WhyWrong(question: question, chose: chosen),
      ],
    );
  }
}

/// The half of the screen that asks the question.
class _QuestionPane extends ConsumerStatefulWidget {
  const _QuestionPane({
    required this.question,
    required this.revealed,
    required this.progress,
  });

  final QuizQuestion question;
  final bool revealed;
  final String progress;

  @override
  ConsumerState<_QuestionPane> createState() => _QuestionPaneState();
}

class _QuestionPaneState extends ConsumerState<_QuestionPane> {
  String? _spoken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakIfWanted());
  }

  @override
  void didUpdateWidget(_QuestionPane old) {
    super.didUpdateWidget(old);
    if (old.question.itemId != widget.question.itemId ||
        old.question.mode != widget.question.mode) {
      _speakIfWanted();
    }
  }

  /// Purpose: Read the question aloud when it appears, if that is wanted.
  /// Inputs: None; reads the question and the preference.
  /// Returns: None.
  /// Side effects: Speaks through the device's engine.
  /// Notes: Internal helper used within this file only. Spoken **once per
  /// question**, tracked by the text itself: a rebuild — from choosing an
  /// option, from the keyboard opening — must not start the audio again over
  /// itself. A listening question is unanswerable in silence, so this is what
  /// makes it work without a tap; every other question with audio gets the
  /// same treatment because hearing the word while reading it is the point.
  void _speakIfWanted() {
    if (!mounted) return;
    final text = widget.question.speakText;
    if (text == null || text.isEmpty || text == _spoken) return;
    if (!ref.read(appSettingsProvider).autoSpeak) return;
    if (!TtsService.instance.hasJapaneseVoice) return;
    _spoken = text;
    TtsService.instance.speak(text);
  }

  /// Purpose: Build the prompt, its subtitle and its speak button.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. A
  /// listening question's prompt is empty until it has been answered — the
  /// whole point is that the learner hears it rather than reads it — so the
  /// text appears only once `revealed` is true.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final question = widget.question;
    final revealed = widget.revealed;
    final progress = widget.progress;
    final listening = listeningQuizModes.contains(question.mode);
    final showPrompt = !listening || revealed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          progress,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // A generated question says so before it is read, not after it is
        // answered: the learner is entitled to know that this one was written
        // by a model on their phone and is not part of the catalog.
        if (question.generated) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.aiGeneratedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _instruction(l10n),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (showPrompt && question.prompt.isNotEmpty)
          FuriganaText(
            question.prompt,
            reading: question.promptReading,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (showPrompt && question.promptSubtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              question.promptSubtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (question.speakText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SpeakButton(
                text: question.speakText!,
                iconSize: listening ? 40 : null,
              ),
            ),
          ),
      ],
    );
  }

  /// Purpose: Say what the learner is being asked to do.
  /// Inputs: `l10n`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Every mode says it in
  /// words rather than relying on the shape of the question, because a
  /// conjugation blank and a particle blank look identical.
  String _instruction(AppLocalizations l10n) => switch (widget.question.mode) {
    QuizMode.vocabListening || QuizMode.kanaListening => l10n.quizListenPrompt,
    QuizMode.vocabTypeReading => l10n.quizTypeReadingHint,
    QuizMode.grammarOrder => l10n.quizOrderPrompt,
    QuizMode.grammarParticle => l10n.quizParticlePrompt,
    QuizMode.grammarConjugation => l10n.quizConjugationPrompt,
    QuizMode.grammarPattern => l10n.quizPatternPrompt,
    QuizMode.vocabCloze => l10n.quizClozePrompt,
    QuizMode.grammarSentenceToMeaning => l10n.quizSentenceToMeaningPrompt,
    QuizMode.grammarMeaningToSentence => l10n.quizMeaningToSentencePrompt,
    _ => l10n.quizModeLabel(widget.question.mode),
  };
}

/// Purpose: Name a quiz mode in the learner's language.
/// Inputs: The `mode`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: An extension rather than a free function so both the runner and the
/// modes page reach it the same way.
extension QuizModeLabel on AppLocalizations {
  /// Purpose: Name one quiz mode.
  /// Inputs: `mode`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Exhaustive on purpose — a new mode without a name is a compile
  /// error rather than a blank row in Settings.
  String quizModeLabel(QuizMode mode) => switch (mode) {
    QuizMode.vocabJaToMeaning => quizModeVocabJaToMeaning,
    QuizMode.vocabMeaningToJa => quizModeVocabMeaningToJa,
    QuizMode.vocabReadingToKanji => quizModeVocabReadingToKanji,
    QuizMode.vocabKanjiToReading => quizModeVocabKanjiToReading,
    QuizMode.vocabListening => quizModeVocabListening,
    QuizMode.vocabTypeReading => quizModeVocabTypeReading,
    QuizMode.kanaToRomaji => quizModeKanaToRomaji,
    QuizMode.romajiToKana => quizModeRomajiToKana,
    QuizMode.kanaListening => quizModeKanaListening,
    QuizMode.grammarParticle => quizModeGrammarParticle,
    QuizMode.grammarConjugation => quizModeGrammarConjugation,
    QuizMode.grammarOrder => quizModeGrammarOrder,
    QuizMode.grammarPattern => quizModeGrammarPattern,
    QuizMode.vocabCloze => quizModeVocabCloze,
    QuizMode.grammarSentenceToMeaning => quizModeGrammarSentenceToMeaning,
    QuizMode.grammarMeaningToSentence => quizModeGrammarMeaningToSentence,
  };
}

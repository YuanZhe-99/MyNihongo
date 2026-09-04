import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/models/content_catalog.dart';
import '../../content/services/content_repository.dart';
import '../../content/services/study_item_labels.dart';
import '../../kana/models/kana.dart';
import '../../progress/models/study_record.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../speech/services/tts_service.dart';
import '../models/quiz_config.dart';
import '../models/quiz_question.dart';
import '../../lessons/services/lesson_repository.dart';
import '../../lessons/services/lesson_rules.dart';
import '../services/question_bank.dart';
import '../services/question_generator.dart';
import 'dart:async';

import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/practice_prompt_builder.dart';
import '../../lessons/models/lesson_path.dart';
import '../services/ai_question_generator.dart';
import '../services/quiz_session.dart';
import '../widgets/quiz_runner.dart';

/// A quiz session, as a full-screen route outside the tab shell.
///
/// Outside the shell for the same reason the sentence lab is: it is something
/// entered with a purpose from somewhere else and left when it is finished, not
/// a place to browse. Entered with `context.push('/quiz', extra: config)`.
class QuizPage extends ConsumerStatefulWidget {
  /// Purpose: Create the quiz page.
  /// Inputs: The `config` describing the session.
  /// Returns: A new `QuizPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const QuizPage({super.key, required this.config});

  /// What the session is about.
  final QuizConfig config;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  QuizSession? _session;
  bool _building = true;
  bool _finished = false;

  /// Whether a checkpoint was passed, once one has been marked.
  bool? _checkpointPassed;

  @override
  void initState() {
    super.initState();
    // After the first frame, so the providers this reads are available and a
    // slow catalog load shows the page rather than blocking the route.
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  /// Purpose: Assemble the session's questions.
  /// Inputs: None; reads the config, the catalog and the queue.
  /// Returns: None.
  /// Side effects: Builds a `QuizSession` and rebuilds.
  /// Notes: Internal helper used within this file only. The analyser is awaited
  /// only when a grammar mode is enabled: building the lexicon takes tens of
  /// milliseconds over 7,700 entries, and a kana quiz has no use for it.
  Future<void> _build() async {
    final catalog = await ref.read(contentCatalogProvider.future);
    final modes = _enabledModes();
    final analyzer = modes.any(parsedQuizModes.contains)
        ? await ref.read(sentenceAnalyzerProvider.future)
        : null;

    final source = widget.config.source;
    final unit = source is UnitSource
        ? (await ref.read(
            lessonPathProvider(source.level).future,
          )).unitById(source.unitId)
        : null;
    if (!mounted) return;

    final generator = QuestionGenerator(catalog: catalog, analyzer: analyzer);
    final locale = Localizations.localeOf(context);
    final script = source is KanaRows ? source.script : KanaScript.hiragana;

    final questions = <QuizQuestion>[];
    if (unit != null) {
      // A unit is small enough to build its whole pool and then draw from it,
      // which is what makes a rare mode as likely as a common one.
      questions.addAll(
        QuestionBank.build(
          unit: unit,
          catalog: catalog,
          generator: generator,
          modes: modes,
          locale: locale,
        ).draw(
          widget.config.maxQuestions,
          progress:
              ref.read(progressDataProvider).value ??
              const ProgressData(records: []),
        ),
      );
    } else {
      for (final id in _itemIds(catalog)) {
        if (questions.length >= widget.config.maxQuestions) break;
        final question = generator.forItem(
          id,
          modes,
          locale: locale,
          script: script,
        );
        if (question != null) questions.add(question);
      }
    }

    if (!mounted) return;
    final session = questions.isEmpty
        ? null
        : QuizSession(
            questions: questions,
            onFirstAnswer: widget.config.recordProgress
                ? (id, correct) => ref
                      .read(progressDataProvider.notifier)
                      .recordAnswer(id, correct)
                : null,
          );
    setState(() {
      _building = false;
      _session = session;
    });
    // Extra questions are asked for only once the session is on screen, and
    // only for a unit: a generated question is about a grammar point this unit
    // teaches, and there is no such point outside one.
    if (session != null && unit != null) {
      unawaited(
        _generate(
          session,
          unit,
          catalog,
          {for (final question in questions) question.prompt},
        ),
      );
    }
  }

  /// Purpose: Ask the model for a few extra questions, in the background.
  /// Inputs: The `session` to append to, the `unit`, and the `catalog`.
  /// Returns: None.
  /// Side effects: Runs a model on the device; appends to the session.
  /// Notes: Internal helper used within this file only. Started **after** the
  /// session exists, so the learner is already answering question one while
  /// this waits on a model. Nothing here can fail loudly: no switch, no
  /// templates, no reply, or a reply that does not parse all end the same way,
  /// with the session the learner already has.
  Future<void> _generate(
    QuizSession session,
    LessonUnit unit,
    ContentCatalog catalog,
    Set<String> avoid,
  ) async {
    if (!ref.read(aiAssistServiceProvider).canExplain) return;
    final templates = ref.read(practicePromptTemplatesProvider).value;
    if (templates == null || !mounted) return;
    final generator = AiQuestionGenerator(
      unit: unit,
      catalog: catalog,
      builder: PracticePromptBuilder(templates),
      locale: Localizations.localeOf(context),
      service: AiPracticeService.instance,
    );
    await for (final question in generator.generate(avoid: avoid)) {
      if (!mounted) return;
      session.append(question);
    }
  }

  /// Purpose: Write the checkpoint result, when this session was one.
  /// Inputs: The finished `session`.
  /// Returns: None.
  /// Side effects: Writes a `lesson:` record and reloads the progress file.
  /// Notes: Internal helper used within this file only. Only a checkpoint
  /// writes anything here — ordinary practice over a unit has already
  /// recorded every item it asked about, one answer at a time, and a unit is
  /// not itself a thing to be reviewed on a schedule.
  ///
  /// **Passing is judged on first-try accuracy**, the same number the summary
  /// shows, so the learner can see why they passed or did not.
  void _recordCheckpoint(QuizSession session) {
    final source = widget.config.source;
    if (source is! UnitSource || !source.checkpoint) return;
    if (!widget.config.recordProgress) return;
    final summary = session.summary;
    if (summary.total == 0) return;
    _checkpointPassed = summary.accuracy >= checkpointPassAccuracy;
    ref
        .read(progressDataProvider.notifier)
        .recordLessonResult(lessonRecordId(source.unitId), _checkpointPassed!);
  }

  /// Purpose: Decide which modes may be used in this session.
  /// Inputs: None.
  /// Returns: `Set<QuizMode>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. An empty set in the
  /// config means "everything the learner has left on". Listening modes are
  /// dropped where the device has no Japanese voice, because a question nobody
  /// can hear has no answer.
  Set<QuizMode> _enabledModes() {
    final chosen = widget.config.modes.isEmpty
        ? QuizMode.values.toSet()
        : widget.config.modes;
    if (TtsService.instance.hasJapaneseVoice) return chosen;
    return chosen.difference(listeningQuizModes);
  }

  /// Purpose: List the catalog ids this session asks about.
  /// Inputs: The loaded `catalog`.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The due and new sources
  /// read the review queue, so a quiz started from the Learn tab asks exactly
  /// what that tab said was waiting.
  List<String> _itemIds(ContentCatalog catalog) {
    final source = widget.config.source;
    final queue = ref.read(reviewQueueProvider);
    // Copied before shuffling: `IdsSource` may hold the caller's own list, and
    // a const one throws rather than being quietly reordered underneath them.
    return List<String>.of(switch (source) {
      DueReviews() => [for (final record in queue?.due ?? []) record.id],
      NewItems() => [...?queue?.newIds],
      IdsSource(:final ids) => ids,
      KanaRows() => _kanaIds(source),
      // A unit does not go through here: its questions come from the bank,
      // which needs the unit rather than a list of ids.
      UnitSource() => const <String>[],
      LevelSource(:final level, :final kind) => switch (kind) {
        StudyKind.vocab => [
          for (final entry in catalog.vocab)
            if (entry.level == level) entry.id,
        ],
        StudyKind.grammar => [
          for (final point in catalog.grammar)
            if (point.level == level) point.id,
        ],
        _ => const <String>[],
      },
    })..shuffle();
  }

  /// Purpose: List the kana ids of the selected rows.
  /// Inputs: The `source`.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Rows are addressed by
  /// index because `kanaBasicRows` has two rows labelled `n` — the な row and
  /// ん — so a label is not a key.
  List<String> _kanaIds(KanaRows source) {
    final out = <String>[];
    void take(List<KanaRow> table, List<int> indices) {
      for (final index in indices) {
        if (index < 0 || index >= table.length) continue;
        for (final entry in table[index].entries) {
          if (entry != null) out.add(entry.progressId);
        }
      }
    }

    take(kanaBasicRows, source.basic);
    take(kanaVoicedRows, source.voiced);
    take(kanaYoonRows, source.yoon);
    return out;
  }

  /// Purpose: Confirm before discarding a session in progress.
  /// Inputs: None.
  /// Returns: `Future<bool>` — whether to leave.
  /// Side effects: May show a dialog.
  /// Notes: Internal helper used within this file only. Only asks once
  /// something has been answered; leaving a quiz nobody has started is not a
  /// decision worth interrupting.
  Future<bool> _confirmLeave() async {
    final session = _session;
    if (session == null || session.attempts == 0 || _finished) return true;
    final l10n = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quizLeaveTitle),
        content: Text(l10n.quizLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.quizLeaveConfirm),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  /// Purpose: Build the quiz, its summary, or the reason there is neither.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = _session;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.quizTitle)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
            child: switch ((_building, session, _finished)) {
              (true, _, _) => const Center(child: CircularProgressIndicator()),
              (_, null, _) => _empty(context, l10n),
              (_, final s?, true) => _summary(context, l10n, s),
              (_, final s?, false) => QuizRunner(
                session: s,
                onFinished: () {
                  _recordCheckpoint(s);
                  setState(() => _finished = true);
                },
              ),
            },
          ),
        ),
      ),
    );
  }

  /// Purpose: Explain that no question could be built.
  /// Inputs: `context`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Reachable honestly: a
  /// learner with every mode but the two written-form ones switched off, asking
  /// about words that have no kanji, has asked for nothing answerable.
  Widget _empty(BuildContext context, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(l10n.quizEmpty, textAlign: TextAlign.center)),
  );

  /// Purpose: Show the session's result.
  /// Inputs: `context`, `l10n`, the finished `session`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The score is over first
  /// answers; the wrong list names the items through the catalog rather than by
  /// id, so it is something a learner can act on.
  Widget _summary(
    BuildContext context,
    AppLocalizations l10n,
    QuizSession session,
  ) {
    final theme = Theme.of(context);
    final summary = session.summary;
    final catalog = ref.watch(contentCatalogProvider).value;
    final locale = Localizations.localeOf(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.quizSummaryTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.quizSummaryScore(summary.firstTryCorrect, summary.total),
          style: theme.textTheme.titleMedium,
        ),
        if (_checkpointPassed case final passed?) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: passed
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                passed
                    ? l10n.pathCheckpointPassed
                    : l10n.pathCheckpointFailed(
                        (summary.accuracy * 100).round(),
                        (checkpointPassAccuracy * 100).round(),
                      ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (summary.wrongIds.isEmpty)
          Text(l10n.quizSummaryPerfect)
        else ...[
          Text(
            l10n.quizSummaryReview,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final id in summary.wrongIds)
            Builder(
              builder: (context) {
                final label = resolveStudyItemLabel(
                  id,
                  catalog: catalog,
                  locale: locale,
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(label.title),
                  subtitle: label.subtitle == null
                      ? null
                      : Text(label.subtitle!),
                );
              },
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.quizSummaryDone),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/exam_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/models/jlpt_level.dart';
import '../../learn/widgets/jlpt_practice_card.dart';
import '../../progress/models/exam_attempt.dart';
import '../../progress/services/nihongo_storage.dart';
import '../../quiz/models/quiz_question.dart';
import '../../quiz/services/quiz_session.dart';
import '../../quiz/widgets/quiz_runner.dart';
import '../../speech/services/tts_service.dart';
import '../models/drill_file.dart';
import '../models/drill_section.dart';
import '../services/drill_repository.dart';
import '../services/drill_sampler.dart';
import '../services/exam_session.dart';
import '../widgets/drill_passage_view.dart';
import '../widgets/exam_results_view.dart';
import '../widgets/listening_script_player.dart';

/// What a mock is being started for: a fresh paper, or the saved one.
class ExamConfig {
  /// Purpose: Ask for a new paper.
  /// Inputs: `level`, `scale`.
  /// Returns: A new `ExamConfig` instance.
  /// Side effects: None.
  /// Notes: None.
  const ExamConfig(this.level, {this.scale = ExamScale.short}) : resume = false;

  /// Purpose: Ask for the paper already saved on this device.
  /// Inputs: None.
  /// Returns: A new `ExamConfig` instance.
  /// Side effects: None.
  /// Notes: The level and scale come from the save, so they are ignored here.
  const ExamConfig.resume()
    : level = JlptLevel.n5,
      scale = ExamScale.short,
      resume = true;

  /// The level to sit.
  final JlptLevel level;

  /// How much of the paper.
  final ExamScale scale;

  /// Whether to pick up the saved paper instead of drawing a new one.
  final bool resume;
}

/// One sitting of a timed JLPT paper.
///
/// A full-screen route outside the tab shell, like the quiz: it is entered with
/// a purpose and left when it is finished, and a navigation bar under a running
/// clock would be an invitation to leave.
class ExamPage extends ConsumerStatefulWidget {
  /// Purpose: Create the exam page.
  /// Inputs: The `config` saying what to sit.
  /// Returns: A new `ExamPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const ExamPage({super.key, required this.config});

  /// What is being sat.
  final ExamConfig config;

  @override
  ConsumerState<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends ConsumerState<ExamPage>
    with WidgetsBindingObserver {
  ExamSession? _exam;
  bool _building = true;
  bool _finished = false;
  Map<String, DrillPassage> _passages = const {};
  Map<String, DrillSection> _sectionOf = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exam?.dispose();
    super.dispose();
  }

  /// Purpose: Stop the clock when the app leaves the foreground, and pick it
  /// up again when it comes back.
  /// Inputs: The new `state`.
  /// Returns: None.
  /// Side effects: Pauses or resumes the clock; saves; may submit the block.
  /// Notes: The clock measures attention, not wall-clock time. A learner who
  /// takes a phone call has not spent that time on the paper, and one who
  /// leaves it overnight has not lost the paper. The deadline is re-checked on
  /// the way back in, because a phone that slept past it has to find out on
  /// waking rather than resume a block that ended hours ago.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final exam = _exam;
    if (exam == null || _finished) return;
    if (state == AppLifecycleState.resumed) {
      if (!exam.checkDeadline()) exam.resumeClock();
    } else {
      exam.pauseClock();
      unawaited(_save());
    }
  }

  /// Purpose: Draw the paper, or pick up the saved one.
  /// Inputs: None; reads the config, the structure and the drill files.
  /// Returns: None.
  /// Side effects: Reads assets and the save file; builds an `ExamSession`.
  /// Notes: Internal helper used within this file only.
  ///
  /// **Listening is dropped where there is no Japanese voice**, and the block
  /// is left out of the paper entirely rather than shown and skipped: a block
  /// nobody can hear is not a section anybody scored zero on.
  Future<void> _build() async {
    final structure = await ref.read(jlptStructureProvider.future);
    final saved = widget.config.resume
        ? SavedExam.fromJson(await NihongoStorage.loadExamInProgress())
        : null;
    final level = widget.config.resume
        ? JlptLevel.parse(saved?.level) ?? widget.config.level
        : widget.config.level;
    final scale = widget.config.resume && saved?.scale == 'full'
        ? ExamScale.full
        : widget.config.scale;
    final spec = structure.forLevel(level);
    final files = await ref.read(drillLevelProvider(level).future);
    if (!mounted || spec == null || (widget.config.resume && saved == null)) {
      setState(() => _building = false);
      return;
    }

    final locale = Localizations.localeOf(context);
    final byId = <String, DrillQuestion>{
      for (final file in files.values)
        for (final question in file.questions) question.id: question,
    };
    final sections = <String, DrillSection>{};
    for (final entry in files.entries) {
      for (final question in entry.value.questions) {
        sections[question.id] = entry.key;
      }
    }

    final passages = <String, DrillPassage>{};
    void collect(DrillQuestion question) {
      for (final file in files.values) {
        final passage = file.passageById(question.passageId);
        if (passage != null) passages[passage.id] = passage;
      }
    }

    final hasVoice = TtsService.instance.hasJapaneseVoice;
    final blocks = <ExamBlock>[];

    if (saved != null) {
      // Question ids the shipped files no longer have are dropped. Content is
      // rewritten between releases, and a paper that refused to resume because
      // three of its questions had been renumbered would be a worse answer
      // than one that is three questions shorter and says how many it asked.
      for (var i = 0; i < saved.blocks.length; i++) {
        final block = saved.blocks[i];
        final questions = [for (final id in block.questionIds) ?byId[id]];
        for (final question in questions) {
          collect(question);
        }
        blocks.add(
          ExamBlock(
            index: i,
            sections: block.sections,
            limit: block.limit,
            usedBefore: block.used,
            submitted: block.submitted,
            started: block.started,
            session: _sessionFor(questions, locale),
          ),
        );
      }
      for (var i = 0; i < blocks.length; i++) {
        blocks[i].session.restore(saved.blocks[i].answers);
      }
    } else {
      final composition = spec.composition(scale);
      final minutes = spec.minutes(scale);
      for (var i = 0; i < spec.blocks.length; i++) {
        final wanted = spec.blocks[i].sections.where(
          (s) => hasVoice || s != DrillSection.listening,
        );
        if (wanted.isEmpty) continue;
        final questions = <DrillQuestion>[];
        for (final section in wanted) {
          final file = files[section];
          if (file == null || file.isEmpty) continue;
          questions.addAll(
            DrillSampler.drawByPassage(
              file,
              counts: {
                for (final entry in composition.entries)
                  if (entry.key.section == section) entry.key: entry.value,
              },
              asked: ref.read(askedQuestionsProvider).asked,
              lastAsked: ref.read(askedQuestionsProvider).lastAsked,
            ),
          );
        }
        if (questions.isEmpty) continue;
        for (final question in questions) {
          collect(question);
        }
        blocks.add(
          ExamBlock(
            index: blocks.length,
            sections: wanted.toList(),
            limit: Duration(minutes: minutes[i]),
            session: _sessionFor(questions, locale),
          ),
        );
      }
    }

    if (!mounted) return;
    _passages = passages;
    _sectionOf = sections;
    setState(() {
      _building = false;
      _exam =
          blocks.isEmpty
                ? null
                : ExamSession(
                    level: level.label,
                    scale: scale,
                    blocks: blocks,
                    startedAt: saved?.startedAt,
                  )
            ?..addListener(_onExamChanged);
      _finished = _exam?.isFinished ?? false;
    });
  }

  /// Purpose: Build one block's session.
  /// Inputs: The `questions` and the `locale`.
  /// Returns: `QuizSession`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **No re-queueing**, and
  /// every answer still moves its item's review interval: sitting a mock is
  /// studying, and the schedule should not pretend it did not happen.
  QuizSession _sessionFor(List<DrillQuestion> questions, Locale locale) =>
      QuizSession(
        questions: [for (final q in questions) q.toQuizQuestion(locale)],
        requeue: false,
        onFirstAnswer: (id, correct) =>
            ref.read(progressDataProvider.notifier).recordAnswer(id, correct),
      );

  /// Purpose: Follow the exam's clock and save after every change.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds; writes the save file.
  /// Notes: Internal helper used within this file only. Saving on every
  /// notification is once a second while a block runs, which is a small atomic
  /// write to a file nothing else reads — and the alternative is a paper lost
  /// to a phone that ran out of battery.
  void _onExamChanged() {
    if (!mounted) return;
    setState(() {});
    unawaited(_save());
  }

  /// Purpose: Write the paper down, or clear it once it is finished.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Writes or deletes the save file.
  /// Notes: Internal helper used within this file only. **Saves are chained,
  /// never concurrent.** The clock notifies once a second and leaving the page
  /// saves as well, so two writes to the same file could start in the same
  /// millisecond; each one still writes the whole paper, so running them in
  /// order costs nothing and the last one is the current state either way.
  Future<void> _save({bool refreshCard = false}) {
    final chained = _saving.then((_) => _saveNow(refreshCard));
    _saving = chained.catchError((_) {});
    return chained;
  }

  /// The save in flight, so the next one queues behind it rather than racing.
  Future<void> _saving = Future<void>.value();

  /// Purpose: Do one save.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Writes or deletes the save file; may refresh the Learn card.
  /// Notes: Internal helper used within this file only; call [_save].
  Future<void> _saveNow(bool refreshCard) async {
    final exam = _exam;
    if (exam == null) return;
    if (exam.isFinished) {
      await NihongoStorage.clearExamInProgress();
    } else {
      await NihongoStorage.saveExamInProgress(exam.toJson());
    }
    // The Learn card reads the save through a `FutureProvider`, which resolved
    // before this paper existed. Without this the learner leaves a half-sat
    // exam and the card that should offer to continue it shows nothing —
    // which is what the device did before that line was added.
    //
    // **Only when the card is about to be looked at**, though. Refreshing it
    // on every tick starts a read of the file that the next tick's write then
    // renames over, and Windows refuses a rename onto a file another handle
    // has open — so a save failed roughly once a minute, on a page whose whole
    // job is not losing the paper. The card is behind this page, so the only
    // moments it can be seen are the ones that leave.
    if (refreshCard && mounted) ref.refresh(savedExamProvider);
  }

  /// Purpose: Record the finished paper and clear the save.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Writes an `exam:` record; deletes the save file.
  /// Notes: Internal helper used within this file only. Written once, at the
  /// end, because half a paper is not an attempt — and unlike a practice
  /// section, a mock that was abandoned is not recorded at all.
  Future<void> _record() async {
    final exam = _exam;
    if (exam == null || _finished) return;
    _finished = true;

    final tallies = <String, (int, int)>{};
    final answers = <String, int>{};
    final seconds = <String, int>{};
    final limits = <String, int>{};
    for (final block in exam.blocks) {
      final first = block.sections.first.name;
      seconds[first] = block.usedBefore.inSeconds;
      limits[first] = block.limit.inSeconds;
      for (final outcome in block.session.outcomes) {
        final section = _sectionOf[outcome.key];
        if (section == null) continue;
        final current = tallies[section.name] ?? (0, 0);
        tallies[section.name] = (
          current.$1 + 1,
          current.$2 + (outcome.correct ? 1 : 0),
        );
        answers[outcome.key] = outcome.answered
            ? (outcome.correct ? 1 : 0)
            : examUnanswered;
      }
    }
    if (answers.isEmpty) return;

    final suffix = (answers.keys.join().hashCode & 0xffff)
        .toRadixString(16)
        .padLeft(4, '0');
    await ref
        .read(progressDataProvider.notifier)
        .recordExam(
          ExamAttempt(
            id: ExamAttempt.buildId(exam.startedAt, suffix),
            level: exam.level,
            mode: ExamMode.mock,
            scale: exam.scale.name,
            startedAt: exam.startedAt,
            finishedAt: DateTime.now().toUtc(),
            sections: {
              for (final entry in tallies.entries)
                entry.key: ExamSectionResult(
                  asked: entry.value.$1,
                  right: entry.value.$2,
                  seconds: seconds[entry.key],
                  limitSeconds: limits[entry.key],
                ),
            },
            answers: answers,
          ),
        );
    await NihongoStorage.clearExamInProgress();
    if (mounted) ref.refresh(savedExamProvider);
  }

  /// Purpose: Show whatever the question on screen is about.
  /// Inputs: `context` and the `question`.
  /// Returns: `Widget?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A listening script
  /// plays **once** in a mock, which is the paper's own rule, and the
  /// translation is never offered — a mock measures what the learner can read
  /// unaided.
  Widget? _passageFor(BuildContext context, QuizQuestion question) {
    final passage = _passages[question.passageId];
    if (passage == null) return null;
    if (passage.type.section == DrillSection.listening) {
      return ListeningScriptPlayer(
        key: ValueKey(passage.id),
        passage: passage,
        maxPlays: 1,
      );
    }
    return DrillPassageView(
      key: ValueKey(passage.id),
      passage: passage,
      allowTranslation: false,
    );
  }

  /// Purpose: Confirm before leaving a paper that is still running.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: Pauses the clock and saves; may show a dialog.
  /// Notes: Internal helper used within this file only. Unlike the quiz, the
  /// answer is not "the rest is discarded": the paper is saved and the Learn
  /// card offers to continue it. So this is an information dialog rather than
  /// a warning, and it says where the paper went.
  Future<bool> _confirmLeave() async {
    final exam = _exam;
    if (exam == null || _finished || exam.isFinished) return true;
    exam.pauseClock();
    await _save(refreshCard: true);
    if (!mounted) return true;
    final l10n = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.examLeaveTitle),
        content: Text(l10n.examLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.examLeaveConfirm),
          ),
        ],
      ),
    );
    if (leave != true && mounted) exam.resumeClock();
    return leave ?? false;
  }

  /// Purpose: Build the start card, the timed block, or the results.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exam = _exam;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.jlptMock)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
            child: switch ((_building, exam)) {
              (true, _) => const Center(child: CircularProgressIndicator()),
              (_, null) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(l10n.jlptNoContent, textAlign: TextAlign.center),
                ),
              ),
              (_, final e?) when e.isFinished => ExamResultsView(
                exam: e,
                sectionOf: _sectionOf,
                onDone: () async {
                  final navigator = Navigator.of(context);
                  await _record();
                  navigator.pop();
                },
              ),
              (_, final e?) when e.betweenBlocks => _startCard(l10n, e),
              (_, final e?) => _block(l10n, e),
            },
          ),
        ),
      ),
    );
  }

  /// Purpose: Offer to start the next block.
  /// Inputs: `l10n`, the `exam`.
  /// Returns: `Widget`.
  /// Side effects: Starts the clock on tap.
  /// Notes: Internal helper used within this file only. A paper does not roll
  /// straight from one timed block into the next. The real thing has a break,
  /// and starting a clock the learner has not looked at is not a test of
  /// Japanese.
  Widget _startCard(AppLocalizations l10n, ExamSession exam) {
    final block = exam.current!;
    final theme = Theme.of(context);
    final names = block.sections
        .map((section) => l10n.drillSectionName(section))
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.examBlockTitle(exam.currentIndex + 1, exam.blocks.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(names, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            l10n.examBlockMinutes(block.limit.inMinutes),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.examQuestionCount(block.session.total),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: exam.resumeClock,
            child: Text(l10n.examStartBlock),
          ),
        ],
      ),
    );
  }

  /// Purpose: Run the block that is on the clock.
  /// Inputs: `l10n`, the `exam`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **No feedback between
  /// questions**: a paper is marked at the end, and being told after each one
  /// is the thing a real exam most conspicuously does not do.
  Widget _block(AppLocalizations l10n, ExamSession exam) {
    final block = exam.current!;
    final theme = Theme.of(context);
    final left = exam.remaining;
    final minutes = left.inMinutes.toString().padLeft(2, '0');
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    // The last minute is the one worth colouring: before that a countdown in
    // red is just noise, and after it there is nothing to warn about.
    final urgent = left.inSeconds <= 60;

    return QuizRunner(
      key: ValueKey('block-${block.index}'),
      session: block.session,
      showFeedback: false,
      questionPaneWidth: drillPassagePaneWidth,
      leadingBuilder: _passageFor,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            block.sections
                .map((section) => l10n.drillSectionName(section))
                .join(' · '),
            style: theme.textTheme.labelLarge,
          ),
          Text(
            '$minutes:$seconds',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: urgent ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
      onFinished: exam.finishBlockEarly,
    );
  }
}

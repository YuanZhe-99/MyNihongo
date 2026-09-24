import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../speech/widgets/speak_button.dart';
import '../models/lesson_path.dart';
import '../models/scenario.dart';
import '../services/scenario_chat.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/services/writing_rewrite.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/services/content_repository.dart';
import '../../sentence/services/sentence_analyzer.dart';

/// What a scenario page needs to run, passed as the route's `extra`.
class ScenarioArgs {
  /// Purpose: Carry a scenario and the unit it belongs to.
  /// Inputs: `scenario`, `unit`.
  /// Returns: A new `ScenarioArgs` instance.
  /// Side effects: None.
  /// Notes: The unit comes along so the page can name what is being practised
  /// without looking the path up again.
  const ScenarioArgs({required this.scenario, required this.unit});

  /// The conversation to play.
  final Scenario scenario;

  /// The unit it belongs to.
  final LessonUnit unit;
}

/// Play one scripted conversation, one line at a time.
///
/// The learner taps to advance, and at a branch picks what to say. Both the
/// script and the choices are read aloud on request, which is the point of a
/// conversation the app can speak.
///
/// **A wrong choice does not end the conversation.** The chosen line is shown
/// in the transcript where it was said, marked right or wrong, the script
/// carries on, and the tally at the end says how many were right. Nothing is
/// written to the scheduler: choosing one of three is not recall, and the
/// unit's practice session is where recall is measured.
///
/// **With on-device AI on, the script is not the end.** Once it has run out,
/// the learner can go on typing Japanese and the other speaker answers in
/// character — see [ScenarioChat] for why that is capped and why nothing about
/// it is stored. The scripted half is the lesson and stands on its own; a
/// device with no model, or with the switch off, simply reaches the tally and
/// stops, as it always did.
class ScenarioPage extends ConsumerStatefulWidget {
  /// Purpose: Show one conversation.
  /// Inputs: The `args`.
  /// Returns: A new `ScenarioPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const ScenarioPage({super.key, required this.args});

  /// The conversation and its unit.
  final ScenarioArgs args;

  @override
  ConsumerState<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends ConsumerState<ScenarioPage> {
  /// How many script lines have been shown.
  int _shown = 1;

  /// The branch waiting for an answer, when one is.
  ScenarioBranch? _asking;

  /// What the learner said, keyed by the branch's `after` so the reply can be
  /// shown in the place in the conversation where it was said.
  final _said = <int, ScenarioChoice>{};

  /// The free conversation after the script, when there is one.
  final _chat = ScenarioChat();

  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Whether a reply is being written right now.
  bool _sending = false;

  /// Why the last attempt produced nothing, when it produced nothing.
  GenAiFailure? _failure;

  Scenario get _scenario => widget.args.scenario;

  @override
  void initState() {
    super.initState();
    _asking = _scenario.branchAfter(1);
    AiAssistService.instance.addListener(_onAiChanged);
  }

  @override
  void dispose() {
    AiAssistService.instance.removeListener(_onAiChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Purpose: Rebuild when the on-device AI's state changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only. What makes the
  /// conversation appear and disappear with the switch while the page is open,
  /// rather than at the next visit.
  void _onAiChanged() {
    if (mounted) setState(() {});
  }

  /// Whether the script has run to its end with nothing left to ask.
  bool get _finished => _asking == null && _shown >= _scenario.dialogue.length;

  /// Purpose: Show the next line, or the branch that comes before it.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only.
  void _advance() {
    if (_finished) return;
    setState(() {
      _shown++;
      _asking = _scenario.branchAfter(_shown);
    });
  }

  /// Purpose: Record the reply the learner picked and carry on.
  /// Inputs: The `choice`.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only. The conversation
  /// continues whether the choice was right or wrong; only the tally differs.
  void _choose(ScenarioChoice choice) {
    final branch = _asking;
    if (branch == null) return;
    setState(() {
      _said[branch.after] = choice;
      _asking = null;
    });
  }

  /// Whether the on-device model can carry the conversation on.
  bool get _canChat => AiAssistService.instance.canExplain;

  /// Who the learner is talking to, named as the script names them.
  String _partner(AppLocalizations l10n) {
    final speaker = _scenario.partnerSpeaker;
    return speaker.isEmpty ? l10n.scenarioPartner : speaker;
  }

  /// Purpose: Say what the learner typed, and get an answer in character.
  /// Inputs: None; reads the composer.
  /// Returns: None.
  /// Side effects: Runs the proofreader and then the model on the device, and
  /// appends two turns.
  /// Notes: Internal helper used within this file only.
  ///
  /// **The proofreader runs first and is awaited**, never alongside the reply.
  /// AICore serves one inference to an app at a time, so a proofread fired
  /// beside the reply would come back `busy` — and a proofread that fails is
  /// swallowed, because the conversation is the feature and a missing
  /// correction is not worth interrupting it for.
  Future<void> _send() async {
    final said = _input.text.trim();
    if (said.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _failure = null;
      _input.clear();
    });

    String? proofread;
    // The analyser is only read when there is a proofreader to feed: loading a
    // lexicon to do nothing with would put the whole reply behind it.
    if (AiAssistService.instance.canProofread) {
      try {
        final analyzer = await ref.read(sentenceAnalyzerProvider.future);
        final enhancer = analyzer.enhancer;
        if (enhancer != null) {
          final rewritten = await proofreadSentences(enhancer, [
            analyzer.analyze(said),
          ]);
          if (rewritten != null && rewritten.trim() != said) {
            proofread = rewritten.trim();
          }
        }
      } on Object {
        // A proofreader that would not run changes nothing about the reply.
      }
    }
    if (!mounted) return;
    setState(() => _chat.addLearner(said, proofread: proofread));
    _scrollToEnd();

    try {
      final builder = await practicePromptBuilder(ref);
      // Order matters: a page left while the builder was loading is a page
      // that must not be told anything, and `setState` after `dispose` throws.
      if (!mounted) return;
      if (builder == null) {
        setState(() => _sending = false);
        return;
      }
      final catalog = ref.read(contentCatalogProvider).asData?.value;
      final unit = widget.args.unit;
      final points = [
        for (final id in unit.grammar) ?catalog?.grammarById(id),
      ];
      final prompt = builder.forScenarioReply(
        title: _scenario.title.resolveJoined(Localizations.localeOf(context)),
        speaker: _partner(AppLocalizations.of(context)!),
        script: [
          for (final line in _scenario.dialogue)
            (speaker: line.speaker, ja: line.ja),
        ],
        turns: [
          for (final turn in _chat.turns.take(_chat.turns.length - 1))
            (learner: turn.learner, ja: turn.ja),
        ],
        learnerLine: said,
        level: points.firstOrNull?.level.label ?? '',
        words: [for (final id in unit.vocab) ?catalog?.vocabById(id)],
        patterns: [for (final point in points) point.pattern],
        locale: Localizations.localeOf(context),
      );
      if (prompt == null) {
        setState(() {
          _sending = false;
          _failure = GenAiFailure.failed;
        });
        return;
      }
      final raw = await AiPracticeService.instance.run(
        prompt,
        maxOutputTokens: builder.maxOutputTokens,
      );
      if (!mounted) return;
      final reply = PracticeResponseParser.scenarioReply(raw);
      setState(() {
        _sending = false;
        if (reply == null) {
          _failure = GenAiFailure.failed;
        } else {
          _chat.addReply(reply.japanese, meaning: reply.meaning);
        }
      });
      _scrollToEnd();
    } on GenAiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failure = error.failure;
      });
    }
  }

  /// Purpose: Keep the newest line in view.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Scrolls.
  /// Notes: Internal helper used within this file only. After the frame, since
  /// the line being scrolled to does not exist until it is laid out.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  /// Purpose: Build the page.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One column of lines that grows downwards, because a conversation
  /// is read in order and the newest line is the one being read.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final lines = _scenario.dialogue.take(_shown).toList();
    final branch = _asking;

    return Scaffold(
      appBar: AppBar(title: Text(_scenario.title.resolveJoined(locale))),
      // A column rather than a bare list, because the composer has to sit
      // above the keyboard: a field at the bottom of a scrolling list is under
      // the IME on a phone, and no amount of scrolling brings it back.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
              for (var i = 0; i < lines.length; i++) ...[
                _line(context, lines[i], locale),
                // The learner's own reply belongs in the conversation, at the
                // point they said it — a transcript that drops it reads as if
                // the other speaker simply carried on alone.
                if (_said[i + 1] case final choice?)
                  _saidLine(context, choice, locale),
              ],
              if (branch != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.scenarioChoose,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                for (final choice in branch.choices)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton(
                      onPressed: () => _choose(choice),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FuriganaText(choice.ja, reading: choice.reading),
                      ),
                    ),
                  ),
              ] else if (_finished) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.scenarioDone(_rightCount, _said.length),
                  style: theme.textTheme.titleMedium,
                ),
                ..._chatSection(context, l10n, theme),
              ] else ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _advance,
                  child: Text(l10n.scenarioNext),
                ),
              ],
                  ],
                ),
              ),
              if (_composerVisible) _composer(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether the learner can type a turn right now.
  bool get _composerVisible =>
      _finished && _canChat && !_chat.ended && !_chat.capReached;

  /// Purpose: Build the free conversation under the tally.
  /// Inputs: `context`, `l10n`, `theme`.
  /// Returns: The widgets to append to the transcript, empty where there is no
  /// conversation to have.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Nothing is shown at
  /// all when the model cannot run: the scripted conversation and its tally
  /// are the lesson, and a device without a model has not lost anything it was
  /// promised.
  List<Widget> _chatSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (!_canChat) return const [];
    if (_chat.ended) {
      return [
        const SizedBox(height: 16),
        Text(l10n.scenarioEnded, style: theme.textTheme.bodyMedium),
      ];
    }
    final partner = _partner(l10n);
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.scenarioContinue,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // Always offered, and offered while a reply is being written: the
          // learner deciding when they are done is the difference between a
          // conversation and an exercise.
          OutlinedButton(
            onPressed: () => setState(_chat.end),
            child: Text(l10n.scenarioEnd),
          ),
        ],
      ),
      if (_chat.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.scenarioContinueHint(partner),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      const SizedBox(height: 8),
      for (final turn in _chat.turns)
        turn.learner
            ? _learnerTurn(context, l10n, theme, turn)
            : _replyTurn(context, l10n, theme, turn, partner),
      if (_sending)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: AiExplanationCard(title: '', loading: true),
        ),
      if (_failure case final failure?)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: AiExplanationCard(title: '', failure: failure),
        ),
      if (_chat.capReached)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            l10n.scenarioCapReached,
            style: theme.textTheme.bodyMedium,
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.scenarioTurns(_chat.learnerTurns, ScenarioChat.maxLearnerTurns),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }

  /// Purpose: Render a line the learner typed.
  /// Inputs: `context`, `l10n`, `theme`, the `turn`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Shaped like
  /// `_saidLine` so a typed turn reads as the learner's in the same way a
  /// chosen one does, minus the right/wrong mark: nothing here is being
  /// marked. The proofreader's line sits under it when it had something to
  /// say, which is a correction offered rather than a score taken.
  Widget _learnerTurn(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ScenarioTurn turn,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(turn.ja, style: theme.textTheme.bodyLarge),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              turn.proofread == null
                  ? l10n.scenarioProofreadOk
                  : l10n.scenarioProofread(turn.proofread!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// Purpose: Render what the other speaker said back.
  /// Inputs: `context`, `l10n`, `theme`, the `turn`, the `partner`'s name.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. In an
  /// `AiExplanationCard`, which is where everything generated in this app is
  /// shown and which carries "generated on this device" **above** the text.
  /// The reply has no reading, so the speak button is given the kanji and the
  /// engine reads it as it finds it — a known limit, written up in
  /// `ai-assist.md`.
  Widget _replyTurn(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ScenarioTurn turn,
    String partner,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiExplanationCard(
          title: l10n.scenarioReplyTitle(partner),
          text: turn.meaning == null
              ? turn.ja
              : '${turn.ja}\n${turn.meaning}',
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SpeakButton(text: turn.ja),
        ),
      ],
    ),
  );

  /// Purpose: Build the field the learner types their turn into.
  /// Inputs: `context`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Outside the scrolling
  /// transcript and inside a `SafeArea`, so it stays above the keyboard.
  Widget _composer(BuildContext context, AppLocalizations l10n) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                labelText: l10n.scenarioInputHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            tooltip: l10n.scenarioSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    ),
  );

  /// How many of the learner's replies were the expected one.
  int get _rightCount => _said.values.where((choice) => choice.correct).length;

  /// Purpose: Render the line the learner chose to say.
  /// Inputs: `context`, the `choice`, the `locale`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Marked right or wrong
  /// where the speaker's name would be, and set apart from the script by its
  /// tinted background, because the learner needs to see at a glance which
  /// lines in the transcript were theirs. It is shown either way: the whole
  /// point of a wrong reply not ending the conversation is being able to read
  /// what it looked like in place.
  Widget _saidLine(
    BuildContext context,
    ScenarioChoice choice,
    Locale locale,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Icon(
                choice.correct ? Icons.check_circle : Icons.cancel_outlined,
                size: 20,
                color: choice.correct
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FuriganaText(choice.ja, reading: choice.reading),
                  if (choice.translations
                        .resolveTranslation(locale)
                        .isNotEmpty)
                    Text(
                      choice.translations.resolveTranslationJoined(locale),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            SpeakButton(text: choice.reading ?? choice.ja),
          ],
        ),
      ),
    );
  }

  /// Purpose: Render one spoken line.
  /// Inputs: `context`, the `line`, the `locale`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The speaker's label is
  /// shown as written, the Japanese carries its kana, and the translation sits
  /// underneath in the reader's own language.
  Widget _line(BuildContext context, DialogueLine line, Locale locale) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Chip(
                label: Text(line.speaker),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuriganaText(line.ja, reading: line.reading),
                if (line.translations
                      .resolveTranslation(locale)
                      .isNotEmpty)
                  Text(
                    line.translations.resolveTranslationJoined(locale),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SpeakButton(text: line.reading ?? line.ja),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/services/content_repository.dart';
import '../../sentence/services/lexicon.dart';
import '../services/pronunciation_scorer.dart';
import '../services/speech_backend.dart';
import '../services/speech_recognition_service.dart';
import 'speak_button.dart';

/// What the learner is practising: one kana, word, or example sentence.
class PracticeTarget {
  const PracticeTarget({required this.display, required this.reading});

  /// What is shown, as the catalog writes it.
  final String display;

  /// The kana the attempt is compared against.
  final String reading;
}

/// Purpose: Open the pronunciation practice sheet for one item.
/// Inputs: `context`, `target`.
/// Returns: None; completes when the sheet closes.
/// Side effects: Presents a modal bottom sheet, which opens the microphone
/// when the learner starts a recording.
/// Notes: Modal rather than a page, for the same reason the detail sheets are:
/// practising is something done to an item you are already looking at, and
/// coming back to it should take no navigation.
Future<void> showPronunciationPracticeSheet(
  BuildContext context,
  PracticeTarget target,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _PracticeSheet(target: target),
  );
}

class _PracticeSheet extends ConsumerStatefulWidget {
  const _PracticeSheet({required this.target});

  final PracticeTarget target;

  @override
  ConsumerState<_PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends ConsumerState<_PracticeSheet> {
  final _speech = SpeechRecognitionService.instance;
  PronunciationResult? _result;
  bool _rationaleShown = false;

  /// Purpose: Subscribe to the recognizer's state.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Adds a listener and resets any leftover session state.
  /// Notes: The service is app-wide, so a previous sheet's result must not
  /// appear in this one.
  @override
  void initState() {
    super.initState();
    _speech.reset();
    _speech.addListener(_onSpeechChanged);
  }

  /// Purpose: Release the recognizer when the sheet closes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels an in-flight session and removes the listener.
  /// Notes: Cancelling rather than stopping: a sheet the learner dismissed
  /// should not deliver a score to nobody, and the microphone must close.
  @override
  void dispose() {
    _speech.removeListener(_onSpeechChanged);
    _speech.cancel();
    super.dispose();
  }

  /// Purpose: Rebuild, and score the attempt once it is final.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Sets the local result.
  /// Notes: Internal helper used within this file only. Scoring happens here
  /// rather than in `build`, so a rebuild for any other reason does not
  /// recompute an alignment that has not changed.
  void _onSpeechChanged() {
    if (!mounted) return;
    if (_speech.phase == SpeechPhase.done) {
      final catalog = ref.read(contentCatalogProvider).value;
      final scorer = PronunciationScorer(
        catalog == null ? null : Lexicon.build(catalog),
      );
      _result = scorer.score(
        target: widget.target.reading,
        heard: _speech.heard,
      );
    } else if (_speech.phase == SpeechPhase.listening) {
      _result = null;
    }
    setState(() {});
  }

  /// Purpose: Start a recording, explaining the microphone first if needed.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May show a dialog; opens the microphone.
  /// Notes: Internal helper used within this file only. The rationale is shown
  /// before the platform prompt, and only when the permission is not already
  /// granted, so the system dialog never arrives unexplained — `PLAN.md` M2.2
  /// requires the microphone to be asked for at first use, never at install.
  Future<void> _startListening() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_rationaleShown && !await _speech.hasPermission()) {
      _rationaleShown = true;
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.practiceMicRationaleTitle),
          content: Text(l10n.practiceMicRationaleBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.practiceMicRationaleAllow),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await _speech.listen();
  }

  /// Purpose: Build the sheet in whichever state the session is in.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One column, capped at `pageMaxContentWidth`: the content is a
  /// target line, a button and a row of mora chips, and none of that is worth
  /// splitting into panes at any window size.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.practiceTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.target.display,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.target.reading != widget.target.display)
                            Text(
                              widget.target.reading,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SpeakButton(text: widget.target.reading),
                  ],
                ),
                const SizedBox(height: 16),
                _buildControl(l10n, theme),
                const SizedBox(height: 16),
                if (_result != null) ..._buildResult(l10n, theme),
                if (_speech.phase == SpeechPhase.failed)
                  Text(
                    _failureMessage(l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.practiceLimitsNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Purpose: Build the record button and its status line.
  /// Inputs: `l10n`, `theme`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. While listening the
  /// button stops the session, and the partial transcript is shown live so the
  /// learner can see the recognizer reacting rather than guessing.
  Widget _buildControl(AppLocalizations l10n, ThemeData theme) {
    final listening = _speech.phase == SpeechPhase.listening;
    final processing = _speech.phase == SpeechPhase.processing;
    return Row(
      children: [
        FilledButton.icon(
          onPressed: processing
              ? null
              : (listening ? _speech.stop : _startListening),
          icon: Icon(listening ? Icons.stop : Icons.mic),
          label: Text(
            listening
                ? l10n.practiceListening
                : (processing
                      ? l10n.practiceProcessing
                      : (_result == null
                            ? l10n.practiceStart
                            : l10n.practiceRetry)),
          ),
        ),
        const SizedBox(width: 12),
        if (listening && _speech.heard.isNotEmpty)
          Expanded(
            child: Text(
              _speech.heard,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Purpose: Build the mora diff, the score, and what was heard.
  /// Inputs: `l10n`, `theme`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The diff comes first
  /// and the score after it: a per-mora picture of what to fix is the useful
  /// output, and the number is only a summary of the same alignment.
  List<Widget> _buildResult(AppLocalizations l10n, ThemeData theme) {
    final result = _result!;
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final mora in result.diff) _moraChip(theme, mora)],
      ),
      const SizedBox(height: 12),
      Text(
        result.isPerfect
            ? l10n.practicePerfect
            : l10n.practiceScore(result.score),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.practiceHeard(result.heardKana),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        children: [
          _legend(theme, MoraOp.correct, l10n.practiceLegendCorrect),
          _legend(theme, MoraOp.substituted, l10n.practiceLegendSubstituted),
          _legend(theme, MoraOp.missing, l10n.practiceLegendMissing),
          _legend(theme, MoraOp.extra, l10n.practiceLegendExtra),
        ],
      ),
    ];
  }

  /// Purpose: Render one aligned mora.
  /// Inputs: `theme`, `mora`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A missing mora shows
  /// what should have been said, struck through; an extra one shows what was
  /// said that should not have been. Colour alone never carries the meaning —
  /// the legend below names each state, and the shapes differ.
  Widget _moraChip(ThemeData theme, MoraDiff mora) {
    final colors = _colorsFor(theme, mora.op);
    final text = mora.op == MoraOp.extra
        ? (mora.heard ?? '')
        : (mora.target ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.$2,
              decoration: mora.op == MoraOp.missing
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          if (mora.op == MoraOp.substituted && mora.heard != null)
            Text(
              mora.heard!,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.$2),
            ),
        ],
      ),
    );
  }

  /// Purpose: Render one legend entry.
  /// Inputs: `theme`, `op`, `label`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _legend(ThemeData theme, MoraOp op, String label) {
    final colors = _colorsFor(theme, op);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors.$1,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Purpose: Pick the background and foreground colour for a mora state.
  /// Inputs: `theme`, `op`.
  /// Returns: A record of background and foreground.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. All four come from the
  /// scheme rather than from literals, so they follow the theme.
  (Color, Color) _colorsFor(ThemeData theme, MoraOp op) {
    final scheme = theme.colorScheme;
    return switch (op) {
      MoraOp.correct => (scheme.primaryContainer, scheme.onPrimaryContainer),
      MoraOp.substituted => (scheme.errorContainer, scheme.onErrorContainer),
      MoraOp.missing => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      MoraOp.extra => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
  }

  /// Purpose: Turn a recognizer failure into something the learner can act on.
  /// Inputs: `l10n`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. `languageUnavailable`
  /// is the interesting one: it is what an offline-only request answers on a
  /// device with no Japanese model, and the message names both fixes — install
  /// the data, or turn the network fallback on knowingly.
  String _failureMessage(AppLocalizations l10n) => switch (_speech.failure) {
    SpeechFailure.noMatch => l10n.practiceNoMatch,
    SpeechFailure.languageUnavailable => l10n.practiceLanguageUnavailable,
    SpeechFailure.permissionDenied => l10n.practicePermissionDenied,
    _ => l10n.practiceUnavailable,
  };
}

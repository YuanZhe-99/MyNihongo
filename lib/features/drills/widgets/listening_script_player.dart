import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../speech/services/tts_service.dart';
import '../models/drill_file.dart';

/// Plays a listening script line by line, and hides the transcript until it is
/// no longer the answer.
///
/// The transcript is what makes 聴解 practice worth anything — the learner has
/// to be able to see what they missed — and it is also the thing that would
/// make the question free. So it appears after the question has been answered,
/// and never before.
class ListeningScriptPlayer extends StatefulWidget {
  /// Purpose: Play one script.
  /// Inputs: The `passage`; `maxPlays` — how many times it may be heard;
  /// `revealed` — whether the transcript may be shown.
  /// Returns: A new `ListeningScriptPlayer` instance.
  /// Side effects: None until played.
  /// Notes: `maxPlays` is unlimited in practice and one in a mock, because the
  /// real 聴解 plays each item once and practising against a different rule
  /// teaches a habit the exam punishes.
  const ListeningScriptPlayer({
    super.key,
    required this.passage,
    this.maxPlays,
    this.revealed = false,
  });

  /// The script to play.
  final DrillPassage passage;

  /// How many plays are allowed; null for as many as the learner wants.
  final int? maxPlays;

  /// Whether the transcript may be shown.
  final bool revealed;

  @override
  State<ListeningScriptPlayer> createState() => _ListeningScriptPlayerState();
}

class _ListeningScriptPlayerState extends State<ListeningScriptPlayer> {
  int _plays = 0;
  bool _playing = false;
  int _line = -1;

  @override
  void dispose() {
    // The widget is going away, but the engine is not: a script left playing
    // would keep talking over whatever comes next.
    TtsService.instance.stop();
    super.dispose();
  }

  /// Purpose: Read the script aloud, one line at a time.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Produces audio; highlights each line as it is spoken.
  /// Notes: Internal helper used within this file only. Each line is awaited
  /// before the next begins, which is what makes the highlight mean anything.
  ///
  /// `stop()` runs before each line because `TtsService.speak` treats a repeat
  /// of the text it is already speaking as a request to stop — a script with
  /// two identical lines would otherwise go silent on the second.
  ///
  /// The reading is spoken where the content has one. An engine handed 一日
  /// has to guess between ついたち and いちにち, and a listening question whose
  /// audio guessed wrong is unanswerable.
  Future<void> _play() async {
    if (_playing) return;
    if (!TtsService.instance.hasJapaneseVoice) return;
    final limit = widget.maxPlays;
    if (limit != null && _plays >= limit) return;

    setState(() {
      _playing = true;
      _plays++;
    });
    try {
      for (var i = 0; i < widget.passage.lines.length; i++) {
        if (!mounted) return;
        setState(() => _line = i);
        final line = widget.passage.lines[i];
        await TtsService.instance.stop();
        await TtsService.instance.speak(line.reading ?? line.ja);
      }
    } finally {
      if (mounted) {
        setState(() {
          _playing = false;
          _line = -1;
        });
      }
    }
  }

  /// Purpose: Build the play control and, once answered, the transcript.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Without
  /// a Japanese voice the control is **disabled rather than hidden**, with the
  /// reason beside it: a listening question with no visible way to listen
  /// looks like a bug, and this is the same rule `SpeakButton` follows.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasVoice = TtsService.instance.hasJapaneseVoice;
    final limit = widget.maxPlays;
    final left = limit == null ? null : limit - _plays;
    final canPlay = hasVoice && !_playing && (left == null || left > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: canPlay ? _play : null,
              icon: Icon(
                _playing ? Icons.graphic_eq : Icons.play_arrow_outlined,
              ),
              label: Text(_plays == 0 ? l10n.drillPlay : l10n.drillPlayAgain),
            ),
            if (left != null) ...[
              const SizedBox(width: 8),
              Text(
                l10n.drillPlaysLeft(left),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (!hasVoice)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.drillNoVoice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (widget.revealed) ...[
          const SizedBox(height: 10),
          Text(
            l10n.drillTranscript,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < widget.passage.lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: i == _line
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.passage.lines[i].speaker.isNotEmpty)
                      Text(
                        widget.passage.lines[i].speaker,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    FuriganaText(
                      widget.passage.lines[i].ja,
                      reading: widget.passage.lines[i].reading,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

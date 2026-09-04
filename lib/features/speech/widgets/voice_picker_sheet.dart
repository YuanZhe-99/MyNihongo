import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../services/tts_service.dart';
import 'voice_labels.dart';

/// Purpose: Let the learner hear each Japanese voice and choose one.
/// Inputs: `context`; `previewText` — the sample every voice speaks; `selected`
/// — the currently chosen voice name, or null for automatic; `onChanged`.
/// Returns: `Future<void>` completing when the sheet closes.
/// Side effects: Shows a modal bottom sheet, and speaks while it is open.
/// Notes: A dropdown of engine identifiers was unusable — the names are
/// machine-readable strings and nothing in them says how a voice sounds. A
/// sheet has room for a readable name, what is different about each voice, and
/// a play button, which is the only way to actually judge one. Choosing is a
/// separate act from listening: [TtsService.preview] restores the learner's own
/// voice afterwards, so auditioning never silently changes the app.
Future<void> showVoicePickerSheet(
  BuildContext context, {
  required String previewText,
  required String? selected,
  required ValueChanged<String?> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _VoicePickerSheet(
      previewText: previewText,
      selected: selected,
      onChanged: onChanged,
    ),
  );
}

/// The sheet's own widget, so the selection redraws without rebuilding
/// Settings.
class _VoicePickerSheet extends StatefulWidget {
  const _VoicePickerSheet({
    required this.previewText,
    required this.selected,
    required this.onChanged,
  });

  final String previewText;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  State<_VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends State<_VoicePickerSheet> {
  late String? _selected = widget.selected;

  /// Purpose: Apply a choice and keep the sheet open.
  /// Inputs: `name` — a voice name, or null for automatic.
  /// Returns: None.
  /// Side effects: Redraws the sheet and applies the choice to the engine.
  /// Notes: Internal helper used within this file only. The sheet stays open
  /// on purpose: a learner comparing two voices should not have to reopen it
  /// between them.
  void _choose(String? name) {
    setState(() => _selected = name);
    widget.onChanged(name);
  }

  /// Purpose: Build the list of voices.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// sheet is capped at 70% of the screen so it never covers the whole app on
  /// a phone, and scrolls when an engine offers many voices.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tts = TtsService.instance;
    final voices = tts.japaneseVoices;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: RadioGroup<String?>(
          groupValue: _selected,
          onChanged: _choose,
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l10n.speechVoicePick,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              RadioListTile<String?>(
                value: null,
                title: Text(l10n.speechVoiceDefault),
                subtitle: Text(
                  voiceDefaultLabel(l10n, voices, tts.defaultJapaneseVoice),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (var i = 0; i < voices.length; i++)
                _voiceRow(context, l10n, theme, voices, i),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Build one voice row with its sample button.
  /// Inputs: `context`, `l10n`, `theme`, the ordered `voices`, and the `index`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: Internal helper used within this file only. The raw engine name is
  /// shown in a smaller line rather than hidden: it is meaningless to read but
  /// it is what a bug report needs, and what the system speech settings show.
  Widget _voiceRow(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    List<Map<String, String>> voices,
    int index,
  ) {
    final voice = voices[index];
    final name = voice['name'] ?? '';
    return RadioListTile<String?>(
      value: name,
      title: Text(voiceDisplayName(l10n, voices, index)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            voiceQualifiers(l10n, voice),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      isThreeLine: true,
      secondary: ValueListenableBuilder<String?>(
        valueListenable: TtsService.instance.speaking,
        builder: (context, speaking, _) {
          final active = speaking == widget.previewText.trim();
          return IconButton(
            icon: Icon(
              active ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            ),
            tooltip: l10n.speechVoicePreview,
            onPressed: () => active
                ? TtsService.instance.stop()
                : TtsService.instance.preview(voice, widget.previewText),
          );
        },
      ),
    );
  }
}

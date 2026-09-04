import '../../../l10n/app_localizations.dart';
import '../models/voice_ordering.dart';

/// Purpose: Name a Japanese voice in a way a learner can act on.
/// Inputs: `l10n`, the `voices` list already ordered by
/// [sortJapaneseVoices], and the `index` of the one being named.
/// Returns: `String` — "Japanese voice 2" and so on.
/// Side effects: None.
/// Notes: Engine voice names are identifiers, not names: `ja-jp-x-jab#male_1-local`
/// tells a learner nothing and differs between engines. Numbering the ordered
/// list gives a stable, readable handle; the raw name is still shown beside it
/// so a bug report can name the exact voice. The number depends on the order,
/// which is why the order is total and defined in one place.
String voiceDisplayName(
  AppLocalizations l10n,
  List<Map<String, String>> voices,
  int index,
) => l10n.speechVoiceNumbered(index + 1);

/// Purpose: Describe what is different about a voice, in a short line.
/// Inputs: `l10n`, `voice`.
/// Returns: `String` — availability first, then quality, joined with a dot.
/// Side effects: None.
/// Notes: Availability leads because it is what changes whether the voice
/// works at all; quality is omitted when the engine did not report it rather
/// than guessed at.
String voiceQualifiers(AppLocalizations l10n, Map<String, String> voice) {
  final parts = <String>[
    if (voiceIsNotInstalled(voice))
      l10n.speechVoiceNotInstalled
    else if (voiceNeedsNetwork(voice))
      l10n.speechVoiceNetwork
    else
      l10n.speechVoiceOffline,
    ...switch (voiceQualityRank(voice)) {
      3 || 4 => [l10n.speechVoiceQualityHigh],
      2 => [l10n.speechVoiceQualityNormal],
      0 || 1 => [l10n.speechVoiceQualityLow],
      _ => const <String>[],
    },
  ];
  return parts.join(' · ');
}

/// Purpose: Name the voice the app uses when the learner has not chosen one.
/// Inputs: `l10n`, the ordered `voices`, and the `voice` in use, if any.
/// Returns: `String` — the automatic label, plus which voice that resolved to.
/// Side effects: None.
/// Notes: "Chosen automatically" alone leaves the learner unable to tell what
/// they would be changing, so the resolved voice is named too.
String voiceDefaultLabel(
  AppLocalizations l10n,
  List<Map<String, String>> voices,
  Map<String, String>? voice,
) {
  if (voice == null) return l10n.speechVoiceDefault;
  final index = voices.indexWhere((v) => v['name'] == voice['name']);
  if (index < 0) return l10n.speechVoiceDefault;
  return '${l10n.speechVoiceDefault} · '
      '${l10n.speechVoiceUsing(voiceDisplayName(l10n, voices, index))}';
}

/// Known Android speech engines, so the picker shows a brand rather than a
/// package name. Anything not listed shows its package name, which is still
/// the truth.
const _engineNames = <String, String>{
  'com.google.android.tts': 'Google',
  'com.samsung.SMT': 'Samsung',
  'com.samsung.android.SMT': 'Samsung',
  'espeak.speech.tts': 'eSpeak',
  'com.redzoc.ramees.tts.engine': 'RHVoice',
  'com.acapelagroup.android.tts': 'Acapela',
};

/// Purpose: Name a speech engine for a menu.
/// Inputs: `engine` — a package name.
/// Returns: `String` — a known brand, or the package name unchanged.
/// Side effects: None.
/// Notes: Deliberately not localized: these are product names.
String engineDisplayName(String engine) => _engineNames[engine] ?? engine;

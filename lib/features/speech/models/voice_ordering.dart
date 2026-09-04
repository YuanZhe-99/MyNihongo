/// Purpose: Order and describe the Japanese voices an engine offers, so the
/// service and the picker agree on which one is "best" and on what each one is
/// called.
/// Inputs: Voice maps from `TtsBackend.voices()`.
/// Returns: Pure predicates, a rank, and a comparator.
/// Side effects: None.
/// Notes: Kept out of both the service and the widget because both need it and
/// neither should own it. Android voice maps carry `quality`, `latency`,
/// `network_required` and `features` as strings; every field is optional, and a
/// voice from another platform may have none of them.
library;

/// Voice quality names, worst first, as `flutter_tts` spells them.
const _qualityOrder = <String>[
  'very low',
  'low',
  'normal',
  'high',
  'very high',
];

/// Purpose: Report whether the engine says this voice's data is not on device.
/// Inputs: `voice`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Android reports it through the `notInstalled` feature flag. Such a
/// voice can be selected and then produces silence, so it is never the default.
bool voiceIsNotInstalled(Map<String, String> voice) =>
    (voice['features'] ?? '').contains('notInstalled');

/// Purpose: Report whether speaking with this voice needs the network.
/// Inputs: `voice`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: A network voice works, but it is slower and it leaves the device —
/// so an offline voice is always preferred and the picker says which is which.
bool voiceNeedsNetwork(Map<String, String> voice) =>
    voice['network_required'] == '1' || voice['network_required'] == 'true';

/// Purpose: Rank a voice's quality so voices can be sorted by it.
/// Inputs: `voice`.
/// Returns: `int` — higher is better; -1 when the engine did not say.
/// Side effects: None.
/// Notes: None.
int voiceQualityRank(Map<String, String> voice) =>
    _qualityOrder.indexOf(voice['quality'] ?? '');

/// Purpose: Order Japanese voices best-first.
/// Inputs: `a`, `b`.
/// Returns: `int` for `List.sort`.
/// Side effects: None.
/// Notes: Installed before missing, offline before network, then quality, then
/// the engine's own name so the order never depends on enumeration order. The
/// order is what the picker numbers against, so it has to be total and stable.
int compareJapaneseVoices(Map<String, String> a, Map<String, String> b) {
  final installed = (voiceIsNotInstalled(a) ? 1 : 0).compareTo(
    voiceIsNotInstalled(b) ? 1 : 0,
  );
  if (installed != 0) return installed;
  final network = (voiceNeedsNetwork(a) ? 1 : 0).compareTo(
    voiceNeedsNetwork(b) ? 1 : 0,
  );
  if (network != 0) return network;
  final quality = voiceQualityRank(b).compareTo(voiceQualityRank(a));
  if (quality != 0) return quality;
  return (a['name'] ?? '').compareTo(b['name'] ?? '');
}

/// Purpose: Sort a list of Japanese voices best-first.
/// Inputs: `voices`.
/// Returns: A new sorted `List<Map<String, String>>`.
/// Side effects: None.
/// Notes: Returns a copy; the caller's list keeps the engine's order.
List<Map<String, String>> sortJapaneseVoices(
  List<Map<String, String>> voices,
) => [...voices]..sort(compareJapaneseVoices);

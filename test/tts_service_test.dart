import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/tts_backend.dart';
import 'package:my_nihongo/features/speech/services/tts_service.dart';

/// Purpose: Test the text-to-speech service against a recording fake backend.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: A `flutter_test` run has no speech engine, so everything worth
/// testing sits on this side of the `TtsBackend` seam: the rate conversion,
/// the Japanese-only voice filter, the one-utterance-at-a-time rule, and the
/// promise that a throwing engine never takes the app down with it.
class _FakeTtsBackend implements TtsBackend {
  _FakeTtsBackend({this.voiceList = const [], this.throws = false});

  final List<Map<String, String>> voiceList;
  final bool throws;

  final List<String> spoken = [];
  final List<double> rates = [];
  final List<Map<String, String>> selectedVoices = [];
  String? language;
  int stops = 0;

  @override
  Future<bool> setLanguage(String language) async {
    if (throws) throw StateError('no engine');
    this.language = language;
    return true;
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    if (throws) throw StateError('no engine');
    return voiceList.any(
      (v) => (v['locale'] ?? '').startsWith(language.split('-').first),
    );
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    if (throws) throw StateError('no engine');
    rates.add(rate);
  }

  @override
  Future<List<Map<String, String>>> voices() async {
    if (throws) throw StateError('no engine');
    return voiceList;
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    if (throws) throw StateError('no engine');
    selectedVoices.add(voice);
  }

  @override
  Future<void> speak(String text) async {
    if (throws) throw StateError('no engine');
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    if (throws) throw StateError('no engine');
    stops++;
  }
}

void main() {
  const jaVoice = {'name': 'Kyoko', 'locale': 'ja-JP'};
  const jaVoice2 = {'name': 'Otoya', 'locale': 'ja_JP'};
  const enVoice = {'name': 'Zira', 'locale': 'en-US'};

  test('the engine rate is half the user-facing multiple', () {
    expect(TtsService.engineRate(1.0), 0.5);
    expect(TtsService.engineRate(0.6), closeTo(0.3, 1e-9));
    expect(TtsService.engineRate(1.2), closeTo(0.6, 1e-9));
  });

  test('init sets Japanese and keeps only Japanese voices', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [enVoice, jaVoice, jaVoice2],
    );
    final tts = TtsService(backend);
    await tts.init();
    expect(backend.language, 'ja-JP');
    expect(tts.hasJapaneseVoice, isTrue);
    expect(tts.japaneseVoices.map((v) => v['name']), ['Kyoko', 'Otoya']);
  });

  test('an engine with no Japanese voice reports none', () async {
    final backend = _FakeTtsBackend(voiceList: const [enVoice]);
    final tts = TtsService(backend);
    await tts.init();
    expect(tts.hasJapaneseVoice, isFalse);
    expect(tts.japaneseVoices, isEmpty);
  });

  test('a device with no engine at all is not fatal', () async {
    final tts = TtsService(_FakeTtsBackend(throws: true));
    await tts.init(rate: 1.1, voiceName: 'Kyoko');
    await tts.speak('こんにちは');
    await tts.stop();
    expect(tts.hasJapaneseVoice, isFalse);
    expect(tts.speaking.value, isNull);
  });

  test('the persisted rate is applied and clamped', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init(rate: 5.0);
    expect(tts.rate, TtsService.maxRate);
    expect(backend.rates.last, TtsService.engineRate(TtsService.maxRate));
  });

  test('speaking sets and clears the shared speaking state', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    expect(tts.speaking.value, isNull);
    await tts.speak('こんにちは');
    expect(backend.spoken, ['こんにちは']);
    expect(tts.speaking.value, isNull);
  });

  test('tapping the same text again stops instead of repeating', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    // Simulate an utterance still in flight when the second tap arrives.
    tts.speaking.value = 'こんにちは';
    await tts.speak('こんにちは');
    expect(backend.spoken, isEmpty);
    expect(backend.stops, 1);
    expect(tts.speaking.value, isNull);
  });

  test('a different text interrupts the one playing', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    tts.speaking.value = 'こんにちは';
    await tts.speak('さようなら');
    expect(backend.stops, 1);
    expect(backend.spoken, ['さようなら']);
  });

  test('blank text is never spoken', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    await tts.speak('   ');
    expect(backend.spoken, isEmpty);
  });

  test('an unknown voice name falls back to the engine default', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init(voiceName: 'Nobody');
    expect(tts.voiceName, isNull);
    expect(backend.selectedVoices, isEmpty);
  });

  test('a known voice name is applied to the engine', () async {
    final backend = _FakeTtsBackend(voiceList: const [enVoice, jaVoice]);
    final tts = TtsService(backend);
    await tts.init(voiceName: 'Kyoko');
    expect(tts.voiceName, 'Kyoko');
    expect(backend.selectedVoices, [
      {'name': 'Kyoko', 'locale': 'ja-JP'},
    ]);
  });
}

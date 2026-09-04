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
  _FakeTtsBackend({
    this.voiceList = const [],
    this.throws = false,
    this.engineList = const [],
    this.languageAccepted,
    this.voiceAccepted = true,
  });

  List<Map<String, String>> voiceList;
  final bool throws;
  final List<String> engineList;

  /// What `setLanguage` answers; null derives it from [voiceList], which is
  /// what the Android plugin does — it refuses a language it has no voice for.
  /// Set it explicitly to model an engine that has been rebuilt onto a
  /// language it no longer has.
  bool? languageAccepted;

  /// What `setVoice` answers.
  bool voiceAccepted;

  /// Every backend call in order — the only way to test the ordering the
  /// language fix depends on.
  final List<String> calls = [];

  final List<String> spoken = [];
  final List<double> rates = [];
  final List<Map<String, String>> selectedVoices = [];
  final List<String> enginesSet = [];
  String? language;
  int stops = 0;

  @override
  Future<bool> setLanguage(String language) async {
    calls.add('setLanguage');
    if (throws) throw StateError('no engine');
    this.language = language;
    return languageAccepted ?? _hasLanguage(language);
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    calls.add('isLanguageAvailable');
    if (throws) throw StateError('no engine');
    return _hasLanguage(language);
  }

  bool _hasLanguage(String language) => voiceList.any(
    (v) => (v['locale'] ?? '').startsWith(language.split('-').first),
  );

  @override
  Future<void> setSpeechRate(double rate) async {
    if (throws) throw StateError('no engine');
    rates.add(rate);
  }

  @override
  Future<List<Map<String, String>>> voices() async {
    calls.add('voices');
    if (throws) throw StateError('no engine');
    return voiceList;
  }

  @override
  Future<bool> setVoice(Map<String, String> voice) async {
    calls.add('setVoice');
    if (throws) throw StateError('no engine');
    selectedVoices.add(voice);
    return voiceAccepted;
  }

  @override
  Future<List<String>> engines() async {
    calls.add('engines');
    if (throws) throw StateError('no engine');
    return engineList;
  }

  @override
  Future<String?> defaultEngine() async {
    calls.add('defaultEngine');
    if (throws) throw StateError('no engine');
    return engineList.isEmpty ? null : engineList.first;
  }

  @override
  Future<bool> setEngine(String engine) async {
    calls.add('setEngine');
    if (throws) throw StateError('no engine');
    enginesSet.add(engine);
    return true;
  }

  @override
  Future<void> speak(String text) async {
    calls.add('speak');
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

  test('an unknown voice name falls back to the best Japanese voice', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init(voiceName: 'Nobody');
    expect(tts.voiceName, isNull);
    // Not "no voice at all": leaving the engine on its own default is what
    // let it read Japanese in the device's language.
    expect(backend.selectedVoices, [
      {'name': 'Kyoko', 'locale': 'ja-JP'},
    ]);
  });

  test('the language is set only after a queued call has been awaited', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    // The plugin replays queued calls from its init callback and then
    // overwrites the language with the system default. A setLanguage sent
    // before that point is discarded, which is the whole bug: awaiting any
    // queued call first is what makes the write stick.
    expect(
      backend.calls.indexOf('isLanguageAvailable') <
          backend.calls.indexOf('setLanguage'),
      isTrue,
      reason: 'setLanguage must not be the first call to reach the engine',
    );
  });

  test('every utterance re-applies language, voice and rate', () async {
    final backend = _FakeTtsBackend(voiceList: const [jaVoice]);
    final tts = TtsService(backend);
    await tts.init();
    backend.calls.clear();
    await tts.speak('こんにちは');
    expect(backend.calls, ['setLanguage', 'setVoice', 'speak']);
  });

  test('an engine that has lost Japanese is rebuilt once, then speaks', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [jaVoice],
      engineList: const ['com.google.android.tts'],
    );
    final tts = TtsService(backend);
    await tts.init();
    expect(tts.hasJapaneseVoice, isTrue);

    // The plugin rebuilt its TextToSpeech behind our back: the engine is on
    // the system default language and no longer has the voice we chose.
    backend.languageAccepted = false;
    backend.voiceAccepted = false;
    backend.voiceList = const [];
    backend.calls.clear();

    await tts.speak('こんにちは');
    expect(backend.enginesSet, ['com.google.android.tts']);
    expect(backend.calls.where((c) => c == 'setEngine').length, 1);
    expect(backend.spoken, ['こんにちは']);
  });

  test('a device that never had Japanese is not rebuilt', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [enVoice],
      engineList: const ['com.google.android.tts'],
      languageAccepted: false,
    );
    final tts = TtsService(backend);
    await tts.init();
    await tts.speak('こんにちは');
    // Rebuilding an engine is expensive and would fix nothing here.
    expect(backend.enginesSet, isEmpty);
  });

  test('the best voice is installed, offline and highest quality', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [
        {
          'name': 'missing',
          'locale': 'ja-JP',
          'quality': 'very high',
          'features': 'notInstalled',
        },
        {'name': 'network', 'locale': 'ja-JP', 'quality': 'very high',
          'network_required': '1'},
        {'name': 'plain', 'locale': 'ja-JP', 'quality': 'normal',
          'network_required': '0'},
        {'name': 'good', 'locale': 'ja-JP', 'quality': 'high',
          'network_required': '0'},
      ],
    );
    final tts = TtsService(backend);
    await tts.init();
    expect(tts.defaultJapaneseVoice?['name'], 'good');
    expect(tts.japaneseVoices.map((v) => v['name']), [
      'good',
      'plain',
      'network',
      'missing',
    ]);
  });

  test('a preview speaks with one voice and restores the chosen one', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [jaVoice, jaVoice2],
    );
    final tts = TtsService(backend);
    await tts.init(voiceName: 'Kyoko');
    backend.selectedVoices.clear();
    await tts.preview(jaVoice2, 'こんにちは');
    expect(backend.spoken, ['こんにちは']);
    expect(backend.selectedVoices.first['name'], 'Otoya');
    expect(
      backend.selectedVoices.last['name'],
      'Kyoko',
      reason: 'hearing a voice must not be the same act as choosing it',
    );
    expect(tts.voiceName, 'Kyoko');
  });

  test('switching engines re-reads the voices and drops the chosen one', () async {
    final backend = _FakeTtsBackend(
      voiceList: const [jaVoice],
      engineList: const ['com.google.android.tts', 'com.samsung.SMT'],
    );
    final tts = TtsService(backend);
    await tts.init(voiceName: 'Kyoko');
    expect(tts.engines, ['com.google.android.tts', 'com.samsung.SMT']);

    backend.voiceList = const [jaVoice2];
    await tts.setEngine('com.samsung.SMT');
    expect(backend.enginesSet.last, 'com.samsung.SMT');
    expect(tts.voiceName, isNull);
    expect(tts.japaneseVoices.map((v) => v['name']), ['Otoya']);
  });

  test('a voice list that is non-empty does not by itself mean Japanese works',
      () async {
    final backend = _FakeTtsBackend(
      voiceList: const [jaVoice],
      languageAccepted: false,
      voiceAccepted: false,
    );
    final tts = TtsService(backend);
    await tts.init();
    expect(tts.hasJapaneseVoice, isFalse);
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

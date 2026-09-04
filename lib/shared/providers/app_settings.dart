import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai/services/ai_assist_service.dart';
import '../../features/reminders/services/reminder_service.dart';
import '../../l10n/app_localizations.dart';
import '../../features/content/models/jlpt_level.dart';
import '../../features/kana/models/kana.dart';
import '../../features/progress/services/nihongo_storage.dart';
import '../../features/quiz/models/quiz_question.dart';
import '../../features/speech/services/speech_recognition_service.dart';
import '../../features/speech/services/tts_service.dart';
import '../utils/adaptive_layout.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  /// Purpose: Create an app settings notifier instance.
  /// Inputs: None.
  /// Returns: A new `AppSettingsNotifier` instance.
  /// Side effects: Starts loading the persisted settings.
  /// Notes: None.
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadPersisted();
  }

  /// Purpose: Load the persisted preferences from disk.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Reads `storage_config.json` and replaces the state.
  /// Notes: Internal helper used within this file only. **A storage failure
  /// leaves every default in place rather than propagating.** This runs from
  /// the constructor, so nothing is awaiting it and an exception would surface
  /// as an unhandled asynchronous error while the app carried on with the
  /// defaults anyway — the same outcome, reported as a crash. A device whose
  /// documents directory is not available yet starts on defaults, which is
  /// what it would do with an empty config file.
  Future<void> _loadPersisted() async {
    try {
      await _readPersisted();
    } catch (_) {
      // Defaults, already in `state` from the constructor.
    }
  }

  /// Purpose: Read every persisted preference and apply it.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Reads the config file, replaces the state, and configures
  /// the speech and AI services from it.
  /// Notes: Internal helper used within this file only.
  Future<void> _readPersisted() async {
    final modeStr = await NihongoStorage.getThemeMode();
    final localeTag = await NihongoStorage.getLocaleTag();
    final vocabLevel = await NihongoStorage.getVocabLevel();
    final grammarLevel = await NihongoStorage.getGrammarLevel();
    final kanaScript = await NihongoStorage.getKanaScript();
    final columns = await NihongoStorage.getReferenceListColumns();
    final ttsRate = await NihongoStorage.getTtsRate();
    final ttsVoice = await NihongoStorage.getTtsVoice();
    final ttsEngine = await NihongoStorage.getTtsEngine();
    final quizModes = await NihongoStorage.getQuizModes();
    final speechNetworkFallback =
        await NihongoStorage.getSpeechNetworkFallback();
    final aiAssistEnabled = await NihongoStorage.getAiAssistEnabled();
    final showFurigana = await NihongoStorage.getShowFurigana();
    final reminderEnabled = await NihongoStorage.getReminderEnabled();
    final (reminderHour, reminderMinute) =
        await NihongoStorage.getReminderTime();

    final themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    Locale? locale;
    if (localeTag != null) {
      final parts = localeTag.split('_');
      locale = parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
    }

    state = AppSettings(
      themeMode: themeMode,
      locale: locale,
      vocabLevel: JlptLevel.parse(vocabLevel),
      grammarLevel: JlptLevel.parse(grammarLevel),
      kanaScript: kanaScript == 'katakana'
          ? KanaScript.katakana
          : KanaScript.hiragana,
      // An out-of-range value in a hand-edited config reads as automatic.
      referenceListColumns: columns != null && columns >= 1 && columns <= 4
          ? columns
          : listColumnsAuto,
      ttsRate: ttsRate?.clamp(TtsService.minRate, TtsService.maxRate) ?? 1.0,
      ttsVoice: ttsVoice,
      ttsEngine: ttsEngine,
      quizModes: _parseQuizModes(quizModes),
      speechNetworkFallback: speechNetworkFallback,
      aiAssistEnabled: aiAssistEnabled,
      showFurigana: showFurigana,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );

    // The engine is configured from the same values the UI shows, once the
    // preferences are known. It is deliberately not awaited: a device with no
    // speech engine must not delay the first frame.
    TtsService.instance.init(
      rate: state.ttsRate,
      voiceName: state.ttsVoice,
      engineId: state.ttsEngine,
    );
    SpeechRecognitionService.instance.networkFallbackAllowed =
        state.speechNetworkFallback;
    // Same reason it is not awaited: switching the AI on asks the device what
    // its models can do, which must not delay the first frame — and on a
    // device that was left switched off it does nothing at all.
    unawaited(AiAssistService.instance.setEnabled(state.aiAssistEnabled));
  }

  /// Purpose: Remember the vocabulary page's level filter.
  /// Inputs: `level` — null means all levels.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: The pages read this synchronously from the state, so a filter set
  /// before the first load has landed is not overwritten by it.
  void setVocabLevel(JlptLevel? level) {
    state = state.copyWith(vocabLevel: level, clearVocabLevel: level == null);
    NihongoStorage.setVocabLevel(level?.label);
  }

  /// Purpose: Remember the grammar page's level filter.
  /// Inputs: `level` — null means all levels.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: Separate from the vocabulary filter on purpose.
  void setGrammarLevel(JlptLevel? level) {
    state = state.copyWith(
      grammarLevel: level,
      clearGrammarLevel: level == null,
    );
    NihongoStorage.setGrammarLevel(level?.label);
  }

  /// Purpose: Remember the kana chart's script.
  /// Inputs: `script`.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: Hiragana is the default and is stored as an absent key.
  void setKanaScript(KanaScript script) {
    state = state.copyWith(kanaScript: script);
    NihongoStorage.setKanaScript(
      script == KanaScript.katakana ? 'katakana' : null,
    );
  }

  /// Purpose: Remember the chosen column count for the reference lists.
  /// Inputs: `columns` — 1 to 4, or [listColumnsAuto] for automatic.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: Stored as chosen, not as rendered: the layout clamps it to what
  /// fits, so the choice comes back when the window grows again.
  void setReferenceListColumns(int columns) {
    state = state.copyWith(referenceListColumns: columns);
    NihongoStorage.setReferenceListColumns(
      columns == listColumnsAuto ? null : columns,
    );
  }

  /// Purpose: Change the text-to-speech speaking rate.
  /// Inputs: `rate` — a multiple of normal speed.
  /// Returns: None.
  /// Side effects: Applies the rate to the engine and persists it.
  /// Notes: 1.0 is stored as an absent key, not as a value.
  void setTtsRate(double rate) {
    final clamped = rate.clamp(TtsService.minRate, TtsService.maxRate);
    state = state.copyWith(ttsRate: clamped);
    TtsService.instance.setRate(clamped);
    NihongoStorage.setTtsRate(clamped == 1.0 ? null : clamped);
  }

  /// Purpose: Choose the Japanese voice.
  /// Inputs: `name` — null selects the engine default.
  /// Returns: None.
  /// Side effects: Applies the voice to the engine and persists the choice.
  /// Notes: A voice that has since been uninstalled resolves back to the
  /// engine default inside `TtsService`, so a stale name is harmless.
  void setTtsVoice(String? name) {
    state = state.copyWith(ttsVoice: name, clearTtsVoice: name == null);
    TtsService.instance.setVoiceByName(name);
    NihongoStorage.setTtsVoice(name);
  }

  /// Purpose: Switch to another text-to-speech engine.
  /// Inputs: `engine` — an engine package name, or null for the system
  /// default.
  /// Returns: None.
  /// Side effects: Rebuilds the platform engine, clears the chosen voice, and
  /// persists both.
  /// Notes: The voice is cleared because voice names belong to an engine: the
  /// name the user picked on one engine names nothing on another, and keeping
  /// it would leave the picker showing a choice the engine never accepted.
  void setTtsEngine(String? engine) {
    state = state.copyWith(
      ttsEngine: engine,
      clearTtsEngine: engine == null,
      clearTtsVoice: true,
    );
    unawaited(TtsService.instance.setEngine(engine));
    NihongoStorage.setTtsEngine(engine);
    NihongoStorage.setTtsVoice(null);
  }

  /// Purpose: Remember which quiz modes are switched on.
  /// Inputs: `modes` — an empty set means every mode.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: Stored as an absent key when every mode is on, so a later build
  /// that adds a mode switches it on for anybody who never opted out. The
  /// caller is responsible for not switching every mode off; the quiz would
  /// have nothing to ask.
  void setQuizModes(Set<QuizMode> modes) {
    state = state.copyWith(quizModes: modes);
    final all = modes.length == QuizMode.values.length;
    NihongoStorage.setQuizModes(
      modes.isEmpty || all ? null : modes.map((m) => m.name).join(','),
    );
  }

  /// Purpose: Read a stored quiz-mode list.
  /// Inputs: `stored` — the comma-joined names, or null.
  /// Returns: `Set<QuizMode>`; empty for null, meaning every mode.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A name this build does
  /// not know is skipped rather than fatal: a preference written by a newer
  /// build must not stop the app from starting.
  static Set<QuizMode> _parseQuizModes(String? stored) {
    if (stored == null || stored.isEmpty) return const {};
    final byName = {for (final mode in QuizMode.values) mode.name: mode};
    return {for (final name in stored.split(',')) ?byName[name.trim()]};
  }

  /// Purpose: Allow or forbid a fallback to network speech recognition.
  /// Inputs: `allowed`.
  /// Returns: None.
  /// Side effects: Applies the choice to the recognizer and persists it.
  /// Notes: Off by default and stored as an absent key, so a device that never
  /// touched this setting never sends audio anywhere. The app never turns it
  /// on by itself — only this setter, from the switch in Settings.
  void setSpeechNetworkFallback(bool allowed) {
    state = state.copyWith(speechNetworkFallback: allowed);
    SpeechRecognitionService.instance.networkFallbackAllowed = allowed;
    NihongoStorage.setSpeechNetworkFallback(allowed);
  }

  /// Purpose: Turn the daily reminder on or off.
  /// Inputs: `enabled`, and `l10n` so the reminder text is in the learner's
  /// own language.
  /// Returns: `Future<bool>` — whether it ended up on.
  /// Side effects: **Asks for notification permission** when turning it on;
  /// persists the choice and rebuilds the schedule.
  /// Notes: Permission is requested here and nowhere else. If it is refused
  /// the switch stays off, because a switch that says on while the system says
  /// no is a lie about what will happen. Turning it off cancels the schedule
  /// immediately rather than letting a week of reminders run out.
  Future<bool> setReminderEnabled(bool enabled, AppLocalizations l10n) async {
    if (enabled && !await ReminderService.instance.requestPermission()) {
      return false;
    }
    state = state.copyWith(reminderEnabled: enabled);
    await NihongoStorage.setReminderEnabled(enabled);
    await ReminderService.instance.reschedule(l10n);
    return enabled;
  }

  /// Purpose: Choose what time the reminder fires.
  /// Inputs: `hour`, `minute`, and `l10n` for the text.
  /// Returns: A future completing once the schedule is rebuilt.
  /// Side effects: Persists the time and reschedules.
  /// Notes: The stored day of the last desktop reminder is cleared, so moving
  /// the time earlier fires today rather than tomorrow.
  Future<void> setReminderTime(
    int hour,
    int minute,
    AppLocalizations l10n,
  ) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await NihongoStorage.setReminderTime(hour, minute);
    await NihongoStorage.setLastReminderDate(null);
    await ReminderService.instance.reschedule(l10n);
  }

  /// Purpose: Turn on-device AI assistance on or off.
  /// Inputs: `enabled`.
  /// Returns: None.
  /// Side effects: Applies the choice to `AiAssistService` — which asks the
  /// device what its models can do when switched on — and persists it.
  /// Notes: Off by default and stored as an absent key. Nothing in the app
  /// turns this on by itself; only this setter, from the switch in Settings.
  /// Purpose: Turn the kana printed over kanji on or off.
  /// Inputs: `show`.
  /// Returns: None.
  /// Side effects: Persists the choice.
  /// Notes: On by default, so **off** is what gets stored — the one inverted
  /// preference in the app, because a learner who has never opened Settings is
  /// the learner who most needs the readings.
  void setShowFurigana(bool show) {
    state = state.copyWith(showFurigana: show);
    NihongoStorage.setShowFurigana(show);
  }

  void setAiAssistEnabled(bool enabled) {
    state = state.copyWith(aiAssistEnabled: enabled);
    unawaited(AiAssistService.instance.setEnabled(enabled));
    NihongoStorage.setAiAssistEnabled(enabled);
  }

  /// Purpose: Update theme mode with the provided value.
  /// Inputs: `mode`.
  /// Returns: None.
  /// Side effects: Persists the selected theme mode.
  /// Notes: `system` is stored as an absent key, not a value.
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    NihongoStorage.setThemeMode(str);
  }

  /// Purpose: Update locale with the provided value.
  /// Inputs: `locale` — null follows the system.
  /// Returns: None.
  /// Side effects: Persists the selected locale.
  /// Notes: Stored as `language` or `language_COUNTRY`, which is what carries
  /// `zh_TW`: Traditional and Simplified Chinese differ only by country here,
  /// so a tag that dropped it would silently move a reader to the other one.
  void setLocale(Locale? locale) {
    state = state.copyWith(locale: locale, clearLocale: locale == null);
    if (locale == null) {
      NihongoStorage.setLocaleTag(null);
    } else {
      final tag = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      NihongoStorage.setLocaleTag(tag);
    }
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Locale? locale;

  /// The vocabulary page's level filter; null shows every level.
  final JlptLevel? vocabLevel;

  /// The grammar page's level filter; null shows every level.
  final JlptLevel? grammarLevel;

  /// Which script the kana chart shows.
  final KanaScript kanaScript;

  /// Chosen column count for the reference lists, or [listColumnsAuto].
  final int referenceListColumns;

  /// The text-to-speech speaking rate as a multiple of normal speed.
  final double ttsRate;

  /// The chosen Japanese voice's engine name; null uses the best voice the
  /// engine offers.
  final String? ttsVoice;

  /// The chosen speech engine's package name; null uses the system default.
  final String? ttsEngine;

  /// The quiz modes left switched on; empty means every mode.
  final Set<QuizMode> quizModes;

  /// Whether the user allowed speech recognition to fall back to a network
  /// service. Off unless they turned it on.
  final bool speechNetworkFallback;

  /// Whether the user turned on-device AI assistance on. Off unless they did.
  final bool aiAssistEnabled;

  /// Whether kana are printed over the kanji that need them. On unless the
  /// learner turned it off.
  final bool showFurigana;

  /// Whether the daily reminder is on. Off unless the learner turned it on.
  final bool reminderEnabled;

  /// The hour the reminder fires, in the device's own time.
  final int reminderHour;

  /// The minute it fires.
  final int reminderMinute;

  /// Purpose: Create an app settings instance.
  /// Inputs: All fields.
  /// Returns: A new `AppSettings` instance.
  /// Side effects: None.
  /// Notes: Device-local preferences only; nothing here is synced. They live
  /// in one object so a page reads them synchronously from the provider rather
  /// than starting its own async read and racing its own first frame.
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.vocabLevel,
    this.grammarLevel,
    this.kanaScript = KanaScript.hiragana,
    this.referenceListColumns = listColumnsAuto,
    this.ttsRate = 1.0,
    this.ttsVoice,
    this.ttsEngine,
    this.quizModes = const {},
    this.speechNetworkFallback = false,
    this.aiAssistEnabled = false,
    this.showFurigana = true,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  /// Purpose: Create a copy with selected fields replaced.
  /// Inputs: The fields to replace, plus a `clear` flag per nullable one.
  /// Returns: `AppSettings`.
  /// Side effects: None.
  /// Notes: The `clear` flags exist because `null` already means "keep".
  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    JlptLevel? vocabLevel,
    bool clearVocabLevel = false,
    JlptLevel? grammarLevel,
    bool clearGrammarLevel = false,
    KanaScript? kanaScript,
    int? referenceListColumns,
    double? ttsRate,
    String? ttsVoice,
    bool clearTtsVoice = false,
    String? ttsEngine,
    bool clearTtsEngine = false,
    Set<QuizMode>? quizModes,
    bool? speechNetworkFallback,
    bool? aiAssistEnabled,
    bool? showFurigana,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      vocabLevel: clearVocabLevel ? null : (vocabLevel ?? this.vocabLevel),
      grammarLevel: clearGrammarLevel
          ? null
          : (grammarLevel ?? this.grammarLevel),
      kanaScript: kanaScript ?? this.kanaScript,
      referenceListColumns: referenceListColumns ?? this.referenceListColumns,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsVoice: clearTtsVoice ? null : (ttsVoice ?? this.ttsVoice),
      ttsEngine: clearTtsEngine ? null : (ttsEngine ?? this.ttsEngine),
      quizModes: quizModes ?? this.quizModes,
      speechNetworkFallback:
          speechNetworkFallback ?? this.speechNetworkFallback,
      aiAssistEnabled: aiAssistEnabled ?? this.aiAssistEnabled,
      showFurigana: showFurigana ?? this.showFurigana,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(),
    );

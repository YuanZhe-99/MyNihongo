import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/content/models/jlpt_level.dart';
import '../../features/kana/models/kana.dart';
import '../../features/progress/services/nihongo_storage.dart';
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

  /// Purpose: Load the persisted theme mode and locale from disk.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Reads `storage_config.json` and replaces the state.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadPersisted() async {
    final modeStr = await NihongoStorage.getThemeMode();
    final localeTag = await NihongoStorage.getLocaleTag();
    final vocabLevel = await NihongoStorage.getVocabLevel();
    final grammarLevel = await NihongoStorage.getGrammarLevel();
    final kanaScript = await NihongoStorage.getKanaScript();
    final columns = await NihongoStorage.getReferenceListColumns();

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
    );
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
  /// Notes: Stored as `language` or `language_COUNTRY`.
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
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(),
    );

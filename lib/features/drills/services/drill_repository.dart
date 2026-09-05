import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/jlpt_level.dart';
import '../models/drill_file.dart';
import '../models/drill_section.dart';

/// Loads the drill files a JLPT paper is drawn from.
///
/// Separate from `ContentRepository` for the reason `LessonRepository` is: the
/// catalog is what every page needs and is worth an isolate; a drill file is
/// one section of one level, read only when somebody opens that section, and a
/// level with no file yet is an ordinary state rather than a failure.
class DrillRepository {
  /// Purpose: Prevent construction.
  /// Inputs: None.
  /// Returns: Never.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  DrillRepository._();

  /// Purpose: Name the asset one level's section lives in.
  /// Inputs: `level`, `section`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Flat — `n5-reading.json`, not `n5/reading.json` — so `pubspec.yaml`
  /// needs one asset line rather than one per level, and the two hard-coded
  /// directory lists in `tool/convert_zh_tw.dart` and `content_zh_tw_test.dart`
  /// gain one entry rather than five.
  static String assetFor(JlptLevel level, DrillSection section) =>
      'assets/content/drills/${level.name}-${section.name}.json';

  /// Purpose: Load one level's section.
  /// Inputs: `level`, `section`, and a `bundle` for tests.
  /// Returns: `Future<DrillFile>` — empty when the section has no file.
  /// Side effects: Reads an asset.
  /// Notes: A missing file is an empty section, not an error. Levels are
  /// written one release at a time, so a build that ships N5 and not N4 is the
  /// normal state and the Learn card says so rather than showing a failure.
  static Future<DrillFile> load(
    JlptLevel level,
    DrillSection section, [
    AssetBundle? bundle,
  ]) async {
    final source = bundle ?? rootBundle;
    final asset = assetFor(level, section);
    // Asked of the manifest rather than attempted and caught. A missing asset
    // is the **normal** state for most of the twenty level-section pairs while
    // the levels are still being written, and `loadString` does not merely
    // throw for one — it reports a Flutter error first, which a widget test
    // fails on even though the throw itself is handled here.
    if (!await _exists(asset, source)) {
      return DrillFile(level: level, section: section);
    }
    try {
      final raw = await source.loadString(asset);
      return DrillFile.fromJson(
        jsonDecode(raw),
        level: level,
        section: section,
      );
    } catch (_) {
      return DrillFile(level: level, section: section);
    }
  }

  /// Purpose: Load the structure file.
  /// Inputs: A `bundle` for tests.
  /// Returns: `Future<JlptStructure>` — `JlptStructure.empty` if it will not
  /// load.
  /// Side effects: Reads an asset.
  /// Notes: One file for every level, because it is small and because every
  /// screen that shows a composition wants to compare levels.
  static Future<JlptStructure> loadStructure([AssetBundle? bundle]) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(
        'assets/content/drills/structure.json',
      );
      return JlptStructure.fromJson(jsonDecode(raw));
    } catch (_) {
      return JlptStructure.empty;
    }
  }

  /// Purpose: Say whether an asset was actually bundled.
  /// Inputs: The `asset` path and the `bundle` to ask.
  /// Returns: `Future<bool>`.
  /// Side effects: Reads the asset manifest, which the bundle caches.
  /// Notes: Internal helper used within this file only. A manifest that will
  /// not load at all is treated as "try it and see", so a platform where this
  /// is unavailable degrades to the old behaviour rather than reporting every
  /// level as unwritten.
  static Future<bool> _exists(String asset, AssetBundle bundle) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest.listAssets().contains(asset);
    } catch (_) {
      return true;
    }
  }
}

/// One level's section, loaded on demand.
///
/// A `family` over the pair because a learner practising N5 grammar should not
/// cause N1 listening to be parsed.
final drillFileProvider =
    FutureProvider.family<DrillFile, (JlptLevel, DrillSection)>(
      (ref, key) => DrillRepository.load(key.$1, key.$2),
    );

/// Every section of one level, for the card that has to say which are ready.
///
/// Loaded together because the question the Learn tab asks is about the level
/// as a whole — "what can I practise?" — and answering it one section at a
/// time would show the buttons appearing one by one.
final drillLevelProvider =
    FutureProvider.family<Map<DrillSection, DrillFile>, JlptLevel>((
      ref,
      level,
    ) async {
      final files = await Future.wait([
        for (final section in DrillSection.values)
          DrillRepository.load(level, section),
      ]);
      return {for (final file in files) file.section: file};
    });

/// The JLPT's own composition and timings.
final jlptStructureProvider = FutureProvider<JlptStructure>(
  (ref) => DrillRepository.loadStructure(),
);

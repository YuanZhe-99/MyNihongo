import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/jlpt_level.dart';
import '../models/lesson_path.dart';

/// Loads the unit files that turn a level into a path.
///
/// Separate from `ContentRepository` on purpose. The catalog is what every
/// page needs and is worth parsing on an isolate; a path is one small file
/// that only the Learn tab and a lesson session read, and a level with no file
/// yet is an ordinary state rather than a failure.
class LessonRepository {
  /// Purpose: Prevent construction.
  /// Inputs: None.
  /// Returns: Never.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  LessonRepository._();

  /// Purpose: Name the asset a level's units live in.
  /// Inputs: `level`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: One file per level, like the grammar files and for the same
  /// reason: a level can be written and reviewed without touching another.
  static String assetFor(JlptLevel level) =>
      'assets/content/lessons/${level.name}.json';

  /// Purpose: Load one level's path.
  /// Inputs: `level`, and a `bundle` for tests.
  /// Returns: `Future<LessonPath>` — empty when the level has no file.
  /// Side effects: Reads an asset.
  /// Notes: A missing file is an empty path, not an error. Levels are written
  /// one at a time, so a build that ships N5's units and not N4's is the
  /// normal state rather than a broken one, and the Learn tab says "not
  /// written yet" instead of showing an error.
  static Future<LessonPath> load(JlptLevel level, [AssetBundle? bundle]) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(assetFor(level));
      return LessonPath.fromJson(jsonDecode(raw));
    } catch (_) {
      return LessonPath(level: level.label, units: const []);
    }
  }
}

/// One level's path, loaded on demand.
///
/// A `family` because the learner's target level can change and because a
/// level nobody is studying should not be parsed at all.
final lessonPathProvider = FutureProvider.family<LessonPath, JlptLevel>(
  (ref, level) => LessonRepository.load(level),
);

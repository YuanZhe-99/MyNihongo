/// Purpose: Read and parse the bundled content files.
/// Inputs: The asset bundle.
/// Returns: A `ContentCatalog`, and a provider holding one per app run.
/// Side effects: Reads assets; parses on a background isolate by default.
/// Notes: Content is read-only and ships inside the app, so it is neither
/// synced nor backed up — only the user's progress against it is. See
/// `doc/en-us/features/content-catalog.md`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_catalog.dart';

/// The raw strings of the content files, in the order the parser wants them.
///
/// A record rather than three arguments, because `compute` takes one message.
typedef ContentSources = ({
  String vocab,
  List<String> grammar,
  String kanaNotes,
});

/// Loads the bundled content files.
class ContentRepository {
  /// Purpose: Prevent direct instantiation and expose only static members.
  /// Inputs: None.
  /// Returns: A new `ContentRepository._` instance.
  /// Side effects: None.
  /// Notes: Implementations should preserve this contract.
  ContentRepository._();

  /// Asset path of the generated vocabulary file.
  static const vocabAsset = 'assets/content/vocab.json';

  /// Asset paths of the per-level grammar files, easiest level first.
  ///
  /// One file per level so a level can be written and reviewed on its own, and
  /// so the diff of adding N4 does not touch N5. Append as levels are written.
  static const grammarAssets = ['assets/content/grammar/n5.json'];

  /// Asset path of the kana teaching notes.
  static const kanaNotesAsset = 'assets/content/kana_notes.json';

  /// Whether to parse on a background isolate.
  ///
  /// Widget tests set this to false: `compute` never completes under
  /// `FakeAsync`, so `pumpAndSettle` would hang forever.
  @visibleForTesting
  static bool parseInIsolate = true;

  /// Purpose: Read and parse every content file.
  /// Inputs: Optional `bundle` for tests; defaults to `rootBundle`.
  /// Returns: `Future<ContentCatalog>`.
  /// Side effects: Reads assets, and by default spawns an isolate to parse.
  /// Notes: The vocabulary file is roughly 2 MB, so it is read with
  /// `cache: false` — keeping it in the bundle's string cache would hold a
  /// second copy for the life of the process, and it is parsed exactly once.
  /// Decoding and building the catalog run on an isolate so the first frame
  /// after launch is not dropped.
  static Future<ContentCatalog> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    final sources = (
      vocab: await assets.loadString(vocabAsset, cache: false),
      grammar: [
        for (final asset in grammarAssets) await assets.loadString(asset),
      ],
      kanaNotes: await assets.loadString(kanaNotesAsset),
    );
    return parseInIsolate
        ? compute(parseContent, sources)
        : parseContent(sources);
  }

  /// Purpose: Turn the raw file contents into a catalog.
  /// Inputs: `sources`.
  /// Returns: `ContentCatalog`.
  /// Side effects: None.
  /// Notes: Top-level-callable and free of Flutter bindings, because it runs
  /// on an isolate. Exposed for the test that checks both paths agree.
  @visibleForTesting
  static ContentCatalog parseContent(ContentSources sources) {
    return ContentCatalog.fromJson(jsonDecode(sources.vocab), [
      for (final raw in sources.grammar) jsonDecode(raw),
    ], jsonDecode(sources.kanaNotes));
  }
}

/// Purpose: Parse content on a background isolate.
/// Inputs: `sources`.
/// Returns: `ContentCatalog`.
/// Side effects: None.
/// Notes: `compute` needs a top-level or static function; this forwards to the
/// static one so the logic lives with the rest of the repository.
ContentCatalog parseContent(ContentSources sources) =>
    ContentRepository.parseContent(sources);

/// The parsed content catalog, loaded once per app run.
final contentCatalogProvider = FutureProvider<ContentCatalog>(
  (ref) => ContentRepository.load(),
);

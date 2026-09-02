import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_catalog.dart';

/// Loads the bundled content files.
///
/// Content is read-only and ships inside the app, so it is neither synced nor
/// backed up — only the user's progress against it is. See
/// `doc/en-us/features/content-catalog.md`.
class ContentRepository {
  /// Purpose: Prevent direct instantiation and expose only static members.
  /// Inputs: None.
  /// Returns: A new `ContentRepository._` instance.
  /// Side effects: None.
  /// Notes: Implementations should preserve this contract.
  ContentRepository._();

  /// Asset path of the vocabulary file.
  static const vocabAsset = 'assets/content/vocab_seed.json';

  /// Asset path of the grammar file.
  static const grammarAsset = 'assets/content/grammar_seed.json';

  /// Purpose: Read and parse both content files.
  /// Inputs: Optional `bundle` for tests; defaults to `rootBundle`.
  /// Returns: `Future<ContentCatalog>`.
  /// Side effects: Reads two assets.
  /// Notes: Parsing runs on the calling isolate. The seed files are small;
  /// move this to `compute` when the JMdict-sized catalog arrives.
  static Future<ContentCatalog> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    final vocabRaw = await assets.loadString(vocabAsset);
    final grammarRaw = await assets.loadString(grammarAsset);
    return ContentCatalog.fromJson(
      jsonDecode(vocabRaw),
      jsonDecode(grammarRaw),
    );
  }
}

/// The parsed content catalog, loaded once per app run.
final contentCatalogProvider = FutureProvider<ContentCatalog>(
  (ref) => ContentRepository.load(),
);

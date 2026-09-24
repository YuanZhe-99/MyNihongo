import '../../l10n/app_localizations.dart';

/// Purpose: Name a part-of-speech tag in the learner's language.
/// Inputs: `l10n`, and a `tag` from the content's closed set
/// (`vocabPartsOfSpeech`).
/// Returns: `String` — the tag itself when it is not one the app knows.
/// Side effects: None.
/// Notes: The vocabulary sheet printed these tags verbatim — `verb-godan`,
/// `suru-verb` — in every language, which is jargon to an English reader and
/// untranslated to everyone else. The same token-to-ARB switch as
/// `formLabel`. The fallback is defensive only: `content_catalog_test`
/// already fails on a tag outside the set.
String posLabel(AppLocalizations l10n, String tag) => switch (tag) {
  'noun' => l10n.posNoun,
  'pronoun' => l10n.posPronoun,
  'proper-noun' => l10n.posProperNoun,
  'verb-godan' => l10n.posVerbGodan,
  'verb-ichidan' => l10n.posVerbIchidan,
  'verb-irregular' => l10n.posVerbIrregular,
  'suru-verb' => l10n.posSuruVerb,
  'transitive' => l10n.posTransitive,
  'intransitive' => l10n.posIntransitive,
  'auxiliary' => l10n.posAuxiliary,
  'i-adjective' => l10n.posIAdjective,
  'na-adjective' => l10n.posNaAdjective,
  'no-adjective' => l10n.posNoAdjective,
  'adnominal' => l10n.posAdnominal,
  'adverb' => l10n.posAdverb,
  'particle' => l10n.posParticle,
  'conjunction' => l10n.posConjunction,
  'interjection' => l10n.posInterjection,
  'expression' => l10n.posExpression,
  'counter' => l10n.posCounter,
  'numeric' => l10n.posNumeric,
  'prefix' => l10n.posPrefix,
  'suffix' => l10n.posSuffix,
  _ => tag,
};

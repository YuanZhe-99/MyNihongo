/// Purpose: Name the closed set of part-of-speech tags the content files use.
/// Inputs: None.
/// Returns: A constant set.
/// Side effects: None.
/// Notes: Deliberately importing nothing, so `tool/import_vocab.dart` can share
/// the same file rather than keeping a second copy that drifts. JMdict's own
/// tag vocabulary is much larger and much finer; the import maps it onto these
/// names, and a test asserts every shipped entry uses only them.
library;

/// Every part-of-speech tag a `vocab.json` entry may carry.
const vocabPartsOfSpeech = <String>{
  'noun',
  'pronoun',
  'proper-noun',
  'verb-godan',
  'verb-ichidan',
  'verb-irregular',
  'suru-verb',
  'transitive',
  'intransitive',
  'auxiliary',
  'i-adjective',
  'na-adjective',
  'no-adjective',
  'adnominal',
  'adverb',
  'particle',
  'conjunction',
  'interjection',
  'expression',
  'counter',
  'numeric',
  'prefix',
  'suffix',
};

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';

/// Purpose: Check that parsing on an isolate and parsing inline agree.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the content assets twice, once on a background isolate.
/// Notes: `parseInIsolate` exists so widget tests can avoid `compute`, which
/// never completes under `FakeAsync`. This is what stops that seam from
/// quietly becoming two different parsers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => ContentRepository.parseInIsolate = true);

  test('both parse paths produce the same catalog', () async {
    ContentRepository.parseInIsolate = false;
    final inline = await ContentRepository.load();

    ContentRepository.parseInIsolate = true;
    final isolate = await ContentRepository.load();

    expect(isolate.vocab.length, inline.vocab.length);
    expect(isolate.grammar.length, inline.grammar.length);
    expect(isolate.kanaNotes.length, inline.kanaNotes.length);
    expect(
      isolate.vocab.map((e) => e.id).take(50),
      inline.vocab.map((e) => e.id).take(50),
    );
    expect(isolate.allVocabIds.length, inline.allVocabIds.length);
  });

  test('the asset paths are the generated ones, not the old seed files', () {
    expect(ContentRepository.vocabAsset, 'assets/content/vocab.json');
    expect(
      ContentRepository.grammarAssets,
      contains('assets/content/grammar/n5.json'),
    );
    expect(ContentRepository.kanaNotesAsset, 'assets/content/kana_notes.json');
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Purpose: Hold two files to the boundary their own documentation claims for
/// them, by reading what they import.
/// Inputs: None; reads the source files.
/// Returns: None.
/// Side effects: Reads two files under `lib/`.
/// Notes: Both claims are load-bearing and neither is visible from a normal
/// test. `AiPracticeService` writes no record because it cannot reach one, and
/// `QuizSession` takes progress as a callback rather than a dependency so a
/// test can watch exactly what it would have written. An import added in good
/// faith would break both quietly — the code would still work, the invariant
/// would be gone, and three documents would start saying something untrue.
///
/// This test was written because `ai-assist.md`, `quizzes.md` and two function
/// pages all said "a test asserts this" and none did.
void main() {
  /// Purpose: Read one library's import lines.
  /// Inputs: The `path` under `lib/`.
  /// Returns: Every `import` line, trimmed.
  /// Side effects: Reads the file.
  /// Notes: Internal helper used within this test file only. Line-based on
  /// purpose: an import is one line in this codebase, and a parser here would
  /// be more machinery than the claim is worth.
  List<String> importsOf(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '$path has moved');
    return [
      for (final line in file.readAsLinesSync())
        if (line.trimLeft().startsWith('import ')) line.trim(),
    ];
  }

  test('the practice AI service cannot reach storage or progress', () {
    final imports = importsOf(
      'lib/features/ai/services/ai_practice_service.dart',
    );
    expect(imports, isNotEmpty);
    for (final line in imports) {
      expect(
        line,
        isNot(anyOf(contains('progress/'), contains('nihongo_storage'))),
        reason: 'nothing generated writes a record, and this is why it cannot',
      );
    }
  });

  test('a quiz session takes progress as a callback, not a dependency', () {
    final imports = importsOf('lib/features/quiz/services/quiz_session.dart');
    expect(imports, isNotEmpty);
    for (final line in imports) {
      expect(
        line,
        isNot(anyOf(contains('progress/'), contains('nihongo_storage'))),
        reason: 'a test can only watch what it would have written because the '
            'session hands it over rather than writing it',
      );
    }
  });
}

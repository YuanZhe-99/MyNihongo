/// Cleans up what the on-device model returns.
///
/// A small model asked for four sentences will sometimes answer with a
/// markdown heading, a bulleted list, a repetition of the prompt, or nothing
/// at all. None of that is worth showing, and none of it is worth a
/// round-trip: this turns a raw completion into either a paragraph or null,
/// and the UI shows a failure line for null.
///
/// Everything here is pure and unit-tested, which is the point of keeping it
/// out of the widget and out of the platform channel.
class ResponseParser {
  const ResponseParser._();

  /// How long a shown explanation may be, in characters.
  ///
  /// Four sentences of Chinese are far shorter than four of English, so the
  /// cap is generous; it exists to stop a model that ignored the instruction
  /// from filling the page, not to enforce the instruction.
  static const maxExplanationChars = 700;

  /// Purpose: Turn a raw completion into a paragraph worth showing.
  /// Inputs: `raw` from the model, and the `prompt` it answered.
  /// Returns: `String?` — null when there is nothing usable.
  /// Side effects: None.
  /// Notes: The `prompt` is passed so an answer that merely echoes the input
  /// can be rejected. A model that echoes has not answered, and showing the
  /// learner their own sentence back — labelled as an explanation — is worse
  /// than saying nothing.
  static String? explanation(String raw, {String? prompt}) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    text = _stripFences(text);
    text = text
        .split('\n')
        .map(_stripLineMarkup)
        .where((line) => line.isNotEmpty)
        .join('\n');
    text = text.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    if (text.isEmpty) return null;

    if (prompt != null && _isEcho(text, prompt)) return null;
    return _capAtSentence(text, maxExplanationChars);
  }

  /// Purpose: Pick the one correction worth offering.
  /// Inputs: The model's `suggestions` and the `original` sentence.
  /// Returns: `String?` — null when none of them says anything new.
  /// Side effects: None.
  /// Notes: A proofreader handed a correct sentence answers with the sentence
  /// itself. Offering that as a correction would teach the learner that their
  /// correct sentence was wrong, so an unchanged suggestion is dropped and the
  /// UI says nothing needed changing.
  static String? correction(List<String> suggestions, String original) {
    final normalizedOriginal = _normalize(original);
    for (final suggestion in suggestions) {
      final trimmed = suggestion.trim();
      if (trimmed.isEmpty) continue;
      if (_normalize(trimmed) == normalizedOriginal) continue;
      return trimmed;
    }
    return null;
  }

  /// Purpose: Remove a markdown code fence wrapping the whole answer.
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static String _stripFences(String text) {
    if (!text.startsWith('```')) return text;
    final lines = text.split('\n');
    if (lines.length < 2) return text;
    final body = lines.sublist(1);
    if (body.isNotEmpty && body.last.trim().startsWith('```')) {
      body.removeLast();
    }
    return body.join('\n').trim();
  }

  /// Purpose: Strip list bullets, numbering and heading marks from one line.
  /// Inputs: `line`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Inline emphasis is
  /// removed too: the card renders plain text, so a stray asterisk would be
  /// shown as an asterisk.
  static String _stripLineMarkup(String line) {
    var text = line.trim();
    text = text.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
    text = text.replaceFirst(RegExp(r'^[-*•]\s+'), '');
    text = text.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
    // `replaceAllMapped`, not `replaceAll`: Dart's string replacement does not
    // expand `$1`, so a group reference would be written out literally.
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => match[1]!,
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)'),
      (match) => match[1]!,
    );
    return text.trim();
  }

  /// Purpose: Decide whether the answer is just the prompt repeated.
  /// Inputs: `text`, `prompt`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Compares only the
  /// first line, because an echo starts with one: a real answer that happens
  /// to open by quoting the sentence still has its own second line.
  static bool _isEcho(String text, String prompt) {
    final first = _normalize(text.split('\n').first);
    if (first.isEmpty) return true;
    if (text.split('\n').length > 1) return false;
    return _normalize(prompt).contains(first);
  }

  /// Purpose: Cut long text at the last sentence end that fits.
  /// Inputs: `text`, `max`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Japanese, Chinese and
  /// English sentence enders are all treated as boundaries; with none in
  /// range the text is cut hard and ellipsised, which reads as truncation
  /// rather than as a model that stopped mid-thought.
  static String _capAtSentence(String text, int max) {
    if (text.length <= max) return text;
    final window = text.substring(0, max);
    var cut = -1;
    for (final end in ['。', '！', '？', '.', '!', '?', '\n']) {
      final index = window.lastIndexOf(end);
      if (index > cut) cut = index;
    }
    if (cut > max ~/ 2) return window.substring(0, cut + 1).trim();
    return '${window.trim()}…';
  }

  /// Purpose: Normalize text for comparison.
  /// Inputs: `text`.
  /// Returns: `String` with whitespace removed.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Whitespace is dropped
  /// entirely rather than collapsed, because Japanese is written without it
  /// and a model may add or remove spaces freely.
  static String _normalize(String text) =>
      text.replaceAll(RegExp(r'\s+'), '').trim();
}

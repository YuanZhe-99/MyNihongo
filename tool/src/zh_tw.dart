/// The content key the Traditional Chinese text is written under.
///
/// One string names the locale everywhere: the ARB file is `app_zh_TW.arb`,
/// the stored preference is `zh_TW`, and this is the content key, so a reader
/// who learns the tag in one place has learned it in all three.
const zhTwKey = 'zh_TW';

/// The content key the Simplified Chinese text is authored under.
const zhKey = 'zh';

/// Purpose: Add a generated Traditional Chinese string beside every Simplified
/// one in a decoded content file.
/// Inputs: `json` — anything `jsonDecode` returned; `convert` — the Simplified
/// to Traditional conversion.
/// Returns: The same structure with `zh_TW` set wherever `zh` exists.
/// Side effects: None — a new structure is built, the input is not mutated.
/// Notes: `zh_TW` is written **immediately after** `zh` and any existing one is
/// replaced, which is what makes the tool idempotent: re-running it on its own
/// output produces a byte-identical file, so a rebuild with unchanged inputs
/// leaves an empty `git diff`. A `zh_TW` whose `zh` has since been deleted goes
/// with it, because generated text may never outlive its source.
Object? withTraditional(Object? json, String Function(String) convert) {
  if (json is Map) {
    final out = <String, Object?>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      if (key == zhTwKey) continue;
      final value = entry.value;
      if (key == zhKey) {
        out[zhKey] = value;
        final traditional = _translate(value, convert);
        if (traditional != null) out[zhTwKey] = traditional;
        continue;
      }
      out[key] = withTraditional(value, convert);
    }
    return out;
  }
  if (json is List) {
    return [for (final item in json) withTraditional(item, convert)];
  }
  return json;
}

/// Purpose: Convert one `zh` value, whether it is a string or a list of them.
/// Inputs: `value`, `convert`.
/// Returns: The converted value, or null when there is nothing to convert.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Content stores a gloss
/// as a list and an explanation as a string; both shapes go through here so
/// neither is silently skipped.
Object? _translate(Object? value, String Function(String) convert) {
  if (value is String) return value.isEmpty ? null : convert(value);
  if (value is List) {
    final items = value.whereType<String>().toList();
    if (items.length != value.length || items.isEmpty) return null;
    return [for (final item in items) convert(item)];
  }
  return null;
}

/// Where the OpenCC dictionaries live, relative to the repository root.
const openCcDirectory = 'tool/content/opencc';

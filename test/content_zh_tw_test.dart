// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/src/chinese_converter.dart';
import '../tool/src/zh_tw.dart';

/// Purpose: Test that the Traditional Chinese text the app ships is exactly
/// what `tool/convert_zh_tw.dart` produces from the Simplified text beside it.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the content assets and the OpenCC dictionaries.
/// Notes: This is the same guarantee `content_catalog_test.dart` gives the
/// Chinese gloss overlay: generated content that is committed has to be
/// checkable, or a Simplified edit lands and the Traditional text quietly
/// stays behind. Editing a `zh_TW` string by hand fails here too, which is
/// deliberate — the fix is to edit the `zh` and re-run the tool.
void main() {
  // Enumerated rather than listed. A hard-coded list means a new level's
  // grammar file is converted by the tool and never checked by this test,
  // which is the failure mode this test exists to prevent. `prompts/` is not
  // here for the same reason it is not in the tool: its Traditional text is
  // hand-written, not generated.
  final paths = [
    'assets/content/vocab.json',
    'assets/content/kana_notes.json',
    'assets/content/function_words.json',
    for (final name in const ['grammar', 'lessons'])
      if (Directory('assets/content/$name').existsSync())
        for (final file in Directory('assets/content/$name')
            .listSync()
            .whereType<File>())
          if (file.path.endsWith('.json'))
            file.path.replaceAll(r'\', '/'),
  ]..sort();

  late OpenCcConverter converter;

  setUpAll(() => converter = OpenCcConverter.load(openCcDirectory));

  /// Walk every map in a decoded file, reporting each one to `visit`.
  void walk(Object? json, void Function(Map<Object?, Object?>) visit) {
    if (json is Map) {
      visit(json);
      for (final value in json.values) {
        walk(value, visit);
      }
    } else if (json is List) {
      for (final item in json) {
        walk(item, visit);
      }
    }
  }

  test('every Traditional string is the conversion of the one beside it', () {
    var checked = 0;
    for (final path in paths) {
      walk(jsonDecode(File(path).readAsStringSync()), (map) {
        final zh = map[zhKey];
        final zhTw = map[zhTwKey];
        if (zh == null) {
          expect(
            zhTw,
            isNull,
            reason: '$path has $zhTwKey with no $zhKey: $map',
          );
          return;
        }
        if (zh is String) {
          expect(zhTw, converter.convert(zh), reason: '$path: $zh');
          checked++;
        } else if (zh is List) {
          expect(zhTw, [
            for (final item in zh.cast<String>()) converter.convert(item),
          ], reason: '$path: $zh');
          checked++;
        }
      });
    }
    expect(checked, greaterThan(1000), reason: 'the content should be large');
  });

  test('Japanese quoted inside the Chinese text is not converted', () {
    // A grammar note about 来る is written in Chinese and quotes the Japanese
    // word. 來る is not a word in either language, and shipping it would teach
    // a character Japanese does not use.
    final broken = {
      for (final token in converter.preserved)
        if (converter.convertIgnoringPreserved(token) != token)
          converter.convertIgnoringPreserved(token),
    };
    expect(broken, isNotEmpty, reason: 'the preserve list should not be empty');

    for (final path in paths) {
      final text = File(path).readAsStringSync();
      for (final wrong in broken) {
        expect(
          text.contains(wrong),
          isFalse,
          reason: '$path contains $wrong, which is neither language',
        );
      }
    }
  });
}

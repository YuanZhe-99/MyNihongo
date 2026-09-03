import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/platform_capabilities.dart';

/// Opens the platform's own speech settings.
///
/// A missing Japanese voice is a device state the user can fix, but only in a
/// place the app cannot reach from Flutter. Android answers a method channel
/// that fires the TTS settings intent; Windows hands `ms-settings:speech` to
/// the shell. Everywhere else there is no documented deep link and the caller
/// falls back to naming the settings pane in text.
class SystemSettingsLauncher {
  static const _channel = MethodChannel('com.yuanzhe.my_nihongo/system');

  /// Purpose: Open the system speech settings.
  /// Inputs: None.
  /// Returns: `Future<bool>` — false when there is no deep link, or when the
  /// platform refused to open it.
  /// Side effects: Sends the user to another app.
  /// Notes: Never throws: a failure is a false, so the caller can show a
  /// message instead. The Windows branch shells out to `explorer.exe`, which
  /// is how a `ms-settings:` URI is opened without a URL-launcher plugin.
  static Future<bool> openSpeechSettings() async {
    if (!canOpenSystemSpeechSettings) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final opened = await _channel.invokeMethod<bool>('openSpeechSettings');
        return opened ?? false;
      }
      final result = await Process.run('explorer.exe', ['ms-settings:speech']);
      // explorer.exe returns a non-zero code even on success; the URI handler
      // reports failure by not opening anything, which cannot be observed here.
      return result.exitCode == 0 || result.exitCode == 1;
    } catch (_) {
      return false;
    }
  }
}

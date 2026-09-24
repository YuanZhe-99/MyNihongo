import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Purpose: Keep the five version fields a release moves in step.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads `pubspec.yaml` and `installer.iss`.
/// Notes: `installer.iss`'s two `VersionInfo*` lines stayed at 0.4.7 for four
/// releases (0.4.8 to 0.4.11) while `pubspec.yaml` and `msix_version` moved
/// every time. Nothing noticed because nothing built the installer. The
/// release flow pushes the tag without waiting for CI, so this is run locally
/// before tagging, and CI's run is the backstop.
void main() {
  String field(String text, RegExp pattern, String name) {
    final match = pattern.firstMatch(text);
    expect(match, isNotNull, reason: '$name not found');
    return match!.group(1)!;
  }

  test('pubspec.yaml and installer.iss name one X.Y.Z', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final installer = File('installer.iss').readAsStringSync();

    final version = field(
      pubspec,
      RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$', multiLine: true),
      'pubspec version',
    );
    final fields = <String, String>{
      'pubspec version': version,
      'msix_version': field(
        pubspec,
        RegExp(r'^\s+msix_version:\s*(\d+\.\d+\.\d+)\.0\s*$', multiLine: true),
        'msix_version',
      ),
      'AppVersion': field(
        installer,
        RegExp(r'^AppVersion=(\d+\.\d+\.\d+)\s*$', multiLine: true),
        'AppVersion',
      ),
      'VersionInfoVersion': field(
        installer,
        RegExp(r'^VersionInfoVersion=(\d+\.\d+\.\d+)\.0\s*$', multiLine: true),
        'VersionInfoVersion',
      ),
      'VersionInfoProductVersion': field(
        installer,
        RegExp(
          r'^VersionInfoProductVersion=(\d+\.\d+\.\d+)\s*$',
          multiLine: true,
        ),
        'VersionInfoProductVersion',
      ),
    };

    for (final entry in fields.entries) {
      expect(entry.value, version, reason: '${entry.key} is not $version');
    }
  });
}

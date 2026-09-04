import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/models/voice_ordering.dart';

/// Purpose: Test the order and the predicates the voice picker numbers against.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The order is load-bearing rather than cosmetic: the picker names
/// voices "Japanese voice 1, 2, 3" by position, and the service takes the first
/// installed one as its default. An unstable order would rename voices between
/// runs and silently change which one speaks.
void main() {
  const installedOffline = {
    'name': 'ja-jp-x-jab#male_1-local',
    'locale': 'ja-JP',
    'quality': 'normal',
    'network_required': '0',
    'features': '',
  };
  const installedHigh = {
    'name': 'ja-jp-x-jac#female_2-local',
    'locale': 'ja-JP',
    'quality': 'very high',
    'network_required': '0',
    'features': '',
  };
  const networkVoice = {
    'name': 'ja-JP-Neural',
    'locale': 'ja-JP',
    'quality': 'very high',
    'network_required': '1',
    'features': '',
  };
  const notInstalled = {
    'name': 'ja-jp-x-jad#male_3-local',
    'locale': 'ja-JP',
    'quality': 'very high',
    'network_required': '0',
    'features': 'notInstalled',
  };

  test('a voice missing its data is recognised as not installed', () {
    expect(voiceIsNotInstalled(notInstalled), isTrue);
    expect(voiceIsNotInstalled(installedOffline), isFalse);
  });

  test('a network voice is recognised in both shapes the engines use', () {
    expect(voiceNeedsNetwork(networkVoice), isTrue);
    expect(
      voiceNeedsNetwork(const {'name': 'x', 'network_required': 'true'}),
      isTrue,
    );
    expect(voiceNeedsNetwork(installedOffline), isFalse);
  });

  test('an unreported quality ranks below every reported one', () {
    expect(voiceQualityRank(const {'name': 'x'}), -1);
    expect(voiceQualityRank(installedOffline), greaterThan(-1));
    expect(
      voiceQualityRank(installedHigh),
      greaterThan(voiceQualityRank(installedOffline)),
    );
  });

  test('installed beats missing, offline beats network, then quality', () {
    final sorted = sortJapaneseVoices([
      notInstalled,
      networkVoice,
      installedOffline,
      installedHigh,
    ]);
    expect(sorted.map((v) => v['name']), [
      installedHigh['name'],
      installedOffline['name'],
      networkVoice['name'],
      notInstalled['name'],
    ]);
  });

  test('the order does not depend on the engine enumeration order', () {
    final one = sortJapaneseVoices([installedHigh, installedOffline]);
    final two = sortJapaneseVoices([installedOffline, installedHigh]);
    expect(one.map((v) => v['name']), two.map((v) => v['name']));
  });

  test('voices the engine described identically are ordered by name', () {
    final sorted = sortJapaneseVoices([
      const {'name': 'b', 'locale': 'ja-JP'},
      const {'name': 'a', 'locale': 'ja-JP'},
    ]);
    expect(sorted.map((v) => v['name']), ['a', 'b']);
  });

  test('sorting leaves the caller list alone', () {
    final original = [installedOffline, installedHigh];
    sortJapaneseVoices(original);
    expect(original.first['name'], installedOffline['name']);
  });
}

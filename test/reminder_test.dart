import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:my_nihongo/features/reminders/services/reminder_backend.dart';
import 'package:my_nihongo/features/reminders/services/reminder_planner.dart';
import 'package:my_nihongo/features/reminders/services/reminder_service.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test what a reminder says, when it fires, and above all when it
/// asks for permission.
/// Inputs: None.
/// Returns: None.
/// Side effects: Writes into a temporary directory.
/// Notes: The plugin is never touched: a fake backend records what it was
/// asked to do, which is the only part worth asserting. The first test in the
/// permission group is the one that matters. M2.4 shipped a build that asked
/// for the microphone the moment Settings opened; this is the same mistake
/// with a different permission, so "init never asks" is written down rather
/// than assumed.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// A backend that records rather than notifies.
class _FakeBackend extends ReminderBackend {
  int inits = 0;
  int permissionRequests = 0;
  int cancels = 0;
  bool grant = true;
  List<ScheduledReminder> scheduled = const [];
  final shown = <String>[];

  @override
  Future<void> init() async => inits++;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> schedule(List<ScheduledReminder> reminders) async {
    scheduled = reminders;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled = const [];
  }

  @override
  Future<void> showNow(String title, String body) async => shown.add(body);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_remind_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  group('what the plan says', () {
    test('a week of reminders, one a day', () {
      final plan = planReminders(
        hour: 20,
        minute: 0,
        now: DateTime(2026, 9, 4, 9),
        progress: const ProgressData(),
        path: const LessonPath(level: 'N5', units: []),
        l10n: l10n,
      );
      expect(plan, hasLength(reminderDays));
      expect(plan.first.fireAt, DateTime(2026, 9, 4, 20));
      expect(plan.last.fireAt, DateTime(2026, 9, 10, 20));
      expect(plan.map((r) => r.id).toSet(), hasLength(reminderDays));
    });

    test('a time that has already passed today starts tomorrow', () {
      // Turning the switch on at nine in the evening must not fire a reminder
      // for eight that morning.
      final plan = planReminders(
        hour: 8,
        minute: 0,
        now: DateTime(2026, 9, 4, 21),
        progress: const ProgressData(),
        path: const LessonPath(level: 'N5', units: []),
        l10n: l10n,
      );
      expect(plan.first.fireAt, DateTime(2026, 9, 5, 8));
    });

    test('today says how many items are due', () {
      final due = StudyRecord.create(
        'vocab:jm1',
      ).copyWith(dueAt: DateTime.utc(2026, 9, 3));
      final plan = planReminders(
        hour: 20,
        minute: 0,
        now: DateTime(2026, 9, 4, 9),
        progress: ProgressData(records: [due]),
        path: const LessonPath(level: 'N5', units: []),
        l10n: l10n,
      );
      expect(plan.first.body, contains('1'));
    });

    test('with nothing due it names the next unit instead of a number', () {
      const path = LessonPath(
        level: 'N5',
        units: [
          LessonUnit(
            id: 'unit:n5-1',
            title: LocalizedStrings({
              'en': ['Greetings'],
            }),
          ),
        ],
      );
      final plan = planReminders(
        hour: 20,
        minute: 0,
        now: DateTime(2026, 9, 4, 9),
        progress: const ProgressData(),
        path: path,
        l10n: l10n,
      );
      expect(plan.first.body, contains('Greetings'));
    });

    test('with no path and nothing due it still says something', () {
      final plan = planReminders(
        hour: 20,
        minute: 0,
        now: DateTime(2026, 9, 4, 9),
        progress: const ProgressData(),
        path: const LessonPath(level: 'N5', units: []),
        l10n: l10n,
      );
      expect(plan.first.body, isNotEmpty);
    });
  });

  group('when permission is asked for', () {
    test('init never asks', () async {
      final backend = _FakeBackend();
      await ReminderService(backend: backend).init();
      expect(backend.inits, 1);
      expect(
        backend.permissionRequests,
        0,
        reason: 'a device that never turned reminders on is never asked',
      );
    });

    test('rescheduling with the switch off cancels and asks nothing', () async {
      final backend = _FakeBackend();
      await ReminderService(backend: backend).reschedule(l10n);
      expect(backend.permissionRequests, 0);
      expect(backend.cancels, 1);
      expect(backend.scheduled, isEmpty);
    });

    test('rescheduling with the switch on schedules a week', () async {
      await NihongoStorage.setReminderEnabled(true);
      final backend = _FakeBackend();
      await ReminderService(backend: backend).reschedule(l10n);
      expect(backend.scheduled, hasLength(reminderDays));
      expect(
        backend.permissionRequests,
        0,
        reason: 'permission was granted when the switch was turned on',
      );
    });
  });

  group('the time preference', () {
    test('defaults to eight in the evening', () async {
      expect(await NihongoStorage.getReminderTime(), (20, 0));
    });

    test('another time round trips', () async {
      await NihongoStorage.setReminderTime(7, 5);
      expect(await NihongoStorage.getReminderTime(), (7, 5));
    });

    test('setting it back to the default removes the key', () async {
      await NihongoStorage.setReminderTime(7, 5);
      await NihongoStorage.setReminderTime(20, 0);
      final raw = File(p.join(temp.path, 'MyNihongo', 'storage_config.json'));
      expect(raw.readAsStringSync(), isNot(contains('reminderTime')));
    });

    test('a hand-edited nonsense time reads as the default', () async {
      final config = File(
        p.join(temp.path, 'MyNihongo', 'storage_config.json'),
      );
      await config.writeAsString('{"reminderTime": "25:99"}');
      expect(await NihongoStorage.getReminderTime(), (20, 0));
      await config.writeAsString('{"reminderTime": "nonsense"}');
      expect(await NihongoStorage.getReminderTime(), (20, 0));
    });
  });
}

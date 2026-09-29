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
  int schedules = 0;
  bool failInit = false;
  bool grant = true;
  List<ScheduledReminder> scheduled = const [];
  final shown = <String>[];

  @override
  Future<void> init() async {
    inits++;
    if (failInit) throw StateError('init failed');
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> schedule(List<ScheduledReminder> reminders) async {
    schedules++;
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

    test('every reminder keeps its wall-clock time across a clock change', () {
      // Daylight saving makes a day 23 or 25 hours long; adding 24 hours to
      // the first reminder would drift the rest by an hour. Only proves itself
      // in a time zone that changes its clocks.
      for (final start in [
        DateTime(2026, 3, 5, 9),
        DateTime(2026, 10, 28, 9),
        DateTime(2026, 11, 1, 22),
      ]) {
        final plan = planReminders(
          hour: 0,
          minute: 30,
          now: start,
          progress: const ProgressData(),
          path: const LessonPath(level: 'N5', units: []),
          l10n: l10n,
        );
        for (final reminder in plan) {
          expect(reminder.fireAt.hour, 0, reason: '${reminder.fireAt}');
          expect(reminder.fireAt.minute, 30, reason: '${reminder.fireAt}');
        }
        for (var i = 1; i < plan.length; i++) {
          final before = plan[i - 1].fireAt;
          expect(plan[i].fireAt.day, isNot(before.day));
        }
      }
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

  group('keeping the plan alive', () {
    test('init is shared, and a failed one is tried again', () async {
      final backend = _FakeBackend()..failInit = true;
      final service = ReminderService(backend: backend);
      await expectLater(service.init(), throwsA(isA<StateError>()));
      backend.failInit = false;
      await service.init();
      await service.init();
      expect(backend.inits, 2, reason: 'one failure, then one shared success');
    });

    test(
      'a reschedule at startup plans without asking for permission',
      () async {
        await NihongoStorage.setReminderEnabled(true);
        final backend = _FakeBackend();
        final service = ReminderService(backend: backend);
        await service.reschedule(l10n);
        expect(backend.inits, 1, reason: 'reschedule initialises the backend');
        expect(backend.scheduled, hasLength(reminderDays));
        expect(backend.permissionRequests, 0);
        service.dispose();
      },
    );

    test('a refresh before any reschedule does nothing', () async {
      await NihongoStorage.setReminderEnabled(true);
      final backend = _FakeBackend();
      await ReminderService(backend: backend).refresh();
      expect(backend.schedules, 0);
      expect(backend.inits, 0);
    });

    test(
      'a refresh re-plans with the wording of the last reschedule',
      () async {
        await NihongoStorage.setReminderEnabled(true);
        final backend = _FakeBackend();
        final service = ReminderService(backend: backend);
        await service.reschedule(l10n);
        await service.refresh();
        expect(backend.schedules, 2);
        service.dispose();
      },
    );

    test('five refreshes at once cost at most two plans', () async {
      await NihongoStorage.setReminderEnabled(true);
      final backend = _FakeBackend();
      final service = ReminderService(backend: backend);
      await service.reschedule(l10n);
      final before = backend.schedules;
      await Future.wait([for (var i = 0; i < 5; i++) service.refresh()]);
      // A run in progress may still be finishing its queued pass; let it.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(backend.schedules - before, lessThanOrEqualTo(2));
      expect(backend.schedules - before, greaterThanOrEqualTo(1));
      service.dispose();
    });

    test('once reminders are off a refresh does nothing', () async {
      final backend = _FakeBackend();
      final service = ReminderService(backend: backend);
      await service.reschedule(l10n);
      final cancels = backend.cancels;
      await service.refresh();
      expect(backend.schedules, 0);
      expect(backend.cancels, cancels);
    });

    test('a refresh that fails is swallowed', () async {
      await NihongoStorage.setReminderEnabled(true);
      final backend = _FakeBackend();
      final service = ReminderService(backend: backend);
      await service.reschedule(l10n);
      await File(
        p.join(temp.path, 'MyNihongo', 'nihongo_progress.json'),
      ).writeAsString('{ not json');
      await service.refresh();
      service.dispose();
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

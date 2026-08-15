import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tracker/data/tracker_database.dart';
import 'package:tracker/services/notification_service.dart';
import 'package:tracker/state/tracker_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('a complete day survives closing and reopening SQLite', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('tracker-test-');
    final path = '${directory.path}${Platform.pathSeparator}tracker.db';

    final firstDatabase = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: path,
    );
    await firstDatabase.open();
    final first = TrackerController(firstDatabase, NotificationService());
    await first.initialize();

    expect(first.profile, isNull);
    expect(
      await first.createProfile(
        'Aikansh',
        'aikansh@example.com',
        'strong-pass',
      ),
      isNull,
    );
    final passwordRecord = first.profile?['password_hash'] as String;
    expect(passwordRecord, startsWith('pbkdf2-sha256\$60000\$'));
    expect(passwordRecord, isNot(contains('strong-pass')));

    await first.createRoutine({
      'title': 'Read before scrolling',
      'description': 'Two focused pages before social media.',
      'type': 'QUANTITY',
      'target_quantity': 2,
      'unit': 'pages',
      'category': 'STUDY',
      'frequency': 'DAILY',
      'scheduled_days': '',
      'weekly_target': 7,
      'estimated_minutes': 10,
      'preferred_time': null,
      'minimum_target': 1,
      'stretch_target': 4,
      'paused_until': null,
      'start_date': first.todayKey,
      'end_date': null,
      'status': 'ACTIVE',
    });

    expect(first.todayRoutineRecords, hasLength(1));
    final routineRecordId = first.todayRoutineRecords.single['id'] as int;
    await first.skipRoutine(routineRecordId, 'Protect a low-energy day');
    expect(first.todayRoutineRecords.single['skipped'], 1);
    expect(
      first.todayRoutineRecords.single['skip_reason'],
      'Protect a low-energy day',
    );
    await first.progressRoutine(routineRecordId, 0);
    expect(first.todayRoutineRecords.single['skipped'], 0);
    await first.progressRoutine(routineRecordId, 1);
    expect(first.todayRoutineRecords.single['completed'], 0);
    await first.progressRoutine(routineRecordId, 1);
    expect(first.todayRoutineRecords.single['completed'], 1);

    await first.createTask(
      {
        'title': 'Submit the placement report',
        'description': 'Proofread before sending.',
        'item_type': 'TASK',
        'scheduled_date': first.todayKey,
        'all_day': 0,
        'start_time': null,
        'priority': 'HIGH',
        'deadline': '18:00',
        'estimated_minutes': 30,
        'reminder_minutes': null,
        'recurrence_frequency': 'NONE',
        'recurrence_interval': 1,
        'recurrence_weekdays': '',
        'recurrence_end_date': null,
      },
      ['Draft', 'Review'],
    );

    final task = first.todayTasks.single;
    expect(first.subtasksFor(task['id'] as int), hasLength(2));
    await first.toggleSubtask(
      first.subtasksFor(task['id'] as int).first['id'] as int,
    );
    expect(first.subtasksFor(task['id'] as int).first['done'], 1);
    await first.completeTask(task['id'] as int);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await first.createTask({
      'title': 'University holiday',
      'description': 'A real all-day calendar item.',
      'item_type': 'EVENT',
      'scheduled_date': first.key(tomorrow),
      'all_day': 1,
      'start_time': null,
      'priority': 'MEDIUM',
      'deadline': null,
      'estimated_minutes': 30,
      'reminder_minutes': null,
      'recurrence_frequency': 'NONE',
      'recurrence_interval': 1,
      'recurrence_weekdays': '',
      'recurrence_end_date': null,
    }, const []);

    await first.saveMood({
      'date': first.todayKey,
      'mood': 4,
      'energy': 3,
      'stress': 2,
      'focus': 4,
      'sleep_hours': 7.5,
      'emotions': 'hopeful,calm',
      'factors': 'study,sleep',
      'note': 'The plan felt realistic.',
    });
    await first.savePlan({
      'date': first.todayKey,
      'intention': 'Finish one important thing well.',
      'implementation_intention': 'If distracted, take one slow breath.',
      'capacity': 'NORMAL',
      'priority_ids': '${task['id']}',
      'shutdown_note': 'Tomorrow begins with revision.',
    });
    expect(
      await first.startFocus(title: 'Report deep work', minutes: 25),
      isNull,
    );
    await first.updateFocus(
      first.focusSessions.single['id'] as int,
      distractions: 1,
      note: 'Phone stayed face down.',
      finishStatus: 'COMPLETED',
    );
    await first.createGoal(
      {
        'title': 'Placement ready',
        'description': 'Prepare with evidence, not panic.',
        'life_area': 'CAREER',
        'target_date': first.key(DateTime.now().add(const Duration(days: 90))),
        'status': 'ACTIVE',
      },
      ['Revise core CS', 'Complete mock interview'],
    );
    await first.toggleMilestone(first.milestones.first['id'] as int);
    final monday = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    await first.saveWeeklyReview({
      'week_start': first.key(monday),
      'wins': 'Finished the report',
      'lessons': 'Smaller plans survive busy days',
      'next_week_focus': 'Mock interviews',
      'rating': 4,
      'snapshot': '{}',
    });

    expect(first.dailyScore, 100);
    await firstDatabase.db.close();

    final reopenedDatabase = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: path,
    );
    await reopenedDatabase.open();
    final reopened = TrackerController(reopenedDatabase, NotificationService());
    await reopened.initialize();

    expect(reopened.profile?['name'], 'Aikansh');
    expect(reopened.unlocked, isTrue);
    expect(reopened.todayTasks.single['status'], 'COMPLETED');
    expect(
      reopened.tasks.singleWhere(
        (entry) => entry['title'] == 'University holiday',
      )['all_day'],
      1,
    );
    expect(reopened.todayRoutineRecords.single['completed'], 1);
    expect(reopened.subtasksFor(task['id'] as int).first['done'], 1);
    expect(reopened.moodFor(reopened.todayKey)?['sleep_hours'], 7.5);
    expect(reopened.plans.single['capacity'], 'NORMAL');
    expect(reopened.focusSessions.single['status'], 'COMPLETED');
    expect(reopened.goals.single['title'], 'Placement ready');
    expect(
      reopened.milestones.where((item) => item['done'] == 1),
      hasLength(1),
    );
    expect(reopened.weeklyReviews.single['rating'], 4);
    expect(reopened.dailyScore, 100);
    await reopened.lock();
    expect(reopened.unlocked, isFalse);
    expect(
      await reopened.login('aikansh@example.com', 'wrong-pass'),
      'Incorrect email or password.',
    );
    expect(await reopened.login('aikansh@example.com', 'strong-pass'), isNull);
    expect(reopened.unlocked, isTrue);

    await reopenedDatabase.db.close();
    await directory.delete(recursive: true);
  });

  test('task reminders ask permission and use the real scheduled time', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('tracker-test-');
    final path = '${directory.path}${Platform.pathSeparator}tracker.db';
    final database = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: path,
    );
    await database.open();
    final notifications = _RecordingNotifications();
    final controller = TrackerController(database, notifications);
    await controller.initialize();
    await controller.createProfile(
      'Aikansh',
      'aikansh@example.com',
      'strong-pass',
    );

    final eventTime = DateTime.now().add(const Duration(hours: 3));
    final clock =
        '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';
    final reminderScheduled = await controller.createTask({
      'title': 'Placement briefing',
      'description': '',
      'item_type': 'EVENT',
      'scheduled_date': controller.key(eventTime),
      'all_day': 0,
      'start_time': clock,
      'priority': 'HIGH',
      'deadline': null,
      'estimated_minutes': 45,
      'reminder_minutes': 30,
      'recurrence_frequency': 'NONE',
      'recurrence_interval': 1,
      'recurrence_weekdays': '',
      'recurrence_end_date': null,
    }, const []);

    expect(reminderScheduled, isTrue);
    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduled, hasLength(1));
    expect(notifications.scheduled.single.title, 'Placement briefing');
    expect(
      notifications.scheduled.single.at,
      DateTime(
        eventTime.year,
        eventTime.month,
        eventTime.day,
        eventTime.hour,
        eventTime.minute,
      ).subtract(const Duration(minutes: 30)),
    );

    notifications.permissionGranted = false;
    final denied = await controller.scheduleTaskReminders();
    expect(denied, isFalse);
    expect(notifications.scheduled, hasLength(1));

    await database.db.close();
    await directory.delete(recursive: true);
  });

  test(
    'recurring tasks create dated occurrences only through their horizon',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp('tracker-test-');
      final database = TrackerDatabase(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}${Platform.pathSeparator}tracker.db',
      );
      await database.open();
      final controller = TrackerController(database, NotificationService());
      await controller.initialize();
      final start = DateTime.now();
      final end = start.add(const Duration(days: 2));

      await controller.createTask({
        'title': 'Three-day revision block',
        'description': '',
        'item_type': 'TASK',
        'scheduled_date': controller.key(start),
        'all_day': 1,
        'start_time': null,
        'priority': 'MEDIUM',
        'deadline': null,
        'estimated_minutes': 20,
        'reminder_minutes': null,
        'recurrence_frequency': 'DAILY',
        'recurrence_interval': 1,
        'recurrence_weekdays': '',
        'recurrence_end_date': controller.key(end),
      }, const []);

      expect(controller.tasks, hasLength(3));
      expect(controller.tasks.map((item) => item['scheduled_date']).toSet(), {
        controller.key(start),
        controller.key(start.add(const Duration(days: 1))),
        controller.key(end),
      });
      expect(
        controller.tasks.map((item) => item['series_id']).toSet(),
        hasLength(1),
      );

      await database.db.close();
      await directory.delete(recursive: true);
    },
  );

  test('smart reminders resync only when planned work changes', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('tracker-test-');
    final database = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}${Platform.pathSeparator}tracker.db',
    );
    await database.open();
    final notifications = _RecordingNotifications();
    final controller = TrackerController(database, notifications);
    await controller.initialize();

    expect(await controller.setSmartReminders(true), isTrue);
    expect(notifications.daySummaries, 15);
    await controller.refresh();
    expect(notifications.daySummaries, 15);

    await controller.saveMood({
      'date': controller.todayKey,
      'mood': 4,
      'energy': 3,
      'stress': 2,
      'focus': 4,
      'sleep_hours': 7.5,
      'emotions': '',
      'factors': '',
      'note': '',
    });
    expect(notifications.daySummaries, 15);

    await controller.createTask({
      'title': 'Prepare interview notes',
      'description': '',
      'item_type': 'TASK',
      'scheduled_date': controller.todayKey,
      'all_day': 1,
      'start_time': null,
      'priority': 'HIGH',
      'deadline': null,
      'estimated_minutes': 30,
      'reminder_minutes': null,
      'recurrence_frequency': 'NONE',
      'recurrence_interval': 1,
      'recurrence_weekdays': '',
      'recurrence_end_date': null,
    }, const []);
    expect(notifications.daySummaries, 30);

    await database.db.close();
    await directory.delete(recursive: true);
  });

  test('offline workspace opens when notifications are unavailable', () async {
    SharedPreferences.setMockInitialValues({'tracker-smart-reminders': true});
    final directory = await Directory.systemTemp.createTemp('tracker-test-');
    final database = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}${Platform.pathSeparator}tracker.db',
    );
    await database.open();
    final controller = TrackerController(database, NotificationService());

    await controller.initialize();

    expect(controller.ready, isTrue);
    expect(controller.smartRemindersEnabled, isFalse);
    expect(controller.initializationFailed, isFalse);

    await database.db.close();
    await directory.delete(recursive: true);
  });

  test('legacy password digests migrate after a successful login', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('tracker-test-');
    final database = TrackerDatabase(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}${Platform.pathSeparator}tracker.db',
    );
    await database.open();
    final legacy = sha256.convert(utf8.encode('legacy-pass')).toString();
    await database.insert('profile', {
      'id': 1,
      'name': 'Legacy user',
      'email': 'legacy@example.com',
      'password_hash': legacy,
      'timezone': 'Asia/Kolkata',
      'created_at': DateTime.now().toIso8601String(),
    });
    final controller = TrackerController(database, NotificationService());
    await controller.initialize();

    expect(
      await controller.login('legacy@example.com', 'wrong-pass'),
      isNotNull,
    );
    expect(await controller.login('legacy@example.com', 'legacy-pass'), isNull);
    final migrated = (await database.rows('profile', limit: 1)).single;
    expect(migrated['password_hash'], startsWith('pbkdf2-sha256\$60000\$'));
    expect(migrated['password_hash'], isNot(legacy));

    await database.db.close();
    await directory.delete(recursive: true);
  });
}

class _RecordingNotifications extends NotificationService {
  bool permissionGranted = true;
  int permissionRequests = 0;
  int daySummaries = 0;
  final scheduled = <({int id, String title, String body, DateTime at})>[];

  @override
  bool get available => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    scheduled.add((id: id, title: title, body: body, at: at));
  }

  @override
  Future<void> scheduleDaySummary({
    required DateTime date,
    required List<String> unfinishedTitles,
  }) async {
    daySummaries++;
  }
}

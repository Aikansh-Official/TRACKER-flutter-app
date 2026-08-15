import 'dart:io';

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
    expect(reopened.todayRoutineRecords.single['completed'], 1);
    expect(reopened.subtasksFor(task['id'] as int).first['done'], 1);
    expect(reopened.moodFor(reopened.todayKey)?['sleep_hours'], 7.5);
    expect(reopened.plans.single['capacity'], 'NORMAL');
    expect(reopened.dailyScore, 100);

    await reopenedDatabase.db.close();
    await directory.delete(recursive: true);
  });
}

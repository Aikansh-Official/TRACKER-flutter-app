import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../data/tracker_database.dart';
import '../services/notification_service.dart';

class TrackerController extends ChangeNotifier {
  TrackerController(this.database, this.notifications);
  final TrackerDatabase database;
  final NotificationService notifications;
  late SharedPreferences preferences;
  bool ready = false;
  bool initializationFailed = false;
  bool darkMode = false;
  bool smartRemindersEnabled = false;
  bool unlocked = false;
  int page = 0;
  Map<String, Object?>? profile;
  List<Map<String, Object?>> routines = [];
  List<Map<String, Object?>> routineRecords = [];
  List<Map<String, Object?>> tasks = [];
  List<Map<String, Object?>> subtasks = [];
  List<Map<String, Object?>> moods = [];
  List<Map<String, Object?>> plans = [];
  List<Map<String, Object?>> focusSessions = [];
  List<Map<String, Object?>> goals = [];
  List<Map<String, Object?>> milestones = [];
  List<Map<String, Object?>> weeklyReviews = [];
  DateTime selectedDate = DateTime.now();

  String key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String get todayKey => key(DateTime.now());
  String _now() => DateTime.now().toIso8601String();
  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  Future<void> initialize() async {
    preferences = await SharedPreferences.getInstance();
    darkMode = preferences.getBool('tracker-theme-dark') ?? false;
    smartRemindersEnabled =
        preferences.getBool('tracker-smart-reminders') ?? false;
    final rows = await database.rows('profile', limit: 1);
    profile = rows.isEmpty ? null : rows.first;
    unlocked =
        profile != null && (preferences.getBool('tracker-unlocked') ?? false);
    if (profile != null) await refresh();
    ready = true;
    notifyListeners();
  }

  void markInitializationFailed() {
    initializationFailed = true;
    ready = true;
    notifyListeners();
  }

  Future<String?> createProfile(
    String name,
    String email,
    String password,
  ) async {
    if (name.trim().isEmpty) return 'Tell TRACKER what to call you.';
    if (!email.contains('@')) return 'Enter a valid email address.';
    if (password.length < 8) return 'Use at least 8 characters.';
    await database.insert('profile', {
      'id': 1,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': _hash(password),
      'timezone': 'Asia/Kolkata',
      'created_at': _now(),
    });
    profile = (await database.rows('profile', limit: 1)).first;
    unlocked = true;
    await preferences.setBool('tracker-unlocked', true);
    await refresh();
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final rows = await database.rows(
      'profile',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), _hash(password)],
      limit: 1,
    );
    if (rows.isEmpty) return 'Incorrect email or password.';
    profile = rows.first;
    unlocked = true;
    await preferences.setBool('tracker-unlocked', true);
    await refresh();
    notifyListeners();
    return null;
  }

  Future<void> lock() async {
    unlocked = false;
    await preferences.setBool('tracker-unlocked', false);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    darkMode = !darkMode;
    await preferences.setBool('tracker-theme-dark', darkMode);
    notifyListeners();
  }

  void navigate(int value) {
    page = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _prepareToday();
    final rows = await Future.wait([
      database.rows('routines', orderBy: 'created_at DESC'),
      database.rows('routine_records', orderBy: 'date DESC'),
      database.rows(
        'tasks',
        orderBy:
            "scheduled_date ASC, COALESCE(start_time, deadline, '23:59') ASC",
      ),
      database.rows('subtasks', orderBy: 'id ASC'),
      database.rows('moods', orderBy: 'date ASC'),
      database.rows('daily_plans', orderBy: 'date DESC'),
      database.rows('focus_sessions', orderBy: 'started_at DESC'),
      database.rows('goals', orderBy: 'created_at DESC'),
      database.rows('milestones', orderBy: 'id ASC'),
      database.rows('weekly_reviews', orderBy: 'week_start DESC'),
    ]);
    routines = rows[0];
    routineRecords = rows[1];
    tasks = rows[2];
    subtasks = rows[3];
    moods = rows[4];
    plans = rows[5];
    focusSessions = rows[6];
    goals = rows[7];
    milestones = rows[8];
    weeklyReviews = rows[9];
    if (smartRemindersEnabled) await syncSmartDayReminders();
    notifyListeners();
  }

  Future<void> _prepareToday() async {
    await database.db.update(
      'tasks',
      {'status': 'PENDING'},
      where: "scheduled_date < ? AND status IN ('TODAY','SCHEDULED')",
      whereArgs: [todayKey],
    );
    await database.db.update(
      'tasks',
      {'status': 'TODAY'},
      where: "scheduled_date = ? AND status = 'SCHEDULED'",
      whereArgs: [todayKey],
    );
    await database.db.update(
      'routines',
      {'status': 'EXPIRED'},
      where: "end_date IS NOT NULL AND end_date < ? AND status = 'ACTIVE'",
      whereArgs: [todayKey],
    );
    final active = await database.rows(
      'routines',
      where:
          "status = 'ACTIVE' AND start_date <= ? AND (end_date IS NULL OR end_date >= ?) AND (paused_until IS NULL OR paused_until < ?)",
      whereArgs: [todayKey, todayKey, todayKey],
    );
    for (final routine in active) {
      if (await _isRoutineDue(routine, DateTime.now())) {
        await database.db.insert('routine_records', {
          'routine_id': routine['id'],
          'date': todayKey,
          'target_snapshot': routine['target_quantity'],
          'completed_quantity': 0,
          'completed': 0,
          'skipped': 0,
          'skip_reason': '',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<bool> _isRoutineDue(
    Map<String, Object?> routine,
    DateTime date,
  ) async {
    final frequency = routine['frequency'] as String;
    final weekday = date.weekday % 7;
    if (frequency == 'DAILY') return true;
    if (frequency == 'WEEKDAYS') return date.weekday <= 5;
    if (frequency == 'WEEKENDS') return date.weekday >= 6;
    if (frequency == 'CUSTOM') {
      return (routine['scheduled_days'] as String)
          .split(',')
          .contains('$weekday');
    }
    if (frequency == 'WEEKLY_TARGET') {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final done =
          Sqflite.firstIntValue(
            await database.db.rawQuery(
              'SELECT COUNT(*) FROM routine_records WHERE routine_id = ? AND date >= ? AND completed = 1',
              [routine['id'], key(monday)],
            ),
          ) ??
          0;
      return done < (routine['weekly_target'] as int);
    }
    return false;
  }

  List<Map<String, Object?>> get todayTasks => tasks
      .where(
        (e) =>
            e['scheduled_date'] == todayKey &&
            ['TODAY', 'COMPLETED'].contains(e['status']),
      )
      .toList();
  List<Map<String, Object?>> get todayRoutineRecords => routineRecords
      .where(
        (e) =>
            e['date'] == todayKey &&
            routineById(e['routine_id'] as int) != null,
      )
      .toList();
  List<Map<String, Object?>> get pendingTasks =>
      tasks.where((e) => e['status'] == 'PENDING').toList();
  List<Map<String, Object?>> get archivedItems =>
      tasks.where((e) => e['status'] == 'ARCHIVED').toList();
  Map<String, Object?>? routineById(int id) => routines
      .cast<Map<String, Object?>?>()
      .firstWhere((e) => e?['id'] == id, orElse: () => null);
  List<Map<String, Object?>> subtasksFor(int taskId) =>
      subtasks.where((e) => e['task_id'] == taskId).toList();
  Map<String, Object?>? moodFor(String date) => moods
      .cast<Map<String, Object?>?>()
      .firstWhere((e) => e?['date'] == date, orElse: () => null);

  int get activePlannedCount =>
      todayTasks
          .where(
            (e) => !['SKIPPED', 'DROPPED', 'DELEGATED'].contains(e['status']),
          )
          .length +
      todayRoutineRecords.where((e) => e['skipped'] == 0).length;
  int get completedCount =>
      todayTasks.where((e) => e['status'] == 'COMPLETED').length +
      todayRoutineRecords
          .where((e) => e['completed'] == 1 && e['skipped'] == 0)
          .length;
  int get dailyScore => activePlannedCount == 0
      ? 0
      : ((completedCount / activePlannedCount) * 100).round();

  Future<void> createRoutine(Map<String, Object?> values) async {
    await database.insert('routines', {...values, 'created_at': _now()});
    await refresh();
  }

  Future<void> progressRoutine(int recordId, int delta) async {
    final record = routineRecords.firstWhere((e) => e['id'] == recordId);
    final target = record['target_snapshot'] as int;
    final next = ((record['completed_quantity'] as int) + delta).clamp(
      0,
      target,
    );
    await database.update(
      'routine_records',
      {
        'completed_quantity': next,
        'completed': next >= target ? 1 : 0,
        'skipped': 0,
        'skip_reason': '',
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
    await refresh();
  }

  Future<void> skipRoutine(int recordId, String reason) async {
    await database.update(
      'routine_records',
      {
        'completed_quantity': 0,
        'completed': 0,
        'skipped': 1,
        'skip_reason': reason.trim(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
    await refresh();
  }

  Future<void> archiveRoutine(int id, {bool restore = false}) async {
    await database.update(
      'routines',
      {'status': restore ? 'ACTIVE' : 'ARCHIVED'},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> createTask(
    Map<String, Object?> values,
    List<String> checklist,
  ) async {
    final start = DateTime.parse(values['scheduled_date'] as String);
    final frequency = values['recurrence_frequency'] as String? ?? 'NONE';
    final interval = values['recurrence_interval'] as int? ?? 1;
    final weekdays = ((values['recurrence_weekdays'] as String?) ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toSet();
    final explicitEnd = values['recurrence_end_date'] as String?;
    final limitDate = explicitEnd == null || explicitEnd.isEmpty
        ? start.add(const Duration(days: 365))
        : DateTime.parse(explicitEnd);
    final dates = <DateTime>[start];
    if (frequency != 'NONE') {
      var cursor = start.add(const Duration(days: 1));
      while (!cursor.isAfter(limitDate) && dates.length < 120) {
        final days = cursor.difference(start).inDays;
        var include = false;
        if (frequency == 'DAILY') include = days % interval == 0;
        if (frequency == 'WEEKLY') {
          include =
              (days ~/ 7) % interval == 0 &&
              (weekdays.isEmpty
                  ? cursor.weekday == start.weekday
                  : weekdays.contains(cursor.weekday % 7));
        }
        if (frequency == 'MONTHLY') {
          include =
              cursor.day == start.day &&
              ((cursor.year - start.year) * 12 + cursor.month - start.month) %
                      interval ==
                  0;
        }
        if (include) dates.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    final series = frequency == 'NONE'
        ? null
        : DateTime.now().microsecondsSinceEpoch.toString();
    await database.db.transaction((txn) async {
      for (final date in dates) {
        final dateKey = key(date);
        final id = await txn.insert('tasks', {
          ...values,
          'original_date': key(start),
          'scheduled_date': dateKey,
          'series_id': series,
          'occurrence_date': dateKey,
          'status': dateKey == todayKey ? 'TODAY' : 'SCHEDULED',
          'created_at': _now(),
        });
        for (final item
            in checklist.where((e) => e.trim().isNotEmpty).take(30)) {
          await txn.insert('subtasks', {
            'task_id': id,
            'title': item.trim(),
            'done': 0,
          });
        }
      }
    });
    await refresh();
    if (values['reminder_minutes'] != null) {
      await scheduleTaskReminders(seriesId: series);
    }
  }

  Future<void> updateTask(int id, Map<String, Object?> values) async {
    await database.update('tasks', values, where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> completeTask(int id) async {
    final task = tasks.firstWhere((e) => e['id'] == id);
    final complete = task['status'] != 'COMPLETED';
    await database.update(
      'tasks',
      {
        'status': complete
            ? 'COMPLETED'
            : (task['scheduled_date'] == todayKey ? 'TODAY' : 'SCHEDULED'),
        'outcome': complete ? 'COMPLETED' : null,
        'completed_at': complete ? _now() : null,
        'resolved_at': complete ? _now() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> toggleSubtask(int id) async {
    final item = subtasks.firstWhere((e) => e['id'] == id);
    final done = item['done'] == 0;
    await database.update(
      'subtasks',
      {'done': done ? 1 : 0, 'completed_at': done ? _now() : null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> resolveTask(
    int id,
    String outcome, {
    String note = '',
    String? delegatedTo,
    String? newDate,
  }) async {
    final status = switch (outcome) {
      'RESCHEDULED' => newDate == todayKey ? 'TODAY' : 'SCHEDULED',
      'SKIPPED' => 'SKIPPED',
      'DROPPED' => 'DROPPED',
      'DELEGATED' => 'DELEGATED',
      _ => outcome,
    };
    await database.update(
      'tasks',
      {
        'status': status,
        'outcome': outcome,
        'outcome_note': note,
        'delegated_to': delegatedTo ?? '',
        'scheduled_date': ?newDate,
        'resolved_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> archiveTask(int id, {bool restore = false}) async {
    final task = tasks.firstWhere((e) => e['id'] == id);
    await database.update(
      'tasks',
      {
        'status': restore
            ? ((task['scheduled_date'] as String).compareTo(todayKey) < 0
                  ? 'PENDING'
                  : task['scheduled_date'] == todayKey
                  ? 'TODAY'
                  : 'SCHEDULED')
            : 'ARCHIVED',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> saveMood(Map<String, Object?> entry) async {
    final existing = await database.rows(
      'moods',
      where: 'date = ?',
      whereArgs: [entry['date']],
    );
    final values = {...entry, 'updated_at': _now()};
    if (existing.isEmpty) {
      await database.insert('moods', {...values, 'created_at': _now()});
    } else {
      await database.update(
        'moods',
        values,
        where: 'date = ?',
        whereArgs: [entry['date']],
      );
    }
    await refresh();
  }

  Future<void> savePlan(Map<String, Object?> plan) async {
    final date = plan['date'];
    final existing = await database.rows(
      'daily_plans',
      where: 'date = ?',
      whereArgs: [date],
    );
    final values = {...plan, 'updated_at': _now()};
    if (existing.isEmpty) {
      await database.insert('daily_plans', values);
    } else {
      await database.update(
        'daily_plans',
        values,
        where: 'date = ?',
        whereArgs: [date],
      );
    }
    await refresh();
  }

  Future<String?> startFocus({
    required String title,
    required int minutes,
    int? taskId,
  }) async {
    if (focusSessions.any((e) => e['status'] == 'ACTIVE')) {
      return 'Finish or abandon the active focus session first.';
    }
    await database.insert('focus_sessions', {
      'task_type': taskId == null ? 'GENERAL' : 'TASK',
      'task_id': taskId,
      'title': title,
      'planned_minutes': minutes,
      'started_at': _now(),
      'distractions': 0,
      'status': 'ACTIVE',
      'note': '',
    });
    await refresh();
    return null;
  }

  Future<void> updateFocus(
    int id, {
    int? distractions,
    String? note,
    String? finishStatus,
  }) async {
    final values = <String, Object?>{};
    if (distractions != null) values['distractions'] = distractions;
    if (note != null) values['note'] = note;
    if (finishStatus != null) {
      final session = focusSessions.firstWhere((e) => e['id'] == id);
      final started = DateTime.parse(session['started_at'] as String);
      values.addAll({
        'status': finishStatus,
        'ended_at': _now(),
        'duration_minutes': DateTime.now()
            .difference(started)
            .inMinutes
            .clamp(0, 1440),
      });
    }
    await database.update(
      'focus_sessions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> createGoal(Map<String, Object?> goal, List<String> items) async {
    await database.db.transaction((txn) async {
      final id = await txn.insert('goals', {...goal, 'created_at': _now()});
      for (final item in items.where((e) => e.trim().isNotEmpty)) {
        await txn.insert('milestones', {
          'goal_id': id,
          'title': item.trim(),
          'done': 0,
        });
      }
    });
    await refresh();
  }

  Future<void> toggleMilestone(int id) async {
    final item = milestones.firstWhere((e) => e['id'] == id);
    final done = item['done'] == 0;
    await database.update(
      'milestones',
      {'done': done ? 1 : 0, 'completed_at': done ? _now() : null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<void> saveWeeklyReview(Map<String, Object?> review) async {
    final week = review['week_start'];
    final existing = await database.rows(
      'weekly_reviews',
      where: 'week_start = ?',
      whereArgs: [week],
    );
    final values = {...review, 'updated_at': _now()};
    if (existing.isEmpty) {
      await database.insert('weekly_reviews', values);
    } else {
      await database.update(
        'weekly_reviews',
        values,
        where: 'week_start = ?',
        whereArgs: [week],
      );
    }
    await refresh();
  }

  Future<void> scheduleTaskReminders({String? seriesId}) async {
    final items = tasks.where(
      (e) =>
          e['reminder_minutes'] != null &&
          (seriesId == null || e['series_id'] == seriesId),
    );
    for (final item in items) {
      final time =
          (item['start_time'] ?? item['deadline'] ?? '09:00') as String;
      final pieces = time.split(':');
      final date = DateTime.parse(item['scheduled_date'] as String);
      final at = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(pieces[0]),
        int.parse(pieces[1]),
      ).subtract(Duration(minutes: item['reminder_minutes'] as int));
      await notifications.schedule(
        id: item['id'] as int,
        title: item['title'] as String,
        body: '${item['item_type'] == 'EVENT' ? 'Event' : 'Task'} at $time',
        at: at,
      );
    }
  }

  Future<bool> setSmartReminders(bool enabled) async {
    if (enabled) {
      final allowed = await notifications.requestPermission();
      if (!allowed) return false;
      smartRemindersEnabled = true;
      await preferences.setBool('tracker-smart-reminders', true);
      await syncSmartDayReminders();
    } else {
      smartRemindersEnabled = false;
      await preferences.setBool('tracker-smart-reminders', false);
      final today = DateTime.now();
      for (var offset = 0; offset < 15; offset++) {
        await notifications.cancelDaySummary(today.add(Duration(days: offset)));
      }
    }
    notifyListeners();
    return true;
  }

  Future<void> syncSmartDayReminders() async {
    final now = DateTime.now();
    for (var offset = 0; offset < 15; offset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      final titles = await _unfinishedTitlesFor(date);
      await notifications.scheduleDaySummary(
        date: date,
        unfinishedTitles: titles,
      );
    }
  }

  Future<List<String>> _unfinishedTitlesFor(DateTime date) async {
    final dateKey = key(date);
    final titles = <String>{};
    for (final task in tasks.where(
      (entry) =>
          entry['scheduled_date'] == dateKey &&
          ![
            'COMPLETED',
            'SKIPPED',
            'DROPPED',
            'DELEGATED',
            'ARCHIVED',
          ].contains(entry['status']),
    )) {
      titles.add(task['title'] as String);
    }

    if (dateKey == todayKey) {
      for (final record in todayRoutineRecords.where(
        (entry) => entry['completed'] == 0 && entry['skipped'] == 0,
      )) {
        final routine = routineById(record['routine_id'] as int);
        if (routine != null) titles.add(routine['title'] as String);
      }
    } else {
      for (final routine in routines.where(
        (entry) =>
            entry['status'] == 'ACTIVE' &&
            (entry['start_date'] as String).compareTo(dateKey) <= 0 &&
            (entry['end_date'] == null ||
                (entry['end_date'] as String).compareTo(dateKey) >= 0) &&
            (entry['paused_until'] == null ||
                (entry['paused_until'] as String).compareTo(dateKey) < 0),
      )) {
        if (await _isRoutineDue(routine, date)) {
          titles.add(routine['title'] as String);
        }
      }
    }
    return titles.toList();
  }

  Future<void> exportJson() async {
    final data = {
      'app': 'TRACKER',
      'version': 1,
      'exportedAt': _now(),
      'profile': {
        'name': profile?['name'],
        'email': profile?['email'],
        'timezone': profile?['timezone'],
      },
      'routines': routines,
      'routineRecords': routineRecords,
      'tasks': tasks,
      'subtasks': subtasks,
      'moods': moods,
      'plans': plans,
      'focusSessions': focusSessions,
      'goals': goals,
      'milestones': milestones,
      'weeklyReviews': weeklyReviews,
    };
    await _shareFile(
      'tracker-export-$todayKey.json',
      const JsonEncoder.withIndent('  ').convert(data),
      'application/json',
    );
  }

  Future<void> exportIcs() async {
    final b = StringBuffer(
      'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//TRACKER//Offline Android//EN\r\n',
    );
    for (final task in tasks.where(
      (e) => ![
        'ARCHIVED',
        'SKIPPED',
        'DROPPED',
        'DELEGATED',
      ].contains(e['status']),
    )) {
      final date = (task['scheduled_date'] as String).replaceAll('-', '');
      final title = (task['title'] as String)
          .replaceAll(',', '\\,')
          .replaceAll(';', '\\;');
      b.writeln('BEGIN:VEVENT\r');
      b.writeln('UID:${task['id']}@tracker.local\r');
      b.writeln(
        'DTSTAMP:${DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc())}\r',
      );
      if (task['all_day'] == 1) {
        final end = DateTime.parse(
          task['scheduled_date'] as String,
        ).add(const Duration(days: 1));
        b.writeln('DTSTART;VALUE=DATE:$date\r');
        b.writeln('DTEND;VALUE=DATE:${DateFormat('yyyyMMdd').format(end)}\r');
      } else {
        final time =
            ((task['start_time'] ?? task['deadline'] ?? '09:00') as String)
                .replaceAll(':', '');
        b.writeln('DTSTART:${date}T${time}00\r');
      }
      b.writeln('SUMMARY:$title\r');
      b.writeln('END:VEVENT\r');
    }
    b.write('END:VCALENDAR\r\n');
    await _shareFile(
      'tracker-calendar-$todayKey.ics',
      b.toString(),
      'text/calendar',
    );
  }

  Future<void> _shareFile(String name, String content, String mime) async {
    final file = File(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}$name',
    );
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        text: 'TRACKER offline export',
      ),
    );
  }
}

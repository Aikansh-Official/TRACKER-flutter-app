import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TrackerDatabase {
  late final Database db;

  Future<void> open() async {
    db = await openDatabase(
      join(await getDatabasesPath(), 'tracker_offline.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE profile(id INTEGER PRIMARY KEY CHECK(id=1), name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata', created_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE routines(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', type TEXT NOT NULL, target_quantity INTEGER NOT NULL DEFAULT 1, unit TEXT NOT NULL DEFAULT 'times', category TEXT NOT NULL, frequency TEXT NOT NULL, scheduled_days TEXT NOT NULL DEFAULT '', weekly_target INTEGER NOT NULL DEFAULT 3, estimated_minutes INTEGER NOT NULL DEFAULT 25, preferred_time TEXT, minimum_target INTEGER NOT NULL DEFAULT 1, stretch_target INTEGER NOT NULL DEFAULT 1, paused_until TEXT, start_date TEXT NOT NULL, end_date TEXT, status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE routine_records(id INTEGER PRIMARY KEY AUTOINCREMENT, routine_id INTEGER NOT NULL, date TEXT NOT NULL, target_snapshot INTEGER NOT NULL, completed_quantity INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0, skipped INTEGER NOT NULL DEFAULT 0, skip_reason TEXT NOT NULL DEFAULT '', UNIQUE(routine_id,date), FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE)''',
    );
    await db.execute(
      '''CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', item_type TEXT NOT NULL DEFAULT 'TASK', original_date TEXT NOT NULL, scheduled_date TEXT NOT NULL, all_day INTEGER NOT NULL DEFAULT 1, start_time TEXT, priority TEXT NOT NULL DEFAULT 'MEDIUM', deadline TEXT, estimated_minutes INTEGER NOT NULL DEFAULT 30, reminder_minutes INTEGER, recurrence_frequency TEXT NOT NULL DEFAULT 'NONE', recurrence_interval INTEGER NOT NULL DEFAULT 1, recurrence_weekdays TEXT NOT NULL DEFAULT '', recurrence_end_date TEXT, series_id TEXT, occurrence_date TEXT, status TEXT NOT NULL DEFAULT 'SCHEDULED', outcome TEXT, outcome_note TEXT NOT NULL DEFAULT '', delegated_to TEXT NOT NULL DEFAULT '', completed_at TEXT, resolved_at TEXT, created_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE subtasks(id INTEGER PRIMARY KEY AUTOINCREMENT, task_id INTEGER NOT NULL, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0, completed_at TEXT, FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''',
    );
    await db.execute(
      '''CREATE TABLE moods(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE, mood INTEGER NOT NULL, energy INTEGER NOT NULL, stress INTEGER NOT NULL, focus INTEGER NOT NULL, sleep_hours REAL NOT NULL DEFAULT 0, emotions TEXT NOT NULL DEFAULT '', factors TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE daily_plans(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE, intention TEXT NOT NULL DEFAULT '', implementation_intention TEXT NOT NULL DEFAULT '', capacity TEXT NOT NULL DEFAULT 'NORMAL', priority_ids TEXT NOT NULL DEFAULT '', shutdown_note TEXT NOT NULL DEFAULT '', updated_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE focus_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, task_type TEXT NOT NULL, task_id INTEGER, title TEXT NOT NULL, planned_minutes INTEGER NOT NULL, started_at TEXT NOT NULL, ended_at TEXT, duration_minutes INTEGER, distractions INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'ACTIVE', note TEXT NOT NULL DEFAULT '')''',
    );
    await db.execute(
      '''CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', life_area TEXT NOT NULL, target_date TEXT, status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL)''',
    );
    await db.execute(
      '''CREATE TABLE milestones(id INTEGER PRIMARY KEY AUTOINCREMENT, goal_id INTEGER NOT NULL, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0, completed_at TEXT, FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE)''',
    );
    await db.execute(
      '''CREATE TABLE weekly_reviews(id INTEGER PRIMARY KEY AUTOINCREMENT, week_start TEXT NOT NULL UNIQUE, wins TEXT NOT NULL DEFAULT '', lessons TEXT NOT NULL DEFAULT '', next_week_focus TEXT NOT NULL DEFAULT '', rating INTEGER NOT NULL DEFAULT 3, snapshot TEXT NOT NULL DEFAULT '{}', updated_at TEXT NOT NULL)''',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_date ON tasks(scheduled_date,status)',
    );
    await db.execute(
      'CREATE INDEX idx_routine_records_date ON routine_records(date)',
    );
    await db.execute('CREATE INDEX idx_moods_date ON moods(date)');
  }

  Future<List<Map<String, Object?>>> rows(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) => db.query(
    table,
    where: where,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: limit,
  );
  Future<int> insert(String table, Map<String, Object?> values) =>
      db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) => db.update(table, values, where: where, whereArgs: whereArgs);
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) => db.delete(table, where: where, whereArgs: whereArgs);
  Future<void> transaction(Future<void> Function(Transaction txn) action) =>
      db.transaction(action);
}

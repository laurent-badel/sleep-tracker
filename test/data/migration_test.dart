import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:sleep_tracker/data/database.dart';

void main() {
  test('v1→v2 migration preserves existing rows and relaxes NOT NULL',
      () async {
    // Bootstrap a real v1-schema database via raw sqlite3. Drift's default
    // column naming is snake_case of the getter, so this matches the DDL the
    // v1 codegen actually produced.
    final sqlite = sqlite3.openInMemory();
    sqlite.execute('''
      CREATE TABLE daily_entries (
        date TEXT PRIMARY KEY NOT NULL,
        sleep_rating INTEGER NOT NULL,
        exercise_rating INTEGER NOT NULL,
        school_stress_rating INTEGER NOT NULL,
        screen_usage_rating INTEGER NOT NULL,
        note TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
    sqlite.execute(
      "INSERT INTO daily_entries VALUES "
      "('2026-08-20', 4, 3, 2, 5, 'hello', 1000)",
    );
    // Tell drift this database is at schema version 1.
    sqlite.execute('PRAGMA user_version = 1');

    final db = AppDatabase.forTesting(NativeDatabase.opened(sqlite));
    addTearDown(db.close);

    // Trigger the migration by running a query.
    final before = await db.dailyDao.getByDate('2026-08-20');
    expect(before, isNotNull);
    expect(before!.sleepRating, 4);
    expect(before.exerciseRating, 3);
    expect(before.schoolStressRating, 2);
    expect(before.screenUsageRating, 5);
    expect(before.note, 'hello');
    // New columns are null on old rows.
    expect(before.moodRating, isNull);
    expect(before.medicationTaken, isNull);

    // A save with an original-four feature omitted (Value.absent()) succeeds
    // and preserves the previously-logged value (spec §2 Value.absent() rule).
    await db.dailyDao.upsert(
      DailyEntriesCompanion(
        date: const Value('2026-08-20'),
        sleepRating: const Value(5),
        note: const Value('bye'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    final after = await db.dailyDao.getByDate('2026-08-20');
    expect(after!.sleepRating, 5);
    expect(after.note, 'bye');
    expect(after.exerciseRating, 3); // left unchanged via Value.absent()
    expect(after.moodRating, isNull);
  });
}

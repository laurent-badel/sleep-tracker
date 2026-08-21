import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';

void main() {
  late AppDatabase db;
  late DailyRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRepository(db.dailyDao);
  });

  tearDown(() async => db.close());

  DailyEntriesCompanion entry({
    required String date,
    int sleep = 0,
    int exercise = 0,
    int stress = 0,
    int screen = 0,
    String? note,
  }) {
    return DailyEntriesCompanion(
      date: Value(date),
      sleepRating: Value(sleep),
      exerciseRating: Value(exercise),
      schoolStressRating: Value(stress),
      screenUsageRating: Value(screen),
      note: Value(note),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
  }

  test('upsert creates, then updates, and clearing the note persists as null',
      () async {
    const date = '2026-08-21';

    await repo.upsert(entry(date: date, sleep: 4, note: 'first note'));

    var current = await repo.watchByDate(date).first;
    expect(current, isNotNull);
    expect(current!.sleepRating, 4);
    expect(current.note, 'first note');

    // Same-day update with the note cleared — must persist as null, never
    // silently keep the old value (the Value.absent() trap, spec §2).
    await repo.upsert(entry(date: date, sleep: 5, note: null));

    current = await repo.watchByDate(date).first;
    expect(current!.sleepRating, 5);
    expect(current.note, isNull);
  });

  test('watchAll emits entries ordered descending by date', () async {
    await repo.upsert(entry(date: '2026-08-20'));
    await repo.upsert(entry(date: '2026-08-21'));

    final all = await repo.watchAll().first;
    expect(all.map((e) => e.date), ['2026-08-21', '2026-08-20']);
  });
}

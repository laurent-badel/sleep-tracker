import 'package:drift/drift.dart';
import 'database.dart';
import 'daily_entries_table.dart';

part 'daily_dao.g.dart';

@DriftAccessor(tables: [DailyEntries])
class DailyDao extends DatabaseAccessor<AppDatabase> with _$DailyDaoMixin {
  DailyDao(super.db);

  Future<void> upsert(DailyEntriesCompanion entry) =>
      into(dailyEntries).insertOnConflictUpdate(entry);

  Stream<DailyEntry?> watchByDate(String date) =>
      (select(dailyEntries)..where((t) => t.date.equals(date)))
          .watchSingleOrNull();

  Stream<List<DailyEntry>> watchAll() =>
      (select(dailyEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();
}

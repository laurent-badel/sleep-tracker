import 'daily_dao.dart';
import 'database.dart';

/// Thin pass-through wrapper around [DailyDao].
///
/// Widgets and view models depend on this, not on the DAO directly.
class DailyRepository {
  final DailyDao dao;
  DailyRepository(this.dao);

  Stream<DailyEntry?> watchByDate(String date) => dao.watchByDate(date);
  Stream<List<DailyEntry>> watchAll() => dao.watchAll();
  Future<void> upsert(DailyEntriesCompanion entry) => dao.upsert(entry);
  Future<DailyEntry?> getByDate(String date) => dao.getByDate(date);
  Future<List<DailyEntry>> getAllForExport() => dao.getAllForExport();
}

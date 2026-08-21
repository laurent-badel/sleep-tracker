import 'package:drift/drift.dart';

class DailyEntries extends Table {
  // ISO-8601 (yyyy-MM-dd), stored as TEXT primary key.
  TextColumn get date => text()();
  IntColumn get sleepRating => integer()();        // 0–5
  IntColumn get exerciseRating => integer()();     // 0–5, 0 = none, 5 = a lot
  IntColumn get schoolStressRating => integer()(); // 0–5, 0 = nothing special, 5 = very stressful
  IntColumn get screenUsageRating => integer()();  // 0–5, 0 = no screens, 5 = heavy screen use
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();          // epoch millis

  @override
  Set<Column> get primaryKey => {date};
}

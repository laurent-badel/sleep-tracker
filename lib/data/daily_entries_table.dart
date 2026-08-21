import 'package:drift/drift.dart';

class DailyEntries extends Table {
  // ISO-8601 (yyyy-MM-dd), stored as TEXT primary key.
  TextColumn get date => text()();

  // Original four — nullable since schema v2 so a disabled feature can be
  // left `Value.absent()` without violating NOT NULL (spec §2).
  IntColumn get sleepRating => integer().nullable()();        // 0–5
  IntColumn get exerciseRating => integer().nullable()();     // 0–5, 0 = none, 5 = a lot
  IntColumn get schoolStressRating => integer().nullable()(); // 0–5, 0 = nothing special, 5 = very stressful
  IntColumn get screenUsageRating => integer().nullable()();  // 0–5, 0 = no screens, 5 = heavy screen use

  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();          // epoch millis

  // New catalog features (all nullable, null = not logged/disabled).
  IntColumn get moodRating => integer().nullable()();
  IntColumn get energyRating => integer().nullable()();
  IntColumn get nutritionRating => integer().nullable()();
  IntColumn get physicalRating => integer().nullable()();
  IntColumn get socialRating => integer().nullable()();
  IntColumn get productivityRating => integer().nullable()();
  IntColumn get waterRating => integer().nullable()();
  IntColumn get caffeineRating => integer().nullable()();
  IntColumn get alcoholRating => integer().nullable()();
  IntColumn get smokingRating => integer().nullable()();
  IntColumn get medicationTaken => integer().nullable()(); // 0/1
  IntColumn get workdayFlag => integer().nullable()();     // 0/1

  @override
  Set<Column> get primaryKey => {date};
}

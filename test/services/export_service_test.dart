import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/services/export_service.dart';

void main() {
  // getTemporaryDirectory() needs the method-channel binding initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailyRepository repo;
  late ExportService export;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRepository(db.dailyDao);
    // path_provider has no platform implementation in `flutter test` — inject
    // a temp dir (per test, so files don't collide).
    final temp = Directory.systemTemp.createTempSync('export_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    export = ExportService(repo, tempDir: () async => temp);
  });

  tearDown(() async => db.close());

  Future<void> seed({
    required String date,
    int sleep = 3,
    String? note,
    int updatedAt = 1000,
  }) async {
    await repo.upsert(
      DailyEntriesCompanion(
        date: Value(date),
        sleepRating: Value(sleep),
        exerciseRating: const Value(0),
        schoolStressRating: const Value(0),
        screenUsageRating: const Value(0),
        note: Value(note),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  test('exportToCsv returns null when there is no data', () async {
    final file = await export.exportToCsv();
    expect(file, isNull);
  });

  test('exportToCsv writes stable headers, ISO dates, and a UTF-8 BOM',
      () async {
    await seed(date: '2026-08-20', sleep: 4, note: 'Bien dormi, ぐっすり 😊');
    await seed(date: '2026-08-21', sleep: 2);

    final all = await repo.getAllForExport();
    expect(all.length, 2); // sanity: seeds persisted

    final file = await export.exportToCsv();
    expect(file, isNotNull);

    final bytes = await file!.readAsBytes();
    // UTF-8 BOM present.
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);

    final content = utf8.decode(bytes.skip(3).toList());
    // Parse with the csv package (naive split(',') breaks on quoted commas in
    // the note field).
    final rows = const CsvDecoder().convert(content);
    final header = rows.first.cast<String>();
    final dataRows = rows.skip(1).toList();

    // Stable, unlocalized headers (raw Drift column keys), ascending dates.
    expect(header.first, 'date');
    expect(header, contains('sleepRating'));
    expect(header, contains('note'));
    expect(header, contains('updatedAt'));
    expect(dataRows.first.first, '2026-08-20');
    expect(dataRows[1].first, '2026-08-21');

    // updatedAt is ISO 8601, not a raw epoch integer.
    final updatedAtCell = header.indexOf('updatedAt');
    final cell = dataRows.first[updatedAtCell];
    expect(DateTime.tryParse(cell), isNotNull);
    expect(cell, isNot('1000'));

    // Non-ASCII note survives round-trip (quoting + BOM).
    expect(content, contains('Bien dormi'));
    expect(content, contains('ぐっすり'));
  });

  test('exportToCsv quotes notes containing commas', () async {
    await seed(date: '2026-08-20', note: 'slept ok, woke early');

    final file = await export.exportToCsv();
    final bytes = await file!.readAsBytes();
    final content = utf8.decode(bytes.skip(3).toList());

    // The comma-containing note is quoted so the CSV stays well-formed.
    expect(content, contains('"slept ok, woke early"'));
  });
}

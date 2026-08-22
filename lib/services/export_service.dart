import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/daily_repository.dart';

/// Generates a full raw CSV dump of every entry and hands it to the OS via
/// the share sheet (spec Phase 10).
///
/// - **Full dump:** all columns for all rows, regardless of which features are
///   currently enabled — consistent with `Value.absent()` (disabling hides
///   from the UI, never deletes historical data).
/// - **Stable headers:** raw Drift column keys (`sleepRating`, ...), never
///   localized — the file is stable and diffable across languages.
/// - `date` stays exactly as stored (`yyyy-MM-dd`); `updatedAt` (epoch millis)
///   is converted to ISO 8601 for readability.
/// - Files go to the OS temporary directory; the OS owns cleanup. The app
///   does not manage destinations or delete the file.
class ExportService {
  final DailyRepository repository;

  /// Overridable for tests (path_provider has no implementation in
  /// `flutter test`); defaults to the OS temp directory.
  final Future<Directory> Function() tempDir;

  ExportService(
    this.repository, {
    Future<Directory> Function()? tempDir,
  }) : tempDir = tempDir ?? getTemporaryDirectory;

  static const _columns = [
    'date',
    'sleepRating',
    'exerciseRating',
    'schoolStressRating',
    'screenUsageRating',
    'moodRating',
    'energyRating',
    'nutritionRating',
    'physicalRating',
    'socialRating',
    'productivityRating',
    'waterRating',
    'caffeineRating',
    'alcoholRating',
    'smokingRating',
    'medicationTaken',
    'workdayFlag',
    'note',
    'updatedAt',
  ];

  /// Returns null when there is nothing to export.
  Future<File?> exportToCsv() async {
    final entries = await repository.getAllForExport();
    if (entries.isEmpty) return null;

    final rows = <List<dynamic>>[_columns];
    for (final e in entries) {
      rows.add([
        e.date,
        e.sleepRating,
        e.exerciseRating,
        e.schoolStressRating,
        e.screenUsageRating,
        e.moodRating,
        e.energyRating,
        e.nutritionRating,
        e.physicalRating,
        e.socialRating,
        e.productivityRating,
        e.waterRating,
        e.caffeineRating,
        e.alcoholRating,
        e.smokingRating,
        e.medicationTaken,
        e.workdayFlag,
        e.note ?? '',
        DateTime.fromMillisecondsSinceEpoch(e.updatedAt).toIso8601String(),
      ]);
    }

    // csv 8.x: CsvEncoder (ListToCsvConverter was removed). addBom emits the
    // UTF-8 BOM — critical for Excel to read non-ASCII characters (accents,
    // CJK, emoji) in the note field; Google Sheets ignores it harmlessly.
    final csvString = const CsvEncoder(addBom: true).convert(rows);
    final dir = await tempDir();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(dir.path, 'wellness_export_$ts.csv'));
    await file.writeAsString(csvString, encoding: utf8);
    return file;
  }
}

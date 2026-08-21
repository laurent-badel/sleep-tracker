import 'package:intl/intl.dart';

/// Formats [d] as an ISO-8601 (`yyyy-MM-dd`) key in **local** time.
///
/// This key doubles as the `DailyEntries` primary key and must sort
/// lexicographically like a real date, so the format is frozen — never change
/// it anywhere (including display code), and never build keys with
/// `.toUtc()` (UTC keys shift by the timezone offset around midnight).
String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Returns today's date key — local time, never UTC.
String todayKey() => dateKey(DateTime.now());

/// Returns the date key [daysAgo] days before today. Calendar arithmetic
/// (local midnight) so it is DST-safe and crosses month/year boundaries
/// correctly (used by Stats' 30-day window and streak).
String dateKeyForDaysAgo(int daysAgo) {
  final now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day - daysAgo));
}

import 'package:intl/intl.dart';

/// Returns today's date as an ISO-8601 (`yyyy-MM-dd`) key in **local** time.
///
/// This key doubles as the `DailyEntries` primary key and must sort
/// lexicographically like a real date, so the format is frozen — never change
/// it anywhere (including display code), and never build keys with
/// `.toUtc()` (UTC keys shift by the timezone offset around midnight).
String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

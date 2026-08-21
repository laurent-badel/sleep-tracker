import 'package:flutter_test/flutter_test.dart';

import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/utils/dates.dart';
import 'package:sleep_tracker/viewmodels/stats_view_model.dart';

DailyEntry entry(String date, {int sleep = 0}) => DailyEntry(
      date: date,
      sleepRating: sleep,
      exerciseRating: 0,
      schoolStressRating: 0,
      screenUsageRating: 0,
      updatedAt: 0,
    );

void main() {
  group('buildSlots', () {
    test('produces 30 ascending slots with today last', () {
      final entries = [entry(dateKeyForDaysAgo(0), sleep: 4)];

      final slots = buildSlots(entries);

      expect(slots.length, 30);
      expect(slots[29]?.sleepRating, 4); // today, last slot
      expect(slots[0], isNull); // 29 days ago
    });

    test('maps entries to their correct day', () {
      final today = dateKeyForDaysAgo(0);
      final threeDaysAgo = dateKeyForDaysAgo(3);
      final entries = [
        entry(today, sleep: 1),
        entry(threeDaysAgo, sleep: 3),
      ];

      final slots = buildSlots(entries);

      expect(slots[29]?.sleepRating, 1);
      expect(slots[26]?.sleepRating, 3); // index 29 - 3
      expect(slots[25], isNull);
    });
  });

  group('Metric.averageOf', () {
    test('averages only days with entries in the window', () {
      // today (4) + yesterday (2) → (4+2)/2
      final slots = buildSlots([
        entry(dateKeyForDaysAgo(0), sleep: 4),
        entry(dateKeyForDaysAgo(1), sleep: 2),
      ]);

      final avg = Metric.sleep.averageOf(slots, 7);

      expect(avg, 3.0);
    });

    test('excludes gaps from the denominator', () {
      // today (5) + 2 days ago (5) with a gap in between → still 5.0
      final slots = buildSlots([
        entry(dateKeyForDaysAgo(0), sleep: 5),
        entry(dateKeyForDaysAgo(2), sleep: 5),
      ]);

      final avg = Metric.sleep.averageOf(slots, 7);

      expect(avg, 5.0);
    });

    test('returns null when the window has no data', () {
      final slots = buildSlots([entry(dateKeyForDaysAgo(10), sleep: 3)]);

      expect(Metric.sleep.averageOf(slots, 7), isNull);
      expect(Metric.sleep.averageOf(slots, 30), 3.0);
    });
  });

  group('computeStreak', () {
    test('counts consecutive days ending today', () {
      final entries = [
        entry(dateKeyForDaysAgo(0)),
        entry(dateKeyForDaysAgo(1)),
        entry(dateKeyForDaysAgo(2)),
      ];

      expect(computeStreak(entries), 3);
    });

    test('starts from yesterday when today has no entry', () {
      final entries = [
        entry(dateKeyForDaysAgo(1)),
        entry(dateKeyForDaysAgo(2)),
        entry(dateKeyForDaysAgo(3)),
      ];

      expect(computeStreak(entries), 3);
    });

    test('stops at the first gap', () {
      final entries = [
        entry(dateKeyForDaysAgo(0)),
        entry(dateKeyForDaysAgo(1)),
        entry(dateKeyForDaysAgo(3)), // gap at 2
      ];

      expect(computeStreak(entries), 2);
    });

    test('returns null when there is no streak', () {
      expect(computeStreak([]), isNull);
      // Only an entry 10 days ago — nothing consecutive ending today/yesterday.
      expect(computeStreak([entry(dateKeyForDaysAgo(10))]), isNull);
    });
  });

  test('Metric.ratingOf extracts the right column', () {
    final e = DailyEntry(
      date: '2026-08-21',
      sleepRating: 1,
      exerciseRating: 2,
      schoolStressRating: 3,
      screenUsageRating: 4,
      updatedAt: 0,
    );

    expect(Metric.sleep.ratingOf(e), 1);
    expect(Metric.exercise.ratingOf(e), 2);
    expect(Metric.schoolStress.ratingOf(e), 3);
    expect(Metric.screenUsage.ratingOf(e), 4);
  });
}

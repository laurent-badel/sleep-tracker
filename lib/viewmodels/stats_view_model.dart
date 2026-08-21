import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import '../utils/dates.dart';

/// The four tracked metrics (spec §3). `ratingOf` extracts the 0–5 rating for
/// this metric from an entry; the painter receives it as a tear-off so it
/// stays metric-agnostic.
enum Metric {
  sleep('Sleep'),
  exercise('Exercise'),
  schoolStress('School stress'),
  screenUsage('Screen time');

  const Metric(this.label);

  final String label;

  int ratingOf(DailyEntry e) => switch (this) {
        Metric.sleep => e.sleepRating,
        Metric.exercise => e.exerciseRating,
        Metric.schoolStress => e.schoolStressRating,
        Metric.screenUsage => e.screenUsageRating,
      };

  /// Rolling mean over the last [window] calendar days of [slots] (slots are
  /// ascending with today last). Only days with entries count toward the
  /// denominator — gaps are excluded. Returns null when the window has no data.
  double? averageOf(List<DailyEntry?> slots, int window) {
    final start = slots.length - window;
    final values = <int>[];
    for (var i = start < 0 ? 0 : start; i < slots.length; i++) {
      final e = slots[i];
      if (e != null) values.add(ratingOf(e));
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// Builds the chart slots: a fixed-length list (default 30) in **ascending**
/// order — index 0 is [days]-1 days ago, index `days-1` is today; null = a day
/// with no entry (spec §3, view-layer logic: Drift only returns rows that exist).
List<DailyEntry?> buildSlots(List<DailyEntry> entries, {int days = 30}) {
  final byDate = {for (final e in entries) e.date: e};
  return [
    for (var i = days - 1; i >= 0; i--) byDate[dateKeyForDaysAgo(i)],
  ];
}

/// Consecutive days with any entry, walking backward from today — or from
/// yesterday if today has no entry yet (spec §3). Returns null when there is
/// no streak to show. Must run over full history (never a capped window).
int? computeStreak(List<DailyEntry> entries) {
  if (entries.isEmpty) return null;
  final has = {for (final e in entries) e.date: true};
  final startOffset = has.containsKey(todayKey()) ? 0 : 1;
  var count = 0;
  var offset = startOffset;
  while (has.containsKey(dateKeyForDaysAgo(offset))) {
    count++;
    offset++;
  }
  return count > 0 ? count : null;
}

/// Subscribes to `watchAll()` once, over full history (spec §3), and derives
/// everything the Stats screen needs on each emission.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel(this._repo) {
    _sub = _repo.watchAll().listen((entries) {
      _recompute(entries);
      notifyListeners();
    });
  }

  final DailyRepository _repo;
  StreamSubscription<List<DailyEntry>>? _sub;

  bool loaded = false; // gate: don't build stats before the first emission
  int entryCount = 0;
  int? streak; // null → "—" (spec §3)
  Map<Metric, List<DailyEntry?>> slots = const {};
  Map<Metric, double?> avg7 = const {};
  Map<Metric, double?> avg30 = const {};

  void _recompute(List<DailyEntry> entries) {
    loaded = true;
    entryCount = entries.length;
    streak = computeStreak(entries);
    slots = {
      for (final m in Metric.values) m: buildSlots(entries),
    };
    avg7 = {
      for (final m in Metric.values) m: m.averageOf(slots[m]!, 7),
    };
    avg30 = {
      for (final m in Metric.values) m: m.averageOf(slots[m]!, 30),
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

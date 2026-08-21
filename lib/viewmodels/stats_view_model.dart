import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import '../models/feature_def.dart';
import '../utils/dates.dart';
import 'feature_settings_controller.dart';

/// Rolling mean over the last [window] calendar days of [slots] (slots are
/// ascending with today last). Only days with entries count toward the
/// denominator — gaps are excluded. Returns null when the window has no data.
double? averageOf(List<DailyEntry?> slots, FeatureDef feature, int window) {
  final start = slots.length - window;
  final values = <int>[];
  for (var i = start < 0 ? 0 : start; i < slots.length; i++) {
    final e = slots[i];
    if (e != null) {
      final v = feature.getValue(e);
      if (v != null) values.add(v);
    }
  }
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
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
/// everything the Stats screen needs on each emission. Also listens to the
/// [FeatureSettingsController] so toggling features updates the cards live.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel(this._repo, this._featureSettings) {
    _sub = _repo.watchAll().listen((entries) {
      _entries = entries;
      _recompute();
    });
    _featureSettings.addListener(_recompute);
  }

  final DailyRepository _repo;
  final FeatureSettingsController _featureSettings;
  StreamSubscription<List<DailyEntry>>? _sub;
  List<DailyEntry> _entries = const [];

  bool loaded = false; // gate: don't build stats before the first emission
  int entryCount = 0;
  int? streak; // null → "—" (spec §3)
  List<FeatureDef> features = const [];
  Map<String, List<DailyEntry?>> slots = const {}; // feature key → slots
  Map<String, double?> avg7 = const {};
  Map<String, double?> avg30 = const {};

  void _recompute() {
    loaded = true;
    final entries = _entries;
    entryCount = entries.length;
    streak = computeStreak(entries);
    features = _featureSettings.enabledFeatures;
    slots = {
      for (final f in features) f.key: buildSlots(entries),
    };
    avg7 = {
      for (final f in features) f.key: averageOf(slots[f.key]!, f, 7),
    };
    avg30 = {
      for (final f in features) f.key: averageOf(slots[f.key]!, f, 30),
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _featureSettings.removeListener(_recompute);
    super.dispose();
  }
}

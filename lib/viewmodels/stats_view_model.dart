import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';

/// Subscribes to `watchAll()` once, over full history (spec §3).
///
/// Phase 1 placeholder: the subscription and notification plumbing exist, but
/// derived state (30-day chart slots, rolling averages, streak) is computed in
/// Phase 4.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel(this._repo) {
    _sub = _repo.watchAll().listen((entries) {
      // Phase 4: derive chart slots, averages, and streak here.
      notifyListeners();
    });
  }

  final DailyRepository _repo;
  StreamSubscription<List<DailyEntry>>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

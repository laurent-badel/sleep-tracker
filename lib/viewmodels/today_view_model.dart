import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import '../utils/dates.dart';

/// Owns today's date, the `watchByDate` subscription, and midnight rollover.
/// Created once at the root (spec §4) — never inside the tab widget.
class TodayViewModel extends ChangeNotifier {
  TodayViewModel(this._repo) {
    _subscribe();
    _rolloverTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => checkRollover(),
    );
  }

  final DailyRepository _repo;
  String today = todayKey(); // local time, never UTC
  DailyEntry? currentEntry;
  bool loaded = false; // gate: don't build the form before first emission
  StreamSubscription<DailyEntry?>? _sub;
  Timer? _rolloverTimer;

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchByDate(today).listen((entry) {
      currentEntry = entry;
      loaded = true;
      notifyListeners();
    });
  }

  void checkRollover() {
    final t = todayKey();
    if (t == today) return;
    today = t;
    currentEntry = null;
    loaded = false; // Today screen shows spinner until new day's emission
    _subscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rolloverTimer?.cancel();
    super.dispose();
  }
}

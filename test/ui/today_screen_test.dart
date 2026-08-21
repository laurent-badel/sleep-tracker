import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/ui/today_screen.dart';
import 'package:sleep_tracker/utils/dates.dart';
import 'package:sleep_tracker/viewmodels/today_view_model.dart';

void main() {
  testWidgets('Today: form renders, save persists and shows snackbar',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DailyRepository(db.dailyDao);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider(create: (_) => TodayViewModel(repo)),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Form loaded (no spinner), all four pickers + Save present.
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    for (final label in ['Sleep', 'Exercise', 'School stress', 'Screen time']) {
      expect(find.text(label), findsOneWidget);
    }

    // Select a rating, scroll the Save button into view, and save.
    await tester.tap(find.byTooltip('Sleep 4'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget); // snackbar

    // Verify DB state in real-async mode: drift delivers stream events via
    // timers, which never fire inside testWidgets' fake-async zone — an
    // `await stream.first` outside runAsync hangs until the per-test timeout.
    await tester.runAsync(() async {
      final entry = await repo.watchByDate(todayKey()).first;
      expect(entry, isNotNull);
      expect(entry!.sleepRating, 4);
      expect(entry.note, isNull);
    });

    // Dispose the tree inside the test body, then advance fake time so
    // drift's zero-duration stream-close timer fires (a plain pump() with no
    // duration only flushes microtasks — the timer would still be pending).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

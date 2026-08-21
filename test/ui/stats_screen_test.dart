import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/ui/stats_screen.dart';
import 'package:sleep_tracker/utils/dates.dart';
import 'package:sleep_tracker/viewmodels/stats_view_model.dart';

void main() {
  late AppDatabase db;
  late DailyRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRepository(db.dailyDao);
  });

  tearDown(() async => db.close());

  Future<void> seed({required String date, int sleep = 0}) async {
    await repo.upsert(
      DailyEntriesCompanion(
        date: Value(date),
        sleepRating: Value(sleep),
        exerciseRating: Value(0),
        schoolStressRating: Value(0),
        screenUsageRating: Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> pumpStats(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider(create: (_) => StatsViewModel(repo)),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Stats shows placeholder with fewer than 2 days of data',
      (tester) async {
    await seed(date: dateKeyForDaysAgo(0), sleep: 4);
    await pumpStats(tester);

    expect(find.text('Log at least two days to see your stats.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Stats shows streak and four metric cards', (tester) async {
    await seed(date: dateKeyForDaysAgo(0), sleep: 4);
    await seed(date: dateKeyForDaysAgo(1), sleep: 3);
    await seed(date: dateKeyForDaysAgo(2), sleep: 5);
    await pumpStats(tester);

    // Streak card (3 consecutive days ending today).
    expect(find.text('3-day streak'), findsOneWidget);

    // First metric cards visible without scrolling.
    for (final label in ['Sleep', 'Exercise', 'School stress']) {
      expect(find.text(label), findsOneWidget);
    }

    // Averages row present for the sleep card with real numbers.
    expect(find.text('7-day avg: 4.0 · 30-day avg: 4.0'), findsOneWidget);

    // The 4th card is below the fold in the 600px test viewport; ListView
    // builds lazily, so scroll it into view before asserting.
    await tester.scrollUntilVisible(
      find.text('Screen time'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Screen time'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

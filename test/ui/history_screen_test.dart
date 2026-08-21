import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/ui/history_screen.dart';
import 'package:sleep_tracker/viewmodels/feature_settings_controller.dart';

void main() {
  late AppDatabase db;
  late DailyRepository repo;
  late FeatureSettingsController featureSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    featureSettings = FeatureSettingsController();
    await featureSettings.load();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRepository(db.dailyDao);
  });

  tearDown(() async => db.close());

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: featureSettings),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed({
    required String date,
    int sleep = 0,
    int exercise = 0,
    int stress = 0,
    int screen = 0,
    String? note,
  }) async {
    await repo.upsert(
      DailyEntriesCompanion(
        date: Value(date),
        sleepRating: Value(sleep),
        exerciseRating: Value(exercise),
        schoolStressRating: Value(stress),
        screenUsageRating: Value(screen),
        note: Value(note),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // Dispose the tree inside the test body, then advance fake time so drift's
  // zero-duration stream-close timer fires (a plain pump() with no duration
  // only flushes microtasks — the timer would still be pending).
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('History shows empty state when there are no entries',
      (tester) async {
    await pumpHistory(tester);

    expect(
      find.text(
        'No entries yet — log today from the Today tab, or tap + '
        'to backfill a past day.',
      ),
      findsOneWidget,
    );

    await teardownTree(tester);
  });

  testWidgets('History lists entries with date, summary, and note preview',
      (tester) async {
    await seed(date: '2026-08-20', sleep: 4, exercise: 3, stress: 2, screen: 5);
    await seed(date: '2026-08-21', note: 'A long note that should be truncated');
    await pumpHistory(tester);

    // Rows rendered with display dates (MMMEd).
    expect(find.text('Thu, Aug 20'), findsOneWidget);
    expect(find.text('Fri, Aug 21'), findsOneWidget);

    // Compact summaries (full short labels; '-' for a not-logged feature).
    expect(find.text('Sleep:4 Exercise:3 Stress:2 Screen:5'), findsOneWidget);
    expect(find.text('Sleep:0 Exercise:0 Stress:0 Screen:0'), findsOneWidget);

    // Note icon + preview for the entry with a note.
    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(find.text('A long note that should be truncated'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('Tapping a row opens the editor; saving persists and pops',
      (tester) async {
    await seed(date: '2026-08-20', sleep: 2);
    await pumpHistory(tester);

    await tester.tap(find.text('Thu, Aug 20'));
    await tester.pumpAndSettle();

    // Bottom sheet with the shared form, pre-seeded.
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);

    // Change the sleep rating and save.
    await tester.tap(find.byTooltip('Sleep 4'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Sheet closed after save.
    expect(find.text('Metrics'), findsNothing);

    // Verify DB state in real-async mode: drift delivers stream events via
    // timers, which never fire inside testWidgets' fake-async zone — an
    // `await stream.first` outside runAsync hangs until the per-test timeout.
    await tester.runAsync(() async {
      final entry = await repo.watchByDate('2026-08-20').first;
      expect(entry!.sleepRating, 4); // tapped Sleep 4 (5-level scale, 0-4)
    });

    await teardownTree(tester);
  });
}

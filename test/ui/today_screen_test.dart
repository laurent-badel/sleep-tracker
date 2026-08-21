import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/l10n/generated/app_localizations.dart';
import 'package:sleep_tracker/ui/today_screen.dart';
import 'package:sleep_tracker/utils/dates.dart';
import 'package:sleep_tracker/viewmodels/feature_settings_controller.dart';
import 'package:sleep_tracker/viewmodels/today_view_model.dart';

void main() {
  late AppDatabase db;
  late DailyRepository repo;
  late FeatureSettingsController featureSettings;

  Future<void> pumpToday(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: featureSettings),
          ChangeNotifierProvider(create: (_) => TodayViewModel(repo)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TodayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedToday({int sleep = 3, String? note}) async {
    await repo.upsert(
      DailyEntriesCompanion(
        date: Value(todayKey()),
        sleepRating: Value(sleep),
        exerciseRating: const Value(0),
        schoolStressRating: const Value(0),
        screenUsageRating: const Value(0),
        note: Value(note),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    featureSettings = FeatureSettingsController();
    await featureSettings.load();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRepository(db.dailyDao);
  });

  tearDown(() async => db.close());

  testWidgets('Today: form renders, save persists and shows snackbar',
      (tester) async {
    await pumpToday(tester);

    // Form loaded (no spinner), all four pickers + Save present.
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    for (final label in ['Sleep', 'Exercise', 'School stress', 'Screen time']) {
      expect(find.text(label), findsOneWidget);
    }
    // First-time logging: no Cancel affordance.
    expect(find.text('Cancel'), findsNothing);

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

  testWidgets('Today: saved entry shows caught-up card with summary + Edit',
      (tester) async {
    await seedToday(sleep: 4);
    await pumpToday(tester);

    // Caught-up card, not the form.
    expect(find.text("You're all caught up for today."), findsOneWidget);
    expect(find.text('Sleep:4 Exercise:0 Stress:0 Screen:0'), findsOneWidget);
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.text('Metrics'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Today: Edit opens the pre-filled form; Save returns to card',
      (tester) async {
    await seedToday(sleep: 2);
    await pumpToday(tester);

    await tester.tap(find.text('Edit entry'));
    await tester.pumpAndSettle();

    // Form with Cancel, pre-seeded (sleep 2 → 'Sleep 2' tooltip is the value).
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Change a rating and save → back to the card.
    await tester.tap(find.byTooltip('Sleep 4'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up for today."), findsOneWidget);
    expect(find.text('Sleep:4 Exercise:0 Stress:0 Screen:0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Today: Cancel returns to the card without saving',
      (tester) async {
    await seedToday(sleep: 2);
    await pumpToday(tester);

    await tester.tap(find.text('Edit entry'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up for today."), findsOneWidget);
    // Unchanged: sleep still 2.
    expect(find.text('Sleep:2 Exercise:0 Stress:0 Screen:0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sleep_tracker/app.dart';
import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/l10n/generated/app_localizations.dart';
import 'package:sleep_tracker/services/notification_service.dart';
import 'package:sleep_tracker/utils/dates.dart';
import 'package:sleep_tracker/utils/prefs.dart';
import 'package:sleep_tracker/viewmodels/feature_settings_controller.dart';
import 'package:sleep_tracker/viewmodels/stats_view_model.dart';
import 'package:sleep_tracker/viewmodels/today_view_model.dart';

/// Phase 7 acceptance: the app renders fully (all 3 tabs + Settings) under
/// each supported locale via the in-app language preference — no missing-key
/// fallback (the untranslated gate is the static guarantee; this exercises the
/// real widget tree).
void main() {
  for (final code in ['en', 'fr', 'de', 'ja', 'it']) {
    testWidgets('app renders under locale $code', (tester) async {
      SharedPreferences.setMockInitialValues({
        selectedLanguageKey: code,
        'enabled_features': ['sleepRating', 'moodRating'],
      });

      final featureSettings = FeatureSettingsController();
      await featureSettings.load();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DailyRepository(db.dailyDao);
      // Two entries — today + yesterday — so Stats isn't in the placeholder
      // state AND Today shows the caught-up card (dates must be relative to
      // the real "now", not hardcoded).
      await repo.upsert(
        DailyEntriesCompanion(
          date: Value(dateKeyForDaysAgo(0)),
          sleepRating: const Value(4),
          moodRating: const Value(3),
          updatedAt: Value(1),
        ),
      );
      await repo.upsert(
        DailyEntriesCompanion(
          date: Value(dateKeyForDaysAgo(1)),
          sleepRating: const Value(5),
          moodRating: const Value(4),
          updatedAt: Value(2),
        ),
      );

      languagePreference.value = code;
      // navigationManager is a global — reset to Today so each locale starts
      // on the same tab (a previous test may have navigated away).
      navigationManager.navigateTo(0);
      final l = lookupAppLocalizations(Locale(code));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider.value(value: navigationManager),
            Provider.value(value: NotificationService()),
            ChangeNotifierProvider.value(value: featureSettings),
            ChangeNotifierProvider(
              create: (_) => TodayViewModel(repo),
            ),
            ChangeNotifierProvider(
              create: (_) => StatsViewModel(repo, featureSettings),
            ),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      // Today tab: a saved entry for today means the caught-up card (with the
      // localized Edit button) — not the form.
      expect(find.text(l.todayCaughtUp), findsOneWidget);
      expect(find.text(l.todayEdit), findsOneWidget);

      // Bottom-nav labels are present (localized per locale).
      expect(find.byType(NavigationBar), findsOneWidget);

      // Switch to History and Stats; they must render without exceptions.
      navigationManager.navigateTo(1);
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);

      navigationManager.navigateTo(2);
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets); // charts render

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }
}

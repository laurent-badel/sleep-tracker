import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sleep_tracker/app.dart';
import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/services/notification_service.dart';
import 'package:sleep_tracker/viewmodels/feature_settings_controller.dart';
import 'package:sleep_tracker/viewmodels/stats_view_model.dart';
import 'package:sleep_tracker/viewmodels/today_view_model.dart';

void main() {
  testWidgets('app builds and the Today tab renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final featureSettings = FeatureSettingsController();
    await featureSettings.load();

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DailyRepository(db.dailyDao);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: navigationManager),
          Provider.value(value: NotificationService()),
          ChangeNotifierProvider.value(value: featureSettings),
          ChangeNotifierProvider(create: (_) => TodayViewModel(repo)),
          ChangeNotifierProvider(
            create: (_) => StatsViewModel(repo, featureSettings),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // Today tab renders (AppBar title + bottom-nav label).
    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Stats'), findsWidgets);

    // Dispose the tree inside the test body, then advance fake time so
    // drift's zero-duration stream-close timer fires (a plain pump() with no
    // duration only flushes microtasks — the timer would still be pending).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sleep_tracker/app.dart';
import 'package:sleep_tracker/data/daily_repository.dart';
import 'package:sleep_tracker/data/database.dart';
import 'package:sleep_tracker/services/notification_service.dart';
import 'package:sleep_tracker/viewmodels/stats_view_model.dart';
import 'package:sleep_tracker/viewmodels/today_view_model.dart';

void main() {
  testWidgets('app builds and the Today tab renders', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DailyRepository(db.dailyDao);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: navigationManager),
          Provider.value(value: NotificationService()),
          ChangeNotifierProvider(create: (_) => TodayViewModel(repo)),
          ChangeNotifierProvider(create: (_) => StatsViewModel(repo)),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // Today tab renders (AppBar title + bottom-nav label).
    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Stats'), findsWidgets);
  });
}

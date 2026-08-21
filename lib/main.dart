import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'data/daily_repository.dart';
import 'data/database.dart';
import 'services/notification_service.dart';
import 'viewmodels/stats_view_model.dart';
import 'viewmodels/today_view_model.dart';

/// Foreground notification tap → Today (spec §5). No `BuildContext` here:
/// only the global [navigationManager].
void onNotificationResponse(NotificationResponse response) {
  navigationManager.navigateTo(0);
}

/// Background/terminated tap — runs in a separate isolate, so it must be a
/// top-level entry point and must not touch widget state (spec §5).
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  navigationManager.navigateTo(0);
}

/// The one and only composition root (spec §4).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init is a hard prerequisite for zonedSchedule — it throws
  // otherwise. NOTE: initializeTimeZones() comes from
  // package:timezone/data/latest.dart, NOT package:timezone/timezone.dart.
  tzdata.initializeTimeZones();
  try {
    // flutter_timezone 5.x returns a TimezoneInfo object, not a String.
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  } catch (_) {
    // Keep tz.local rather than block startup on an exotic device.
  }

  // Notifications: plugin init, callbacks, then re-schedule from saved settings.
  final notifications = NotificationService();
  await notifications.init();
  await notifications.rescheduleFromSettings();

  // Cold start from a notification tap never fires the tap callbacks — check
  // explicitly (spec §5).
  if (await notifications.launchedByNotification()) {
    navigationManager.navigateTo(0); // Today
  }

  final container = AppContainer.create();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: container.repository),
        ChangeNotifierProvider.value(value: navigationManager),
        Provider.value(value: notifications),
        ChangeNotifierProvider(
          create: (_) => TodayViewModel(container.repository),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsViewModel(container.repository),
        ),
      ],
      child: const App(),
    ),
  );
}

/// Manual DI container (spec §4).
class AppContainer {
  final AppDatabase database;
  final DailyRepository repository;

  AppContainer._(this.database, this.repository);

  factory AppContainer.create() {
    final db = AppDatabase();
    final repo = DailyRepository(db.dailyDao);
    return AppContainer._(db, repo);
  }

  Future<void> dispose() => database.close();
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:sleep_tracker/services/notification_service.dart';
import 'package:sleep_tracker/ui/settings_screen.dart';

import '../helpers/fake_android_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // scheduleReminder reads tz.local; main() does this, tests must too.
    // Note: use 'Etc/UTC' — bare 'UTC' isn't in the tzf name table.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    FlutterLocalNotificationsPlatform.instance = FakeAndroidPlugin();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider.value(value: NotificationService())],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders with reminder off and the default 20:00 time',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('8:00 PM'), findsOneWidget); // default 20:00, en_US
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('enabling the reminder persists enabled=true and schedules',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    final fake =
        FlutterLocalNotificationsPlatform.instance as FakeAndroidPlugin;
    expect(fake.scheduled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_enabled'), isTrue);
  });

  testWidgets('disabling the reminder persists enabled=false and cancels',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'reminder_enabled': true,
      'reminder_hour': 20,
      'reminder_minute': 0,
    });
    await pumpSettings(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_enabled'), isFalse);
  });
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:sleep_tracker/services/notification_service.dart';

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

  test('loadReminderSettings defaults to off at 20:00', () async {
    final service = NotificationService();

    final s = await service.loadReminderSettings();

    expect(s.enabled, isFalse);
    expect(s.hour, NotificationService.defaultHour);
    expect(s.minute, NotificationService.defaultMinute);
  });

  test('saveReminderSettings round-trips enabled + time', () async {
    final service = NotificationService();

    await service.saveReminderSettings(enabled: true, hour: 7, minute: 30);
    final s = await service.loadReminderSettings();

    expect(s.enabled, isTrue);
    expect(s.hour, 7);
    expect(s.minute, 30);
  });

  test('rescheduleFromSettings with disabled setting is a safe no-op', () async {
    final service = NotificationService();

    // Should not throw even though no platform implementation is registered.
    await service.rescheduleFromSettings();

    final s = await service.loadReminderSettings();
    expect(s.enabled, isFalse);
  });
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Minimal fake Android implementation for tests.
///
/// The real plugin talks to a MethodChannel that doesn't exist in `flutter
/// test`, and v22.3.0's `zonedSchedule` uses a `!` on the resolved Android
/// impl — so anything that schedules would crash without this registered via
/// `FlutterLocalNotificationsPlatform.instance`.
class FakeAndroidPlugin extends AndroidFlutterLocalNotificationsPlugin {
  bool scheduled = false;
  bool? permissionGranted = true;
  bool exactAllowed = false;

  @override
  Future<bool?> requestNotificationsPermission() async => permissionGranted;

  @override
  Future<bool?> canScheduleExactNotifications() async => exactAllowed;

  @override
  Future<void> cancel({required int id, String? tag}) async {
    scheduled = false;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    scheduled = true;
  }
}

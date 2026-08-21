/// Wraps `flutter_local_notifications` + `shared_preferences` reminder
/// settings.
///
/// Phase 1: scaffolding stub — the full implementation (plugin init,
/// permissions, `zonedSchedule`, deep-link callbacks) lands in Phase 5. The
/// API below is frozen by the spec (§5); keep the signatures stable.
class NotificationService {
  static const notificationId = 1001; // fixed ID → rescheduling replaces, never duplicates
  static const channelId = 'daily_reminder';
  static const channelName = 'Daily reminder';
  static const title = 'Daily check-in';
  static const body = 'Log your sleep, exercise, stress, and screen time.';

  Future<void> init() async {
    // Phase 5: plugin.initialize with both tap callbacks.
  }

  Future<bool> requestPermissions() async {
    // Phase 5: POST_NOTIFICATIONS on Android 13+ / UNUserNotificationCenter on iOS.
    return false;
  }

  Future<void> scheduleReminder(int hour, int minute) async {
    // Phase 5: cancel + zonedSchedule next occurrence.
  }

  Future<void> cancel() async {
    // Phase 5.
  }

  Future<void> rescheduleFromSettings() async {
    // Phase 5: read shared_preferences; schedule if enabled (idempotent).
  }

  Future<bool> launchedByNotification() async {
    // Phase 5: wraps getNotificationAppLaunchDetails.
    return false;
  }
}

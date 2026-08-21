import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/generated/app_localizations.dart';
import '../utils/prefs.dart';
/// Wraps `flutter_local_notifications` + `shared_preferences` reminder
/// settings (spec §5).
///
/// API verified against the installed package source (v22.3.0) on 2026-08-21:
/// - `zonedSchedule` requires `androidScheduleMode` (no default in this major).
/// - `DarwinInitializationSettings` defaults `request*Permission` to **true**,
///   which would prompt for permission at startup on iOS — explicitly disabled
///   here; permissions are requested only when the user enables the reminder.
///
/// i18n (Phase 7): no `BuildContext` here, so strings are resolved via the
/// generated top-level `lookupAppLocalizations` with the system locale. They
/// are baked in at schedule time; `rescheduleFromSettings()` runs on every
/// launch, so a system-language change takes effect on the next launch (spec
/// §5).
class NotificationService {
  static const notificationId = 1001; // fixed ID → rescheduling replaces, never duplicates
  static const channelId = 'daily_reminder';
  static const defaultHour = 20;
  static const defaultMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Phase 8: notifications follow the in-app language preference (saved
  /// `selected_language`), falling back to the OS locale on 'system'.
  /// Async because it reads the pref — callers already await scheduling.
  Future<AppLocalizations> _l10n() async {
    final saved = await loadSelectedLanguage();
    final locale = saved == systemLanguageCode
        ? PlatformDispatcher.instance.locale
        : Locale(saved);
    return lookupAppLocalizations(locale);
  }

  /// Registers both tap callbacks (spec §5, deep-link entry points 1 & 2).
  /// `onDidReceiveBackgroundNotificationResponse` must be a top-level
  /// `@pragma('vm:entry-point')` function (it runs in a separate isolate).
  Future<void> init({
    required void Function(NotificationResponse) onDidReceiveNotificationResponse,
    required void Function(NotificationResponse) onDidReceiveBackgroundNotificationResponse,
  }) async {
    const settings = InitializationSettings(
      // Small-icon: a crescent-moon alpha silhouette (Android tints it white
      // in the status bar; a full-color launcher icon renders as a white box).
      android: AndroidInitializationSettings('@drawable/ic_stat_moon'),
      iOS: DarwinInitializationSettings(
        // Suppress init-time permission requests — we ask on enable instead.
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  /// POST_NOTIFICATIONS on Android 13+ / UNUserNotificationCenter on iOS.
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    // Non-mobile (tests, etc.): nothing to request.
    return true;
  }

  /// Daily repeat via `zonedSchedule` with `DateTimeComponents.time`. The next
  /// occurrence is computed explicitly — never rely on the plugin to advance a
  /// past time (spec §5).
  Future<void> scheduleReminder(int hour, int minute) async {
    await cancel();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Default to inexact (spec §5); escalate to exact only if already granted
    // — the plugin does not throw when exact scheduling is silently denied.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final exactAllowed =
        await androidImpl?.canScheduleExactNotifications() ?? false;
    final mode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final l10n = await _l10n();

    await _plugin.zonedSchedule(
      id: notificationId,
      title: l10n.notifTitle,
      body: l10n.notifBody,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          l10n.notifChannelName,
          channelDescription: l10n.notifChannelDescription,
          icon: 'ic_stat_moon', // small-icon silhouette (matches default)
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, // a daily reminder should show even when
          presentSound: true, // the app is foregrounded (spec §5)
        ),
      ),
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'today', // decorative in v1 — all callbacks navigate to Today
    );
  }

  Future<void> cancel() => _plugin.cancel(id: notificationId);

  /// Reads saved settings and (re)schedules if enabled — the source of truth
  /// on every launch; cheap and idempotent (spec §5).
  Future<void> rescheduleFromSettings() async {
    final settings = await loadReminderSettings();
    if (!settings.enabled) {
      await cancel();
      return;
    }
    await scheduleReminder(settings.hour, settings.minute);
  }

  /// Cold-start tap detection — a launching tap fires neither callback
  /// (spec §5, deep-link entry point 3).
  Future<bool> launchedByNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  // ---- Reminder settings persistence (shared_preferences) ----

  Future<({bool enabled, int hour, int minute})> loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(reminderEnabledKey) ?? false,
      hour: prefs.getInt(reminderHourKey) ?? defaultHour,
      minute: prefs.getInt(reminderMinuteKey) ?? defaultMinute,
    );
  }

  Future<void> saveReminderSettings({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(reminderEnabledKey, enabled);
    if (hour != null) await prefs.setInt(reminderHourKey, hour);
    if (minute != null) await prefs.setInt(reminderMinuteKey, minute);
  }
}

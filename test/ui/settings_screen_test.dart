import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:sleep_tracker/app.dart' show languagePreference;
import 'package:sleep_tracker/l10n/generated/app_localizations.dart';
import 'package:sleep_tracker/services/notification_service.dart';
import 'package:sleep_tracker/ui/settings_screen.dart';
import 'package:sleep_tracker/utils/prefs.dart';
import 'package:sleep_tracker/viewmodels/feature_settings_controller.dart';

import '../helpers/fake_android_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FeatureSettingsController featureSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // scheduleReminder reads tz.local; main() does this, tests must too.
    // Note: use 'Etc/UTC' — bare 'UTC' isn't in the tzf name table.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    FlutterLocalNotificationsPlatform.instance = FakeAndroidPlugin();
    featureSettings = FeatureSettingsController();
    await featureSettings.load();
    // Global language preference persists across tests — reset it.
    languagePreference.value = systemLanguageCode;
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: NotificationService()),
          ChangeNotifierProvider.value(value: featureSettings),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders with reminder off, the default 20:00 time, and the '
      'default enabled features checked', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('8:00 PM'), findsOneWidget); // default 20:00, en_US
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    // Features section is below the fold once the Language section is added —
    // the lazy ListView hasn't built it yet, so scroll it into view first.
    await tester.scrollUntilVisible(
      find.text('Sleep'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Features section: the four default-enabled are checked, others are not.
    for (final label in ['Sleep', 'Exercise', 'School stress', 'Screen time']) {
      expect(
        tester
            .widget<CheckboxListTile>(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isTrue,
      );
    }
    await tester.scrollUntilVisible(
      find.text('Mood'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('Mood'),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('toggling a feature off updates the enabled set', (tester) async {
    await pumpSettings(tester);

    // 'Mood' is below the fold (Language section above the features) — build
    // it via scrollUntilVisible, then bring it fully into the viewport.
    await tester.scrollUntilVisible(
      find.text('Mood'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('Mood'),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .value,
      isTrue,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('enabled_features'), contains('moodRating'));
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

  testWidgets('Language section renders system default + all languages',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Language'), findsOneWidget);
    for (final label in [
      'System default',
      'English',
      'Français',
      'Deutsch',
      '日本語',
      'Italiano',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('selecting a language updates the global and persists',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();

    expect(languagePreference.value, 'ja');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_language'), 'ja');
  });

  testWidgets('selecting System default restores locale following',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_language': 'ja',
    });
    languagePreference.value = 'ja';
    await pumpSettings(tester);

    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();

    expect(languagePreference.value, 'system');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_language'), 'system');
  });
}

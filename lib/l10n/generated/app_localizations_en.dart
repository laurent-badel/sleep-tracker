// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navToday => 'Today';

  @override
  String get navHistory => 'History';

  @override
  String get navStats => 'Stats';

  @override
  String get todaySettingsTooltip => 'Settings';

  @override
  String get todaySaved => 'Saved';

  @override
  String get todayCaughtUp => 'You\'re all caught up for today.';

  @override
  String get todayEdit => 'Edit entry';

  @override
  String get cancel => 'Cancel';

  @override
  String get metricsHeader => 'Metrics';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get saveButton => 'Save';

  @override
  String get historyEmpty =>
      'No entries yet — log today from the Today tab, or tap + to backfill a past day.';

  @override
  String get historyAddTooltip => 'Add or edit a day';

  @override
  String get statsNotEnoughData => 'Log at least two days to see your stats.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Log a day to start a streak';

  @override
  String get streakKeepGoing => 'Keep it going!';

  @override
  String statsAverages(String avg7, String avg30) {
    return '7-day avg: $avg7 · 30-day avg: $avg30';
  }

  @override
  String statsNormalizedAvg(String value) {
    return '$value / 10';
  }

  @override
  String statsFrequencyAvg(String days, String total) {
    return '$days / $total days';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsReminder => 'Daily reminder';

  @override
  String get settingsReminderSubtitle => 'Remind me to log my day';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsFeatures => 'Features';

  @override
  String get settingsFeaturesSubtitle =>
      'Choose what to track. Disabling never deletes past data.';

  @override
  String get settingsPermissionDenied =>
      'Enable notifications in system settings to receive reminders';

  @override
  String get settingsExportHeader => 'Export Data';

  @override
  String get settingsExportButton => 'Export to CSV';

  @override
  String get settingsExportPrivacyWarning =>
      'Exported files are plain text and are not encrypted. They contain sensitive data like notes and medication logs.';

  @override
  String get exportNoData => 'No data to export yet.';

  @override
  String get exportShareSubject => 'Daily Wellness Tracker Export';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get languageEn => 'English';

  @override
  String get languageFr => 'Français';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get languageJa => '日本語';

  @override
  String get languageIt => 'Italiano';

  @override
  String get notifTitle => 'Daily check-in';

  @override
  String get notifBody => 'Don\'t forget to log your daily data!';

  @override
  String get notifChannelName => 'Daily reminder';

  @override
  String get notifChannelDescription => 'Once-daily reminder to log your day';

  @override
  String get featureSleepRating => 'Sleep';

  @override
  String get featureExerciseRating => 'Exercise';

  @override
  String get featureSchoolStressRating => 'School stress';

  @override
  String get featureScreenUsageRating => 'Screen time';

  @override
  String get featureMoodRating => 'Mood';

  @override
  String get featureEnergyRating => 'Energy';

  @override
  String get featureNutritionRating => 'Nutrition';

  @override
  String get featurePhysicalRating => 'Physical pain';

  @override
  String get featureSocialRating => 'Social';

  @override
  String get featureProductivityRating => 'Productivity';

  @override
  String get featureWaterRating => 'Water';

  @override
  String get featureCaffeineRating => 'Caffeine';

  @override
  String get featureAlcoholRating => 'Alcohol';

  @override
  String get featureSmokingRating => 'Smoking';

  @override
  String get featureMedicationTaken => 'Medication';

  @override
  String get featureWorkdayFlag => 'Workday';

  @override
  String get featureSleepRatingLow => 'poor';

  @override
  String get featureExerciseRatingLow => 'none';

  @override
  String get featureSchoolStressRatingLow => 'nothing special';

  @override
  String get featureScreenUsageRatingLow => 'no screens';

  @override
  String get featureMoodRatingLow => 'low';

  @override
  String get featureEnergyRatingLow => 'drained';

  @override
  String get featureNutritionRatingLow => 'poor';

  @override
  String get featurePhysicalRatingLow => 'none';

  @override
  String get featureSocialRatingLow => 'none';

  @override
  String get featureProductivityRatingLow => 'low';

  @override
  String get featureWaterRatingLow => 'almost none';

  @override
  String get featureCaffeineRatingLow => 'none';

  @override
  String get featureAlcoholRatingLow => 'none';

  @override
  String get featureSmokingRatingLow => 'none';

  @override
  String get featureMedicationTakenLow => 'no';

  @override
  String get featureWorkdayFlagLow => 'day off';

  @override
  String get featureSleepRatingHigh => 'great';

  @override
  String get featureExerciseRatingHigh => 'a lot';

  @override
  String get featureSchoolStressRatingHigh => 'very stressful';

  @override
  String get featureScreenUsageRatingHigh => 'heavy use';

  @override
  String get featureMoodRatingHigh => 'great';

  @override
  String get featureEnergyRatingHigh => 'energized';

  @override
  String get featureNutritionRatingHigh => 'great';

  @override
  String get featurePhysicalRatingHigh => 'severe';

  @override
  String get featureSocialRatingHigh => 'a lot';

  @override
  String get featureProductivityRatingHigh => 'high';

  @override
  String get featureWaterRatingHigh => 'a lot';

  @override
  String get featureCaffeineRatingHigh => 'a lot';

  @override
  String get featureAlcoholRatingHigh => 'a lot';

  @override
  String get featureSmokingRatingHigh => 'a lot';

  @override
  String get featureMedicationTakenHigh => 'yes';

  @override
  String get featureWorkdayFlagHigh => 'workday';

  @override
  String get featureSchoolStressRatingShort => 'Stress';

  @override
  String get featureScreenUsageRatingShort => 'Screen';
}

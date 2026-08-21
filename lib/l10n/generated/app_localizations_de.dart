// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navToday => 'Heute';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navStats => 'Statistiken';

  @override
  String get todaySettingsTooltip => 'Einstellungen';

  @override
  String get todaySaved => 'Gespeichert';

  @override
  String get todayCaughtUp => 'Du bist für heute auf dem neuesten Stand.';

  @override
  String get todayEdit => 'Eintrag bearbeiten';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get metricsHeader => 'Kennzahlen';

  @override
  String get noteLabel => 'Notiz (optional)';

  @override
  String get saveButton => 'Speichern';

  @override
  String get historyEmpty =>
      'Noch keine Einträge — erfasse heute im Tab „Heute“ oder tippe auf +, um einen vergangenen Tag nachzutragen.';

  @override
  String get historyAddTooltip => 'Tag hinzufügen oder bearbeiten';

  @override
  String get statsNotEnoughData =>
      'Erfasse mindestens zwei Tage, um deine Statistiken zu sehen.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-tägige Serie',
      one: '1-tägige Serie',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Erfasse einen Tag, um eine Serie zu starten';

  @override
  String get streakKeepGoing => 'Weiter so!';

  @override
  String statsAverages(String avg7, String avg30) {
    return '7-Tage-Ø: $avg7 · 30-Tage-Ø: $avg30';
  }

  @override
  String statsNormalizedAvg(String value) {
    return '$value / 10';
  }

  @override
  String statsFrequencyAvg(String days, String total) {
    return '$days / $total Tage';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsReminder => 'Tägliche Erinnerung';

  @override
  String get settingsReminderSubtitle =>
      'Mich an das Erfassen meines Tages erinnern';

  @override
  String get settingsReminderTime => 'Erinnerungszeit';

  @override
  String get settingsFeatures => 'Merkmale';

  @override
  String get settingsFeaturesSubtitle =>
      'Wähle, was du erfassen möchtest. Deaktivieren löscht keine vergangenen Daten.';

  @override
  String get settingsPermissionDenied =>
      'Aktiviere Benachrichtigungen in den Systemeinstellungen, um Erinnerungen zu erhalten';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

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
  String get notifTitle => 'Täglicher Check-in';

  @override
  String get notifBody => 'Vergiss nicht, deine täglichen Daten zu erfassen!';

  @override
  String get notifChannelName => 'Tägliche Erinnerung';

  @override
  String get notifChannelDescription =>
      'Tägliche Erinnerung zum Erfassen deines Tages';

  @override
  String get featureSleepRating => 'Schlaf';

  @override
  String get featureExerciseRating => 'Bewegung';

  @override
  String get featureSchoolStressRating => 'Schulstress';

  @override
  String get featureScreenUsageRating => 'Bildschirmzeit';

  @override
  String get featureMoodRating => 'Stimmung';

  @override
  String get featureEnergyRating => 'Energie';

  @override
  String get featureNutritionRating => 'Ernährung';

  @override
  String get featurePhysicalRating => 'Körperliche Schmerzen';

  @override
  String get featureSocialRating => 'Soziales';

  @override
  String get featureProductivityRating => 'Produktivität';

  @override
  String get featureWaterRating => 'Wasser';

  @override
  String get featureCaffeineRating => 'Koffein';

  @override
  String get featureAlcoholRating => 'Alkohol';

  @override
  String get featureSmokingRating => 'Rauchen';

  @override
  String get featureMedicationTaken => 'Medikamente';

  @override
  String get featureWorkdayFlag => 'Arbeitstag';

  @override
  String get featureSleepRatingLow => 'schlecht';

  @override
  String get featureExerciseRatingLow => 'keine';

  @override
  String get featureSchoolStressRatingLow => 'nichts Besonderes';

  @override
  String get featureScreenUsageRatingLow => 'keine Bildschirme';

  @override
  String get featureMoodRatingLow => 'niedrig';

  @override
  String get featureEnergyRatingLow => 'erschöpft';

  @override
  String get featureNutritionRatingLow => 'schlecht';

  @override
  String get featurePhysicalRatingLow => 'keine';

  @override
  String get featureSocialRatingLow => 'keine';

  @override
  String get featureProductivityRatingLow => 'niedrig';

  @override
  String get featureWaterRatingLow => 'fast nichts';

  @override
  String get featureCaffeineRatingLow => 'keine';

  @override
  String get featureAlcoholRatingLow => 'kein';

  @override
  String get featureSmokingRatingLow => 'kein';

  @override
  String get featureMedicationTakenLow => 'nein';

  @override
  String get featureWorkdayFlagLow => 'frei';

  @override
  String get featureSleepRatingHigh => 'sehr gut';

  @override
  String get featureExerciseRatingHigh => 'viel';

  @override
  String get featureSchoolStressRatingHigh => 'sehr stressig';

  @override
  String get featureScreenUsageRatingHigh => 'starke Nutzung';

  @override
  String get featureMoodRatingHigh => 'sehr gut';

  @override
  String get featureEnergyRatingHigh => 'energiegeladen';

  @override
  String get featureNutritionRatingHigh => 'sehr gut';

  @override
  String get featurePhysicalRatingHigh => 'stark';

  @override
  String get featureSocialRatingHigh => 'viel';

  @override
  String get featureProductivityRatingHigh => 'hoch';

  @override
  String get featureWaterRatingHigh => 'viel';

  @override
  String get featureCaffeineRatingHigh => 'viel';

  @override
  String get featureAlcoholRatingHigh => 'viel';

  @override
  String get featureSmokingRatingHigh => 'viel';

  @override
  String get featureMedicationTakenHigh => 'ja';

  @override
  String get featureWorkdayFlagHigh => 'Arbeitstag';

  @override
  String get featureSchoolStressRatingShort => 'Stress';

  @override
  String get featureScreenUsageRatingShort => 'Bildschirm';
}

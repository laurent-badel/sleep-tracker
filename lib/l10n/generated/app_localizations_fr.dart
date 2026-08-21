// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navHistory => 'Historique';

  @override
  String get navStats => 'Statistiques';

  @override
  String get todaySettingsTooltip => 'Réglages';

  @override
  String get todaySaved => 'Enregistré';

  @override
  String get metricsHeader => 'Mesures';

  @override
  String get noteLabel => 'Note (facultatif)';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get historyEmpty =>
      'Aucune entrée pour l\'instant — enregistrez aujourd\'hui depuis l\'onglet Aujourd\'hui, ou appuyez sur + pour ajouter un jour passé.';

  @override
  String get historyAddTooltip => 'Ajouter ou modifier un jour';

  @override
  String get statsNotEnoughData =>
      'Enregistrez au moins deux jours pour voir vos statistiques.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de série',
      one: '1 jour de série',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Enregistrez un jour pour commencer une série';

  @override
  String get streakKeepGoing => 'Continuez !';

  @override
  String statsAverages(String avg7, String avg30) {
    return 'Moy. 7 jours : $avg7 · Moy. 30 jours : $avg30';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsReminder => 'Rappel quotidien';

  @override
  String get settingsReminderSubtitle =>
      'Me rappeler d\'enregistrer ma journée';

  @override
  String get settingsReminderTime => 'Heure du rappel';

  @override
  String get settingsFeatures => 'Caractéristiques';

  @override
  String get settingsFeaturesSubtitle =>
      'Choisissez ce que vous voulez suivre. Désactiver ne supprime jamais les données passées.';

  @override
  String get settingsPermissionDenied =>
      'Activez les notifications dans les réglages système pour recevoir des rappels';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

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
  String get notifTitle => 'Enregistrement quotidien';

  @override
  String get notifBody =>
      'Notez votre sommeil, exercice, stress et temps d\'écran.';

  @override
  String get notifChannelName => 'Rappel quotidien';

  @override
  String get notifChannelDescription =>
      'Rappel quotidien pour enregistrer votre journée';

  @override
  String get featureSleepRating => 'Sommeil';

  @override
  String get featureExerciseRating => 'Exercice';

  @override
  String get featureSchoolStressRating => 'Stress scolaire';

  @override
  String get featureScreenUsageRating => 'Temps d\'écran';

  @override
  String get featureMoodRating => 'Humeur';

  @override
  String get featureEnergyRating => 'Énergie';

  @override
  String get featureNutritionRating => 'Nutrition';

  @override
  String get featurePhysicalRating => 'Douleur physique';

  @override
  String get featureSocialRating => 'Social';

  @override
  String get featureProductivityRating => 'Productivité';

  @override
  String get featureWaterRating => 'Eau';

  @override
  String get featureCaffeineRating => 'Caféine';

  @override
  String get featureAlcoholRating => 'Alcool';

  @override
  String get featureSmokingRating => 'Tabac';

  @override
  String get featureMedicationTaken => 'Médicament';

  @override
  String get featureWorkdayFlag => 'Jour de travail';

  @override
  String get featureSleepRatingLow => 'mauvais';

  @override
  String get featureExerciseRatingLow => 'aucun';

  @override
  String get featureSchoolStressRatingLow => 'rien de spécial';

  @override
  String get featureScreenUsageRatingLow => 'pas d\'écran';

  @override
  String get featureMoodRatingLow => 'mauvaise';

  @override
  String get featureEnergyRatingLow => 'épuisé';

  @override
  String get featureNutritionRatingLow => 'mauvaise';

  @override
  String get featurePhysicalRatingLow => 'aucune';

  @override
  String get featureSocialRatingLow => 'aucun';

  @override
  String get featureProductivityRatingLow => 'faible';

  @override
  String get featureWaterRatingLow => 'presque rien';

  @override
  String get featureCaffeineRatingLow => 'aucune';

  @override
  String get featureAlcoholRatingLow => 'aucun';

  @override
  String get featureSmokingRatingLow => 'aucun';

  @override
  String get featureMedicationTakenLow => 'non';

  @override
  String get featureWorkdayFlagLow => 'jour de repos';

  @override
  String get featureSleepRatingHigh => 'excellent';

  @override
  String get featureExerciseRatingHigh => 'beaucoup';

  @override
  String get featureSchoolStressRatingHigh => 'très stressant';

  @override
  String get featureScreenUsageRatingHigh => 'utilisation intensive';

  @override
  String get featureMoodRatingHigh => 'excellente';

  @override
  String get featureEnergyRatingHigh => 'énergique';

  @override
  String get featureNutritionRatingHigh => 'excellente';

  @override
  String get featurePhysicalRatingHigh => 'sévère';

  @override
  String get featureSocialRatingHigh => 'beaucoup';

  @override
  String get featureProductivityRatingHigh => 'élevée';

  @override
  String get featureWaterRatingHigh => 'beaucoup';

  @override
  String get featureCaffeineRatingHigh => 'beaucoup';

  @override
  String get featureAlcoholRatingHigh => 'beaucoup';

  @override
  String get featureSmokingRatingHigh => 'beaucoup';

  @override
  String get featureMedicationTakenHigh => 'oui';

  @override
  String get featureWorkdayFlagHigh => 'jour de travail';

  @override
  String get featureSchoolStressRatingShort => 'Stress';

  @override
  String get featureScreenUsageRatingShort => 'Écran';
}

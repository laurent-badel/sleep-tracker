// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navToday => 'Oggi';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navStats => 'Statistiche';

  @override
  String get todaySettingsTooltip => 'Impostazioni';

  @override
  String get todaySaved => 'Salvato';

  @override
  String get todayCaughtUp => 'Hai completato le registrazioni di oggi.';

  @override
  String get todayEdit => 'Modifica voce';

  @override
  String get cancel => 'Annulla';

  @override
  String get metricsHeader => 'Metriche';

  @override
  String get noteLabel => 'Nota (facoltativa)';

  @override
  String get saveButton => 'Salva';

  @override
  String get historyEmpty =>
      'Nessuna voce per ora — registra oggi dalla scheda Oggi, oppure tocca + per inserire un giorno passato.';

  @override
  String get historyAddTooltip => 'Aggiungi o modifica un giorno';

  @override
  String get statsNotEnoughData =>
      'Registra almeno due giorni per vedere le statistiche.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni di serie',
      one: '1 giorno di serie',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Registra un giorno per iniziare una serie';

  @override
  String get streakKeepGoing => 'Continua così!';

  @override
  String statsAverages(String avg7, String avg30) {
    return 'Media 7 g: $avg7 · Media 30 g: $avg30';
  }

  @override
  String statsNormalizedAvg(String value) {
    return '$value / 10';
  }

  @override
  String statsFrequencyAvg(String days, String total) {
    return '$days / $total giorni';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsReminder => 'Promemoria giornaliero';

  @override
  String get settingsReminderSubtitle =>
      'Ricordami di registrare la mia giornata';

  @override
  String get settingsReminderTime => 'Ora del promemoria';

  @override
  String get settingsFeatures => 'Caratteristiche';

  @override
  String get settingsFeaturesSubtitle =>
      'Scegli cosa tracciare. Disattivare non cancella mai i dati passati.';

  @override
  String get settingsPermissionDenied =>
      'Abilita le notifiche nelle impostazioni di sistema per ricevere promemoria';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Predefinito di sistema';

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
  String get notifTitle => 'Check-in giornaliero';

  @override
  String get notifBody =>
      'Non dimenticare di registrare i tuoi dati giornalieri!';

  @override
  String get notifChannelName => 'Promemoria giornaliero';

  @override
  String get notifChannelDescription =>
      'Promemoria giornaliero per registrare la tua giornata';

  @override
  String get featureSleepRating => 'Sonno';

  @override
  String get featureExerciseRating => 'Esercizio';

  @override
  String get featureSchoolStressRating => 'Stress scolastico';

  @override
  String get featureScreenUsageRating => 'Tempo sullo schermo';

  @override
  String get featureMoodRating => 'Umore';

  @override
  String get featureEnergyRating => 'Energia';

  @override
  String get featureNutritionRating => 'Alimentazione';

  @override
  String get featurePhysicalRating => 'Dolore fisico';

  @override
  String get featureSocialRating => 'Sociale';

  @override
  String get featureProductivityRating => 'Produttività';

  @override
  String get featureWaterRating => 'Acqua';

  @override
  String get featureCaffeineRating => 'Caffeina';

  @override
  String get featureAlcoholRating => 'Alcol';

  @override
  String get featureSmokingRating => 'Fumo';

  @override
  String get featureMedicationTaken => 'Farmaci';

  @override
  String get featureWorkdayFlag => 'Giorno lavorativo';

  @override
  String get featureSleepRatingLow => 'scarso';

  @override
  String get featureExerciseRatingLow => 'nessuno';

  @override
  String get featureSchoolStressRatingLow => 'niente di speciale';

  @override
  String get featureScreenUsageRatingLow => 'nessuno schermo';

  @override
  String get featureMoodRatingLow => 'basso';

  @override
  String get featureEnergyRatingLow => 'esausto';

  @override
  String get featureNutritionRatingLow => 'scarsa';

  @override
  String get featurePhysicalRatingLow => 'nessuno';

  @override
  String get featureSocialRatingLow => 'nessuno';

  @override
  String get featureProductivityRatingLow => 'bassa';

  @override
  String get featureWaterRatingLow => 'quasi niente';

  @override
  String get featureCaffeineRatingLow => 'nessuna';

  @override
  String get featureAlcoholRatingLow => 'nessuno';

  @override
  String get featureSmokingRatingLow => 'nessuno';

  @override
  String get featureMedicationTakenLow => 'no';

  @override
  String get featureWorkdayFlagLow => 'giorno libero';

  @override
  String get featureSleepRatingHigh => 'ottimo';

  @override
  String get featureExerciseRatingHigh => 'molto';

  @override
  String get featureSchoolStressRatingHigh => 'molto stressante';

  @override
  String get featureScreenUsageRatingHigh => 'uso intenso';

  @override
  String get featureMoodRatingHigh => 'ottimo';

  @override
  String get featureEnergyRatingHigh => 'energico';

  @override
  String get featureNutritionRatingHigh => 'ottima';

  @override
  String get featurePhysicalRatingHigh => 'grave';

  @override
  String get featureSocialRatingHigh => 'molto';

  @override
  String get featureProductivityRatingHigh => 'alta';

  @override
  String get featureWaterRatingHigh => 'molto';

  @override
  String get featureCaffeineRatingHigh => 'molto';

  @override
  String get featureAlcoholRatingHigh => 'molto';

  @override
  String get featureSmokingRatingHigh => 'molto';

  @override
  String get featureMedicationTakenHigh => 'sì';

  @override
  String get featureWorkdayFlagHigh => 'giorno lavorativo';

  @override
  String get featureSchoolStressRatingShort => 'Stress';

  @override
  String get featureScreenUsageRatingShort => 'Schermo';
}

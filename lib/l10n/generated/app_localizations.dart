import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
  ];

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @todaySettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get todaySettingsTooltip;

  /// No description provided for @todaySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get todaySaved;

  /// No description provided for @todayCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up for today.'**
  String get todayCaughtUp;

  /// No description provided for @todayEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get todayEdit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @metricsHeader.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get metricsHeader;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet — log today from the Today tab, or tap + to backfill a past day.'**
  String get historyEmpty;

  /// No description provided for @historyAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add or edit a day'**
  String get historyAddTooltip;

  /// No description provided for @statsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Log at least two days to see your stats.'**
  String get statsNotEnoughData;

  /// Streak card header. {count} is the number of consecutive days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String streakDays(int count);

  /// No description provided for @streakStartHint.
  ///
  /// In en, this message translates to:
  /// **'Log a day to start a streak'**
  String get streakStartHint;

  /// No description provided for @streakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it going!'**
  String get streakKeepGoing;

  /// Per-feature averages row. Values are pre-formatted strings (locale-aware decimal separator).
  ///
  /// In en, this message translates to:
  /// **'7-day avg: {avg7} · 30-day avg: {avg30}'**
  String statsAverages(String avg7, String avg30);

  /// Normalized 0-10 score for ordinal features (Phase 9b). {value} is pre-formatted with one decimal.
  ///
  /// In en, this message translates to:
  /// **'{value} / 10'**
  String statsNormalizedAvg(String value);

  /// Raw frequency for boolean/checkbox features (Phase 9b), e.g. 22 / 30 days.
  ///
  /// In en, this message translates to:
  /// **'{days} / {total} days'**
  String statsFrequencyAvg(String days, String total);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsReminder;

  /// No description provided for @settingsReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log my day'**
  String get settingsReminderSubtitle;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get settingsFeatures;

  /// No description provided for @settingsFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to track. Disabling never deletes past data.'**
  String get settingsFeaturesSubtitle;

  /// No description provided for @settingsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications in system settings to receive reminders'**
  String get settingsPermissionDenied;

  /// No description provided for @settingsExportHeader.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExportHeader;

  /// No description provided for @settingsExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get settingsExportButton;

  /// No description provided for @settingsExportPrivacyWarning.
  ///
  /// In en, this message translates to:
  /// **'Exported files are plain text and are not encrypted. They contain sensitive data like notes and medication logs.'**
  String get settingsExportPrivacyWarning;

  /// No description provided for @exportNoData.
  ///
  /// In en, this message translates to:
  /// **'No data to export yet.'**
  String get exportNoData;

  /// No description provided for @exportShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Daily Wellness Tracker Export'**
  String get exportShareSubject;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @languageDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageIt.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageIt;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get notifTitle;

  /// No description provided for @notifBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to log your daily data!'**
  String get notifBody;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Once-daily reminder to log your day'**
  String get notifChannelDescription;

  /// No description provided for @featureSleepRating.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get featureSleepRating;

  /// No description provided for @featureExerciseRating.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get featureExerciseRating;

  /// No description provided for @featureSchoolStressRating.
  ///
  /// In en, this message translates to:
  /// **'School stress'**
  String get featureSchoolStressRating;

  /// No description provided for @featureScreenUsageRating.
  ///
  /// In en, this message translates to:
  /// **'Screen time'**
  String get featureScreenUsageRating;

  /// No description provided for @featureMoodRating.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get featureMoodRating;

  /// No description provided for @featureEnergyRating.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get featureEnergyRating;

  /// No description provided for @featureNutritionRating.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get featureNutritionRating;

  /// No description provided for @featurePhysicalRating.
  ///
  /// In en, this message translates to:
  /// **'Physical pain'**
  String get featurePhysicalRating;

  /// No description provided for @featureSocialRating.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get featureSocialRating;

  /// No description provided for @featureProductivityRating.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get featureProductivityRating;

  /// No description provided for @featureWaterRating.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get featureWaterRating;

  /// No description provided for @featureCaffeineRating.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get featureCaffeineRating;

  /// No description provided for @featureAlcoholRating.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get featureAlcoholRating;

  /// No description provided for @featureSmokingRating.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get featureSmokingRating;

  /// No description provided for @featureMedicationTaken.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get featureMedicationTaken;

  /// No description provided for @featureWorkdayFlag.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get featureWorkdayFlag;

  /// No description provided for @featureSleepRatingLow.
  ///
  /// In en, this message translates to:
  /// **'poor'**
  String get featureSleepRatingLow;

  /// No description provided for @featureExerciseRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featureExerciseRatingLow;

  /// No description provided for @featureSchoolStressRatingLow.
  ///
  /// In en, this message translates to:
  /// **'nothing special'**
  String get featureSchoolStressRatingLow;

  /// No description provided for @featureScreenUsageRatingLow.
  ///
  /// In en, this message translates to:
  /// **'no screens'**
  String get featureScreenUsageRatingLow;

  /// No description provided for @featureMoodRatingLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get featureMoodRatingLow;

  /// No description provided for @featureEnergyRatingLow.
  ///
  /// In en, this message translates to:
  /// **'drained'**
  String get featureEnergyRatingLow;

  /// No description provided for @featureNutritionRatingLow.
  ///
  /// In en, this message translates to:
  /// **'poor'**
  String get featureNutritionRatingLow;

  /// No description provided for @featurePhysicalRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featurePhysicalRatingLow;

  /// No description provided for @featureSocialRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featureSocialRatingLow;

  /// No description provided for @featureProductivityRatingLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get featureProductivityRatingLow;

  /// No description provided for @featureWaterRatingLow.
  ///
  /// In en, this message translates to:
  /// **'almost none'**
  String get featureWaterRatingLow;

  /// No description provided for @featureCaffeineRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featureCaffeineRatingLow;

  /// No description provided for @featureAlcoholRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featureAlcoholRatingLow;

  /// No description provided for @featureSmokingRatingLow.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get featureSmokingRatingLow;

  /// No description provided for @featureMedicationTakenLow.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get featureMedicationTakenLow;

  /// No description provided for @featureWorkdayFlagLow.
  ///
  /// In en, this message translates to:
  /// **'day off'**
  String get featureWorkdayFlagLow;

  /// No description provided for @featureSleepRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'great'**
  String get featureSleepRatingHigh;

  /// No description provided for @featureExerciseRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureExerciseRatingHigh;

  /// No description provided for @featureSchoolStressRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'very stressful'**
  String get featureSchoolStressRatingHigh;

  /// No description provided for @featureScreenUsageRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'heavy use'**
  String get featureScreenUsageRatingHigh;

  /// No description provided for @featureMoodRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'great'**
  String get featureMoodRatingHigh;

  /// No description provided for @featureEnergyRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'energized'**
  String get featureEnergyRatingHigh;

  /// No description provided for @featureNutritionRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'great'**
  String get featureNutritionRatingHigh;

  /// No description provided for @featurePhysicalRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'severe'**
  String get featurePhysicalRatingHigh;

  /// No description provided for @featureSocialRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureSocialRatingHigh;

  /// No description provided for @featureProductivityRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get featureProductivityRatingHigh;

  /// No description provided for @featureWaterRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureWaterRatingHigh;

  /// No description provided for @featureCaffeineRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureCaffeineRatingHigh;

  /// No description provided for @featureAlcoholRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureAlcoholRatingHigh;

  /// No description provided for @featureSmokingRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'a lot'**
  String get featureSmokingRatingHigh;

  /// No description provided for @featureMedicationTakenHigh.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get featureMedicationTakenHigh;

  /// No description provided for @featureWorkdayFlagHigh.
  ///
  /// In en, this message translates to:
  /// **'workday'**
  String get featureWorkdayFlagHigh;

  /// No description provided for @featureSchoolStressRatingShort.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get featureSchoolStressRatingShort;

  /// No description provided for @featureScreenUsageRatingShort.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get featureScreenUsageRatingShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'generated/app_localizations.dart';

/// Localized display strings for features (spec §3, Phase 7).
///
/// `FeatureDef` holds keys only; these functions map a feature key to its
/// localized label / endpoint captions. Called only from the widget layer
/// (with an `AppLocalizations` from `AppLocalizations.of(context)`).
/// Unknown keys fail visibly (return the key itself / empty) rather than
/// silently showing the wrong text.

String featureLabel(AppLocalizations l, String key) => switch (key) {
      'sleepRating' => l.featureSleepRating,
      'exerciseRating' => l.featureExerciseRating,
      'schoolStressRating' => l.featureSchoolStressRating,
      'screenUsageRating' => l.featureScreenUsageRating,
      'moodRating' => l.featureMoodRating,
      'energyRating' => l.featureEnergyRating,
      'nutritionRating' => l.featureNutritionRating,
      'physicalRating' => l.featurePhysicalRating,
      'socialRating' => l.featureSocialRating,
      'productivityRating' => l.featureProductivityRating,
      'waterRating' => l.featureWaterRating,
      'caffeineRating' => l.featureCaffeineRating,
      'alcoholRating' => l.featureAlcoholRating,
      'smokingRating' => l.featureSmokingRating,
      'medicationTaken' => l.featureMedicationTaken,
      'workdayFlag' => l.featureWorkdayFlag,
      _ => key, // fail visible, not silent
    };

String featureLowCaption(AppLocalizations l, String key) => switch (key) {
      'sleepRating' => l.featureSleepRatingLow,
      'exerciseRating' => l.featureExerciseRatingLow,
      'schoolStressRating' => l.featureSchoolStressRatingLow,
      'screenUsageRating' => l.featureScreenUsageRatingLow,
      'moodRating' => l.featureMoodRatingLow,
      'energyRating' => l.featureEnergyRatingLow,
      'nutritionRating' => l.featureNutritionRatingLow,
      'physicalRating' => l.featurePhysicalRatingLow,
      'socialRating' => l.featureSocialRatingLow,
      'productivityRating' => l.featureProductivityRatingLow,
      'waterRating' => l.featureWaterRatingLow,
      'caffeineRating' => l.featureCaffeineRatingLow,
      'alcoholRating' => l.featureAlcoholRatingLow,
      'smokingRating' => l.featureSmokingRatingLow,
      'medicationTaken' => l.featureMedicationTakenLow,
      'workdayFlag' => l.featureWorkdayFlagLow,
      _ => '',
    };

String featureHighCaption(AppLocalizations l, String key) => switch (key) {
      'sleepRating' => l.featureSleepRatingHigh,
      'exerciseRating' => l.featureExerciseRatingHigh,
      'schoolStressRating' => l.featureSchoolStressRatingHigh,
      'screenUsageRating' => l.featureScreenUsageRatingHigh,
      'moodRating' => l.featureMoodRatingHigh,
      'energyRating' => l.featureEnergyRatingHigh,
      'nutritionRating' => l.featureNutritionRatingHigh,
      'physicalRating' => l.featurePhysicalRatingHigh,
      'socialRating' => l.featureSocialRatingHigh,
      'productivityRating' => l.featureProductivityRatingHigh,
      'waterRating' => l.featureWaterRatingHigh,
      'caffeineRating' => l.featureCaffeineRatingHigh,
      'alcoholRating' => l.featureAlcoholRatingHigh,
      'smokingRating' => l.featureSmokingRatingHigh,
      'medicationTaken' => l.featureMedicationTakenHigh,
      'workdayFlag' => l.featureWorkdayFlagHigh,
      _ => '',
    };

/// Compact label for the History row summary; falls back to the full label
/// for features without a dedicated short key.
String featureShortLabel(AppLocalizations l, String key) => switch (key) {
      'schoolStressRating' => l.featureSchoolStressRatingShort,
      'screenUsageRating' => l.featureScreenUsageRatingShort,
      _ => featureLabel(l, key),
    };

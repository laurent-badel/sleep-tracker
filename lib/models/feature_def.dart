import '../data/database.dart';

/// A single trackable feature (spec §3).
///
/// Display strings (label/captions) are deliberately **not** here — since
/// Phase 7 they live in ARB, resolved via `feature_strings.dart` in the widget
/// layer only (spec §0: no localized strings in const data).
///
/// [scaleLength] defines the input type (there is no separate "type" enum):
/// - `1` → checkbox
/// - `2` → switch
/// - `>=3` → circle-row picker (0 .. scaleLength-1)
class FeatureDef {
  final String key; // matches the Drift column name
  final int scaleLength;
  final bool defaultEnabled;

  const FeatureDef({
    required this.key,
    required this.scaleLength,
    this.defaultEnabled = false,
  });

  /// Extracts this feature's value from an entry, or null if not logged.
  int? getValue(DailyEntry e) => switch (key) {
        'sleepRating' => e.sleepRating,
        'exerciseRating' => e.exerciseRating,
        'schoolStressRating' => e.schoolStressRating,
        'screenUsageRating' => e.screenUsageRating,
        'moodRating' => e.moodRating,
        'energyRating' => e.energyRating,
        'nutritionRating' => e.nutritionRating,
        'physicalRating' => e.physicalRating,
        'socialRating' => e.socialRating,
        'productivityRating' => e.productivityRating,
        'waterRating' => e.waterRating,
        'caffeineRating' => e.caffeineRating,
        'alcoholRating' => e.alcoholRating,
        'smokingRating' => e.smokingRating,
        'medicationTaken' => e.medicationTaken,
        'workdayFlag' => e.workdayFlag,
        _ => null,
      };
}

/// The full fixed catalog (spec §3). Keys only — display strings are resolved
/// from ARB via `feature_strings.dart`. Original four are enabled by default so
/// existing users see zero behavior change; the rest opt in via Settings.
const allFeatures = <FeatureDef>[
  FeatureDef(
    key: 'sleepRating',
    scaleLength: 5,
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'exerciseRating',
    scaleLength: 5,
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'schoolStressRating',
    scaleLength: 5,
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'screenUsageRating',
    scaleLength: 5,
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'moodRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'energyRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'nutritionRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'physicalRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'socialRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'productivityRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'waterRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'caffeineRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'alcoholRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'smokingRating',
    scaleLength: 5,
  ),
  FeatureDef(
    key: 'medicationTaken',
    scaleLength: 2,
  ),
  FeatureDef(
    key: 'workdayFlag',
    scaleLength: 2,
  ),
];

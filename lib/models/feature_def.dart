import '../data/database.dart';

/// A single trackable feature (spec §3).
///
/// [scaleLength] defines the input type (there is no separate "type" enum):
/// - `1` → checkbox
/// - `2` → switch
/// - `>=3` → circle-row picker (0 .. scaleLength-1)
class FeatureDef {
  final String key; // matches the Drift column name
  final String label;
  final int scaleLength;
  final String lowCaption;
  final String highCaption;
  final bool defaultEnabled;

  const FeatureDef({
    required this.key,
    required this.label,
    required this.scaleLength,
    required this.lowCaption,
    required this.highCaption,
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

/// The full fixed catalog (spec §3). Original four are enabled by default so
/// existing users see zero behavior change; the rest opt in via Settings.
const allFeatures = <FeatureDef>[
  FeatureDef(
    key: 'sleepRating',
    label: 'Sleep',
    scaleLength: 5,
    lowCaption: 'poor',
    highCaption: 'great',
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'exerciseRating',
    label: 'Exercise',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'a lot',
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'schoolStressRating',
    label: 'School stress',
    scaleLength: 5,
    lowCaption: 'nothing special',
    highCaption: 'very stressful',
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'screenUsageRating',
    label: 'Screen time',
    scaleLength: 5,
    lowCaption: 'no screens',
    highCaption: 'heavy use',
    defaultEnabled: true,
  ),
  FeatureDef(
    key: 'moodRating',
    label: 'Mood',
    scaleLength: 5,
    lowCaption: 'low',
    highCaption: 'great',
  ),
  FeatureDef(
    key: 'energyRating',
    label: 'Energy',
    scaleLength: 5,
    lowCaption: 'drained',
    highCaption: 'energized',
  ),
  FeatureDef(
    key: 'nutritionRating',
    label: 'Nutrition',
    scaleLength: 5,
    lowCaption: 'poor',
    highCaption: 'great',
  ),
  FeatureDef(
    key: 'physicalRating',
    label: 'Physical pain',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'severe',
  ),
  FeatureDef(
    key: 'socialRating',
    label: 'Social',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'a lot',
  ),
  FeatureDef(
    key: 'productivityRating',
    label: 'Productivity',
    scaleLength: 5,
    lowCaption: 'low',
    highCaption: 'high',
  ),
  FeatureDef(
    key: 'waterRating',
    label: 'Water',
    scaleLength: 5,
    lowCaption: 'almost none',
    highCaption: 'a lot',
  ),
  FeatureDef(
    key: 'caffeineRating',
    label: 'Caffeine',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'a lot',
  ),
  FeatureDef(
    key: 'alcoholRating',
    label: 'Alcohol',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'a lot',
  ),
  FeatureDef(
    key: 'smokingRating',
    label: 'Smoking',
    scaleLength: 5,
    lowCaption: 'none',
    highCaption: 'a lot',
  ),
  FeatureDef(
    key: 'medicationTaken',
    label: 'Medication',
    scaleLength: 2,
    lowCaption: 'no',
    highCaption: 'yes',
  ),
  FeatureDef(
    key: 'workdayFlag',
    label: 'Workday',
    scaleLength: 2,
    lowCaption: 'day off',
    highCaption: 'workday',
  ),
];

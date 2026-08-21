import 'package:drift/drift.dart';

import 'database.dart';

/// Builds a [DailyEntriesCompanion] from the enabled features' ratings.
///
/// **`Value.absent()` rule (spec §2):** a feature not present in
/// [enabledRatings] uses `Value.absent()` — leave unchanged on conflict —
/// never `Value(null)`. If a user disables a feature and later re-enables it,
/// saves made while disabled must not silently null out historical values.
/// `note` uses `Value(null)` when empty (clearing is intentional there).
DailyEntriesCompanion buildEntryCompanion({
  required String date,
  required Map<String, int> enabledRatings,
  required String? note,
}) {
  Value<int> ratingVal(String key) => enabledRatings.containsKey(key)
      ? Value(enabledRatings[key]!)
      : const Value.absent();

  return DailyEntriesCompanion(
    date: Value(date),
    sleepRating: ratingVal('sleepRating'),
    exerciseRating: ratingVal('exerciseRating'),
    schoolStressRating: ratingVal('schoolStressRating'),
    screenUsageRating: ratingVal('screenUsageRating'),
    moodRating: ratingVal('moodRating'),
    energyRating: ratingVal('energyRating'),
    nutritionRating: ratingVal('nutritionRating'),
    physicalRating: ratingVal('physicalRating'),
    socialRating: ratingVal('socialRating'),
    productivityRating: ratingVal('productivityRating'),
    waterRating: ratingVal('waterRating'),
    caffeineRating: ratingVal('caffeineRating'),
    alcoholRating: ratingVal('alcoholRating'),
    smokingRating: ratingVal('smokingRating'),
    medicationTaken: ratingVal('medicationTaken'),
    workdayFlag: ratingVal('workdayFlag'),
    note: Value(note),
    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );
}

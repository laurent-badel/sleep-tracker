import 'package:flutter/foundation.dart';

import '../models/feature_def.dart';
import '../utils/prefs.dart';

/// Holds the globally-enabled feature set (spec §0: "Feature selection is
/// global, not per-entry"). Persisted in `shared_preferences` under
/// `enabled_features`; screens and view models watch this so the form, Stats,
/// and History stay in sync when the user toggles features in Settings.
class FeatureSettingsController extends ChangeNotifier {
  List<String> enabledKeys = const [];
  bool loaded = false;

  /// Loads the persisted set (or the catalog defaults on first run).
  Future<void> load() async {
    enabledKeys = await loadEnabledFeatureKeys();
    loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(String key, bool value) async {
    final next = {...enabledKeys};
    if (value) {
      next.add(key);
    } else {
      next.remove(key);
    }
    enabledKeys = next.toList()..sort();
    notifyListeners();
    await saveEnabledFeatureKeys(enabledKeys);
  }

  /// The enabled [FeatureDef]s in catalog order.
  List<FeatureDef> get enabledFeatures => [
        for (final f in allFeatures)
          if (enabledKeys.contains(f.key)) f,
      ];
}

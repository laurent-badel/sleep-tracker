import 'package:shared_preferences/shared_preferences.dart';

import '../models/feature_def.dart';

/// Keys for `shared_preferences` (reminders + enabled features + language,
/// spec §1 / Phase 8).
const reminderEnabledKey = 'reminder_enabled';
const reminderHourKey = 'reminder_hour';
const reminderMinuteKey = 'reminder_minute';
const enabledFeaturesKey = 'enabled_features';
const selectedLanguageKey = 'selected_language';

/// 'system' (default) or an explicit supported language code.
const systemLanguageCode = 'system';

/// The in-app language override. `'system'` = follow the device locale.
/// Defaults to [systemLanguageCode] when unset (Phase 8).
Future<String> loadSelectedLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(selectedLanguageKey) ?? systemLanguageCode;
}

Future<void> saveSelectedLanguage(String code) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(selectedLanguageKey, code);
}

/// The enabled feature keys. Defaults to the catalog's `defaultEnabled`
/// entries, computed once if the pref is unset (spec §3).
Future<List<String>> loadEnabledFeatureKeys() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getStringList(enabledFeaturesKey);
  if (stored != null) return stored;
  final defaults = [
    for (final f in allFeatures)
      if (f.defaultEnabled) f.key,
  ];
  await prefs.setStringList(enabledFeaturesKey, defaults);
  return defaults;
}

Future<void> saveEnabledFeatureKeys(List<String> keys) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(enabledFeaturesKey, keys);
}

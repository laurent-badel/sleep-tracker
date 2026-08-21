import '../../data/database.dart';
import '../../l10n/feature_strings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/feature_def.dart';

/// Shared compact summary of an entry's **enabled** features, used by the
/// History rows and the Today "caught up" card so the two can never drift
/// apart (spec Phase 9). Format: `"Sleep:4 Exercise:2 ..."` — localized short
/// label + value (`-` when not logged), space-separated.
String entrySummaryLine(
  DailyEntry entry,
  List<FeatureDef> enabled,
  AppLocalizations l,
) {
  return enabled
      .map((f) => '${featureShortLabel(l, f.key)}:${f.getValue(entry) ?? '-'}')
      .join(' ');
}

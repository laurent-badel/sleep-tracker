import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../l10n/feature_strings.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feature_def.dart';
import '../viewmodels/stats_view_model.dart';
import 'widgets/metric_chart.dart';

/// Tab 2 — streak card on top, then one card per **enabled** feature (spec §3,
/// layout closed). Each card: header, 30-day visualization, averages row.
/// `scaleLength >= 3` → bar chart; `scaleLength <= 2` → row of 30 small icons.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsViewModel>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStats)),
      body: !vm.loaded
          ? const Center(child: CircularProgressIndicator())
          : vm.entryCount < 2
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.statsNotEnoughData,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StreakCard(streak: vm.streak),
                    const SizedBox(height: 12),
                    for (final f in vm.features) ...[
                      _FeatureCard(
                        feature: f,
                        slots: vm.slots[f.key]!,
                        avg7: vm.avg7[f.key],
                        avg30: vm.avg30[f.key],
                        freq7: vm.freq7[f.key],
                        freq30: vm.freq30[f.key],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int? streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final s = streak; // local for null-promotion
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.local_fire_department,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          s == null ? '—' : l10n.streakDays(s),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          s == null ? l10n.streakStartHint : l10n.streakKeepGoing,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.slots,
    required this.avg7,
    required this.avg30,
    required this.freq7,
    required this.freq30,
  });

  final FeatureDef feature;
  final List<DailyEntry?> slots;
  final double? avg7;
  final double? avg30;
  final ({int ones, int logged})? freq7;
  final ({int ones, int logged})? freq30;

  // Locale-aware one-decimal formatting (e.g. "4,0" in de/fr, "4.0" in en).
  String _fmt(BuildContext context, double v) =>
      NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag())
          .format(v);

  /// One window's display value (spec Phase 9b):
  /// - ordinal (>=3): normalized 0–10 score via `{value} / 10`
  /// - boolean (<=2): raw frequency via `{days} / {total} days`
  /// - no data in either case: `—` alone (no suffix)
  String _windowValue(
    BuildContext context,
    AppLocalizations l10n,
    double? raw,
    ({int ones, int logged})? freq,
  ) {
    if (feature.scaleLength >= 3) {
      final norm = normalizeMeanTo10(raw, feature.scaleLength);
      if (norm == null) return '—';
      return l10n.statsNormalizedAvg(_fmt(context, norm));
    }
    if (freq == null) return '—';
    return l10n.statsFrequencyAvg('${freq.ones}', '${freq.logged}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(featureLabel(l10n, feature.key),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (feature.scaleLength >= 3)
              SizedBox(
                height: 72,
                width: double.infinity,
                child: CustomPaint(
                  painter: MetricChartPainter(
                    slots: slots,
                    ratingOf: feature.getValue,
                    scaleLength: feature.scaleLength,
                    filledColor: theme.colorScheme.primary,
                    gapColor: theme.colorScheme.surfaceContainerHighest,
                    axisLabelColor: theme.colorScheme.onSurfaceVariant,
                    axisLabelStyle: theme.textTheme.labelSmall ??
                        const TextStyle(fontSize: 10),
                  ),
                ),
              )
            else
              _BooleanRow(
                slots: slots,
                feature: feature,
                filledColor: theme.colorScheme.primary,
                gapColor: theme.colorScheme.surfaceContainerHighest,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.statsAverages(
                _windowValue(context, l10n, avg7, freq7),
                _windowValue(context, l10n, avg30, freq30),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 30 small icons for boolean/switch features (spec §3): filled circle for 1,
/// outlined for 0, gray stub for a missing day.
class _BooleanRow extends StatelessWidget {
  const _BooleanRow({
    required this.slots,
    required this.feature,
    required this.filledColor,
    required this.gapColor,
  });

  final List<DailyEntry?> slots;
  final FeatureDef feature;
  final Color filledColor;
  final Color gapColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          for (final slot in slots)
            Expanded(
              child: Center(
                child: () {
                  final v = slot == null ? null : feature.getValue(slot);
                  final Widget icon;
                  if (v == null) {
                    icon = Icon(Icons.remove, size: 12, color: gapColor);
                  } else if (v == 1) {
                    icon = Icon(Icons.check_circle, size: 14, color: filledColor);
                  } else {
                    icon = Icon(Icons.circle_outlined, size: 14, color: filledColor);
                  }
                  return icon;
                }(),
              ),
            ),
        ],
      ),
    );
  }
}

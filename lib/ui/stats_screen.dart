import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: !vm.loaded
          ? const Center(child: CircularProgressIndicator())
          : vm.entryCount < 2
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Log at least two days to see your stats.',
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
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.local_fire_department,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          streak == null ? '—' : '$streak-day streak',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          streak == null
              ? 'Log a day to start a streak'
              : 'Keep it going!',
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
  });

  final FeatureDef feature;
  final List<DailyEntry?> slots;
  final double? avg7;
  final double? avg30;

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feature.label, style: theme.textTheme.titleMedium),
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
              '7-day avg: ${_fmt(avg7)} · 30-day avg: ${_fmt(avg30)}',
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

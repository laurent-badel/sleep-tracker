import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../viewmodels/stats_view_model.dart';
import 'widgets/metric_chart.dart';

/// Tab 2 — streak card on top, then four metric cards (spec §3, layout
/// closed). Each metric card: header, 30-day bar chart, averages row.
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
                    for (final metric in Metric.values) ...[
                      _MetricCard(
                        metric: metric,
                        slots: vm.slots[metric]!,
                        avg7: vm.avg7[metric],
                        avg30: vm.avg30[metric],
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.slots,
    required this.avg7,
    required this.avg30,
  });

  final Metric metric;
  final List<DailyEntry?> slots;
  final double? avg7;
  final double? avg30;

  String _fmt(double? v) =>
      v == null ? '—' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metric.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              width: double.infinity,
              child: CustomPaint(
                painter: MetricChartPainter(
                  slots: slots,
                  ratingOf: metric.ratingOf,
                  filledColor: theme.colorScheme.primary,
                  gapColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
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

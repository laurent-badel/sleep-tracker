import 'package:flutter/material.dart';

import '../../data/database.dart';

/// Draws the 30 chart slots as vertical bars (spec §3).
///
/// Fixed y-scale 0–5 (no auto-scaling, so weeks are comparable):
/// bar height = `rating / 5 * availableHeight`. Missing days render as short
/// light-gray stubs so gaps stay visible. Colors are injected from `Theme` at
/// construction — never hardcoded (dark mode).
///
/// The metric is passed in as [ratingOf] (a `Metric.ratingOf` tear-off) so
/// this stays a single parameterized painter rather than one per metric.
class MetricChartPainter extends CustomPainter {
  MetricChartPainter({
    required this.slots,
    required this.ratingOf,
    required this.filledColor,
    required this.gapColor,
  });

  final List<DailyEntry?> slots; // length 30, ascending, today last
  final int Function(DailyEntry) ratingOf;
  final Color filledColor;
  final Color gapColor;

  static const _barGap = 1.0;
  static const _gapStubHeight = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth =
        (size.width - _barGap * (slots.length - 1)) / slots.length;
    final paint = Paint();

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final x = i * (barWidth + _barGap);

      if (slot == null) {
        paint.color = gapColor;
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            size.height - _gapStubHeight,
            barWidth,
            _gapStubHeight,
          ),
          paint,
        );
      } else {
        final h = ratingOf(slot) / 5 * size.height;
        paint.color = filledColor;
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MetricChartPainter old) =>
      old.slots != slots ||
      old.ratingOf != ratingOf ||
      old.filledColor != filledColor ||
      old.gapColor != gapColor;
}

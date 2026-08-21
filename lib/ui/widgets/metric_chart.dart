import 'package:flutter/material.dart';

import '../../data/database.dart';

/// Draws the 30 chart slots as vertical bars (spec §3).
///
/// Fixed y-scale 0..[scaleLength]-1 (no auto-scaling, so weeks are
/// comparable): bar height = `rating / (scaleLength - 1) * availableHeight`.
/// Missing days — and logged entries with a null value for this feature
/// (logged before the feature was enabled) — render as short gray stubs so
/// gaps stay visible. Colors are injected from `Theme` at construction —
/// never hardcoded (dark mode).
class MetricChartPainter extends CustomPainter {
  MetricChartPainter({
    required this.slots,
    required this.ratingOf,
    required this.scaleLength,
    required this.filledColor,
    required this.gapColor,
  });

  final List<DailyEntry?> slots; // length 30, ascending, today last
  final int? Function(DailyEntry) ratingOf;
  final int scaleLength;
  final Color filledColor;
  final Color gapColor;

  static const _barGap = 1.0;
  static const _gapStubHeight = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth =
        (size.width - _barGap * (slots.length - 1)) / slots.length;
    final paint = Paint();
    final maxValue = scaleLength - 1;

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final x = i * (barWidth + _barGap);
      final value = slot == null ? null : ratingOf(slot);

      if (value == null || maxValue <= 0) {
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
        final h = value / maxValue * size.height;
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
      old.scaleLength != scaleLength ||
      old.filledColor != filledColor ||
      old.gapColor != gapColor;
}

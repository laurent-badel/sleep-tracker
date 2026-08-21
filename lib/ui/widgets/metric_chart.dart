import 'package:flutter/material.dart';

import '../../data/database.dart';

/// Draws the 30 chart slots as vertical bars (spec §3 / Phase 9b).
///
/// **Ordinal features (`scaleLength >= 3`):** explicit 0–10 y-scale with
/// `0 / 5 / 10` tick labels on the left. Bar height = `rating / (scaleLength-1)
/// * chartHeight` — i.e. a normalized 0–10 score. Missing days — and logged
/// entries with a null value for this feature (logged before the feature was
/// enabled) — render as short gray stubs so gaps stay visible.
///
/// **Boolean/checkbox features (`scaleLength <= 2`):** the painter draws
/// nothing here; the caller renders the icon row (the 0–10 axis concept does
/// not apply — spec Phase 9b).
///
/// Colors are injected from `Theme` at construction — never hardcoded.
class MetricChartPainter extends CustomPainter {
  MetricChartPainter({
    required this.slots,
    required this.ratingOf,
    required this.scaleLength,
    required this.filledColor,
    required this.gapColor,
    required this.axisLabelColor,
    required this.axisLabelStyle,
  });

  final List<DailyEntry?> slots; // length 30, ascending, today last
  final int? Function(DailyEntry) ratingOf;
  final int scaleLength;
  final Color filledColor;
  final Color gapColor;
  final Color axisLabelColor;
  final TextStyle axisLabelStyle;

  static const _gapStubHeight = 4.0;
  static const _leftMargin = 24.0;
  static const _bottomMargin = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (scaleLength <= 2) {
      // Icon-row rendering lives in the caller; nothing to draw here.
      return;
    }

    final max = scaleLength - 1;
    final chartArea = Rect.fromLTWH(
      _leftMargin,
      0,
      size.width - _leftMargin,
      size.height - _bottomMargin,
    );

    // 0 / 5 / 10 axis ticks (left side).
    void tick(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: axisLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    tick('0', chartArea.bottom);
    tick('5', chartArea.center.dy);
    tick('10', chartArea.top);

    // Bars: normalized score / 10 * chartArea.height.
    final barWidth = chartArea.width / slots.length;
    final paint = Paint();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final x = chartArea.left + i * barWidth;
      final value = slot == null ? null : ratingOf(slot);

      final double h;
      if (value == null || max <= 0) {
        paint.color = gapColor;
        h = _gapStubHeight; // short stub for missing days
      } else {
        paint.color = filledColor;
        final normalized = (value / max) * 10.0;
        h = (normalized / 10.0) * chartArea.height;
      }
      canvas.drawRect(
        Rect.fromLTWH(x + 1, chartArea.bottom - h, barWidth - 2, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MetricChartPainter old) =>
      old.slots != slots ||
      old.ratingOf != ratingOf ||
      old.scaleLength != scaleLength ||
      old.filledColor != filledColor ||
      old.gapColor != gapColor ||
      old.axisLabelColor != axisLabelColor;
}

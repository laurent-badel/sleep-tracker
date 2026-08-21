import 'package:flutter/material.dart';

/// One reusable input for every feature type (spec §3), driven by
/// [scaleLength]:
/// - `1` → `CheckboxListTile`
/// - `2` → `SwitchListTile`
/// - `>=3` → the star picker (0 .. scaleLength-1). `Row` + `Expanded` cells
///   span the row so the caption row always matches its width — the old
///   `Wrap` shrink-wrapped while the captions expanded, detaching them on
///   wide/landscape screens. `ConstrainedBox` caps the width on large screens.
///
/// Star fill semantics are **frozen**: `i <= value` means a rating of 0 shows
/// one filled star (the universal 1–5-star convention — worst = 1 star, best =
/// all stars) — do not "fix" it to `i < value`. `Colors.amber` for filled
/// stars is the single documented exception to the "no hardcoded colors" rule
/// (spec §0 / Phase 9); empty stars use `colorScheme.onSurfaceVariant`.
class RatingPicker extends StatelessWidget {
  final String label;
  final String lowCaption; // e.g. 'none'
  final String highCaption; // e.g. 'a lot'
  final int scaleLength; // 1, 2, or >=3
  final int value; // 0 .. scaleLength-1
  final ValueChanged<int> onChanged;

  const RatingPicker({
    super.key,
    required this.label,
    required this.lowCaption,
    required this.highCaption,
    required this.scaleLength,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (scaleLength == 1) {
      return CheckboxListTile(
        title: Text(label),
        value: value == 1,
        onChanged: (v) => onChanged(v == true ? 1 : 0),
      );
    }
    if (scaleLength == 2) {
      return SwitchListTile(
        title: Text(label),
        subtitle: Text(value == 1 ? highCaption : lowCaption),
        value: value == 1,
        onChanged: (v) => onChanged(v ? 1 : 0),
      );
    }

    // Star picker for scaleLength >= 3 (spec Phase 9).
    final theme = Theme.of(context);
    const Color starFilled = Colors.amber; // documented exception (Phase 9)
    final Color starEmpty = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            Row(
              children: List.generate(
                scaleLength,
                (i) => Expanded(
                  child: IconButton(
                    // Include the metric label so TalkBack doesn't read N
                    // identical bare numbers (spec §3 accessibility).
                    tooltip: '$label $i',
                    icon: Icon(
                      i <= value ? Icons.star : Icons.star_border,
                      color: i <= value ? starFilled : starEmpty,
                    ),
                    onPressed: () => onChanged(i),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lowCaption, style: theme.textTheme.bodySmall),
                Text(highCaption, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// One reusable input for every feature type (spec §3), driven by
/// [scaleLength]:
/// - `1` → `CheckboxListTile`
/// - `2` → `SwitchListTile`
/// - `>=3` → the circle-row picker (0 .. scaleLength-1) in a `Wrap` — a plain
///   `Row` can overflow narrow phones once tap targets are counted.
///
/// Circle-row fill semantics are **frozen**: `i <= value` means value 0 shows
/// one filled circle — the filled circle marks the selected value, including
/// 0. Do not "fix" it to `i < value`.
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
    // Original circle-row picker for scaleLength >= 3.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          children: List.generate(
            scaleLength,
            (i) => IconButton(
              // Include the metric label so TalkBack doesn't read six
              // identical bare numbers (spec §3 accessibility requirement).
              tooltip: '$label $i',
              icon: Icon(
                i <= value ? Icons.circle : Icons.circle_outlined,
              ),
              onPressed: () => onChanged(i),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lowCaption, style: Theme.of(context).textTheme.bodySmall),
            Text(highCaption, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

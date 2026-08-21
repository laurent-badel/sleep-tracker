import 'package:flutter/material.dart';

/// One reusable picker for all four metrics (spec §3).
///
/// Six `IconButton`s (0–5) in a `Wrap` — a plain `Row` can overflow narrow
/// phones once tap targets are counted.
///
/// Fill semantics are **frozen**: `i <= value` means rating 0 shows one filled
/// circle — the filled circle marks the selected value, including 0. Do not
/// "fix" it to `i < value`.
class RatingPicker extends StatelessWidget {
  final String label;
  final String lowCaption; // e.g. 'none'
  final String highCaption; // e.g. 'a lot'
  final int value;
  final ValueChanged<int> onChanged;

  const RatingPicker({
    super.key,
    required this.label,
    required this.lowCaption,
    required this.highCaption,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          children: List.generate(
            6,
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

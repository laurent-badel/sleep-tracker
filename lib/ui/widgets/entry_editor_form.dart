import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/database.dart';
import 'rating_picker.dart';

/// One self-contained editor used full-screen on Today **and** inside the
/// History bottom sheet (spec §3).
///
/// Deliberately ViewModel-free: it owns its form state, seeded once in
/// `initState` from `initial`. Because seeding happens once, there is no
/// stream-vs-typist race to guard against. Build it with
/// `key: ValueKey(date)` so a date change discards the old `State` and
/// re-runs `initState` — free, race-free re-hydration.
class EntryEditorForm extends StatefulWidget {
  final String date; // the date being edited (today or historical)
  final DailyEntry? initial; // null → new entry: ratings default 0, note ''
  final Future<void> Function(DailyEntriesCompanion) onSave;
  final VoidCallback? onSaved; // e.g. SnackBar (Today) or Navigator.pop (History)

  const EntryEditorForm({
    super.key,
    required this.date,
    this.initial,
    required this.onSave,
    this.onSaved,
  });

  @override
  State<EntryEditorForm> createState() => _EntryEditorFormState();
}

class _EntryEditorFormState extends State<EntryEditorForm> {
  late int _sleepRating;
  late int _exerciseRating;
  late int _schoolStressRating;
  late int _screenUsageRating;
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _sleepRating = initial?.sleepRating ?? 0;
    _exerciseRating = initial?.exerciseRating ?? 0;
    _schoolStressRating = initial?.schoolStressRating ?? 0;
    _screenUsageRating = initial?.screenUsageRating ?? 0;
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    // Normalize the note: trim; store null if empty (never '').
    final note = _noteController.text.trim();

    // Clamp is the single enforcement point (spec Gotchas) — asserts are
    // compiled out in release, so this protects production.
    final companion = DailyEntriesCompanion(
      date: Value(widget.date),
      sleepRating: Value(_sleepRating.clamp(0, 5)),
      exerciseRating: Value(_exerciseRating.clamp(0, 5)),
      schoolStressRating: Value(_schoolStressRating.clamp(0, 5)),
      screenUsageRating: Value(_screenUsageRating.clamp(0, 5)),
      note: Value(note.isEmpty ? null : note), // Value(null) clears; never Value.absent()
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    await widget.onSave(companion);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Metrics', style: theme.textTheme.titleMedium),
                const Divider(height: 24),
                RatingPicker(
                  label: 'Sleep',
                  lowCaption: 'poor',
                  highCaption: 'great',
                  value: _sleepRating,
                  onChanged: (v) => setState(() => _sleepRating = v),
                ),
                const SizedBox(height: 16),
                RatingPicker(
                  label: 'Exercise',
                  lowCaption: 'none',
                  highCaption: 'a lot',
                  value: _exerciseRating,
                  onChanged: (v) => setState(() => _exerciseRating = v),
                ),
                const SizedBox(height: 16),
                RatingPicker(
                  label: 'School stress',
                  lowCaption: 'nothing special',
                  highCaption: 'very stressful',
                  value: _schoolStressRating,
                  onChanged: (v) => setState(() => _schoolStressRating = v),
                ),
                const SizedBox(height: 16),
                RatingPicker(
                  label: 'Screen time',
                  lowCaption: 'no screens',
                  highCaption: 'heavy use',
                  value: _screenUsageRating,
                  onChanged: (v) => setState(() => _screenUsageRating = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

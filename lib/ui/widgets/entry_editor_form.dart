import 'package:flutter/material.dart';

import '../../data/companion_builder.dart';
import '../../data/database.dart';
import '../../l10n/feature_strings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/feature_def.dart';
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
  final List<FeatureDef> features; // the currently-enabled features
  final Future<void> Function(DailyEntriesCompanion) onSave;
  final VoidCallback? onSaved; // e.g. SnackBar (Today) or Navigator.pop (History)
  // Phase 9: optional cancel — Today passes it on the Edit path to return to
  // the caught-up card; History omits it (dismiss = pop).
  final VoidCallback? onCancel;

  const EntryEditorForm({
    super.key,
    required this.date,
    this.initial,
    required this.features,
    required this.onSave,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<EntryEditorForm> createState() => _EntryEditorFormState();
}

class _EntryEditorFormState extends State<EntryEditorForm> {
  late final Map<String, int> _ratings; // key → 0 .. scaleLength-1
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _ratings = {
      for (final f in widget.features)
        f.key: (initial == null ? 0 : (f.getValue(initial) ?? 0))
            .clamp(0, f.scaleLength - 1),
    };
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

    // Clamp each rating to its scale before building the companion — the
    // single enforcement point (spec Gotchas); asserts are compiled out in
    // release, so this protects production.
    final clamped = {
      for (final f in widget.features)
        f.key: (_ratings[f.key] ?? 0).clamp(0, f.scaleLength - 1),
    };

    final companion = buildEntryCompanion(
      date: widget.date,
      enabledRatings: clamped,
      note: note.isEmpty ? null : note,
    );

    await widget.onSave(companion);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                Text(l10n.metricsHeader, style: theme.textTheme.titleMedium),
                const Divider(height: 24),
                for (final f in widget.features) ...[
                  RatingPicker(
                    label: featureLabel(l10n, f.key),
                    lowCaption: featureLowCaption(l10n, f.key),
                    highCaption: featureHighCaption(l10n, f.key),
                    scaleLength: f.scaleLength,
                    value: _ratings[f.key] ?? 0,
                    onChanged: (v) => setState(() => _ratings[f.key] = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.noteLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.saveButton),
              ),
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _saving ? null : widget.onCancel,
                child: Text(l10n.cancel),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

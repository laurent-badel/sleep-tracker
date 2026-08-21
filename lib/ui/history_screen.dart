import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feature_def.dart';
import '../utils/dates.dart';
import '../viewmodels/feature_settings_controller.dart';
import 'widgets/entry_editor_form.dart';
import 'widgets/entry_summary.dart';

/// Tab 1 — no ViewModel (spec §0): a `StreamBuilder` on `watchAll()`, with the
/// shared `EntryEditorForm` reused in a bottom sheet (pop on save). The FAB
/// backfills a past day (spec §3).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DailyRepository>();
    final features = context.watch<FeatureSettingsController>().enabledFeatures;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHistory)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditEntry(context, repo, features),
        tooltip: l10n.historyAddTooltip,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DailyEntry>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.historyEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryRow(
                entry: entry,
                features: features,
                onTap: () => _openEditor(context, repo, features, entry),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    DailyRepository repo,
    List<FeatureDef> features,
    DailyEntry entry,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        // Bottom viewInsets padding is required or the keyboard covers the
        // note field and Save button (spec §3).
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EntryEditorForm(
            key: ValueKey(
              '${entry.date}|${features.map((f) => f.key).join(',')}',
            ),
            date: entry.date,
            initial: entry,
            features: features,
            onSave: repo.upsert,
            onSaved: () => Navigator.pop(sheetContext), // pop after save
          ),
        ),
      ),
    );
  }

  Future<void> _addOrEditEntry(
    BuildContext context,
    DailyRepository repo,
    List<FeatureDef> features,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2020),
      lastDate: today, // can't log future days (spec §3)
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final pickedKey = dateKey(picked);
    final existing = await repo.getByDate(pickedKey);    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EntryEditorForm(
            key: ValueKey(
              '$pickedKey|${features.map((f) => f.key).join(',')}',
            ),
            date: pickedKey,
            initial: existing,
            features: features,
            onSave: repo.upsert,
            onSaved: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.features,
    required this.onTap,
  });

  final DailyEntry entry;
  final List<FeatureDef> features;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Display format — the ISO key stays storage-only (spec §3); locale-aware.
    final locale = Localizations.localeOf(context).toLanguageTag();
    final displayDate =
        DateFormat.MMMEd(locale).format(DateTime.parse(entry.date));
    final note = entry.note;

    // Compact summary via the shared helper (spec Phase 9) — same line as the
    // Today caught-up card, so they can't drift apart.
    final summary = entrySummaryLine(entry, features, l10n);

    return ListTile(
      onTap: onTap,
      title: Text(displayDate),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(summary, style: theme.textTheme.bodySmall),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.notes,
                    size: 16,
                    // Theme-derived — no hardcoded colors (spec Theme section).
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  // One-line ellipsized preview, not just the icon (spec §3).
                  Expanded(
                    child: Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

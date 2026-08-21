import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import 'widgets/entry_editor_form.dart';

/// Tab 1 — no ViewModel (spec §0): a `StreamBuilder` on `watchAll()`, with the
/// shared `EntryEditorForm` reused in a bottom sheet (pop on save).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DailyRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<DailyEntry>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No entries yet — log your first day from the Today tab.',
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
                onTap: () => _openEditor(context, repo, entry),
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
            key: ValueKey(entry.date),
            date: entry.date,
            initial: entry,
            onSave: repo.upsert,
            onSaved: () => Navigator.pop(sheetContext), // pop after save
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onTap});

  final DailyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Display format — the ISO key stays storage-only (spec §3).
    final displayDate = DateFormat.MMMEd().format(DateTime.parse(entry.date));
    final note = entry.note;

    return ListTile(
      onTap: onTap,
      title: Text(displayDate),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            'Sleep:${entry.sleepRating} Ex:${entry.exerciseRating} '
            'Stress:${entry.schoolStressRating} Screen:${entry.screenUsageRating}',
            style: theme.textTheme.bodySmall,
          ),
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

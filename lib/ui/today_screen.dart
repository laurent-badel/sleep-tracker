import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/daily_repository.dart';
import '../data/database.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feature_def.dart';
import '../viewmodels/feature_settings_controller.dart';
import '../viewmodels/today_view_model.dart';
import 'settings_screen.dart';
import 'widgets/entry_editor_form.dart';
import 'widgets/entry_summary.dart';

/// Tab 0 (spec §3 / Phase 9). The ViewModel owns the date + rollover; this
/// screen renders one of three states:
/// - not loaded → spinner
/// - today has an entry and not editing → "caught up" card (with Edit)
/// - otherwise → the entry form (blank on first-time logging; pre-seeded on
///   the Edit path, with Cancel to return)
///
/// The form is keyed on date + enabled-feature set so both a midnight
/// rollover *and* a feature-selection change discard the old `State` and
/// re-seed (free, race-free re-hydration).
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodayViewModel>();
    final repo = context.read<DailyRepository>();
    final features = context.watch<FeatureSettingsController>().enabledFeatures;
    final l10n = AppLocalizations.of(context);

    // Display uses a human-readable, locale-aware format; the ISO key stays
    // storage-only (spec §2 invariant).
    final locale = Localizations.localeOf(context).toLanguageTag();
    final displayDate =
        DateFormat.yMMMMd(locale).format(DateTime.parse(vm.today));

    return Scaffold(
      appBar: AppBar(
        title: Text(displayDate),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.todaySettingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(vm, repo, features, l10n),
    );
  }

  Widget _buildBody(
    TodayViewModel vm,
    DailyRepository repo,
    List<FeatureDef> features,
    AppLocalizations l10n,
  ) {
    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.currentEntry != null && !_editing) {
      return _CaughtUpCard(
        entry: vm.currentEntry!,
        features: features,
        onEdit: () => setState(() => _editing = true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EntryEditorForm(
        key: ValueKey(
          '${vm.today}|${features.map((f) => f.key).join(',')}',
        ),
        date: vm.today,
        initial: vm.currentEntry, // null → blank form; non-null → Edit path
        features: features,
        onSave: repo.upsert,
        onCancel: vm.currentEntry != null
            ? () => setState(() => _editing = false)
            : null, // nothing to return to on first-time logging
        onSaved: () {
          setState(() => _editing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.todaySaved)),
          );
        },
      ),
    );
  }
}

/// Phase 9: shown when today already has an entry (and we're not editing).
/// The summary is live-derived from the stream, so edits made from History
/// are reflected here without opening the form.
class _CaughtUpCard extends StatelessWidget {
  const _CaughtUpCard({
    required this.entry,
    required this.features,
    required this.onEdit,
  });

  final DailyEntry entry;
  final List<FeatureDef> features;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt,
                    size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(l10n.todayCaughtUp,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  entrySummaryLine(entry, features, l10n),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onEdit, child: Text(l10n.todayEdit)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

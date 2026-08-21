import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/daily_repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../viewmodels/feature_settings_controller.dart';
import '../viewmodels/today_view_model.dart';
import 'settings_screen.dart';
import 'widgets/entry_editor_form.dart';

/// Tab 0 (spec §3). The ViewModel owns the date + rollover; this screen just
/// renders it. The form is keyed on date + enabled-feature set so both a
/// midnight rollover *and* a feature-selection change discard the old `State`
/// and re-seed (free, race-free re-hydration).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

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
      body: !vm.loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EntryEditorForm(
                key: ValueKey(
                  '${vm.today}|${features.map((f) => f.key).join(',')}',
                ),
                date: vm.today,
                initial: vm.currentEntry,
                features: features,
                onSave: repo.upsert,
                onSaved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.todaySaved)),
                  );
                },
              ),
            ),
    );
  }
}

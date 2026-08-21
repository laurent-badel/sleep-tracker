import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/daily_repository.dart';
import '../viewmodels/today_view_model.dart';
import 'settings_screen.dart';
import 'widgets/entry_editor_form.dart';

/// Tab 0 (spec §3). The ViewModel owns the date + rollover; this screen just
/// renders it. The `ValueKey(vm.today)` re-seeds the form on midnight
/// rollover (free, race-free re-hydration).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodayViewModel>();
    final repo = context.read<DailyRepository>();

    // Display uses a human-readable format; the ISO key stays storage-only.
    final displayDate = DateFormat.yMMMMd().format(DateTime.parse(vm.today));

    return Scaffold(
      appBar: AppBar(
        title: Text(displayDate),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
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
                key: ValueKey(vm.today),
                date: vm.today,
                initial: vm.currentEntry,
                onSave: repo.upsert,
                onSaved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved')),
                  );
                },
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

import 'settings_screen.dart';

/// Phase 2 replaces the placeholder body with `EntryEditorForm` driven by
/// `TodayViewModel`. The gear action is final (spec §3).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
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
      body: const Center(child: Text('Today — Phase 2')),
    );
  }
}

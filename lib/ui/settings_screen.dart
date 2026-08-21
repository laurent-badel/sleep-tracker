import 'package:flutter/material.dart';

/// Phase 5 replaces the placeholder with the reminder toggle + time picker.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings — Phase 5')),
    );
  }
}

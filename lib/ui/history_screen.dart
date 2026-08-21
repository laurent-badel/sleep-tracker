import 'package:flutter/material.dart';

/// Phase 3 replaces the placeholder with a `StreamBuilder<List<DailyEntry>>`
/// on `watchAll()` plus the bottom-sheet editor (no ViewModel — spec §0).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('History — Phase 3')),
    );
  }
}

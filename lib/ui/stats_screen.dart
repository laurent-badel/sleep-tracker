import 'package:flutter/material.dart';

/// Phase 4 replaces the placeholder with streak + four metric cards driven by
/// `StatsViewModel`.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: const Center(child: Text('Stats — Phase 4')),
    );
  }
}

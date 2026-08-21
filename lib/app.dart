import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/history_screen.dart';
import 'ui/stats_screen.dart';
import 'ui/today_screen.dart';

/// Single source of truth for the selected bottom-nav tab.
///
/// Lives outside the widget tree so notification callbacks (which have no
/// `BuildContext`) can reach it, and is *also* provided into the tree so
/// widgets can observe it (spec §4).
class NavigationManager extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void navigateTo(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}

/// Global instance — notification callbacks (foreground, background, cold
/// start) all call `navigationManager.navigateTo(0)` on this.
final navigationManager = NavigationManager();

/// Root widget: the `MaterialApp` itself (spec §4 — MultiProvider sits above
/// it in `main()`; no second wrapper layer).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Wellness Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavigationManager>().index;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          TodayScreen(),
          HistoryScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: navigationManager.navigateTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

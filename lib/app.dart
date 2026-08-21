import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/history_screen.dart';
import 'ui/stats_screen.dart';
import 'ui/today_screen.dart';
import 'utils/prefs.dart';

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

/// In-app language override (Phase 8). `'system'` (default) follows the device
/// locale; otherwise one of the supported codes. A plain global like
/// [navigationManager] — the Settings screen writes it, `MaterialApp` listens
/// via [ValueListenableBuilder]. Persisted under `selected_language`.
final ValueNotifier<String> languagePreference = ValueNotifier(systemLanguageCode);

/// Root widget: the `MaterialApp` itself (spec §4 — MultiProvider sits above
/// it in `main()`; no second wrapper layer).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languagePreference,
      builder: (context, langCode, _) {
        // 'system' → null so Flutter falls back to supportedLocales resolution.
        final Locale? appLocale =
            langCode == systemLanguageCode ? null : Locale(langCode);
        return MaterialApp(
          // Brand name — stays untranslated (spec §0 frozen decision).
          title: 'Sleep Tracker',
          locale: appLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      },
    );
  }
}

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavigationManager>().index;
    final l10n = AppLocalizations.of(context);
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
        ],
      ),
    );
  }
}

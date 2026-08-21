# App Architecture: Daily Wellness Tracker (Sleep + Lifestyle) — Flutter

> **v6 — fully integrated spec.** This revision merges the original Flutter plan with two review passes.
>
> Changes vs. v5: closed the theme decision; confirmed `RatingPicker` fill semantics as permanent; dropped unused `watchRange` from DAO/Repository; explicit iOS foreground-presentation flags; closed the stats layout and history note-indicator decisions; added the Kotlin-DSL desugaring form + minSdk verification note; added template test replacement to Phase 1; closed the `Rating` value class question (skip it).
>
> Changes vs. the original Android-native translation (v4): merged the two competing `main()` functions; `TodayViewModel` computes its own date with a 60s rollover timer; `EntryEditorForm` contract with `ValueKey` re-seeding (replaces the hydration-flag workaround); `NavigationManager` defined and wired; `AppDatabase` exposes `dailyDao`; `POST_NOTIFICATIONS` manifest line; next-occurrence scheduling rule; `NotificationService` API with notification strings/ID/defaults; stats contracts (streak from full history, painter shape, calendar-window averages); version-pinning + verify-installed-source guidance.

## 0. Scope and frozen decisions

These are **closed** — do not re-litigate them during implementation:

- **Platforms:** Android + iOS only. The Drift setup below (`NativeDatabase` + `sqlite3_flutter_libs` + `path_provider`) does not compile for web; do not attempt to make it work there.
- **Navigation:** 3 bottom-nav destinations — Today, History, Stats. No `TabBar`, no router package.
- **State management split:** Today → `TodayViewModel` (owns date, subscription, rollover). History → **no ViewModel**; the screen consumes `watchAll()` directly via `StreamBuilder`. Stats → `StatsViewModel` (computes aggregates from one full-history subscription).
- **Reminders:** disabled by default; placeholder time 20:00 when first enabled.
- **Entry deletion:** out of scope for v1. There is no `delete` in the DAO/repository and no delete affordance in the UI. (Future work — don't invent a half-version of it.)
- **`watchRange`:** deliberately omitted — no v1 screen consumes it. Trivial to re-add via `isBetweenValues` if a future feature needs it.
- **`Rating` value class:** skipped in v1 — pickers and the form use raw `int`s; the clamp in `save()` is the single enforcement point.
- **Android minSdk:** 26 (Android 8.0+). Older Android versions are out of scope; this is a deliberate complexity cut. **Core library desugaring is still enabled** — `flutter_local_notifications`' AAR declares `requiresDesugaring=true` and AGP fails the build without it, even at minSdk 26. At API 26+ `java.time` is native, so desugaring is effectively a compile-time no-op (the desugar runtime never engages).
- **Backup/export, localization:** out of scope; English only.

## 1. Architecture Overview

- Pattern: Single `MaterialApp`, MVVM-lite via `ChangeNotifier` + `provider`.
- Flutter has no "Activity" concept — one Dart process hosts the whole widget tree.
- Structure:
  - `main.dart` → the single composition root: async init, dependency graph, `MultiProvider`, `runApp` (§4).
  - ViewModels → `TodayViewModel`, `StatsViewModel` only (see §0). Exposed via `ChangeNotifierProvider` created **at the root**.
  - `DailyRepository` → wraps the Drift DAO; thin pass-through for streams + `upsert`.
  - `NotificationService` → wraps `flutter_local_notifications` + `shared_preferences` reminder settings (§5).
- DI: manual instantiation, no `get_it`/`riverpod` — build everything in `main()` and hand it down via `Provider`.

**Folder layout** (keeps `part` files next to their parents, which Drift codegen requires):

<CODE lang="text">
lib/
  main.dart                 // composition root (single main(), §4)
  app.dart                  // App widget: root scaffold, NavigationBar + IndexedStack
  data/
    daily_entries_table.dart
    daily_dao.dart          // + daily_dao.g.dart (generated)
    database.dart           // + database.g.dart (generated)
    daily_repository.dart
  utils/
    dates.dart              // todayKey() helper — single definition, used by both VMs
  viewmodels/
    today_view_model.dart
    stats_view_model.dart
  services/
    notification_service.dart
  ui/
    today_screen.dart
    history_screen.dart
    stats_screen.dart
    settings_screen.dart
    widgets/
      entry_editor_form.dart
      rating_picker.dart
      metric_chart.dart
</CODE>

### Theme (closed)

- Material 3, `themeMode: ThemeMode.system`.
- `theme:` and `darkTheme:` both built from `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` — the template default seed; arbitrary, not worth revisiting.
- Every custom color (chart bars, gap stubs, note indicators) resolves via `Theme.of(context).colorScheme` — no hardcoded colors. This is what the §3 "painter colors from Theme" requirement depends on.

**Correctness note:** Compose's `Flow` gives Room queries automatic reactive re-emission for free. Flutter's `provider` does **not** — a `ChangeNotifier` only rebuilds listeners when you call `notifyListeners()`. Drift closes the gap on the DB side (its `.watch()` queries are genuinely reactive), but any widget that wants live updates must listen to a `Stream` (via `StreamBuilder`) or a `ChangeNotifier`, never a one-shot `Future`.

## 2. Data Layer (Drift)

Drift is the closest Flutter equivalent to Room: compile-time-checked schema, code generation, and native `Stream`-based reactive queries.

Add to `pubspec.yaml`:

<CODE lang="yaml">
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x
  path: ^1.x
  intl: ^0.19.x              # DateFormat for the ISO date keys; check current major (0.20 exists)
  provider: ^6.x
  flutter_local_notifications: ^18.x   # §5 — see pinning instruction below
  timezone: ^0.9.x           # check current major; required for zonedSchedule
  flutter_timezone: ^2.x     # check current major
  shared_preferences: ^2.x
dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
</CODE>

**Version discipline (agent instruction):** after `flutter pub get`, replace the carets above with the exact resolved versions. For `flutter_local_notifications` specifically: before writing any scheduling code, open the installed package source (`~/.pub-cache/hosted/pub.dev/flutter_local_notifications-<version>/lib/`) and verify the named parameters of `zonedSchedule` and the method names on `AndroidFlutterLocalNotificationsPlugin`. These signatures have shifted across recent majors — do not code from remembered signatures.

**Aside on `part` files:** the generated part directive must match the *current file's own name* — `database.dart` needs `part 'database.g.dart';`, `daily_dao.dart` needs `part 'daily_dao.g.dart';`. Both files need their own directive. Run `dart run build_runner build --delete-conflicting-outputs` (or `watch` during development) after any schema/DAO change.

### Table: DailyEntries

<CODE lang="dart">
import 'package:drift/drift.dart';

class DailyEntries extends Table {
  // ISO-8601 (yyyy-MM-dd), stored as TEXT primary key.
  TextColumn get date => text()();
  IntColumn get sleepRating => integer()();        // 0–5
  IntColumn get exerciseRating => integer()();     // 0–5, 0 = none, 5 = a lot
  IntColumn get schoolStressRating => integer()(); // 0–5, 0 = nothing special, 5 = very stressful
  IntColumn get screenUsageRating => integer()();  // 0–5, 0 = no screens, 5 = heavy screen use
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();          // epoch millis

  @override
  Set<Column> get primaryKey => {date};
}
</CODE>

**Invariant:** the TEXT primary key relies on ISO-8601 sorting correctly as a plain string — that's what makes `ORDER BY date` work. Never change the date-key format anywhere, including display code, and never build keys with `.toUtc()` (use local time; UTC keys shift by the timezone offset around midnight).

### Database

<CODE lang="dart">
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'daily_dao.dart';
import 'daily_entries_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [DailyEntries], daos: [DailyDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  late final dailyDao = DailyDao(this);   // AppContainer and callers use db.dailyDao

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'daily_wellness.sqlite')),
      );
    });
  }
}
</CODE>

`database.dart` imports `daily_dao.dart` (for `daos: [DailyDao]`) and `daily_dao.dart` imports `database.dart` (for `DatabaseAccessor<AppDatabase>`). This circular import is legal in Dart — don't "fix" it by merging the files.

### DAO

<CODE lang="dart">
import 'package:drift/drift.dart';
import 'database.dart';
import 'daily_entries_table.dart';

part 'daily_dao.g.dart';

@DriftAccessor(tables: [DailyEntries])
class DailyDao extends DatabaseAccessor<AppDatabase> with _$DailyDaoMixin {
  DailyDao(super.db);

  Future<void> upsert(DailyEntriesCompanion entry) =>
      into(dailyEntries).insertOnConflictUpdate(entry);

  Stream<DailyEntry?> watchByDate(String date) =>
      (select(dailyEntries)..where((t) => t.date.equals(date)))
          .watchSingleOrNull();

  Stream<List<DailyEntry>> watchAll() =>
      (select(dailyEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();
}
</CODE>

No `delete` method — deletion is out of scope (§0). No `watchRange` either — no v1 consumer; re-add via `isBetweenValues` only if a future feature needs it (§0).

### Repository

<CODE lang="dart">
class DailyRepository {
  final DailyDao dao;
  DailyRepository(this.dao);

  Stream<DailyEntry?> watchByDate(String date) => dao.watchByDate(date);
  Stream<List<DailyEntry>> watchAll() => dao.watchAll();
  Future<void> upsert(DailyEntriesCompanion entry) => dao.upsert(entry);
}
</CODE>

### Upsert semantics — `Value(...)` and the `Value.absent()` trap

`insertOnConflictUpdate` requires every non-nullable column — including the primary key `date` — to be wrapped in `Value(...)` on the companion. For nullable columns the distinction matters:

- `Value(null)` → **set to null** (this is how you clear a note).
- `Value.absent()` → **leave unchanged** on conflict. Never use `Value.absent()` in the upsert companion, or re-saving with a cleared note will silently keep the old value.

<CODE lang="dart">
final companion = DailyEntriesCompanion(
  date: Value(dateString),
  sleepRating: Value(sleepRating),
  exerciseRating: Value(exerciseRating),
  schoolStressRating: Value(schoolStressRating),
  screenUsageRating: Value(screenUsageRating),
  note: Value(note),   // Value(null) clears; never Value.absent() here
  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
);
await repository.upsert(companion);
</CODE>

### Reactive UI — per-screen consumption (decided)

- **Today:** `TodayViewModel` subscribes to `watchByDate(today)` persistently (§3).
- **History:** `StreamBuilder<List<DailyEntry>>` directly on `repository.watchAll()` inside the screen. No ViewModel.
- **Stats:** `StatsViewModel` subscribes to `repository.watchAll()` once and derives everything (§3).

## 3. UI Screens

### Shared widget: `EntryEditorForm` (the one contract that makes Today + History reuse work)

One self-contained `StatefulWidget` is used full-screen on Today **and** inside the History bottom sheet. It must **not** depend on any ViewModel — it owns its own form state, seeded once from the entry it's given:

<CODE lang="dart">
class EntryEditorForm extends StatefulWidget {
  final String date;                    // the date being edited (today or historical)
  final DailyEntry? initial;            // null → new entry: ratings default 0, note ''
  final Future<void> Function(DailyEntriesCompanion) onSave;
  final VoidCallback? onSaved;          // e.g. SnackBar (Today) or Navigator.pop (History)

  const EntryEditorForm({
    super.key,
    required this.date,
    this.initial,
    required this.onSave,
    this.onSaved,
  });
}
</CODE>

Its `State` holds four rating ints and a `TextEditingController`, all seeded in `initState` from `initial` (ratings 0, note `''` when null). Because seeding happens once in `initState`, there is no stream-vs-typist race to guard against. Save behavior:

1. Clamp each rating with `value.clamp(0, 5)`.
2. Normalize note: trim; store `null` if empty (never `''`).
3. Build the companion with `Value(...)` for every column including `updatedAt` (§2).
4. `await onSave(companion)`, then call `onSaved?.call()`.

The Save button is **always enabled** — zeros are valid values ("none"), so there is nothing to validate.

**The `ValueKey` trick:** build the form with `key: ValueKey(date)`. When the date changes (midnight rollover, or editing a different historical entry), Flutter discards the old `State` and re-runs `initState` with the new entry — free, race-free re-hydration.

**Known edge case (accepted for v1):** if today's entry is edited from the History sheet while the Today form holds unsaved local input, the Today form keeps its local values until its own next save (the later save wins; both screens are live-subscribed, so nothing goes stale after a save). If this ever matters, key the form on `ValueKey('${date}-${updatedAt}')` instead — any saved change re-seeds the form (values are identical after your own save, only the cursor resets).

### Today Screen (tab 0)

- Displays today's date (`DateFormat.yMMMMd()` or similar for display — the ISO key is for storage only).
- Gear icon in the app bar → `Navigator.push` to the Settings screen (§5).
- Body: `if (!vm.loaded) CircularProgressIndicator() else EntryEditorForm(key: ValueKey(vm.today), date: vm.today, initial: vm.currentEntry, onSave: repo.upsert, onSaved: () => SnackBar('Saved'))`.
- Wrap the column in a `SingleChildScrollView`; group the four pickers in a `Card` under a "Metrics" header (`ListTile`/`Text` + `Divider`).

**`TodayViewModel`** — computes its own date (never injected), handles midnight rollover with a periodic timer (lifecycle-resume alone would miss the app-stays-open-across-midnight case):

<CODE lang="dart">
class TodayViewModel extends ChangeNotifier {
  TodayViewModel(this._repo) {
    _subscribe();
    _rolloverTimer = Timer.periodic(const Duration(seconds: 60), (_) => checkRollover());
  }

  final DailyRepository _repo;
  String today = todayKey();          // utils/dates.dart — local time, never UTC
  DailyEntry? currentEntry;
  bool loaded = false;                // gate: don't build the form before first emission
  StreamSubscription<DailyEntry?>? _sub;
  Timer? _rolloverTimer;

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchByDate(today).listen((entry) {
      currentEntry = entry;
      loaded = true;
      notifyListeners();
    });
  }

  void checkRollover() {
    final t = todayKey();
    if (t == today) return;
    today = t;
    currentEntry = null;
    loaded = false;                   // Today screen shows spinner until new day's emission
    _subscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rolloverTimer?.cancel();
    super.dispose();
  }
}
</CODE>

**`RatingPicker`** — one reusable widget for all four metrics. Six `IconButton`s (0–5) in a `Wrap` (a plain `Row` can overflow narrow phones once tap targets are counted). The `i <= value` fill means rating 0 shows one filled circle. **Confirmed in pre-implementation review: this is intentional — the filled circle marks the selected value, including 0. Do not "fix" it to `i < value`.** Add endpoint captions under the row, and give every button a `tooltip`/`semanticLabel` so the picker isn't six unlabeled circles to TalkBack:

<CODE lang="dart">
class RatingPicker extends StatelessWidget {
  final String label;
  final String lowCaption;   // e.g. 'none'
  final String highCaption;  // e.g. 'a lot'
  final int value;
  final ValueChanged<int> onChanged;

  const RatingPicker({
    super.key,
    required this.label,
    required this.lowCaption,
    required this.highCaption,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          children: List.generate(6, (i) => IconButton(
            tooltip: '$i',
            icon: Icon(i <= value ? Icons.circle : Icons.circle_outlined),
            onPressed: () => onChanged(i),
          )),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lowCaption, style: Theme.of(context).textTheme.bodySmall),
          Text(highCaption, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ],
    );
  }
}
</CODE>

Captions per metric: sleep ("poor" / "great"), exercise ("none" / "a lot"), school stress ("nothing special" / "very stressful"), screen time ("no screens" / "heavy use").

### History Screen (tab 1)

- **No ViewModel.** The screen is a `StreamBuilder<List<DailyEntry>>` on `context.read<DailyRepository>().watchAll()`.
- Empty state: centered `Text('No entries yet — log your first day from the Today tab.')`.
- Row: date formatted for display via `DateFormat.MMMEd()` (e.g. "Wed, Aug 20" — the ISO key stays storage-only) + compact summary (`"Sleep:4 Ex:3 Stress:2 Screen:5"`) + note indicator when a note exists: a note icon **plus** a one-line ellipsized preview of the note text (not the icon alone). Today's row appears here too; that's fine — both screens are live-subscribed, so edits from either stay in sync.
- Tap a row → `showModalBottomSheet` containing the shared form:

<CODE lang="dart">
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
    child: SingleChildScrollView(
      child: EntryEditorForm(
        key: ValueKey(entry.date),
        date: entry.date,
        initial: entry,
        onSave: context.read<DailyRepository>().upsert,
        onSaved: () => Navigator.pop(sheetContext),   // pop after save
      ),
    ),
  ),
);
</CODE>

The `isScrollControlled` + bottom-inset padding is required or the keyboard covers the note field and Save button.

### Stats Screen (tab 2 — its own bottom-nav destination; decision closed)

**`StatsViewModel`** subscribes to `watchAll()` **once, over full history** — not a 30-day range query. The 30-day window applies only to the charts and averages; streaks must see the entire history or they silently cap at 30. The dataset is tiny (~365 rows/year), so a full-history subscription costs nothing.

Derived state, recomputed on each emission, then `notifyListeners()`:

- **Chart slots (per metric):** `List<DailyEntry?>` of length 30, **ascending** — index 0 is 29 days ago, index 29 is today; `null` = missing day. Built by generating the 30-date range and mapping query rows by date key (view-layer logic; Drift only returns rows that exist).
- **Averages (per metric):** rolling 7- and 30-day means over **calendar windows** including today, averaged only over days that have entries (gaps excluded from the denominator).
- **Streak:** consecutive days with any entry (rating values irrelevant), walking backward from today — or from yesterday if today has no entry yet — stopping at the first gap.

**Layout (closed):** streak card on top ("N-day streak", or "—" when none), then four metric cards — each with a metric-name header, the 30-day bar chart, and one averages row: `7-day avg: X.X · 30-day avg: X.X`, rendering "—" when the window has no data.

**Chart painter contract:** one parameterized `CustomPainter` (or one subclass per metric) drawing the 30 slots as vertical bars: fixed y-scale **0–5** (no auto-scaling, so weeks are comparable), bar height = `rating / 5 * availableHeight`, missing days as short light-gray bars so gaps stay visible. Colors are passed in from `Theme` at construction (don't hardcode — dark mode). Fixed height, full width, inside the scrollable column:

<CODE lang="dart">
class MetricChartPainter extends CustomPainter {
  MetricChartPainter({required this.slots, required this.filledColor, required this.gapColor});

  final List<DailyEntry?> slots; // length 30, ascending, today last
  final Color filledColor;
  final Color gapColor;

  // paint(): 30 bars, fixed 0–5 scale, gray stub for null slots

  @override
  bool shouldRepaint(covariant MetricChartPainter old) =>
      old.slots != slots ||
      old.filledColor != filledColor ||
      old.gapColor != gapColor;
}
</CODE>

**Don't forget `shouldRepaint`:** the default always-repaint wastes frames; naively returning `false` means charts never update when the stream emits. Compare exactly the fields the painter depends on, as above.

**Loading/empty states:** while the first emission hasn't arrived, show a spinner; with fewer than 2 days of data, show placeholder text instead of degenerate charts.

## 4. Navigation & the single composition root

- `NavigationBar` (Material 3) with **3 destinations**: Today, History, Stats. Decision closed — no sub-tabs.
- `IndexedStack` under the bar preserves each tab's scroll position and state across switches. Note it builds all children up front, so History's `StreamBuilder` is live even while you're on Today — fine at this scale.
- No router package needed; plain `Navigator.push` for the Settings screen.

### `NavigationManager` — single source of truth for the selected tab

Both the bottom nav (user taps) and the notification callbacks (§5, which have **no `BuildContext`**) must reach the same object, so it lives outside the widget tree as a plain global, and is *also* provided into the tree so widgets can observe it:

<CODE lang="dart">
class NavigationManager extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void navigateTo(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}

final navigationManager = NavigationManager(); // global instance
</CODE>

Root scaffold: `context.watch<NavigationManager>().index` drives both `NavigationBar.selectedIndex` and `IndexedStack.index`; bar taps call `navigationManager.navigateTo(i)`.

**Critical: where the ViewModels live.** If `TodayViewModel`/`StatsViewModel` were created inside their tab widgets, Flutter would tear them down on tree rebuilds, defeating `IndexedStack`. Instantiate them once, at the root, via `MultiProvider` above `MaterialApp` (below). History has no ViewModel (§0).

The `App` widget **is** the `MaterialApp` itself (root scaffold inside it); `MultiProvider` sits above it in `main()`. Don't introduce a second wrapper layer.

### The one and only `main()`

<CODE lang="dart">
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init is a hard prerequisite for zonedSchedule — it throws otherwise.
  // NOTE: initializeTimeZones() comes from package:timezone/data/latest.dart,
  // NOT from package:timezone/timezone.dart (two separate imports).
  tzdata.initializeTimeZones();
  try {
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (_) {
    // Keep tz.local rather than block startup on an exotic device.
  }

  // Notifications: plugin init, callbacks, then re-schedule from saved settings.
  final notifications = NotificationService();
  await notifications.init();
  await notifications.rescheduleFromSettings();

  // Cold start from a notification tap never fires the tap callbacks — check explicitly.
  if (await notifications.launchedByNotification()) {
    navigationManager.navigateTo(0); // Today
  }

  final container = AppContainer.create();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: container.repository),
        Provider.value(value: navigationManager),
        Provider.value(value: notifications),
        ChangeNotifierProvider(create: (_) => TodayViewModel(container.repository)),
        ChangeNotifierProvider(create: (_) => StatsViewModel(container.repository)),
      ],
      child: const App(),
    ),
  );
}
</CODE>

Keep this pre-`runApp` chain minimal and exception-safe (note the timezone try/catch): everything here delays first frame, and a weird device must not brick app launch.

### Manual DI container

<CODE lang="dart">
class AppContainer {
  final AppDatabase database;
  final DailyRepository repository;

  AppContainer._(this.database, this.repository);

  factory AppContainer.create() {
    final db = AppDatabase();
    final repo = DailyRepository(db.dailyDao);
    return AppContainer._(db, repo);
  }

  Future<void> dispose() => database.close();
}
</CODE>

Drift databases hold OS-level resources, so keep `dispose()` in place even though for a single-process app it rarely runs in practice.

## 5. Reminder & Notifications

This section cannot be a literal Kotlin→Dart translation — `AlarmManager`/`BroadcastReceiver`/`SCHEDULE_EXACT_ALARM` are Android-only. `flutter_local_notifications` provides the cross-platform abstraction.

### `NotificationService` API (Phase 1 stub, Phase 5 implementation)

<CODE lang="dart">
class NotificationService {
  static const notificationId = 1001;          // fixed ID → rescheduling replaces, never duplicates
  static const channelId = 'daily_reminder';
  static const channelName = 'Daily reminder';
  static const title = 'Daily check-in';
  static const body = 'Log your sleep, exercise, stress, and screen time.';

  Future<void> init();                          // plugin.initialize with both tap callbacks (§4 main runs this)
  Future<bool> requestPermissions();            // POST_NOTIFICATIONS on Android 13+ / UNUserNotificationCenter on iOS
  Future<void> scheduleReminder(int hour, int minute); // cancel + zonedSchedule next occurrence
  Future<void> cancel();
  Future<void> rescheduleFromSettings();        // read shared_preferences; schedule if enabled (idempotent)
  Future<bool> launchedByNotification();        // wraps getNotificationAppLaunchDetails
}
</CODE>

### Scheduling

Daily repeat via `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time`. **Compute the next occurrence explicitly** — don't rely on the plugin to advance a past time:

<CODE lang="dart">
Future<void> scheduleReminder(int hour, int minute) async {
  await cancel();
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));

  await _plugin.zonedSchedule(
    notificationId,
    title,
    body,
    scheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelName,
        channelDescription: 'Once-daily reminder to log your day',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,   // explicit — defaults have varied across plugin versions;
        presentSound: true,   // a daily reminder should show even if the app is foregrounded
      ),
    ),
    androidScheduleMode: mode,                    // see exact-alarm note below
    matchDateTimeComponents: DateTimeComponents.time,
    payload: 'today',
  );
}
</CODE>

The `payload: 'today'` is decorative in v1: all three tap callbacks ignore it and unconditionally `navigateTo(0)`. Keep it set as a hook for future per-payload routing.

**Verify this call against the installed package source before writing it.** Recent majors have reshuffled the schedule-mode parameters, and `uiLocalNotificationDateInterpretation` was removed in newer versions — old examples resurrect it and break the build. The notification channel is created implicitly the first time you schedule with these `AndroidNotificationDetails`; there is no separate startup call needed.

### Android exact alarms — default to inexact

A once-daily wellness reminder does not need to fire at the literal minute. Android 12+/14+ restrict `SCHEDULE_EXACT_ALARM` to genuine alarm/calendar apps; requesting it invites user friction and Play policy scrutiny. Default to `AndroidScheduleMode.inexactAllowWhileIdle` and only escalate with a concrete reason, checking the granted state first — the plugin does **not** throw when exact scheduling is silently denied, so never rely on try/catch:

<CODE lang="dart">
final androidImpl = _plugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
final exactAllowed = await androidImpl?.canScheduleExactNotifications() ?? false;
final mode = exactAllowed
    ? AndroidScheduleMode.exactAllowWhileIdle
    : AndroidScheduleMode.inexactAllowWhileIdle;
</CODE>

(Confirm `canScheduleExactNotifications()` against the pinned version — method names have shifted.) Do **not** declare `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` in the manifest while staying on the inexact path.

### Manifest, Gradle, plist

**AndroidManifest.xml — required even on the inexact path** (the runtime prompt alone is not enough on Android 13+):

<CODE lang="xml">
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
</CODE>

**minSdk 26 + core library desugaring (decision closed, verified by build).** `minSdk = 26` (Android 8.0+) cuts off old Android versions. Desugaring **stays enabled** because `flutter_local_notifications`' AAR metadata declares `requiresDesugaring=true` — `checkDebugAarMetadata` fails the build without it regardless of minSdk (verified: build failed with *"Dependency ':flutter_local_notifications' requires core library desugaring to be enabled"*). At API 26+ `java.time` is native, so this is a compile-time no-op. Keep the template's Java compatibility level (17) and apply both:

<CODE lang="kotlin">
// android/app/build.gradle.kts
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
    defaultConfig {
        minSdk = 26
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
</CODE>

**iOS:** nothing to add to `Info.plist` for local notifications — permission is runtime-only via the plugin. Don't invent plist keys.

### Permissions

Use the plugin's built-in methods — no `permission_handler` dependency needed:

- Android: `androidImpl?.requestNotificationsPermission()`
- iOS: `iosImpl?.requestPermissions(alert: true, badge: true, sound: true)`

**On denial:** still save the reminder setting, and show a snackbar ("Enable notifications in system settings to receive reminders") rather than blocking the toggle.

### Deep link — three entry points, all covered

1. **Foreground tap** → `onDidReceiveNotificationResponse`.
2. **Background/terminated tap** → `onDidReceiveBackgroundNotificationResponse`, which must be a **top-level or static** function annotated `@pragma('vm:entry-point')` (it runs in a separate isolate — no `BuildContext`, no touching widget state directly).
3. **Cold start from a notification** → `getNotificationAppLaunchDetails()` during startup, since a launching tap fires neither callback.

All three call `navigationManager.navigateTo(0)` on the global instance (§4) — never resolve anything through `Provider.of` inside them, since there may be no context to resolve from:

<CODE lang="dart">
void onNotificationResponse(NotificationResponse response) {
  navigationManager.navigateTo(0);
}

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  navigationManager.navigateTo(0);
}
</CODE>

### Boot, force-stop, and time changes

The plugin generally reschedules across reboot via its own receivers, but OEM battery-optimization variants are unreliable. Treat **`rescheduleFromSettings()` on every launch** (in `main()`, §4) as the source of truth — it's cheap and idempotent. It also self-heals after the user changes system time or travels across timezones.

### Settings screen

Minimal screen behind the gear icon on Today:

- `SwitchListTile` "Daily reminder" — **default: off**.
- Time row showing the current setting (default 20:00) → `showTimePicker`.
- On enable: request permissions first (see denial handling above); on time change or disable: `cancel()` then reschedule or leave cancelled.
- Persist via `shared_preferences` under explicit keys:

<CODE lang="dart">
static const _reminderEnabledKey = 'reminder_enabled';
static const _reminderHourKey = 'reminder_hour';
static const _reminderMinuteKey = 'reminder_minute';
</CODE>

## 6. Suggested Build Order (Phased Delivery)

### Phase 1 (Core Data + platform scaffolding)
- Drift table, DAO, database (with `dailyDao` accessor), repository; `build_runner` codegen.
- Verify with a throwaway test screen.
- **Also land the notification scaffolding now**: manifest permission, `minSdk = 26` + desugaring in Gradle (see §5 — the plugin's AAR metadata requires it), empty `NotificationService` stub — project-level config is easy to forget if bolted on in Phase 5.
- Replace the template `widget_test.dart` (counter test — it fails the moment `main.dart` changes) with a smoke test: app builds and the Today tab renders.
- Folder layout per §1.

### Phase 2 (Core UI)
- Today screen: `TodayViewModel` (date + rollover timer), `RatingPicker`, `EntryEditorForm` full-screen with the `ValueKey` pattern, save → snackbar.

### Phase 3 (History)
- `StreamBuilder` list + empty state + bottom-sheet reuse of `EntryEditorForm` (pop on save).

### Phase 4 (Stats)
- `StatsViewModel` (full-history subscription), averages, streak, `MetricChartPainter` ×4.

### Phase 5 (Notifications)
- Full `NotificationService`, permission requests, settings screen.

> Phases 1–3 form the core app; 4–5 can slip without blocking a usable daily-logging tool.

### Acceptance Criteria

- Saving from Today updates History and Stats automatically, with no manual refresh.
- Editing a **past entry from History** is reflected in Stats immediately.
- Leaving the app open across midnight shows the new date and an empty form within ~60s, without a restart.
- Clearing the note field and saving persists as empty — reopening the editor shows no stale note (regression test for the `Value.absent()` trap).
- The reminder fires at the chosen time — verify by temporarily scheduling 1–2 minutes ahead, not by waiting a day.
- If exact-alarm permission is denied, scheduling still succeeds via the inexact fallback rather than crashing or silently failing.
- Tapping the notification opens the Today tab from foreground, background, and cold start.
- Reboot or force-stop doesn't silently drop the reminder — it's rescheduled from saved settings on next launch if enabled.

## Implementation Notes & Gotchas

### Date/Time Handling
`utils/dates.dart` holds the single `todayKey()` definition: `DateFormat('yyyy-MM-dd').format(DateTime.now())` — **local time, never `.toUtc()`**. Keep `updatedAt` as `DateTime.now().millisecondsSinceEpoch`. No Dart-side desugaring concerns (the Gradle requirement in §5 is independent of your Dart code).

### Data Validation
Clamp all ratings with `value.clamp(0, 5)` **immediately before building the companion** in `EntryEditorForm.save()` — asserts are compiled out in release and upstream validation alone isn't a contract. **Skip the `Rating` value class in v1** (pickers and the form use raw ints); the clamp in save() is the single enforcement point.

### Streak Calculation
Language-agnostic: count consecutive days with any entry, walking backward from today (or yesterday if today has no entry yet), stopping at the first gap. Must run over **full history** (§3 Stats).

### Recommended tests (optional but cheap)
- DAO upsert/watch round-trip against `NativeDatabase.memory()` — including "clear note persists as null."
- Pure unit tests for streak, calendar-window averages, and rating clamping.
- Widget smoke test replacing the template counter test (app builds, Today visible).
- `flutter analyze` clean as a build gate.

## Summary of what changed vs. a literal translation

| Original (Android-native) | Flutter equivalent | Note |
|---|---|---|
| Room + `@Entity`/`@Dao` + `Flow` | Drift + `Table`/`@DriftAccessor` + `Stream` (`.watch()`) | Requires `build_runner` codegen like Room's annotation processor |
| Jetpack Compose | Flutter widgets | 1:1 conceptually |
| `AlarmManager` + `BroadcastReceiver` + `BOOT_COMPLETED` | `flutter_local_notifications` (`zonedSchedule`, inexact default) | Cross-platform plugin, not a literal translation |
| `NavDeepLinkBuilder` | Notification tap callbacks + `NavigationManager` | Three entry points; no `BuildContext` in callbacks |
| DataStore (Preferences) | `shared_preferences` | 1:1 conceptually |
| Manual DI via `AppContainer` + `ViewModelProvider.Factory` | Manual DI via `AppContainer` + `provider` | 1:1 conceptually |
| Compose `Canvas` | `CustomPainter` + `CustomPaint` | 1:1 conceptually |
| `ModalBottomSheet` | `showModalBottomSheet` | 1:1 conceptually |
| Per-screen ViewModel scoping (implicit in Nav Component) | ViewModels hoisted to `main()` via `MultiProvider`; History intentionally VM-free | IndexedStack state-preservation fails silently if you get this wrong |
| `AlarmManager.setExactAndAllowWhileIdle` | `AndroidScheduleMode.inexactAllowWhileIdle` default | Corrected — exact alarms restricted on Android 12+/14+ |
| (assumed) no desugaring | `minSdk 26` + desugaring | Plugin AAR metadata requires desugaring even at API 26 (build gate); at 26+ it's a compile-time no-op |
| (open) Stats placement / per-screen state pattern | **Closed:** 3rd nav item; Today VM, History StreamBuilder, Stats VM | Frozen decisions, §0 |
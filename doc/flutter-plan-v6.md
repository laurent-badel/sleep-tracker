# App Architecture: Daily Wellness Tracker (Sleep + Lifestyle) — Flutter

> **v8 — Configurable Feature Catalog + History Backfill.** 
>
> Changes vs. v6/v7: Integrated the Phase 6 addendum. Added a configurable feature catalog (16 predefined metrics, user-selectable via Settings). Generalized `RatingPicker` to support scales of any length, plus booleans (Switch) and checkboxes. Refactored `EntryEditorForm` and Stats to loop over enabled features. Added History screen backfill (FAB + date picker). 
>
> **Critical fixes applied to the addendum:** 
> 1. The original 4 columns *must* be changed to `.nullable()` in the Dart `DailyEntries` class for the schema migration to actually relax the NOT NULL constraint (the addendum missed this). 
> 2. Replaced the addendum's clunky `Map<String, Value>` bridge with a single `buildEntryCompanion` helper that safely handles `Value.absent()` for disabled features. 
> 3. Explicitly defined Stats rendering for `scaleLength <= 2` (icon rows instead of bar charts).
>
> **Carried over from v6 (notification fix, verified 2026-08-21):** the AndroidManifest must declare the plugin's scheduling receivers + `RECEIVE_BOOT_COMPLETED`. Since plugin v16 the plugin's own manifest only declares permissions — without the receivers, `zonedSchedule()` succeeds silently but the fired alarm has no receiver and **no notification ever appears** (bit us in testing: permission granted + reminder enabled + nothing arrived). See §5.

## 0. Scope and frozen decisions

These are **closed** — do not re-litigate them during implementation:

- **Platforms:** Android + iOS only. The Drift setup below (`NativeDatabase` + `sqlite3_flutter_libs` + `path_provider`) does not compile for web; do not attempt to make it work there.
- **Navigation:** 3 bottom-nav destinations — Today, History, Stats. No `TabBar`, no router package.
- **State management split:** Today → `TodayViewModel` (owns date, subscription, rollover). History → **no ViewModel**; the screen consumes `watchAll()` directly via `StreamBuilder`. Stats → `StatsViewModel` (computes aggregates from one full-history subscription).
- **Reminders:** disabled by default; placeholder time 20:00 when first enabled.
- **Entry deletion:** out of scope. There is no `delete` in the DAO/repository and no delete affordance in the UI.
- **Feature model:** every feature is defined by its `scaleLength`. `1` = checkbox, `2` = switch, `>=3` = circle-row picker. There is no separate "type" enum. No numeric/free-value features (e.g., exact water ounces) in this tier.
- **Feature selection is global, not per-entry.** One enabled-set in `shared_preferences`, applied app-wide. 
- **All ordinal features use `scaleLength: 5` (values 0–4).** Decided 2026-08-21 (overrides the earlier "original four stay 0–5" decision): 5 levels give a convenient midpoint (2) for qualitative judgments. The original four keep their *identity* (labels, captions, default-enabled) and are still never *reinterpreted* across feature keys — but their scale is now 5 like the rest of the catalog. Booleans stay `scaleLength: 2` (medication, workday). **Data note:** any previously logged value of 5 (from the old 0–5 era, test data only) clamps to 4 on the next edit; until re-saved it renders slightly tall in charts — no migration is performed for this semantic change.
- **No custom/user-defined features** (arbitrary types, EAV schema) — deliberately out of scope. Fixed-catalog only.
- **Android minSdk:** 26 (Android 8.0+). **Core library desugaring is still enabled** — `flutter_local_notifications`' AAR declares `requiresDesugaring=true` and AGP fails the build without it, even at minSdk 26. At API 26+ `java.time` is native, so desugaring is effectively a compile-time no-op.
- **Backup/export, localization:** out of scope; English only.

## 1. Architecture Overview

- Pattern: Single `MaterialApp`, MVVM-lite via `ChangeNotifier` + `provider`.
- Structure:
  - `main.dart` → the single composition root: async init, dependency graph, `MultiProvider`, `runApp` (§4).
  - ViewModels → `TodayViewModel`, `StatsViewModel` only (see §0). Exposed via `ChangeNotifierProvider` created **at the root**.
  - `DailyRepository` → wraps the Drift DAO; thin pass-through for streams + `upsert`.
  - `NotificationService` → wraps `flutter_local_notifications` + `shared_preferences` reminder settings (§5).
- DI: manual instantiation, no `get_it`/`riverpod` — build everything in `main()` and hand it down via `Provider`.

**Folder layout**:

<CODE lang="text">
lib/
  main.dart                 // composition root (single main(), §4)
  app.dart                  // App widget: root scaffold, NavigationBar + IndexedStack
  data/
    daily_entries_table.dart
    daily_dao.dart          // + daily_dao.g.dart (generated)
    database.dart           // + database.g.dart (generated)
    daily_repository.dart
    companion_builder.dart  // NEW: builds DailyEntriesCompanion from enabled features
  models/
    feature_def.dart        // NEW: FeatureDef class + allFeatures catalog
  utils/
    dates.dart              // todayKey() helper
    prefs.dart              // shared_preferences keys (reminders + enabled_features)
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
- `theme:` and `darkTheme:` both built from `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`.
- Every custom color resolves via `Theme.of(context).colorScheme` — no hardcoded colors.

## 2. Data Layer (Drift)

Add to `pubspec.yaml`:

<CODE lang="yaml">
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x
  path: ^1.x
  intl: ^0.19.x              
  provider: ^6.x
  flutter_local_notifications: ^18.x   
  timezone: ^0.9.x           
  flutter_timezone: ^2.x     
  shared_preferences: ^2.x
dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
</CODE>

**Version discipline:** Pin exact versions after `flutter pub get`. Verify `zonedSchedule` signatures against the installed `flutter_local_notifications` source before writing scheduling code.

### Table: DailyEntries

**CRITICAL:** The original 4 columns *must* be marked `.nullable()` here. If they remain non-nullable in the Dart class, the v2 migration will fail to relax the database constraint, and saves with disabled features will crash.

<CODE lang="dart">
import 'package:drift/drift.dart';

class DailyEntries extends Table {
  TextColumn get date => text()();
  
  // Original four — changed to nullable in v2 to support disabling features
  IntColumn get sleepRating => integer().nullable()();        
  IntColumn get exerciseRating => integer().nullable()();     
  IntColumn get schoolStressRating => integer().nullable()(); 
  IntColumn get screenUsageRating => integer().nullable()();  
  
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();          

  // New catalog features (all nullable, null = not logged/disabled)
  IntColumn get moodRating => integer().nullable()();
  IntColumn get energyRating => integer().nullable()();
  IntColumn get nutritionRating => integer().nullable()();
  IntColumn get physicalRating => integer().nullable()();
  IntColumn get socialRating => integer().nullable()();
  IntColumn get productivityRating => integer().nullable()();
  IntColumn get waterRating => integer().nullable()();
  IntColumn get caffeineRating => integer().nullable()();
  IntColumn get alcoholRating => integer().nullable()();
  IntColumn get smokingRating => integer().nullable()();
  IntColumn get medicationTaken => integer().nullable()();   // 0/1
  IntColumn get workdayFlag => integer().nullable()();     // 0/1

  @override
  Set<Column> get primaryKey => {date};
}
</CODE>

### Database & Migration

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 1. Add new nullable columns
        await m.addColumn(dailyEntries, dailyEntries.moodRating);
        await m.addColumn(dailyEntries, dailyEntries.energyRating);
        await m.addColumn(dailyEntries, dailyEntries.nutritionRating);
        await m.addColumn(dailyEntries, dailyEntries.physicalRating);
        await m.addColumn(dailyEntries, dailyEntries.socialRating);
        await m.addColumn(dailyEntries, dailyEntries.productivityRating);
        await m.addColumn(dailyEntries, dailyEntries.waterRating);
        await m.addColumn(dailyEntries, dailyEntries.caffeineRating);
        await m.addColumn(dailyEntries, dailyEntries.alcoholRating);
        await m.addColumn(dailyEntries, dailyEntries.smokingRating);
        await m.addColumn(dailyEntries, dailyEntries.medicationTaken);
        await m.addColumn(dailyEntries, dailyEntries.workdayFlag);

        // 2. Relax NOT NULL on original 4 columns.
        // Drift's TableMigration automatically rebuilds the table to match 
        // the current Dart schema (which now defines them as .nullable()).
        // No explicit columnTransformer is needed for pass-through columns.
        await m.alterTable(TableMigration(dailyEntries));
      }
    },
  );

  late final dailyDao = DailyDao(this);

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

**Migration testing:** Test this explicitly against a copy of a real v1-schema database with existing rows. Confirm after upgrade: all four original columns kept their values, all twelve new columns are null on old rows, and a save with any original-four feature disabled succeeds.

### DAO & Repository

<CODE lang="dart">
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
      (select(dailyEntries)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<DailyEntry?> getByDate(String date) =>
      (select(dailyEntries)..where((t) => t.date.equals(date)))
          .getSingleOrNull();
}

class DailyRepository {
  final DailyDao dao;
  DailyRepository(this.dao);

  Stream<DailyEntry?> watchByDate(String date) => dao.watchByDate(date);
  Stream<List<DailyEntry>> watchAll() => dao.watchAll();
  Future<void> upsert(DailyEntriesCompanion entry) => dao.upsert(entry);
  Future<DailyEntry?> getByDate(String date) => dao.getByDate(date);
}
</CODE>

### Companion Builder & `Value.absent()` semantics

Because Dart has no reflection, we can't dynamically construct `DailyEntriesCompanion` from a map. Instead, use a single builder function that maps enabled features to `Value(...)` and disabled/missing features to `Value.absent()`. 

**Rule:** Disabled features *must* use `Value.absent()` (leave unchanged on conflict), never `Value(null)`. If a user disables "mood" temporarily and later re-enables it, saves made while it was disabled must not silently null out historical mood values.

<CODE lang="dart">
// data/companion_builder.dart
import 'package:drift/drift.dart';
import 'daily_entries_table.dart';

DailyEntriesCompanion buildEntryCompanion({
  required String date,
  required Map<String, int> enabledRatings,
  required String? note,
}) {
  Value<int> ratingVal(String key) =>
      enabledRatings.containsKey(key) ? Value(enabledRatings[key]!) : const Value.absent();

  return DailyEntriesCompanion(
    date: Value(date),
    sleepRating: ratingVal('sleepRating'),
    exerciseRating: ratingVal('exerciseRating'),
    schoolStressRating: ratingVal('schoolStressRating'),
    screenUsageRating: ratingVal('screenUsageRating'),
    moodRating: ratingVal('moodRating'),
    energyRating: ratingVal('energyRating'),
    nutritionRating: ratingVal('nutritionRating'),
    physicalRating: ratingVal('physicalRating'),
    socialRating: ratingVal('socialRating'),
    productivityRating: ratingVal('productivityRating'),
    waterRating: ratingVal('waterRating'),
    caffeineRating: ratingVal('caffeineRating'),
    alcoholRating: ratingVal('alcoholRating'),
    smokingRating: ratingVal('smokingRating'),
    medicationTaken: ratingVal('medicationTaken'),
    workdayFlag: ratingVal('workdayFlag'),
    note: Value(note),
    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );
}
</CODE>

## 3. UI Screens & Feature Catalog

### `FeatureDef` Catalog

<CODE lang="dart">
// models/feature_def.dart
class FeatureDef {
  final String key;            // matches the Drift column name
  final String label;
  final int scaleLength;       // 1 = checkbox, 2 = switch, >=3 = picker
  final String lowCaption;
  final String highCaption;
  final bool defaultEnabled;

  const FeatureDef({
    required this.key, required this.label, required this.scaleLength,
    required this.lowCaption, required this.highCaption, this.defaultEnabled = false,
  });
}

const allFeatures = <FeatureDef>[
  // Original four — enabled by default so existing users see zero behavior change.
  FeatureDef(key: 'sleepRating', label: 'Sleep', scaleLength: 5, lowCaption: 'poor', highCaption: 'great', defaultEnabled: true),
  FeatureDef(key: 'exerciseRating', label: 'Exercise', scaleLength: 5, lowCaption: 'none', highCaption: 'a lot', defaultEnabled: true),
  FeatureDef(key: 'schoolStressRating', label: 'School stress', scaleLength: 5, lowCaption: 'nothing special', highCaption: 'very stressful', defaultEnabled: true),
  FeatureDef(key: 'screenUsageRating', label: 'Screen time', scaleLength: 5, lowCaption: 'no screens', highCaption: 'heavy use', defaultEnabled: true),

  // New catalog — off by default, user opts in via Settings.
  FeatureDef(key: 'moodRating', label: 'Mood', scaleLength: 5, lowCaption: 'low', highCaption: 'great'),
  FeatureDef(key: 'energyRating', label: 'Energy', scaleLength: 5, lowCaption: 'drained', highCaption: 'energized'),
  FeatureDef(key: 'nutritionRating', label: 'Nutrition', scaleLength: 5, lowCaption: 'poor', highCaption: 'great'),
  FeatureDef(key: 'physicalRating', label: 'Physical pain', scaleLength: 5, lowCaption: 'none', highCaption: 'severe'),
  FeatureDef(key: 'socialRating', label: 'Social', scaleLength: 5, lowCaption: 'none', highCaption: 'a lot'),
  FeatureDef(key: 'productivityRating', label: 'Productivity', scaleLength: 5, lowCaption: 'low', highCaption: 'high'),
  FeatureDef(key: 'waterRating', label: 'Water', scaleLength: 5, lowCaption: 'almost none', highCaption: 'a lot'),
  FeatureDef(key: 'caffeineRating', label: 'Caffeine', scaleLength: 5, lowCaption: 'none', highCaption: 'a lot'),
  FeatureDef(key: 'alcoholRating', label: 'Alcohol', scaleLength: 5, lowCaption: 'none', highCaption: 'a lot'),
  FeatureDef(key: 'smokingRating', label: 'Smoking', scaleLength: 5, lowCaption: 'none', highCaption: 'a lot'),
  FeatureDef(key: 'medicationTaken', label: 'Medication', scaleLength: 2, lowCaption: 'no', highCaption: 'yes'),
  FeatureDef(key: 'workdayFlag', label: 'Workday', scaleLength: 2, lowCaption: 'day off', highCaption: 'workday'),
];
</CODE>

**Enabled-set storage:** `shared_preferences`, key `enabled_features`, stored as a `List<String>` (via `getStringList`). Default = the four `defaultEnabled: true` entries, computed once if the pref is unset.

### Shared widget: `EntryEditorForm`

Contract (`date`, `initial`, `onSave`, `onSaved`) is **unchanged**. Internals change:
- `State` holds `Map<String, int> ratings` instead of four named ints.
- Seeded in `initState` by iterating **enabled** `FeatureDef`s and pulling each value via `getFeatureValue(initial, key) ?? 0`.
- Renders one `RatingPicker` per enabled `FeatureDef`, in catalog order.
- Save: clamps each rating to `scaleLength - 1`, builds the companion via `buildEntryCompanion`, and calls `onSave`.

### `RatingPicker` — generalized by `scaleLength`

<CODE lang="dart">
class RatingPicker extends StatelessWidget {
  final String label;
  final String lowCaption;
  final String highCaption;
  final int scaleLength;   // 1, 2, or >=3
  final int value;         // 0 .. scaleLength-1
  final ValueChanged<int> onChanged;

  const RatingPicker({
    super.key, required this.label, required this.lowCaption, 
    required this.highCaption, required this.scaleLength, 
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (scaleLength == 1) {
      return CheckboxListTile(
        title: Text(label),
        value: value == 1,
        onChanged: (v) => onChanged(v == true ? 1 : 0),
      );
    }
    if (scaleLength == 2) {
      return SwitchListTile(
        title: Text(label),
        subtitle: Text(value == 1 ? highCaption : lowCaption),
        value: value == 1,
        onChanged: (v) => onChanged(v ? 1 : 0),
      );
    }
    // Original circle-row picker for scaleLength >= 3
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          children: List.generate(scaleLength, (i) => IconButton(
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

### Today Screen (tab 0)

- Displays today's date. Gear icon → Settings.
- Body: `EntryEditorForm(key: ValueKey(vm.today), date: vm.today, initial: vm.currentEntry, ...)`.
- `TodayViewModel` unchanged (computes date, 60s rollover timer, subscribes to `watchByDate`).

### History Screen (tab 1)

- `StreamBuilder<List<DailyEntry>>` on `watchAll()`.
- Empty state: `Text('No entries yet — log today from the Today tab, or tap + to backfill a past day.')`.
- Row: date + compact summary of *enabled* features + note indicator.
- Tap row → bottom sheet with `EntryEditorForm`.

**Backfill (FAB):**

<CODE lang="dart">
floatingActionButton: FloatingActionButton(
  onPressed: () => _addOrEditEntry(context),
  child: const Icon(Icons.add),
),

Future<void> _addOrEditEntry(BuildContext context) async {
  final today = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: today,
    firstDate: DateTime(2020),
    lastDate: today,          // can't log future days
  );
  if (picked == null) return;

  final dateKey = DateFormat('yyyy-MM-dd').format(picked); 
  final repo = context.read<DailyRepository>();
  final existing = await repo.getByDate(dateKey);

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: SingleChildScrollView(
        child: EntryEditorForm(
          key: ValueKey(dateKey), date: dateKey, initial: existing,
          onSave: repo.upsert, onSaved: () => Navigator.pop(sheetContext),
        ),
      ),
    ),
  );
}
</CODE>

### Stats Screen (tab 2)

`StatsViewModel` subscribes to `watchAll()` over full history. Replaces hardcoded 4 cards with a loop over currently-enabled `FeatureDef`s.

- **Averages:** unchanged math (mean over 7/30-day calendar windows, gaps excluded).
- **Streak:** unchanged (consecutive days with *any* entry).
- **Chart rendering:**
  - For `scaleLength >= 3`: Use `MetricChartPainter`. Bar height = `rating / (scaleLength - 1) * availableHeight`.
  - For `scaleLength <= 2` (booleans/checkboxes): Do *not* use vertical bars. Render a `Row` of 30 small icons (e.g., `Icons.check_circle` for 1, `Icons.circle_outlined` for 0, gray stub for null).

<CODE lang="dart">
class MetricChartPainter extends CustomPainter {
  MetricChartPainter({
    required this.slots, required this.ratingOf, 
    required this.scaleLength, required this.filledColor, required this.gapColor,
  });

  final List<DailyEntry?> slots; 
  final int Function(DailyEntry) ratingOf;
  final int scaleLength;
  final Color filledColor;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    // bar height = (ratingOf(entry) / (scaleLength - 1)) * size.height
  }

  @override
  bool shouldRepaint(covariant MetricChartPainter old) =>
      old.slots != slots || old.ratingOf != ratingOf || 
      old.scaleLength != scaleLength || old.filledColor != filledColor || old.gapColor != gapColor;
}
</CODE>

## 4. Navigation & the single composition root

- `NavigationBar` with 3 destinations. `IndexedStack` preserves state.
- `NavigationManager` global instance drives tab index.
- `main()` initializes timezones, `NotificationService`, and `MultiProvider`. (See v6 spec for full `main()` and `AppContainer` code — unchanged).

## 5. Reminder & Notifications

`NotificationService` (API + `init` with both tap callbacks), the `zonedSchedule` next-occurrence scheduling, the inexact-alarm fallback, the iOS `DarwinInitializationSettings` permission-suppression, and the Gradle desugaring config are unchanged from v6 — keep that code as-is.

**AndroidManifest.xml — receivers are REQUIRED (verified against the installed v22.3.0 README, 2026-08-21).** Since plugin v16 the plugin's own manifest only declares `VIBRATE`/`POST_NOTIFICATIONS`. Without the receivers below, `zonedSchedule()` succeeds silently but the fired alarm has no receiver → **no notification ever appears** (real-world symptom: permission granted, reminder enabled, nothing arrives). This is the exact fix from the v6 testing session — do not remove these:

<CODE lang="xml">
<!-- Permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<!-- Required so the plugin can reschedule notifications across reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
...
<application ...>
  <!-- Receivers: without these, scheduled notifications silently never fire -->
  <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
  <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
      <action android:name="android.intent.action.BOOT_COMPLETED"/>
      <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
      <action android:name="android.intent.action.QUICKBOOT_POWERON" />
      <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
  </receiver>
</application>
</CODE>

Do **not** declare `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` while on the inexact path.

### Settings screen

Minimal screen behind the gear icon on Today:

1. **Reminders section:** `SwitchListTile` "Daily reminder" + time picker. Persisted via `NotificationService`.
2. **Features section (NEW):** A list of `CheckboxListTile`s, one per `FeatureDef` in `allFeatures`. Toggling updates the `enabled_features` `List<String>` in `shared_preferences`. No confirmation dialog (disabling never deletes data, per `Value.absent()` rule).

## 6. Suggested Build Order (Phased Delivery)

### Phase 1 (Core Data + platform scaffolding)
- Drift table (v1 schema), DAO, database, repository.
- Notification scaffolding: manifest, `minSdk = 26` + desugaring, `NotificationService` stub.
- Smoke test.

### Phase 2 (Core UI)
- Today screen: `TodayViewModel`, `RatingPicker` (hardcoded 4), `EntryEditorForm`.

### Phase 3 (History)
- `StreamBuilder` list + bottom-sheet reuse of `EntryEditorForm`.

### Phase 4 (Stats)
- `StatsViewModel`, averages, streak, `MetricChartPainter` ×4.

### Phase 5 (Notifications)
- Full `NotificationService`, permission requests, settings screen (reminders only).

### Phase 6 (Configurable Features + Backfill)
- **Schema migration (v1→v2):** Change original 4 columns to `.nullable()` in Dart, add 12 new nullable columns. Write `onUpgrade` with `m.addColumn` and `m.alterTable(TableMigration(...))`. **Test against real v1 data.**
- **Catalog:** Add `FeatureDef`, `allFeatures`, and `buildEntryCompanion`.
- **Generalize UI:** Update `RatingPicker` for `scaleLength` branches. Update `EntryEditorForm` to use `Map<String, int>` and loop over enabled features.
- **Settings:** Add feature-selection section.
- **Stats:** Loop over enabled features, add `scaleLength` to painter, add icon-row rendering for `scaleLength <= 2`.
- **History:** Add `getByDate`, FAB, and backfill flow. Update empty state text.

### Acceptance Criteria

- Saving from Today updates History and Stats automatically.
- Leaving the app open across midnight shows the new date and an empty form within ~60s.
- Clearing the note field and saving persists as empty.
- The reminder fires at the chosen time (test by scheduling 1 min ahead).
- Tapping the notification opens the Today tab from foreground, background, and cold start.
- **v6 Additions:** Upgrading a v1 database preserves all existing rows/values; new columns are null. Disabling a feature, then re-enabling it, does not lose previously logged values (confirms `Value.absent()`). Toggling a feature off removes it from Stats and the form. Backfilling a past date via the History FAB creates the row and reflects it in Stats immediately. Date picker cannot select future dates.

## Implementation Notes & Gotchas

### Date/Time Handling
`utils/dates.dart`: `DateFormat('yyyy-MM-dd').format(DateTime.now())` — **local time, never `.toUtc()`**.

### Data Validation
Clamp all ratings with `value.clamp(0, scaleLength - 1)` immediately before building the companion in `EntryEditorForm.save()`. 

### Streak Calculation
Count consecutive days with *any* entry (any non-null feature or note), walking backward from today (or yesterday if today has no entry yet), stopping at the first gap. Must run over **full history**.

## Summary of what changed vs. a literal translation

| Original (Android-native) | Flutter equivalent | Note |
|---|---|---|
| Room + `@Entity`/`@Dao` + `Flow` | Drift + `Table`/`@DriftAccessor` + `Stream` (`.watch()`) | Requires `build_runner` codegen |
| Jetpack Compose | Flutter widgets | 1:1 conceptually |
| `AlarmManager` + `BroadcastReceiver` | `flutter_local_notifications` (`zonedSchedule`, inexact default) | Cross-platform plugin |
| `NavDeepLinkBuilder` | Notification tap callbacks + `NavigationManager` | Three entry points; no `BuildContext` in callbacks |
| DataStore (Preferences) | `shared_preferences` | 1:1 conceptually |
| Manual DI via `AppContainer` | Manual DI via `AppContainer` + `provider` | 1:1 conceptually |
| Compose `Canvas` | `CustomPainter` + `CustomPaint` | 1:1 conceptually |
| `ModalBottomSheet` | `showModalBottomSheet` | 1:1 conceptually |
| Per-screen ViewModel scoping | ViewModels hoisted to `main()` via `MultiProvider` | IndexedStack state-preservation fails silently if wrong |
| `AlarmManager.setExactAndAllowWhileIdle` | `AndroidScheduleMode.inexactAllowWhileIdle` default | Exact alarms restricted on Android 12+/14+ |
| (assumed) no desugaring | `minSdk 26` + desugaring | Plugin AAR metadata requires desugaring |
| (open) Stats placement | **Closed:** 3rd nav item; Today VM, History StreamBuilder, Stats VM | Frozen decisions, §0 |
| Hardcoded 4 metrics | `FeatureDef` catalog + `scaleLength` + `Value.absent()` | Dynamic form/stats, safe disablement |
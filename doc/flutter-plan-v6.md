# App Architecture: Daily Wellness Tracker (Sleep + Lifestyle) — Flutter

> **v9 — Internationalization (Phase 7).**
>
> Changes vs. v8: added Phase 7 i18n — `flutter_localizations` + gen_l10n ARB pipeline (en template + fr/de/ja/it); extracted all UI strings; moved feature labels/captions out of the const `FeatureDef` catalog into ARB via a `feature_strings.dart` bridge; locale-aware display date/number formatting; localized notification strings via `lookupAppLocalizations`. Frozen: system-driven locale (no in-app picker this phase), brand name untranslated, storage formats never localized, localization resolution only in the widget layer.
>
> Changes vs. v6/v7 (v8): Integrated the Phase 6 addendum. Added a configurable feature catalog (16 predefined metrics, user-selectable via Settings). Generalized `RatingPicker` to support scales of any length, plus booleans (Switch) and checkboxes. Refactored `EntryEditorForm` and Stats to loop over enabled features. Added History screen backfill (FAB + date picker).
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
- **Backup/export:** out of scope. **Localization:** in scope as of Phase 7 — `en` (template), `fr`, `de`, `ja`, `it`.
- **Locale resolution:** system-driven by default, with an in-app override via the Settings language picker (Phase 8). Saved as `selected_language` ('system' or an explicit code); 'system' = follow the device locale.
- **App brand name stays untranslated** — `MaterialApp.title` remains a constant.
- **Storage formats are never localized:** ISO `yyyy-MM-dd` date keys and epoch-millis `updatedAt` are fixed patterns. Only *display* formatting is locale-aware.
- **Localization resolution happens only in the widget layer** (where a `BuildContext` exists). ViewModels, `NotificationService`, and const data (`FeatureDef`) never hold localized strings.

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
    companion_builder.dart  // builds DailyEntriesCompanion from enabled features
  models/
    feature_def.dart        // FeatureDef class + allFeatures catalog (keys only, no display strings)
  l10n/                     // NEW (Phase 7)
    app_en.arb              // template
    app_fr.arb
    app_de.arb
    app_ja.arb
    app_it.arb
    feature_strings.dart    // feature key -> localized label/low/high switches
    untranslated.txt        // gen_l10n gap report; must be empty before shipping
    generated/              // gen_l10n output (app_localizations*.dart) — never hand-edited
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
  intl: <PINNED — see alignment rule below>
  provider: ^6.x
  flutter_local_notifications: ^18.x
  timezone: ^0.9.x
  flutter_timezone: ^2.x
  shared_preferences: ^2.x
  flutter_localizations:          # NEW (Phase 7)
    sdk: flutter
dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x

flutter:
  generate: true                  # NEW (Phase 7) — runs gen-l10n as part of builds
</CODE>

**Version discipline:** Pin exact versions after `flutter pub get`. Verify `zonedSchedule` signatures against the installed `flutter_local_notifications` source before writing scheduling code.

**`intl` alignment rule (Phase 7 trap):** `flutter_localizations` pins `intl` to an *exact* version. A direct `intl` dependency with a conflicting caret will fail `pub get` or produce analyzer/behavior mismatches. Procedure: add `flutter_localizations`, run `flutter pub get`, read the resolved `intl` version from `pubspec.lock`, and pin the direct `intl` dependency to that exact version. The direct dependency stays (it is used by `utils/dates.dart` and Stats formatting); it just must match.

### Localization setup (Phase 7)

`l10n.yaml` at the project root:

<CODE lang="yaml">
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/generated
nullable-getter: false
untranslated-messages-file: lib/l10n/untranslated.txt
</CODE>

- Do **not** add `synthetic-package` — it was removed in modern Flutter; output goes to `output-dir`.
- `nullable-getter: false` makes `AppLocalizations.of(context)` non-nullable.
- Run `flutter gen-l10n` after adding/changing keys (it also runs automatically during builds with `generate: true`). Generated files in `lib/l10n/generated/` are **never hand-edited**.
- `untranslated.txt` lists keys missing from non-template ARB files. **Gate: it must be empty before a localized build ships.** Missing keys otherwise silently fall back to English in the UI.

`MaterialApp` wiring (in `app.dart`):

<CODE lang="dart">
MaterialApp(
  title: 'Daily Wellness Tracker',   // brand — stays untranslated (frozen)
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ... theme, home, etc. unchanged
)
</CODE>

Import path: `package:<app>/l10n/generated/app_localizations.dart`.

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

**Phase 7 change:** `FeatureDef` no longer carries display strings — a `const` catalog cannot be localized. Labels and captions live in the ARB files; the `feature_strings.dart` bridge maps keys → generated getters (same "one switch, one file" pattern as `companion_builder.dart`).

<CODE lang="dart">
// models/feature_def.dart
class FeatureDef {
  final String key;            // matches the Drift column name
  final int scaleLength;       // 1 = checkbox, 2 = switch, >=3 = picker
  final bool defaultEnabled;

  const FeatureDef({
    required this.key, required this.scaleLength, this.defaultEnabled = false,
  });
}

const allFeatures = <FeatureDef>[
  // Original four — enabled by default so existing users see zero behavior change.
  FeatureDef(key: 'sleepRating', scaleLength: 5, defaultEnabled: true),
  FeatureDef(key: 'exerciseRating', scaleLength: 5, defaultEnabled: true),
  FeatureDef(key: 'schoolStressRating', scaleLength: 5, defaultEnabled: true),
  FeatureDef(key: 'screenUsageRating', scaleLength: 5, defaultEnabled: true),

  // New catalog — off by default, user opts in via Settings.
  FeatureDef(key: 'moodRating', scaleLength: 5),
  FeatureDef(key: 'energyRating', scaleLength: 5),
  FeatureDef(key: 'nutritionRating', scaleLength: 5),
  FeatureDef(key: 'physicalRating', scaleLength: 5),
  FeatureDef(key: 'socialRating', scaleLength: 5),
  FeatureDef(key: 'productivityRating', scaleLength: 5),
  FeatureDef(key: 'waterRating', scaleLength: 5),
  FeatureDef(key: 'caffeineRating', scaleLength: 5),
  FeatureDef(key: 'alcoholRating', scaleLength: 5),
  FeatureDef(key: 'smokingRating', scaleLength: 5),
  FeatureDef(key: 'medicationTaken', scaleLength: 2),
  FeatureDef(key: 'workdayFlag', scaleLength: 2),
];
</CODE>

**ARB key convention for the catalog:** `feature<Key>`, `feature<Key>Low`, `feature<Key>High` (e.g. `featureSleepRating`, `featureSleepRatingLow`, `featureSleepRatingHigh`).

**The bridge** — the only place feature keys are turned into display strings:

<CODE lang="dart">
// lib/l10n/feature_strings.dart
import 'generated/app_localizations.dart';

String featureLabel(AppLocalizations l, String key) => switch (key) {
  'sleepRating' => l.featureSleepRating,
  'exerciseRating' => l.featureExerciseRating,
  'schoolStressRating' => l.featureSchoolStressRating,
  'screenUsageRating' => l.featureScreenUsageRating,
  // ... one case per feature key ...
  _ => key,   // fail visible, not silent
};

String featureLowCaption(AppLocalizations l, String key) => switch (key) {
  'sleepRating' => l.featureSleepRatingLow,
  // ... same pattern ...
  _ => '',
};

String featureHighCaption(AppLocalizations l, String key) => switch (key) {
  'sleepRating' => l.featureSleepRatingHigh,
  // ... same pattern ...
  _ => '',
};
</CODE>

**Checklist when adding a feature** (extends the existing one): new column in `DailyEntries` + migration, `companion_builder.dart` case, `feature_strings.dart` cases (×3), and ARB keys in **all five** locales.

**Enabled-set storage:** `shared_preferences`, key `enabled_features`, stored as a `List<String>` (via `getStringList`). Default = the four `defaultEnabled: true` entries, computed once if the pref is unset.

### Shared widget: `EntryEditorForm`

Contract (`date`, `initial`, `onSave`, `onSaved`) is **unchanged**. Internals:
- `State` holds `Map<String, int> ratings` instead of four named ints.
- Seeded in `initState` by iterating **enabled** `FeatureDef`s and pulling each value via `getFeatureValue(initial, key) ?? 0`.
- Renders one `RatingPicker` per enabled `FeatureDef`, in catalog order; **labels/captions resolved at build time** via `final l = AppLocalizations.of(context);` + the `feature_strings` bridge (widget layer only, per §0).
- Save: clamps each rating to `scaleLength - 1`, builds the companion via `buildEntryCompanion`, and calls `onSave`.
- Save button label comes from ARB (`todaySave`).

### `RatingPicker` — generalized by `scaleLength`

Unchanged from v8 — it receives plain strings (`label`, `lowCaption`, `highCaption`) and therefore stays localization-agnostic. Callers pass localized strings. Numeric tooltips `'$i'` are universal; keep them.

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

- Displays today's date **locale-aware**: parse the stored key and format with the context's locale — `DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(DateTime.parse(vm.today))`. The *storage* key stays `yyyy-MM-dd` (§0).
- Gear icon → Settings. Save button + "Saved" snackbar from ARB.
- Body: `EntryEditorForm(key: ValueKey(vm.today), date: vm.today, initial: vm.currentEntry, ...)`.
- `TodayViewModel` unchanged (computes date, 60s rollover timer, subscribes to `watchByDate`) — it holds only the ISO key, never a formatted/localized string.

### History Screen (tab 1)

- `StreamBuilder<List<DailyEntry>>` on `watchAll()`.
- Empty state from ARB (`historyEmpty`).
- Row: date via `DateFormat.MMMEd(localeTag)`; compact summary of *enabled* features + note indicator. German strings run long — the summary row **must** keep `maxLines: 1, overflow: TextOverflow.ellipsis`.
- Tap row → bottom sheet with `EntryEditorForm`. (The sheet's builder context is under `MaterialApp`, so `AppLocalizations.of(context)` works inside it.)

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

  final dateKey = DateFormat('yyyy-MM-dd').format(picked);   // explicit pattern: locale-independent, storage-safe
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

(`showDatePicker`/`showTimePicker` materialize from `Localizations` automatically once delegates are wired — no extra work.)

### Stats Screen (tab 2)

`StatsViewModel` subscribes to `watchAll()` over full history and loops over currently-enabled `FeatureDef`s. **The VM returns numbers/slots only; card labels and captions are resolved in the screen widget** (which has context) via the bridge and passed down.

- **Averages:** unchanged math (mean over 7/30-day calendar windows, gaps excluded). **Display formatting is locale-aware:** format the two means with `NumberFormat.decimalPattern(localeTag)` and pass the resulting strings into the ARB `statsAvgRow` placeholder message (German gets a decimal comma for free; never `toStringAsFixed` into UI).
- **Streak:** unchanged math. The streak card text is an ARB **plural** message (see §2 sample) so de/ja/fr/it grammar is correct.
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

- `NavigationBar` with 3 destinations — labels from ARB (`navToday`/`navHistory`/`navStats`). `IndexedStack` preserves state.
- `NavigationManager` global instance drives tab index.
- `main()` initializes timezones, `NotificationService`, and `MultiProvider`. (See v6 spec for full `main()` and `AppContainer` code — unchanged).

## 5. Reminder & Notifications

`NotificationService` (API + `init` with both tap callbacks), the `zonedSchedule` next-occurrence scheduling, the inexact-alarm fallback, the iOS `DarwinInitializationSettings` permission-suppression, and the Gradle desugaring config are unchanged from v6 — keep that code as-is.

**Localized notification strings (Phase 7):** the service has no `BuildContext`, so it cannot use `AppLocalizations.of`. Use the generated top-level lookup with the system locale instead:

<CODE lang="dart">
import 'package:flutter/widgets.dart' show PlatformDispatcher;
import '../l10n/generated/app_localizations.dart';

final l = lookupAppLocalizations(PlatformDispatcher.instance.locale);
// schedule with l.notifTitle / l.notifBody
</CODE>

Strings are baked in at schedule time. That's acceptable because `rescheduleFromSettings()` already runs on every launch (§4 `main()`) — after a system-language change, the next launch re-schedules with fresh strings. **Known cosmetic staleness:** the Android notification *channel name* is cached by the OS at first creation; it stays in the language that was active when the channel was first created. Accepted — it only appears in system notification settings. (If ever revisited: recreate the channel under a new id on locale change.)

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

Minimal screen behind the gear icon on Today; all strings from ARB:

1. **Reminders section:** `SwitchListTile` "Daily reminder" + time picker. Persisted via `NotificationService`.
2. **Features section:** A list of `CheckboxListTile`s, one per `FeatureDef` in `allFeatures`, labels via the `feature_strings` bridge. Toggling updates the `enabled_features` `List<String>` in `shared_preferences`. No confirmation dialog (disabling never deletes data, per `Value.absent()` rule).

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

### Phase 7 (Internationalization)
1. **Pipeline:** add `flutter_localizations`, `generate: true`, `l10n.yaml`; align the direct `intl` pin to `pubspec.lock`; wire `localizationsDelegates`/`supportedLocales` into `MaterialApp`.
2. **Extraction (en):** move *every* user-visible literal into `app_en.arb` — nav labels, Today (save, saved snackbar, metrics header), History (empty state), Stats (streak card plural, averages row, placeholders), Settings (both sections, denial snackbar), notification title/body. Grep the UI sources for raw string literals afterwards; nothing English may remain outside ARB except the brand title.
3. **Catalog refactor:** strip `label`/`lowCaption`/`highCaption` from `FeatureDef`; add `feature_strings.dart` bridge; update `EntryEditorForm`, Stats screen, and Settings feature list call sites.
4. **Locale-aware display formatting:** Today header (`yMMMMd`), History rows (`MMMEd`), Stats averages (`NumberFormat.decimalPattern`) — all with `Localizations.localeOf(context).toLanguageTag()`. Storage formats untouched.
5. **Notifications:** `lookupAppLocalizations(PlatformDispatcher.instance.locale)` for title/body.
6. **Translations:** author `app_fr.arb`, `app_de.arb`, `app_ja.arb`, `app_it.arb` — complete key sets; `untranslated.txt` empty before shipping.
7. **Tests:** locale smoke tests (pump the app under each supported locale with the real delegates).

### Addendum: In-App Language Picker (Phase 8)

> Integration note: replace the §0 bullet "**Locale resolution:** system-driven … no in-app language picker in this phase" with: "**Locale resolution:** system-driven by default, with an in-app override via the Settings language picker (Phase 8)."

This relaxes the v9 "system-driven only" freeze, allowing users to override the device locale from within the app. The architecture requires zero restructuring because localization resolution was already confined to the widget layer and the notification service.

**Storage & State:**
Add a new `shared_preferences` key `selected_language` (String). Valid values are `'system'` (default) or an explicit language code (`'en'`, `'fr'`, `'de'`, `'ja'`, `'it'`).
Expose this via a root-level `ValueNotifier<String>` (e.g., `languagePreference`) — a plain global like `navigationManager`, or provided alongside the other root dependencies. Initialize it from the pref in `main()` before `runApp`, and write the pref back whenever the user changes it.

**`MaterialApp` Wiring:**
Wrap `MaterialApp` in a `ValueListenableBuilder` to react to changes. Map the `'system'` string to `null` so Flutter falls back to its default `supportedLocales` resolution; otherwise, construct a `Locale`.

<CODE lang="dart">
ValueListenableBuilder<String>(
  valueListenable: languagePreference,
  builder: (context, langCode, _) {
    final Locale? appLocale = (langCode == 'system') ? null : Locale(langCode);
    return MaterialApp(
      title: 'Daily Wellness Tracker',
      locale: appLocale, // null = follow system
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // ... theme, home, etc.
    );
  },
)
</CODE>

**Notification Service Update:**
The notification service previously used `PlatformDispatcher.instance.locale`. It must now read the saved preference to ensure notifications match the app's UI language, not just the OS language.

<CODE lang="dart">
Locale resolveNotificationLocale(String savedLangCode) {
  if (savedLangCode == 'system') {
    return PlatformDispatcher.instance.locale;
  }
  return Locale(savedLangCode);
}

// Inside scheduleReminder():
final l = lookupAppLocalizations(resolveNotificationLocale(savedLangCode));
// ... use l.notifTitle, l.notifBody
</CODE>

**Settings UI:**
Add a "Language" section to the Settings screen (above or below Features). Use a list of `RadioListTile`s or a `DropdownButton` mapped to the supported languages plus a "System Default" option.

**Critical Caveat — Notification Rescheduling:**
Changing the in-app language updates the UI instantly, but the OS caches the scheduled notification's title/body strings at the time `zonedSchedule` was called. When the user saves a new language preference in Settings, the UI **must** explicitly call `notificationService.rescheduleFromSettings()` immediately afterward. This cancels and re-fires the schedule with the freshly resolved localized strings, preventing the user from seeing English notifications while using the app in Japanese.

**Build Order:** Add as **Phase 8** (or integrate into Phase 7). It is strictly a UI/Settings addition and touches no data layer or ViewModels.

**Acceptance Criteria (additions):**
- Selecting a language in Settings switches the UI immediately, without an app restart.
- Selecting "System Default" restores device-locale following.
- The choice persists across app restarts via `selected_language`.
- After a language change, the next scheduled reminder fires with title/body in the newly selected language (confirms the reschedule-on-change path).

### Acceptance Criteria

- Saving from Today updates History and Stats automatically.
- Leaving the app open across midnight shows the new date and an empty form within ~60s.
- Clearing the note field and saving persists as empty.
- The reminder fires at the chosen time (test by scheduling 1 min ahead).
- Tapping the notification opens the Today tab from foreground, background, and cold start.
- **v6/v8 additions:** Upgrading a v1 database preserves all existing rows/values; new columns are null. Disabling a feature, then re-enabling it, does not lose previously logged values (confirms `Value.absent()`). Toggling a feature off removes it from Stats and the form. Backfilling a past date via the History FAB creates the row and reflects it in Stats immediately. Date picker cannot select future dates.
- **v9 (i18n) additions:**
  - `flutter gen-l10n` runs clean and `untranslated.txt` is empty for fr/de/ja/it.
  - The app renders fully (all 3 tabs + Settings + bottom sheet) under each supported locale in widget tests — no missing-key fallback.
  - Changing the system language changes the UI language on next launch.
  - DB date keys remain `yyyy-MM-dd` while the device locale is de/ja (regression check that display localization didn't leak into storage).
  - Streak card shows correct plural forms per language (e.g. de `1 Tag` vs `5 Tage`; ja single form).
  - German (longest strings) causes no overflow: picker captions wrap, History summary ellipsizes, Settings tiles wrap.

## Implementation Notes & Gotchas

### Date/Time Handling
`utils/dates.dart`: `DateFormat('yyyy-MM-dd').format(DateTime.now())` — **local time, never `.toUtc()`**. Explicit patterns like `'yyyy-MM-dd'` are locale-*independent* (safe for storage keys under any locale); named constructors (`yMMMMd`, `MMMEd`) are locale-*aware* (display only, pass the locale explicitly).

### Data Validation
Clamp all ratings with `value.clamp(0, scaleLength - 1)` immediately before building the companion in `EntryEditorForm.save()`. 

### Streak Calculation
Count consecutive days with *any* entry (any non-null feature or note), walking backward from today (or yesterday if today has no entry yet), stopping at the first gap. Must run over **full history**.

### Internationalization gotchas (Phase 7 watch-list)
- **`intl` pin conflict:** `flutter_localizations` pins `intl` exactly; align the direct dependency to `pubspec.lock` or `pub get` fails.
- **Silent English fallback:** missing ARB keys don't error — they render the template string. `untranslated.txt` empty is the only gate.
- **Never hand-edit** `lib/l10n/generated/`; regenerate with `flutter gen-l10n`.
- **No localized strings in ViewModels/services/const data.** Widgets resolve via `AppLocalizations.of(context)`; the notification service uses `lookupAppLocalizations` (it is generated as a top-level function in the same file).
- **ICU plurals:** use `{count, plural, ...}` ARB syntax for anything countable (streak). German needs `=1`/`other`; Japanese only `other`; don't fake it with string concatenation.
- **Placeholders:** numbers passed into ARB messages must be pre-formatted strings (`NumberFormat`) or typed placeholders with metadata — decide per key and keep it consistent across locales.
- **Japanese:** no spaces around placeholders or between words; keep captions short. **German:** expect ~30% longer strings — the `Wrap`-based picker and ellipsized History row already absorb this; verify Settings tiles.
- **Bottom sheets/dialogs:** their builder contexts are under `MaterialApp`, so delegates resolve normally — but a `GlobalKey`-or-global-instance shortcut that bypasses the widget tree will not see them.
- **Future in-app language picker (out of scope now):** when added, it means a saved locale override → `MaterialApp(locale: ...)` + `lookupAppLocalizations(savedLocale)` in the notification service + a reschedule on change. The current architecture already supports this without restructuring — which is exactly why resolution is confined to the widget layer today.

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
| Hardcoded English strings | gen_l10n ARB pipeline (en/fr/de/ja/it) + `feature_strings` bridge | Phase 7; strings resolved in widget layer only |
| `strings.xml` resources | `.arb` files + generated `AppLocalizations` | ICU plurals/placeholders for per-language grammar |
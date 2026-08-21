import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/feature_strings.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feature_def.dart';
import '../services/notification_service.dart';
import '../viewmodels/feature_settings_controller.dart';

/// Reminder settings (spec §5). Toggle is **off** by default; time defaults
/// to 20:00. On enable, permissions are requested first — if denied the
/// setting is still saved and a snackbar explains how to fix it.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifications = context.read<NotificationService>();
    final settings = await notifications.loadReminderSettings();
    if (!mounted) return;
    setState(() {
      _enabled = settings.enabled;
      _time = TimeOfDay(hour: settings.hour, minute: settings.minute);
      _loading = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    final notifications = context.read<NotificationService>();
    setState(() => _enabled = value);

    if (value) {
      // Capture before the await — no BuildContext use across the async gap.
      final messenger = ScaffoldMessenger.of(context);
      final denialText = AppLocalizations.of(context).settingsPermissionDenied;
      final granted = await notifications.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        messenger.showSnackBar(SnackBar(content: Text(denialText)));
      }
      await notifications.saveReminderSettings(
        enabled: true,
        hour: _time.hour,
        minute: _time.minute,
      );
      await notifications.scheduleReminder(_time.hour, _time.minute);
    } else {
      await notifications.saveReminderSettings(enabled: false);
      await notifications.cancel();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    if (!mounted) return;

    final notifications = context.read<NotificationService>();
    setState(() => _time = picked);

    // Persist the time either way; reschedule only if currently enabled.
    await notifications.saveReminderSettings(
      enabled: _enabled,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (_enabled) {
      await notifications.scheduleReminder(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l10n.settingsReminder),
                  subtitle: Text(l10n.settingsReminderSubtitle),
                  value: _enabled,
                  onChanged: _onToggle,
                ),
                ListTile(
                  title: Text(l10n.settingsReminderTime),
                  subtitle: Text(_time.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickTime,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    l10n.settingsFeatures,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.settingsFeaturesSubtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                _FeaturesSection(),
              ],
            ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FeatureSettingsController>();
    final l10n = AppLocalizations.of(context);
    if (!controller.loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        for (final f in allFeatures)
          CheckboxListTile(
            title: Text(featureLabel(l10n, f.key)),
            value: controller.enabledKeys.contains(f.key),
            onChanged: (v) => controller.setEnabled(f.key, v ?? false),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';

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
      final granted = await notifications.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Enable notifications in system settings to receive reminders',
            ),
          ),
        );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Daily reminder'),
                  subtitle: const Text('Remind me to log my day'),
                  value: _enabled,
                  onChanged: _onToggle,
                ),
                ListTile(
                  title: const Text('Reminder time'),
                  subtitle: Text(_time.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickTime,
                ),
              ],
            ),
    );
  }
}

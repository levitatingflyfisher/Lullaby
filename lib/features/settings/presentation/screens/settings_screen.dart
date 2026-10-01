import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../controllers/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: ListView(
          children: [
            // Ruling 48: unfinished backup setup is never forgotten. Here, not on
            // Home, which is read at a glance and should not nag. Renders nothing
            // once setup is finished or while dismissed.
            const BackupSetupReminder(),
            ListTile(
              key: const Key('settings-sync'),
              leading: const Icon(Icons.sync),
              title: const Text('Sync with another phone'),
              subtitle: const Text('Share the record with your partner'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/sync'),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              subtitle: Text(themeMode.label),
              onTap: () => _showThemeDialog(context, ref, themeMode),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Lullaby v1.0.0'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Lullaby',
                applicationVersion: '1.0.0',
                applicationLegalese: 'AGPL-3.0 License',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                      'A FLOSS baby tracker for exhausted parents. '
                      'One-handed operation, minimal taps.'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              subtitle: const Text(
                  'Stays on this phone unless you turn on sync or export'),
            ),
            const BackupSettingsSection(),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, OhThemeModePreference current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          RadioGroup<OhThemeModePreference>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).set(value);
              }
              Navigator.pop(context);
            },
            child: Column(
              children: OhThemeModePreference.values.map((mode) {
                return RadioListTile<OhThemeModePreference>(
                  title: Text(mode.label),
                  value: mode,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

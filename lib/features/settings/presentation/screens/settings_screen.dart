import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sanctuary_backup/presentation/widgets/backup_settings_section.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(themeMode.name[0].toUpperCase() +
                themeMode.name.substring(1)),
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
            subtitle: const Text('All data stays on your device'),
          ),
          const BackupSettingsSection(),
        ],
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
              Navigator.pop(context);
            },
            child: Column(
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  title: Text(
                      mode.name[0].toUpperCase() + mode.name.substring(1)),
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

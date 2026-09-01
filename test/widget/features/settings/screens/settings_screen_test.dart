import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/settings/presentation/controllers/theme_controller.dart';
import 'package:lullaby/features/settings/presentation/screens/settings_screen.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// The backup section (sanctuary_backup_ui 0.3.0) reads the key store and
/// the reminder store; without in-memory stand-ins it waits on the platform
/// plugin forever and pumpAndSettle times out.
Widget _settings({SecureKeyStore? store}) => ProviderScope(
      overrides: [
        secureKeyStoreProvider
            .overrideWithValue(store ?? InMemorySecureKeyStore()),
        sanctuaryBackupConfigProvider.overrideWithValue(
          const SanctuaryBackupConfig(
            appId: 'lullaby',
            aadContext: 'ghost-backup/v1',
            appDisplayName: 'Lullaby',
          ),
        ),
        backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
        backupReminderStoreProvider
            .overrideWithValue(InMemoryBackupReminderStore()),
        themeStorageProvider.overrideWithValue(InMemorySecretStorage()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );

void main() {
  group('SettingsScreen', () {
    testWidgets('renders theme option', (tester) async {
      await tester.pumpWidget(
        _settings(),
      );

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Follow phone'), findsOneWidget);
    });

    testWidgets('renders about option', (tester) async {
      await tester.pumpWidget(
        _settings(),
      );

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Lullaby v1.0.0'), findsOneWidget);
    });

    testWidgets('renders privacy option', (tester) async {
      await tester.pumpWidget(
        _settings(),
      );

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('All data stays on your device'), findsOneWidget);
    });

    testWidgets('tapping theme opens dialog', (tester) async {
      await tester.pumpWidget(
        _settings(),
      );

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping about opens about dialog', (tester) async {
      await tester.pumpWidget(
        _settings(),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('AGPL-3.0 License'), findsOneWidget);
    });

    // Ruling 48: unfinished backup setup gets a dismissible "finish setup"
    // line so it is never forgotten. It sits at the top of Settings, not on
    // Home, which is read at a glance at 3 a.m. and should not nag.
    const notSetUp = "Backup isn't set up. Your data is only on this device.";

    testWidgets('no backup yet: the finish-setup line shows and dismisses',
        (tester) async {
      await tester.pumpWidget(_settings());
      await tester.pumpAndSettle();

      expect(find.text(notSetUp), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(notSetUp), findsNothing);
    });

    testWidgets('setup finished: no finish-setup line', (tester) async {
      await tester.pumpWidget(_settings(
        store: InMemorySecureKeyStore(
          mnemonic: 'abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon abandon abandon about',
          acknowledged: true,
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(BackupSetupReminder, skipOffstage: false),
          findsOneWidget);
      expect(find.text(notSetUp), findsNothing);
    });
  });
}

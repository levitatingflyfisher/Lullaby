import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

class MockSecureKeyStore extends Mock implements SecureKeyStore {}

Widget _wrapWithProviders(
  Widget child, {
  required SecureKeyStore store,
}) {
  return ProviderScope(
    overrides: [
      secureKeyStoreProvider.overrideWithValue(store),
      // Lullaby's real backup wiring (legacy ghost-backup/v1 context).
      sanctuaryBackupConfigProvider.overrideWithValue(
        const SanctuaryBackupConfig(
          appId: 'lullaby',
          aadContext: 'ghost-backup/v1',
          appDisplayName: 'Lullaby',
        ),
      ),
      backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
    ],
    child: MaterialApp(home: Scaffold(body: ListView(children: [child]))),
  );
}

void main() {
  group('BackupSettingsSection', () {
    late MockSecureKeyStore store;

    setUp(() {
      store = MockSecureKeyStore();
    });

    testWidgets('shows "Set up encrypted backup" in ghost state', (tester) async {
      when(() => store.readMnemonic()).thenAnswer((_) async => null);
      when(() => store.readSeedAcknowledged()).thenAnswer((_) async => false);
      when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrapWithProviders(const BackupSettingsSection(), store: store),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set up encrypted backup'), findsOneWidget);
      expect(find.text('Export backup'), findsNothing);
    });

    testWidgets('shows "Restore from backup" always', (tester) async {
      when(() => store.readMnemonic()).thenAnswer((_) async => null);
      when(() => store.readSeedAcknowledged()).thenAnswer((_) async => false);
      when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrapWithProviders(const BackupSettingsSection(), store: store),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore from backup'), findsOneWidget);
    });

    testWidgets('shows Export button after seed acknowledged', (tester) async {
      // Simulate a user who has generated and acknowledged a phrase.
      // The AuthNotifier will derive keys from this mnemonic.
      when(() => store.readMnemonic()).thenAnswer(
        (_) async => 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon about',
      );
      when(() => store.readSeedAcknowledged()).thenAnswer((_) async => true);
      when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrapWithProviders(const BackupSettingsSection(), store: store),
      );
      // AuthNotifier needs time to derive keys from the mnemonic
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Set up encrypted backup'), findsNothing);
    });

    testWidgets('shows Reset identity when key exists', (tester) async {
      when(() => store.readMnemonic()).thenAnswer(
        (_) async => 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon about',
      );
      when(() => store.readSeedAcknowledged()).thenAnswer((_) async => true);
      when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrapWithProviders(const BackupSettingsSection(), store: store),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Reset identity'), findsOneWidget);
    });

    testWidgets('shows section header', (tester) async {
      when(() => store.readMnemonic()).thenAnswer((_) async => null);
      when(() => store.readSeedAcknowledged()).thenAnswer((_) async => false);
      when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrapWithProviders(const BackupSettingsSection(), store: store),
      );
      await tester.pumpAndSettle();

      expect(find.text('Encrypted Backup'), findsOneWidget);
    });
  });
}

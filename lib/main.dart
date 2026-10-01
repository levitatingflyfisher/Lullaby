
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import 'app/app.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/sync_providers.dart';
import 'features/sanctuary_backup/after_restore.dart';
import 'features/settings/presentation/controllers/theme_controller.dart';
import 'features/sanctuary_backup/data/backup_serializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the theme choice before the first frame, so a Dark choice never
  // flashes light at launch. Bounded: startup waits at most 300ms.
  final theme = await readStoredThemePreference(const FlutterSecretStorage());
  runApp(
    ProviderScope(
      overrides: [
        initialThemePreferenceProvider.overrideWithValue(theme),
        // Encrypted-backup wiring (sanctuary_backup_ui). Lullaby keeps the
        // legacy ghost-backup/v1 AEAD context and the legacy (appDomain=null)
        // key derivation (SANCTUARY-BRIEF §2.1, §2.3) so the OHBK WIRE FORMAT
        // stays byte-for-byte the one shipped Lullaby wrote. This does NOT
        // mean a pre-rewire (CI-stub-era) exported .ohbk file still decrypts:
        // the stub's KDF (PBKDF2-SHA256/1000) differs from this core's
        // (PBKDF2-SHA512/2048 -> HKDF), so a stub-era backup cannot be
        // restored under the real core. See
        // test/unit/features/sanctuary_backup/stub_compat_gate_test.dart and
        // docs/limitations.md "Known incompatibility: pre-rewire backups".
        // sanctuaryAppDomainProvider is left at its null default — do NOT
        // set a domain here.
        sanctuaryBackupConfigProvider.overrideWithValue(
          SanctuaryBackupConfig(
            appId: 'lullaby',
            aadContext: 'ghost-backup/v1',
            appDisplayName: 'Lullaby',
            restoreReplaceConsequence:
                'Restoring will delete all current babies, feedings, sleeps, '
                'diapers, growth records, medicines, and vaccines, then '
                'replace them with data from the backup file.',
            // Timers, the home widget and any pending Undo can still point
            // at wiped rows; see lullabyAfterRestore.
            onAfterRestore: lullabyAfterRestore,
          ),
        ),
        // Keeps Lullaby's recovery words in its own namespace on web, where
        // every fleet PWA shares one origin's localStorage. No-op on native.
        appScopedKeyStoreOverride(),
        backupSerializerProvider.overrideWith(
          (ref) => LullabyBackupSerializer(
            ref.watch(databaseProvider),
            syncOn: ref.watch(householdSyncProvider).isOn,
          ),
        ),
      ],
      child: const LullabyApp(),
    ),
  );
}

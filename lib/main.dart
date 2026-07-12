import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import 'app/app.dart';
import 'core/providers/database_provider.dart';
import 'features/home_widget/presentation/controllers/home_widget_controller.dart';
import 'features/sanctuary_backup/data/backup_serializer.dart';
import 'features/tracking/presentation/controllers/timer_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
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
            // The Drift watch streams self-refresh after the destructive
            // restore, but in-memory timers and the home widget can still
            // reference wiped rows — invalidate them (the old controller's
            // _refreshAfterRestore).
            onAfterRestore: (ref) {
              ref.invalidate(activeTimersProvider);
              unawaited(
                  ref.read(homeWidgetControllerProvider).triggerUpdate());
            },
          ),
        ),
        backupSerializerProvider.overrideWith(
          (ref) => LullabyBackupSerializer(ref.watch(databaseProvider)),
        ),
      ],
      child: const LullabyApp(),
    ),
  );
}

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
        // key derivation so any already-shipped backup still decrypts
        // (SANCTUARY-BRIEF §2.1, §2.3). sanctuaryAppDomainProvider is left at
        // its null default — do NOT set a domain here.
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

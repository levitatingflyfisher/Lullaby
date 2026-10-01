import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../features/sync/data/household_sync.dart';
import '../../features/sync/data/record_writer.dart';
import '../../features/sync/data/sync_settings_store.dart';
import 'database_provider.dart';

/// Where this phone's sync choices live (theme's store; tests override it).
final syncSettingsStorageProvider =
    Provider<SecretStorage>((ref) => const FlutterSecretStorage());

/// The device key's storage name. Web PWAs share one origin's storage, so it
/// carries the app id.
const lullabyDeviceKeyName = 'oh_lullaby_hearth_device_key_v1';

/// Lullaby's household sync (ADR-0007). Loads nothing until sync is on.
final householdSyncProvider = Provider<HouseholdSync>((ref) {
  final sync = HouseholdSync(
    db: ref.watch(databaseProvider),
    settingsStore: SyncSettingsStore(ref.watch(syncSettingsStorageProvider)),
    readWords: () => ref.read(secureKeyStoreProvider).readMnemonic(),
    deriveSeed: OpenHearthMnemonic.deriveSeed,
    signer: () => SecureStorageSigner(key: lullabyDeviceKeyName),
    initBridge: () => HearthSync.init(),
    // A forgotten phone keeps no words (fleet sync decision 2).
    forgetWords: () => ref.read(authNotifierProvider.notifier).resetIdentity(),
  );
  ref.onDispose(sync.close);
  return sync;
});

/// The writer every repository holds: straight to Drift with sync off,
/// through the household's log with it on.
final recordWriterProvider = Provider<RecordWriter>(
    (ref) => HouseholdRecordWriter(ref.watch(householdSyncProvider)));

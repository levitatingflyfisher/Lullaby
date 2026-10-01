import 'package:flutter_test/flutter_test.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:lullaby/features/sync/data/household_sync.dart';
import 'package:lullaby/features/sync/data/sync_settings_store.dart';
import 'package:lullaby/features/sync/presentation/sync_words.dart';

// Persona J5: offline, the status says what happened in words, never a code.
void main() {
  final on = SyncSnapshot(
    mode: SyncMode.on,
    settings: SyncSettings(on: true, relay: Uri.parse('https://relay.example/'), label: 'Phone 2'),
  );
  final now = DateTime(2026, 10, 2, 3, 20);

  test('no connection is said in words, with when it retries', () {
    final s = on.copyWith(
      lastError: () => const RelayException(0, 'network'),
      retryIn: () => const Duration(minutes: 2),
    );
    expect(syncHeadline(s, now),
        'Couldn’t reach the relay. Check the connection. Trying again in 2 min.');
  });

  test('a busy relay is said in words', () {
    final s = on.copyWith(
      lastError: () => const RelayException(503, 'unavailable'),
      retryIn: () => const Duration(seconds: 30),
    );
    expect(syncHeadline(s, now), 'The relay is busy. Trying again in a moment.');
  });

  test('no relay chosen reads as paused in a browser, not broken', () {
    final s = on.copyWith(settings: const SyncSettings(on: true, label: 'Phone 2'));
    expect(syncHeadline(s, now, wifi: false), startsWith('Paused: no relay chosen.'));
  });

  test('no relay on a phone points at the same-Wi-Fi sync, and nothing is "waiting"', () {
    final s = on.copyWith(
      settings: const SyncSettings(on: true, label: 'Phone 2'),
      waiting: 4,
    );
    expect(syncHeadline(s, now, wifi: true), 'No relay: sync with a phone on this Wi-Fi below.');
    expect(syncWaitingLine(s), isNull);
  });

  test('the headline says which way the last sync went', () {
    final at = DateTime(2026, 10, 2, 3, 14);
    final wifi = on.copyWith(lastSynced: () => at, lastPath: () => SyncPath.wifi);
    expect(syncHeadline(wifi, now), matches(RegExp(r'^Last synced 3:14\sAM on this Wi-Fi\.$')));
    final relay = on.copyWith(lastSynced: () => at, lastPath: () => SyncPath.relay);
    expect(syncHeadline(relay, now), matches(RegExp(r'^Last synced 3:14\sAM through the relay\.$')));
  });

  test('a Wi-Fi sync still shows when the relay is failing', () {
    final s = on.copyWith(
      lastSynced: () => DateTime(2026, 10, 2, 3, 14),
      lastPath: () => SyncPath.wifi,
      lastError: () => const RelayException(0, 'network'),
      retryIn: () => const Duration(minutes: 2),
    );
    expect(
      syncHeadline(s, now),
      matches(RegExp(r'^Last synced 3:14\sAM on this Wi-Fi\. Couldn’t reach the relay\. '
          r'Check the connection\. Trying again in 2 min\.$')),
    );
  });
}

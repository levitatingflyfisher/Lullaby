import 'dart:convert';

import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

/// This phone's sync choices. Device-local, never synced (ADR-0007): whether
/// sync is on, which relay, and the name this phone signs notes with.
class SyncSettings {
  const SyncSettings({this.on = false, this.relay, this.label = 'This phone'});

  /// Sync was turned on here: writes go through the household's log.
  final bool on;

  /// The household relay, or null for none (nothing leaves the phone).
  final Uri? relay;

  /// This phone's name, as the other phones see it.
  final String label;

  SyncSettings copyWith({bool? on, Uri? Function()? relay, String? label}) =>
      SyncSettings(
        on: on ?? this.on,
        relay: relay != null ? relay() : this.relay,
        label: label ?? this.label,
      );

  Map<String, Object?> toJson() =>
      {'on': on, 'relay': relay?.toString(), 'label': label};

  static SyncSettings fromJson(Map<String, Object?> j) => SyncSettings(
        on: j['on'] == true,
        relay: j['relay'] is String ? Uri.tryParse(j['relay'] as String) : null,
        label: j['label'] is String ? j['label'] as String : 'This phone',
      );
}

/// Where [SyncSettings] live: the small key-value store the theme and backup
/// reminder already use. On web it is the origin's localStorage, shared by
/// every fleet PWA, so the key carries the app id.
class SyncSettingsStore {
  const SyncSettingsStore(this.storage);

  final SecretStorage storage;

  static const key = 'oh_lullaby_sync_v1';

  Future<SyncSettings> read() async {
    final raw = await storage.read(key);
    if (raw == null) return const SyncSettings();
    try {
      return SyncSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const SyncSettings();
    }
  }

  Future<void> write(SyncSettings s) => storage.write(key, jsonEncode(s.toJson()));
}

/// Why [text] cannot be a relay address, in plain words, or null if it can.
/// The relay client only speaks https, except plain http to this computer or
/// the Android emulator's host (for testing).
String? relayAddressProblem(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'Type the relay’s address.';
  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'That doesn’t look like a web address. It starts with https://';
  }
  const local = {'127.0.0.1', '::1', 'localhost', '10.0.2.2'};
  if (uri.scheme == 'https') return null;
  if (uri.scheme == 'http' && local.contains(uri.host)) return null;
  return 'The address must start with https:// so the connection is private.';
}

/// [text] as a relay base address (with a trailing slash).
Uri relayUri(String text) {
  final uri = Uri.parse(text.trim());
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

/// Where the theme choice is kept: the same small key-value store the backup
/// package already uses for its own UI preference (the setup reminder), so
/// no new plugin is needed. On web it is this origin's localStorage, so the
/// key carries the app id like the backup package's keys do.
final themeStorageProvider =
    Provider<SecretStorage>((ref) => const FlutterSecretStorage());

const themeModeStorageKey = 'oh_lullaby_theme_mode_v1';

/// The stored choice, read in `main()` before `runApp` so the first frame
/// is already in it (no light flash for someone who chose Dark). Null when
/// nothing was read in time; the notifier then loads it after the fact.
final initialThemePreferenceProvider =
    Provider<OhThemeModePreference?>((ref) => null);

/// Reads the stored theme choice, or null if there is none or it can't be
/// read in [timeout] (startup never waits longer than that on the keychain).
Future<OhThemeModePreference?> readStoredThemePreference(
  SecretStorage storage, {
  Duration timeout = const Duration(milliseconds: 300),
}) async {
  try {
    final raw = await storage.read(themeModeStorageKey).timeout(timeout);
    return raw == null ? null : OhThemeModePreference.fromStorage(raw);
  } on Object {
    return null;
  }
}

/// Light, dark or follow the phone (operator ruling Q3), default follow the
/// phone. Nothing was stored before this key existed, so there is no older
/// value to migrate: every earlier launch started at "follow the phone".
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, OhThemeModePreference>(
        ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<OhThemeModePreference> {
  bool _chosen = false;

  @override
  OhThemeModePreference build() {
    final initial = ref.read(initialThemePreferenceProvider);
    if (initial != null) return initial;
    _load();
    return OhThemeModePreference.defaultValue;
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(themeStorageProvider).read(themeModeStorageKey);
      // A choice made while the read was in flight wins.
      if (_chosen || raw == null) return;
      state = OhThemeModePreference.fromStorage(raw);
    } on Object catch (e, st) {
      developer.log('theme preference unreadable',
          name: 'lullaby', error: e, stackTrace: st);
    }
  }

  Future<void> set(OhThemeModePreference preference) async {
    _chosen = true;
    state = preference;
    try {
      await ref
          .read(themeStorageProvider)
          .write(themeModeStorageKey, preference.storageValue);
    } on Object catch (e, st) {
      // The choice still applies for this session.
      developer.log('theme preference not saved',
          name: 'lullaby', error: e, stackTrace: st);
    }
  }
}

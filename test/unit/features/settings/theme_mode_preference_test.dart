import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/settings/presentation/controllers/theme_controller.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// Operator ruling Q3: light, dark or follow the phone, default follow the
/// phone, and the choice survives a restart.
///
/// There is no legacy value to migrate: before this, ThemeModeNotifier
/// started at ThemeMode.system and never stored anything, so every launch
/// already followed the phone.
void main() {
  ProviderContainer containerWith(InMemorySecretStorage storage) {
    final c = ProviderContainer(overrides: [
      themeStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('nothing stored follows the phone', () async {
    final c = containerWith(InMemorySecretStorage());
    c.read(themeModeProvider);
    await settle();
    expect(c.read(themeModeProvider), OhThemeModePreference.system);
    expect(c.read(themeModeProvider).themeMode, ThemeMode.system);
  });

  test('a stored choice comes back after a restart', () async {
    final storage = InMemorySecretStorage();
    final first = containerWith(storage);
    first.read(themeModeProvider);
    await first.read(themeModeProvider.notifier)
        .set(OhThemeModePreference.dark);
    expect(storage.values[themeModeStorageKey], 'dark');

    final second = containerWith(storage);
    second.read(themeModeProvider);
    await settle();
    expect(second.read(themeModeProvider), OhThemeModePreference.dark);
  });

  test('an unreadable value falls back to following the phone', () async {
    final c = containerWith(
        InMemorySecretStorage({themeModeStorageKey: 'sepia'}));
    c.read(themeModeProvider);
    await settle();
    expect(c.read(themeModeProvider), OhThemeModePreference.system);
  });

  test('a choice made while the stored value loads is not overwritten',
      () async {
    final c = containerWith(
        InMemorySecretStorage({themeModeStorageKey: 'dark'}));
    c.read(themeModeProvider);
    await c.read(themeModeProvider.notifier)
        .set(OhThemeModePreference.light);
    await settle();
    expect(c.read(themeModeProvider), OhThemeModePreference.light);
  });

  test('a preference read before runApp applies on the first frame', () {
    final c = ProviderContainer(overrides: [
      themeStorageProvider.overrideWithValue(InMemorySecretStorage()),
      initialThemePreferenceProvider
          .overrideWithValue(OhThemeModePreference.dark),
    ]);
    addTearDown(c.dispose);
    // Synchronously, before any storage read could complete: no light flash.
    expect(c.read(themeModeProvider), OhThemeModePreference.dark);
  });

  test('readStoredThemePreference returns the stored choice', () async {
    final storage = InMemorySecretStorage({themeModeStorageKey: 'dark'});
    expect(await readStoredThemePreference(storage),
        OhThemeModePreference.dark);
    expect(await readStoredThemePreference(InMemorySecretStorage()), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';

class MockSecureKeyStore extends Mock implements SecureKeyStore {}

void main() {
  test('authNotifierProvider resolves to ghost state with empty keychain', () async {
    final store = MockSecureKeyStore();
    when(() => store.readMnemonic()).thenAnswer((_) async => null);
    when(() => store.readSeedAcknowledged()).thenAnswer((_) async => false);
    when(() => store.readLastBackupAt()).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [secureKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final state = await container.read(authNotifierProvider.future);
    expect(state.tier, equals(AuthTier.ghost));
    expect(state.masterEncryptionKey, isNull);
    expect(state.needsBackupReminder(), isFalse);
  });
}

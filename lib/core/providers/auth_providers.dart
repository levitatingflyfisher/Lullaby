// Re-export sanctuary_auth_core providers for use throughout Lullaby.
// Import from this file within the app — do not import from sanctuary_auth_core directly.
export 'package:sanctuary_auth_core/sanctuary_auth_core.dart'
    show
        authNotifierProvider,
        AuthNotifier,
        AuthState,
        AuthTier,
        secureKeyStoreProvider,
        cryptoServiceProvider,
        CryptoService,
        DerivedKeys,
        GhostBackup,
        EnvelopeCipher,
        BackupFormatException,
        CryptoException,
        SanctuaryAuthException,
        SeedPhraseMismatchException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';

final envelopeCipherProvider = Provider<EnvelopeCipher>((_) => EnvelopeCipher());

# Encrypted-backup auth module — CI stub

This is **not** the real, audited encrypted-backup auth module. The real
package lives outside this repository and is consumed in production via the
path dependency declared in `pubspec.yaml`.

That upstream repo is private, so GitHub Actions cannot check it out (the
workflow token 404s on it). To keep CI useful, the workflow copies this stub
into the expected package location so the app compiles and the test suite
can run.

The stub reproduces:

- the public API surface the app and tests import (`GhostBackup`,
  `EnvelopeCipher`, `AuthNotifier`/`AuthState`/`AuthTier`, `SecureKeyStore`,
  `CryptoService`/`DerivedKeys`, the exception hierarchy, and the providers);
- the documented **OHBK** wire format (4-byte magic + version + suite + 12-byte
  nonce + 16-byte MAC + ciphertext) backed by **real** ChaCha20-Poly1305 and
  PBKDF2 from the `cryptography` package, so the backup round-trip and
  tamper/wrong-key tests exercise genuine AEAD behaviour.

It is intentionally minimal and must never ship in a release build. To restore
real CI verification, give the workflow access to the upstream package (a
deploy key / PAT secret + a pinned ref) and replace the "Vendor" step in
`.github/workflows/ci.yml` with a checkout.

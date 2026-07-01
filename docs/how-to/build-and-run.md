# How to build & run Lullaby

Task-oriented setup for developers. Assumes you can use a terminal and have (or
can install) Flutter. For the architecture, see
[../architecture/OVERVIEW.md](../architecture/OVERVIEW.md).

## Prerequisites

- **Flutter SDK ≥ 3.10.7** (bundles Dart ≥ 3.10.7). Verify with `flutter --version`.
  CI pins Flutter `3.44.2`; older channels shipped a Dart too old to satisfy the
  pubspec constraint.
- **Android:** Android Studio / Android SDK.
- **iOS:** Xcode ≥ 15 (macOS only).
- **Linux desktop:** `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`.

## Get the code and dependencies

```bash
git clone git@github.com:levitatingflyfisher/Lullaby.git
cd Lullaby
flutter pub get
```

`flutter pub get` resolves everything, including the `sanctuary_auth_core` and
`sanctuary_backup_ui` backup-crypto dependencies — their paths point at
sibling checkouts (`../packages/sanctuary_auth_core`,
`../packages/sanctuary_backup_ui`), which CI clones from their own public
repos alongside this one. A fresh local checkout needs those siblings cloned
next to `Lullaby/` at the same directory level (see
[../reference/backup-format.md](../reference/backup-format.md)).

## Generate database code (only after changing the schema)

The Drift-generated files (`*.g.dart`) are committed, so a fresh checkout needs no
codegen. Re-run it whenever you edit `lib/services/database/tables.dart` or a
DAO's queries:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never hand-edit the generated `*.g.dart` files.

## Run

```bash
flutter devices                 # list emulators / connected devices
flutter run -d <device-id>      # run in debug
```

## Verify your setup

```bash
flutter analyze                 # must be clean
flutter test                    # ~450 tests; must be green
```

## Build a release artifact

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (requires Apple signing configured in Xcode)
flutter build ios --release

# Linux desktop  → build/linux/x64/release/bundle/lullaby
flutter build linux --release

# Web  (ships sqlite3.wasm + drift_worker.js from web/ — keep them in sync with the drift version)
flutter build web --release
```

> Before publishing to an app store, change the Android `applicationId` from
> `com.example.lullaby` to your own reverse-domain ID and configure a release
> signing key. Release CI is intentionally omitted until then
> (`.github/workflows/ci.yml`).

## Troubleshooting

- **Version-solving fails on `sdk`/Dart version:** your Flutter is too old — its
  bundled Dart is below 3.10.7. Upgrade Flutter (CI uses 3.44.2).
- **Build errors mentioning `*.g.dart` / missing Drift types:** re-run
  `build_runner` (above).
- **Web build runs but the DB doesn't load:** confirm `web/sqlite3.wasm` and
  `web/drift_worker.js` are present and match your `drift` version.

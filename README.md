# Lullaby

**FLOSS baby tracker for exhausted parents.**

Lullaby is a privacy-first, offline baby tracking app. All data is stored locally on the device — no accounts, no cloud sync, no ads. Track feeds, sleep, diapers, growth, health records, and more, all in one place.

![Platform: Android](https://img.shields.io/badge/platform-Android-brightgreen)
![Platform: iOS](https://img.shields.io/badge/platform-iOS-lightgrey)
![Platform: Linux](https://img.shields.io/badge/platform-Linux-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-yellow)

---

## Features

- **Feeding tracker** — log breast, bottle, and solid feeds; left/right side toggle with live timer
- **Sleep tracker** — start/stop sleep sessions with a live timer; view sleep history
- **Diaper tracker** — log wet, dirty, and mixed changes
- **Growth charts** — record weight, height, and head circumference plotted against WHO percentile curves
- **Health records** — medicine dose log and vaccination history
- **Statistics** — feeding trends, sleep patterns, and diaper frequency charts over configurable periods
- **Calendar view** — browse all events by day
- **Timeline** — scrollable activity history with filter chips
- **Doctor summary** — at-a-glance summary ready to share at appointments
- **Multiple babies** — manage profiles for more than one child
- **Dark mode** — system theme + manual override
- **Material 3** — dynamic colour theming on supported Android devices

---

## Screenshots

*Screenshots coming soon.*

---

## Tech Stack

| Layer | Library |
|-------|---------|
| UI framework | [Flutter](https://flutter.dev) ≥ 3.10.7 |
| State management | [Riverpod](https://riverpod.dev) 2.x |
| Database | [Drift](https://drift.simonbinder.eu) (SQLite ORM) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Calendar | [table_calendar](https://pub.dev/packages/table_calendar) |
| Dynamic colour | [dynamic_color](https://pub.dev/packages/dynamic_color) |
| Image picker | [image_picker](https://pub.dev/packages/image_picker) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10.7
- Dart SDK ≥ 3.10.7 (bundled with Flutter)
- For Android: Android SDK / Android Studio
- For iOS: Xcode ≥ 15 (macOS only)
- For Linux: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Setup

```bash
git clone <repo-url>
cd lullaby
flutter pub get
```

### Run in debug mode

```bash
# List connected devices/emulators
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

---

## Building

### Android

```bash
flutter build apk --release
# or for an app bundle:
flutter build appbundle --release
```

> **Note:** Before publishing to the Play Store, update the `applicationId` in `android/app/build.gradle.kts` from `com.example.lullaby` to your organisation's reverse-domain ID, and configure a release signing key.

### iOS

```bash
flutter build ios --release
```

Requires a valid Apple developer signing certificate configured in Xcode.

### Linux

```bash
flutter build linux --release
```

The resulting binary is at `build/linux/x64/release/bundle/lullaby`.

---

## Architecture

Lullaby follows **clean architecture** with a **feature-based folder structure**:

```
lib/
├── app/              # App entry, router, theme
├── core/             # Shared utilities, errors, extensions, providers
├── features/         # One sub-directory per feature
│   ├── babies/       # Baby profiles
│   ├── tracking/     # Feeding / sleep / diaper tracking
│   ├── growth/       # Growth measurements & WHO charts
│   ├── health/       # Medicine & vaccine logs
│   ├── stats/        # Aggregated statistics
│   ├── calendar/     # Calendar view
│   ├── timeline/     # Activity timeline
│   ├── dashboard/    # Home dashboard
│   ├── doctor/       # Doctor summary
│   └── settings/     # App settings
│
│   Each feature contains:
│   ├── domain/       # Entities & repository interfaces
│   ├── data/         # Repository implementations (Drift DAOs)
│   └── presentation/ # Screens, widgets, Riverpod controllers
│
└── services/
    └── database/     # Drift database definition, tables, DAOs
```

State is managed exclusively with **Riverpod** providers. The database layer uses **Drift** with generated code (`*.g.dart` files).

---

## Tests

```bash
# Run all tests
flutter test

# Static analysis
flutter analyze
```

The test suite covers domain entities, repository implementations (using an in-memory SQLite database), controllers, and widgets — 326 test cases across 48 test files.

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## License

MIT — see [LICENSE](LICENSE).

---

## About [Organization Name]

[Organization Name] is a 501(c)(3) nonprofit dedicated to strengthening families through research, education, and free public tools. Learn more at [organization website].

import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

/// Lullaby's recorded fleet posture — every deliberate divergence from
/// canon lives in this one config (see oh_fleet_conformance's README).
void main() => runFleetConformance(const FleetAppConfig(
      appId: 'lullaby',
      // C7 ON: Lullaby draws its text in openhearth_design's package Lora
      // and Nunito (OhTypography.materialTextTheme, operator ruling), so a
      // character those faces cannot draw is a box on a real phone. C7
      // sweeps lib/ for any.
      checks: {
        ...FleetAppConfig.withBundledFonts,
        FleetCheck.c8IconButtons,
        // C10: no raw exception text on screen; failures go through
        // OhErrorState / ohFriendlyErrorMessage and the raw error is logged.
        FleetCheck.c10RawErrors,
        // C11: every app-bar action says what it does in words (icon plus
        // a short label; the theme toggle is icon plus word).
        FleetCheck.c11IconLabels,
        // C9: every routed screen has a way in (router_doors_test is the
        // app's own copy of the same guard).
        FleetCheck.c9Routes,
        // Item 24: the screens below are swept at 360dp × 1.3 in
        // test/a11y/primary_action_sweep_test.dart.
        FleetCheck.c5PrimaryScreens,
        // C12: the accent must not be mistaken for the error red.
        FleetCheck.c12AccentVsError,
      },
      // C12 accents, as rendered: ColorScheme.fromSeed(0xFF7B8FD4)'s primary
      // in each brightness (lib/app/theme/color_schemes.dart). Not covered:
      // on Android 12+ DynamicColorBuilder replaces these with the phone's
      // wallpaper palette, which no static check can know; and C12 measures
      // against ohStyle's urgency role, while Lullaby's own error colour is
      // Material's (0xFFBA1A1A / 0xFFFFB4AB from the same seed).
      accentColors: [
        FleetAccent.light(0xFF4C5C92, label: 'periwinkle seed, light'),
        FleetAccent.dark(0xFFB5C4FF, label: 'periwinkle seed, dark'),
      ],
      primaryActionScreens: {
        'DashboardScreen',
        'BabyEditScreen',
        'FeedingLogScreen',
      },
      // Tokens tier: canonical openhearth_design is the declared dependency;
      // the shipped look stays blessed app identity (Lullaby's periwinkle
      // 0xFF7B8FD4 is app-local, not a canonical token) pinned by the
      // visual golden sweeps.
      styleTier: StyleTier.tokens,
      // ZERO permissions — the empty set IS the claim, over the surface C4
      // actually reads: the SOURCE AndroidManifest declares no permissions
      // (and none may appear). Plugins could still inject permissions at
      // build time via manifest merging; checking the MERGED manifest of a
      // built APK is recorded as a future deepening.
      androidPermissions: {},
      // C4 v2 — the release MERGED surface: source permissions plus
      // what plugins and the manifest merge inject. Bites when an APK
      // build has left a merged manifest under build/ (dev box).
      mergedAndroidPermissions: {
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.WAKE_LOCK',
        'com.openhearth.lullaby.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      },
      // Startup runs the vault freshness/prune hook (lib/app/app.dart).
      expectStartupMaintenance: true,
    ));

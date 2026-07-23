import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

/// Lullaby's recorded fleet posture — every deliberate divergence from
/// canon lives in this one config (see oh_fleet_conformance's README).
void main() => runFleetConformance(const FleetAppConfig(
      appId: 'lullaby',
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
        'com.example.lullaby.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      },
      // Startup runs the vault freshness/prune hook (lib/app/app.dart).
      expectStartupMaintenance: true,
    ));

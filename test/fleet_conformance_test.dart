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
      // ZERO permissions — the empty set IS the claim, enforced both
      // directions: fully offline, nothing leaves the device.
      androidPermissions: {},
      // Startup runs the vault freshness/prune hook (lib/app/app.dart).
      expectStartupMaintenance: true,
    ));

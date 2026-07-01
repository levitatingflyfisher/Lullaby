// Conformance-readiness proof for the openhearth_design dependency.
//
// A 2026-07 sweep of lib/ found ZERO literals equal to canonical OpenHearth
// token values, so no color rewiring was performed (tier-T, zero visual
// change). This test pins the two facts that make the app "conformance
// ready" without touching its identity:
//
//  1. The shared design package resolves and exposes the canonical tokens
//     with the exact values the fleet agreed on — so a future adoption pass
//     can reference OhColors instead of re-checking hex values.
//  2. Lullaby's signature periwinkle seed is NOT a canonical token — it is
//     app-local identity and must stay defined in lib/app/theme.
//
// Lullaby's type ladder and Material-You dynamic-color hook are protected
// identity and are deliberately not exercised here.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';

void main() {
  group('openhearth_design conformance readiness', () {
    test('canonical brand tokens resolve with the agreed values', () {
      expect(OhColors.hearth500, const Color(0xFFA85040));
      expect(OhColors.hearth400, const Color(0xFFC47B6A));
      expect(OhColors.sage500, const Color(0xFF5E9478));
      expect(OhColors.sage400, const Color(0xFF7BAF96));
      expect(OhColors.linen50, const Color(0xFFFBF8F4));
      expect(OhColors.nightSurfaceBase, const Color(0xFF0A0A0C));
    });

    test('Lullaby periwinkle is signature, not a canonical token', () {
      const periwinkle = Color(0xFF7B8FD4);
      const canonical = <Color>[
        OhColors.hearth50, OhColors.hearth100, OhColors.hearth200,
        OhColors.hearth300, OhColors.hearth400, OhColors.hearth500,
        OhColors.hearth600, OhColors.hearth700, OhColors.hearth800,
        OhColors.hearth900,
        OhColors.linen50, OhColors.linen100, OhColors.linen200,
        OhColors.linen300, OhColors.linen400, OhColors.linen500,
        OhColors.linen600, OhColors.linen700, OhColors.linen800,
        OhColors.linen900,
        OhColors.sage100, OhColors.sage200, OhColors.sage400,
        OhColors.sage500, OhColors.sage600,
        OhColors.slate100, OhColors.slate300, OhColors.slate500,
        OhColors.slate700,
        OhColors.amber100, OhColors.amber400,
        OhColors.red100, OhColors.red500,
      ];
      expect(canonical, isNot(contains(periwinkle)));
    });
  });
}

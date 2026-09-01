import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A registered route with no caller is a built screen nobody can reach
/// (lullaby:dmmt-03: Growth, Calendar and Doctor Summary shipped that way).
/// This guard reads the router's top-level paths and requires each to be the
/// exact target of a `push`/`go` somewhere in `lib/` outside the router, so a
/// door that gets removed later fails here instead of silently orphaning the
/// screen again. The four shell branches are reached by the bottom
/// navigation bar and are exempt.
void main() {
  test('every non-shell route in router.dart has a caller in lib/', () {
    final routerSource = File('lib/app/router.dart').readAsStringSync();
    final paths = RegExp(r"path:\s*'([^']+)'")
        .allMatches(routerSource)
        .map((m) => m.group(1)!)
        .toSet();
    const shellBranches = {'/dashboard', '/timeline', '/baby', '/health'};
    final routed = paths.difference(shellBranches);
    expect(routed, isNotEmpty, reason: 'parsed no routes: guard is blind');

    final callerSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('app/router.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    final orphans = routed.where((path) {
      final call = RegExp(
          r"\b(push|go|pushReplacement|replace)\(\s*'" +
              RegExp.escape(path) +
              r"'");
      return !call.hasMatch(callerSources);
    }).toList()
      ..sort();

    expect(orphans, isEmpty,
        reason: 'routes registered but never navigated to: $orphans');
  });
}

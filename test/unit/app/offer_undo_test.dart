import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/undo_host.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:openhearth_design/openhearth_design.dart';

class _F extends Failure {
  const _F() : super('disk full');
}

/// Undo re-inserts the captured row. If that write failed, the bar just
/// vanished and the entry was gone with no word (parked from the rollout,
/// concern 9). A failed restore now comes back as a new offer that says so,
/// so the parent can try again; the captured row is not dropped.
void main() {
  test('a failed restore says so and offers Undo again', () async {
    final undo = OhUndoController();
    var calls = 0;
    offerUndo(undo,
        message: 'Feed deleted',
        what: 'the feed',
        restore: () async =>
            ++calls == 1 ? const Err<void>(_F()) : const Success<void>(null));

    expect(undo.pending!.message, 'Feed deleted');
    await undo.undo();
    expect(undo.pending, isNotNull, reason: 'the failure must not vanish');
    expect(undo.pending!.message, 'Couldn’t bring back the feed. Try again.');

    await undo.undo();
    expect(calls, 2);
    expect(undo.pending, isNull);
  });

  test('every deliberate delete offers Undo through offerUndo', () {
    final direct = [
      for (final f in Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
        if (f.readAsStringSync().contains('undo.show(')) f.path,
    ];
    expect(direct, isEmpty,
        reason: 'a bare show() ignores a failed restore');
  });
}

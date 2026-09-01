import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/undo_host.dart';
import 'package:lullaby/features/home_widget/presentation/controllers/home_widget_controller.dart';
import 'package:lullaby/features/sanctuary_backup/after_restore.dart';

class _QuietHomeWidget extends HomeWidgetController {
  _QuietHomeWidget(super.ref);
  int updates = 0;
  @override
  Future<void> triggerUpdate() async => updates++;
}

/// A restore replaces the whole record (AGENTS.md). An Undo offered before
/// it must not survive it: tapping it afterwards would put a row from the
/// old record into the restored one.
void main() {
  test('a restore ends any pending Undo without running it', () async {
    late _QuietHomeWidget widget;
    final container = ProviderContainer(overrides: [
      homeWidgetControllerProvider.overrideWith((ref) {
        widget = _QuietHomeWidget(ref);
        return widget;
      }),
    ]);
    addTearDown(container.dispose);

    var undone = false;
    container.read(undoControllerProvider).show(
          message: 'Feed deleted',
          onUndo: () async => undone = true,
        );

    final hook = Provider<void>((ref) => lullabyAfterRestore(ref));
    container.read(hook);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(undoControllerProvider).pending, isNull);
    expect(undone, isFalse);
    expect(widget.updates, 1);
  });
}

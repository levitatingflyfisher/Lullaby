import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/undo_host.dart';
import '../home_widget/presentation/controllers/home_widget_controller.dart';
import '../tracking/presentation/controllers/timer_controller.dart';

/// Runs after a destructive restore (`SanctuaryBackupConfig.onAfterRestore`).
///
/// The Drift watch streams refresh themselves, but in-memory state can still
/// point at wiped rows: the running timers, the home widget, and any pending
/// Undo, which would put a row from the old record into the restored one.
void lullabyAfterRestore(Ref ref) {
  ref.invalidate(activeTimersProvider);
  unawaited(ref.read(undoControllerProvider).dismiss());
  unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
}

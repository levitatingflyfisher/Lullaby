import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../../tracking/presentation/controllers/diaper_controller.dart';
import '../../../tracking/presentation/controllers/feeding_controller.dart';
import '../../../tracking/presentation/controllers/sleep_controller.dart';
import '../../../tracking/presentation/controllers/timer_controller.dart';
import '../../../../services/home_widget_service.dart';

final homeWidgetControllerProvider = Provider<HomeWidgetController>((ref) {
  return HomeWidgetController(ref);
});

class HomeWidgetController {
  HomeWidgetController(this._ref);
  final Ref _ref;

  Future<void> triggerUpdate() async {
    final baby = _ref.read(activeBabyProvider).valueOrNull;
    final babyId = baby?.id ?? '';

    final lastFeeding = await _ref.read(lastFeedingProvider(babyId).future);
    final lastSleep = await _ref.read(lastSleepProvider(babyId).future);
    final lastDiaper = await _ref.read(lastDiaperProvider(babyId).future);

    final timers = _ref.read(activeTimersProvider);
    final activeTimer = timers.isEmpty
        ? null
        : (timers.where((t) => t.type == TimerType.feeding).firstOrNull ??
           timers.where((t) => t.type == TimerType.sleep).firstOrNull ??
           timers.first);

    await HomeWidgetService.update(
      baby: baby,
      lastFeeding: lastFeeding,
      lastSleep: lastSleep,
      lastDiaper: lastDiaper,
      activeTimer: activeTimer,
    );
  }
}

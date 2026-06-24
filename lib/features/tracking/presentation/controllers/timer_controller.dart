import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/feeding_log.dart';
import '../../domain/entities/sleep_log.dart';

const _uuid = Uuid();

enum TimerType { feeding, sleep }

class ActiveTimer extends Equatable {
  const ActiveTimer({
    required this.id,
    required this.type,
    required this.startTime,
    required this.label,
    required this.elapsed,
    this.logId,
  });

  final String id;
  final TimerType type;
  final DateTime startTime;
  final String label;
  final Duration elapsed;
  final String? logId;

  ActiveTimer tick() {
    final raw = DateTime.now().difference(startTime);
    return ActiveTimer(
      id: id,
      type: type,
      startTime: startTime,
      label: label,
      // Clamp at zero so a backwards clock change can't render a negative timer
      // (M12).
      elapsed: raw.isNegative ? Duration.zero : raw,
      logId: logId,
    );
  }

  @override
  List<Object?> get props => [id, type, startTime, label, elapsed, logId];
}

final activeTimersProvider =
    NotifierProvider<ActiveTimersNotifier, List<ActiveTimer>>(
        ActiveTimersNotifier.new);

class ActiveTimersNotifier extends Notifier<List<ActiveTimer>> {
  Timer? _ticker;
  // The id of the baby whose active sessions are currently rehydrated, so a
  // switch to a different baby re-scopes the timers (H9).
  String? _rehydratedBabyId;

  @override
  List<ActiveTimer> build() {
    ref.onDispose(() => _ticker?.cancel());
    // Re-scope timers to whichever baby is active. The first value loads the
    // initial baby; a later switch drops the previous baby's in-memory timers
    // (their DB sessions persist and reload on switch back) and loads the new
    // baby's. Tracking the target id — rather than a one-shot "done" latch —
    // keeps this correct even if a switch arrives mid-load or the first load
    // fails. fireImmediately covers the case where the active baby resolved
    // before this notifier was built (H9).
    ref.listen(activeBabyProvider, (previous, next) {
      if (next.hasValue) _scopeToBaby(next.valueOrNull?.id);
    }, fireImmediately: true);
    return [];
  }

  void _scopeToBaby(String? babyId) {
    if (babyId == null || babyId == _rehydratedBabyId) return;
    // Switching to a different baby: clear the previous baby's in-memory timers
    // (only when there were some) before loading the new baby's.
    if (_rehydratedBabyId != null) {
      state = [];
      _ticker?.cancel();
      _ticker = null;
    }
    _rehydratedBabyId = babyId;
    unawaited(_rehydrateForBaby(babyId));
  }

  Future<void> _rehydrateForBaby(String babyId) async {
    try {
      final sleepResult =
          await ref.read(sleepRepositoryProvider).getActiveSleep(babyId);
      final feedingResult = await ref
          .read(feedingRepositoryProvider)
          .getActiveBreastFeeding(babyId);

      // A newer switch superseded this load while we were awaiting — abandon it
      // so a stale baby's sessions aren't appended to the new baby's timers.
      if (_rehydratedBabyId != babyId) return;

      final restored = <ActiveTimer>[];
      final now = DateTime.now();

      if (sleepResult is Success<SleepLogEntity?> &&
          sleepResult.value != null) {
        final s = sleepResult.value!;
        restored.add(ActiveTimer(
          id: _uuid.v4(),
          type: TimerType.sleep,
          startTime: s.startTime,
          label: s.type == SleepType.nap ? 'Nap' : 'Night sleep',
          elapsed: now.difference(s.startTime),
          logId: s.id,
        ));
      }

      if (feedingResult is Success<FeedingLogEntity?> &&
          feedingResult.value != null) {
        final f = feedingResult.value!;
        restored.add(ActiveTimer(
          id: _uuid.v4(),
          type: TimerType.feeding,
          startTime: f.startTime,
          label:
              f.side != null ? 'Breast (${f.side!.name})' : 'Breast',
          elapsed: now.difference(f.startTime),
          logId: f.id,
        ));
      }

      final toAppend = restored
          .where((t) => state.every((existing) => existing.logId != t.logId))
          .toList();
      if (toAppend.isNotEmpty) {
        state = [...state, ...toAppend];
        _ensureTicking();
      }
    } catch (_) {
      // Transient failure: reset the target so the next active-baby emission
      // (e.g. a switch) retries, rather than latching timers to the wrong baby.
      if (_rehydratedBabyId == babyId) _rehydratedBabyId = null;
    }
  }

  void startTimer(ActiveTimer timer) {
    state = [...state, timer];
    _ensureTicking();
  }

  ActiveTimer? stopTimer(String timerId) {
    final timer = state.where((t) => t.id == timerId).firstOrNull;
    if (timer == null) return null;
    state = state.where((t) => t.id != timerId).toList();
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    if (state.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
    }
    return timer;
  }

  ActiveTimer? getTimerByLogId(String logId) =>
      state.where((t) => t.logId == logId).firstOrNull;

  ActiveTimer? getTimerByType(TimerType type) =>
      state.where((t) => t.type == type).firstOrNull;

  void _ensureTicking() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(AppConstants.timerTickInterval, (_) {
      state = state.map((t) => t.tick()).toList();
    });
  }
}

import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/sleep_log.dart';
import 'timer_controller.dart';

const _uuid = Uuid();

final activeSleepProvider =
    StreamProvider.family<SleepLogEntity?, String>((ref, babyId) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.watchActiveSleep(babyId);
});

final lastSleepProvider =
    FutureProvider.family<SleepLogEntity?, String>((ref, babyId) async {
  final repo = ref.watch(sleepRepositoryProvider);
  final result = await repo.getLastSleep(babyId);
  return switch (result) {
    Success(value: final v) => v,
    Err() => null,
  };
});

final sleepControllerProvider =
    NotifierProvider<SleepController, AsyncValue<void>>(SleepController.new);

class SleepController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<SleepLogEntity?> startSleep({SleepType type = SleepType.nap}) async {
    // Guard against double-taps creating duplicate open sessions (H6).
    if (state is AsyncLoading) return null;
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return null;

    state = const AsyncLoading();
    final repo = ref.read(sleepRepositoryProvider);

    // If a sleep session is already in progress, surface it (and make sure it
    // has a visible timer) instead of opening a second one.
    final activeResult = await repo.getActiveSleep(baby.id);
    if (activeResult is Success<SleepLogEntity?> && activeResult.value != null) {
      _ensureSleepTimer(activeResult.value!);
      state = const AsyncData(null);
      return activeResult.value;
    }

    final now = DateTime.now();
    final log = SleepLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      startTime: now,
      type: type,
      createdAt: now,
      modifiedAt: now,
    );

    final result = await repo.createSleep(log);

    state = switch (result) {
      Success() => const AsyncData(null),
      Err(failure: final f) => AsyncError(f.message, StackTrace.current),
    };

    if (result is Success) {
      ref.read(activeTimersProvider.notifier).startTimer(ActiveTimer(
            id: _uuid.v4(),
            type: TimerType.sleep,
            startTime: now,
            label: type == SleepType.nap ? 'Nap' : 'Night sleep',
            elapsed: Duration.zero,
            logId: log.id,
          ));
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }

    return result is Success ? log : null;
  }

  void _ensureSleepTimer(SleepLogEntity log) {
    final timers = ref.read(activeTimersProvider.notifier);
    if (timers.getTimerByLogId(log.id) != null) return;
    timers.startTimer(ActiveTimer(
      id: _uuid.v4(),
      type: TimerType.sleep,
      startTime: log.startTime,
      label: log.type == SleepType.nap ? 'Nap' : 'Night sleep',
      elapsed: DateTime.now().difference(log.startTime),
      logId: log.id,
    ));
  }

  Future<Result<void>> stopSleep(String logId) async {
    final repo = ref.read(sleepRepositoryProvider);
    final timers = ref.read(activeTimersProvider.notifier);
    final babyId = ref.read(activeBabyProvider).valueOrNull?.id ?? '';

    final getResult = await repo.getActiveSleep(babyId);
    if (getResult is Success<SleepLogEntity?> && getResult.value != null) {
      final existing = getResult.value!;
      if (existing.id == logId) {
        final now = DateTime.now();
        final minutes = now.difference(existing.startTime).inMinutes;
        final updated = existing.copyWith(
          endTime: () => now,
          durationMinutes: () => minutes < 0 ? 0 : minutes, // clamp (M12)
          modifiedAt: now,
        );
        final updateResult = await repo.updateSleep(updated);
        // Remove the on-screen timer only once the row is actually closed (H7).
        if (updateResult is Success) {
          final timer = timers.getTimerByLogId(logId);
          if (timer != null) timers.stopTimer(timer.id);
        }
        unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
        return updateResult;
      }
    }

    // Nothing to close: clear any stale timer so the UI doesn't show a ghost.
    final stale = timers.getTimerByLogId(logId);
    if (stale != null) timers.stopTimer(stale.id);
    return const Err(NotFoundFailure('Sleep log not found'));
  }

  Future<Result<void>> updateLog(SleepLogEntity log) async {
    final repo = ref.read(sleepRepositoryProvider);
    final result = await repo.updateSleep(log.copyWith(modifiedAt: DateTime.now()));
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<Result<void>> deleteLog(String id) async {
    final repo = ref.read(sleepRepositoryProvider);
    final result = await repo.deleteSleep(id);
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<Duration> getTodaySleepDuration(String babyId) async {
    final repo = ref.read(sleepRepositoryProvider);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1);

    // Look back a day so an overnight session that started yesterday counts the
    // portion that falls in today (H8). Sum each session's overlap with today.
    final result = await repo.getInRange(
        babyId, todayStart.subtract(const Duration(days: 1)), tomorrowStart);
    final sleeps = switch (result) {
      Success(value: final logs) => logs,
      Err() => <SleepLogEntity>[],
    };

    var minutes = 0;
    for (final s in sleeps) {
      final dur = s.computedDuration;
      final sStart = s.startTime;
      final sEnd = dur != null ? sStart.add(dur) : now;
      final overlapStart = sStart.isAfter(todayStart) ? sStart : todayStart;
      final overlapEnd = sEnd.isBefore(tomorrowStart) ? sEnd : tomorrowStart;
      if (overlapEnd.isAfter(overlapStart)) {
        minutes += overlapEnd.difference(overlapStart).inMinutes;
      }
    }
    return Duration(minutes: minutes);
  }
}

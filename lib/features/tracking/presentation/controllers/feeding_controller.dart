import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/feeding_log.dart';
import 'timer_controller.dart';

const _uuid = Uuid();

final recentFeedingsProvider =
    StreamProvider.family<List<FeedingLogEntity>, String>((ref, babyId) {
  final repo = ref.watch(feedingRepositoryProvider);
  return repo.watchAllForBaby(babyId);
});

final lastFeedingProvider =
    StreamProvider.family<FeedingLogEntity?, String>((ref, babyId) {
  final repo = ref.watch(feedingRepositoryProvider);
  return repo.watchLastFeeding(babyId);
});

final feedingControllerProvider =
    NotifierProvider<FeedingController, AsyncValue<void>>(
        FeedingController.new);

class FeedingController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<FeedingLogEntity?> startBreastFeeding(BreastSide side) async {
    // Guard against double-taps creating duplicate open sessions (H6).
    if (state is AsyncLoading) return null;
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return null;

    state = const AsyncLoading();
    final repo = ref.read(feedingRepositoryProvider);

    // If a breast feed is already in progress, surface it (and make sure it has
    // a visible timer) instead of opening a second one.
    final activeResult = await repo.getActiveBreastFeeding(baby.id);
    if (activeResult is Success<FeedingLogEntity?> && activeResult.value != null) {
      _ensureFeedingTimer(activeResult.value!);
      state = const AsyncData(null);
      return activeResult.value;
    }

    final now = DateTime.now();
    final log = FeedingLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      type: FeedingType.breast,
      startTime: now,
      side: side,
      createdAt: now,
      modifiedAt: now,
    );

    final result = await repo.createFeeding(log);

    state = switch (result) {
      Success() => const AsyncData(null),
      Err(failure: final f) => AsyncError(f.message, StackTrace.current),
    };

    if (result is Success) {
      ref.read(activeTimersProvider.notifier).startTimer(ActiveTimer(
            id: _uuid.v4(),
            type: TimerType.feeding,
            startTime: now,
            label: 'Breast (${side.name})',
            elapsed: Duration.zero,
            logId: log.id,
          ));
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }

    return result is Success ? log : null;
  }

  void _ensureFeedingTimer(FeedingLogEntity log) {
    final timers = ref.read(activeTimersProvider.notifier);
    if (timers.getTimerByLogId(log.id) != null) return;
    timers.startTimer(ActiveTimer(
      id: _uuid.v4(),
      type: TimerType.feeding,
      startTime: log.startTime,
      label: log.side != null ? 'Breast (${log.side!.name})' : 'Breast',
      elapsed: DateTime.now().difference(log.startTime),
      logId: log.id,
    ));
  }

  Future<Result<void>> stopBreastFeeding(String logId) async {
    final repo = ref.read(feedingRepositoryProvider);
    final timers = ref.read(activeTimersProvider.notifier);
    final babyId = ref.read(activeBabyProvider).valueOrNull?.id ?? '';

    // Resolve the actual in-progress breast feed — not merely the last feed of
    // any type, so a bottle/solid logged meanwhile can't strand this session
    // (H7).
    final getResult = await repo.getActiveBreastFeeding(babyId);
    if (getResult is Success<FeedingLogEntity?> && getResult.value != null) {
      final existing = getResult.value!;
      if (existing.id == logId) {
        final now = DateTime.now();
        final minutes = now.difference(existing.startTime).inMinutes;
        final updated = existing.copyWith(
          endTime: () => now,
          durationMinutes: () => minutes < 0 ? 0 : minutes, // clamp (M12)
          modifiedAt: now,
        );
        final updateResult = await repo.updateFeeding(updated);
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
    return const Err(NotFoundFailure('Feeding log not found'));
  }

  Future<Result<void>> logBottleFeeding({
    required double amountMl,
    double? amountOz,
    String? notes,
  }) async {
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return const Err(NotFoundFailure('No active baby'));

    final now = DateTime.now();
    final log = FeedingLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      type: FeedingType.bottle,
      startTime: now,
      amountMl: amountMl,
      amountOz: amountOz,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    final repo = ref.read(feedingRepositoryProvider);
    final result = await repo.createFeeding(log);
    if (result is Success) {
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }
    return result;
  }

  Future<Result<void>> logSolidFeeding({String? notes}) async {
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return const Err(NotFoundFailure('No active baby'));

    final now = DateTime.now();
    final log = FeedingLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      type: FeedingType.solid,
      startTime: now,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    final repo = ref.read(feedingRepositoryProvider);
    final result = await repo.createFeeding(log);
    if (result is Success) {
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }
    return result;
  }

  Future<Result<void>> updateLog(FeedingLogEntity log) async {
    final repo = ref.read(feedingRepositoryProvider);
    final result = await repo.updateFeeding(
        log.copyWith(modifiedAt: DateTime.now()));
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<Result<void>> deleteLog(String id) async {
    final repo = ref.read(feedingRepositoryProvider);
    final result = await repo.deleteFeeding(id);
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<int> getTodayFeedingCount(String babyId) async {
    final repo = ref.read(feedingRepositoryProvider);
    final now = DateTime.now();
    final result = await repo.getInRange(babyId, now.startOfDay, now.endOfDay);
    return switch (result) {
      Success(value: final logs) => logs.length,
      Err() => 0,
    };
  }
}

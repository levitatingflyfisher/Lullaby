import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/diaper_log.dart';

const _uuid = Uuid();

final recentDiapersProvider =
    StreamProvider.family<List<DiaperLogEntity>, String>((ref, babyId) {
  final repo = ref.watch(diaperRepositoryProvider);
  return repo.watchAllForBaby(babyId);
});

final lastDiaperProvider =
    FutureProvider.family<DiaperLogEntity?, String>((ref, babyId) async {
  final repo = ref.watch(diaperRepositoryProvider);
  final result = await repo.getLastDiaper(babyId);
  return switch (result) {
    Success(value: final v) => v,
    Err() => null,
  };
});

final diaperControllerProvider =
    NotifierProvider<DiaperController, AsyncValue<void>>(
        DiaperController.new);

class DiaperController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<DiaperLogEntity?> quickLogWet() async {
    if (state.isLoading) return null;
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return null;

    state = const AsyncLoading();
    final now = DateTime.now();
    final log = DiaperLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      time: now,
      type: DiaperType.wet,
      createdAt: now,
      modifiedAt: now,
    );

    final repo = ref.read(diaperRepositoryProvider);
    final result = await repo.createDiaper(log);
    state = switch (result) {
      Success() => const AsyncData(null),
      Err(failure: final f) => AsyncError(f.message, StackTrace.current),
    };
    if (result is Success) {
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }
    return result is Success ? log : null;
  }

  Future<Result<void>> logDiaper({
    required DiaperType type,
    StoolColor? color,
    String? notes,
  }) async {
    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) {
      return const Err(NotFoundFailure('No active baby'));
    }

    final now = DateTime.now();
    final log = DiaperLogEntity(
      id: _uuid.v4(),
      babyId: baby.id,
      time: now,
      type: type,
      color: color,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    final repo = ref.read(diaperRepositoryProvider);
    final result = await repo.createDiaper(log);
    if (result is Success) {
      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    }
    return result;
  }

  Future<Result<void>> updateLog(DiaperLogEntity log) async {
    final repo = ref.read(diaperRepositoryProvider);
    final result = await repo.updateDiaper(log.copyWith(modifiedAt: DateTime.now()));
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<Result<void>> deleteLog(String id) async {
    final repo = ref.read(diaperRepositoryProvider);
    final result = await repo.deleteDiaper(id);
    unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
    return result;
  }

  Future<int> getTodayDiaperCount(String babyId) async {
    final repo = ref.read(diaperRepositoryProvider);
    final now = DateTime.now();
    final result = await repo.countInRange(babyId, now.startOfDay, now.endOfDay);
    return switch (result) {
      Success(value: final count) => count,
      Err() => 0,
    };
  }
}

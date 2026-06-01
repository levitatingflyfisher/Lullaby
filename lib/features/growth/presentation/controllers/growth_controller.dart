import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/growth_record.dart';

const _uuid = Uuid();

final growthRecordsProvider =
    StreamProvider.family<List<GrowthRecordEntity>, String>((ref, babyId) {
  final repo = ref.watch(growthRepositoryProvider);
  return repo.watchAllForBaby(babyId);
});

final latestGrowthProvider =
    FutureProvider.family<GrowthRecordEntity?, String>((ref, babyId) async {
  final repo = ref.watch(growthRepositoryProvider);
  final result = await repo.getLatest(babyId);
  return result is Success<GrowthRecordEntity?> ? result.value : null;
});

final growthControllerProvider =
    NotifierProvider<GrowthController, AsyncValue<void>>(GrowthController.new);

class GrowthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<GrowthRecordEntity>> createRecord({
    required String babyId,
    required DateTime measuredAt,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    String? notes,
  }) async {
    final now = DateTime.now();
    final record = GrowthRecordEntity(
      id: _uuid.v4(),
      babyId: babyId,
      measuredAt: measuredAt,
      weightKg: weightKg,
      heightCm: heightCm,
      headCircumferenceCm: headCircumferenceCm,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    state = const AsyncLoading();
    final repo = ref.read(growthRepositoryProvider);
    final result = await repo.createGrowthRecord(record);

    return switch (result) {
      Success() => () {
          state = const AsyncData(null);
          return Success(record);
        }(),
      Err(failure: final f) => () {
          state = AsyncError(f.message, StackTrace.current);
          return Err<GrowthRecordEntity>(f);
        }(),
    };
  }

  Future<Result<void>> updateRecord(GrowthRecordEntity record) async {
    final repo = ref.read(growthRepositoryProvider);
    return repo.updateGrowthRecord(record.copyWith(modifiedAt: DateTime.now()));
  }

  Future<Result<void>> deleteRecord(String id) async {
    final repo = ref.read(growthRepositoryProvider);
    return repo.deleteGrowthRecord(id);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/baby.dart';

const _uuid = Uuid();

final babyListProvider = StreamProvider<List<BabyEntity>>((ref) {
  final repo = ref.watch(babyRepositoryProvider);
  return repo.watchAllBabies();
});

final babyControllerProvider =
    NotifierProvider<BabyController, AsyncValue<void>>(BabyController.new);

class BabyController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<BabyEntity>> createBaby({
    required String name,
    required DateTime dateOfBirth,
    Gender? gender,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final baby = BabyEntity(
      id: _uuid.v4(),
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      photoPath: photoPath,
      isActive: true,
      createdAt: now,
      modifiedAt: now,
    );

    state = const AsyncLoading();
    final repo = ref.read(babyRepositoryProvider);
    final result = await repo.createBaby(baby);

    return switch (result) {
      Success() => () {
          state = const AsyncData(null);
          return Success(baby);
        }(),
      Err(failure: final f) => () {
          state = AsyncError(f.message, StackTrace.current);
          return Err<BabyEntity>(f);
        }(),
    };
  }

  Future<Result<void>> updateBaby(BabyEntity baby) async {
    final repo = ref.read(babyRepositoryProvider);
    return repo.updateBaby(baby.copyWith(modifiedAt: DateTime.now()));
  }

  Future<Result<void>> deleteBaby(String id) async {
    final repo = ref.read(babyRepositoryProvider);
    return repo.deleteBaby(id);
  }

  Future<Result<void>> setActiveBaby(String id) async {
    final repo = ref.read(babyRepositoryProvider);
    return repo.setActiveBaby(id);
  }
}

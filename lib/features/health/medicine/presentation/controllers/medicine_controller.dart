import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/errors/result.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../domain/entities/medicine_log.dart';

const _uuid = Uuid();

final medicineLogsProvider =
    StreamProvider.family<List<MedicineLogEntity>, String>((ref, babyId) {
  final repo = ref.watch(medicineRepositoryProvider);
  return repo.watchAllForBaby(babyId);
});

final medicineControllerProvider =
    NotifierProvider<MedicineController, AsyncValue<void>>(
        MedicineController.new);

class MedicineController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<MedicineLogEntity>> add({
    required String babyId,
    required String medicineName,
    double? dosage,
    String? dosageUnit,
    required DateTime administeredAt,
    String? notes,
  }) async {
    final now = DateTime.now();
    final log = MedicineLogEntity(
      id: _uuid.v4(),
      babyId: babyId,
      medicineName: medicineName,
      dosage: dosage,
      dosageUnit: dosageUnit,
      administeredAt: administeredAt,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    state = const AsyncLoading();
    final repo = ref.read(medicineRepositoryProvider);
    final result = await repo.createMedicineLog(log);

    return switch (result) {
      Success() => () {
          state = const AsyncData(null);
          return Success(log);
        }(),
      Err(failure: final f) => () {
          state = AsyncError(f.message, StackTrace.current);
          return Err<MedicineLogEntity>(f);
        }(),
    };
  }

  Future<Result<void>> update(MedicineLogEntity log) async {
    final repo = ref.read(medicineRepositoryProvider);
    return repo.updateMedicineLog(log.copyWith(modifiedAt: DateTime.now()));
  }

  Future<Result<void>> delete(String id) async {
    final repo = ref.read(medicineRepositoryProvider);
    return repo.deleteMedicineLog(id);
  }
}

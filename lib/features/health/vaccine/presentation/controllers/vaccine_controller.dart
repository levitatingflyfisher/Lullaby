import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/errors/result.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../domain/entities/vaccine_record.dart';

const _uuid = Uuid();

final vaccineRecordsProvider =
    StreamProvider.family<List<VaccineRecordEntity>, String>((ref, babyId) {
  final repo = ref.watch(vaccineRepositoryProvider);
  return repo.watchAllForBaby(babyId);
});

final vaccineControllerProvider =
    NotifierProvider<VaccineController, AsyncValue<void>>(
        VaccineController.new);

class VaccineController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<VaccineRecordEntity>> add({
    required String babyId,
    required String vaccineName,
    int? doseNumber,
    DateTime? scheduledDate,
    DateTime? administeredDate,
    String? provider,
    String? notes,
  }) async {
    final now = DateTime.now();
    final record = VaccineRecordEntity(
      id: _uuid.v4(),
      babyId: babyId,
      vaccineName: vaccineName,
      doseNumber: doseNumber,
      scheduledDate: scheduledDate,
      administeredDate: administeredDate,
      provider: provider,
      notes: notes,
      createdAt: now,
      modifiedAt: now,
    );

    state = const AsyncLoading();
    final repo = ref.read(vaccineRepositoryProvider);
    final result = await repo.createVaccineRecord(record);

    return switch (result) {
      Success() => () {
          state = const AsyncData(null);
          return Success(record);
        }(),
      Err(failure: final f) => () {
          state = AsyncError(f.message, StackTrace.current);
          return Err<VaccineRecordEntity>(f);
        }(),
    };
  }

  Future<Result<void>> update(VaccineRecordEntity record) async {
    final repo = ref.read(vaccineRepositoryProvider);
    return repo.updateVaccineRecord(record.copyWith(modifiedAt: DateTime.now()));
  }

  Future<Result<void>> markAdministered(
      String id, VaccineRecordEntity record, DateTime date) async {
    final updated = record.copyWith(
      administeredDate: () => date,
      modifiedAt: DateTime.now(),
    );
    final repo = ref.read(vaccineRepositoryProvider);
    return repo.updateVaccineRecord(updated);
  }

  Future<Result<void>> delete(String id) async {
    final repo = ref.read(vaccineRepositoryProvider);
    return repo.deleteVaccineRecord(id);
  }
}

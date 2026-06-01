import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/result.dart';
import '../../core/providers/repository_providers.dart';
import '../growth/domain/entities/growth_record.dart';
import '../health/medicine/domain/entities/medicine_log.dart';
import '../health/vaccine/domain/entities/vaccine_record.dart';
import '../tracking/domain/entities/diaper_log.dart';
import '../tracking/domain/entities/feeding_log.dart';
import '../tracking/domain/entities/sleep_log.dart';
import 'export_service.dart';

final rawExportProvider =
    FutureProvider.family<String, String>((ref, babyId) async {
  final feedingRepo = ref.watch(feedingRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  final diaperRepo = ref.watch(diaperRepositoryProvider);
  final growthRepo = ref.watch(growthRepositoryProvider);
  final medicineRepo = ref.watch(medicineRepositoryProvider);
  final vaccineRepo = ref.watch(vaccineRepositoryProvider);

  final feedingResult = await feedingRepo.getAllForBaby(babyId);
  final sleepResult = await sleepRepo.getAllForBaby(babyId);
  final diaperResult = await diaperRepo.getAllForBaby(babyId);
  final growthResult = await growthRepo.getAllForBaby(babyId);
  final medicineResult = await medicineRepo.getAllForBaby(babyId);
  final vaccineResult = await vaccineRepo.getAllForBaby(babyId);

  final feedings = feedingResult is Success<List<FeedingLogEntity>>
      ? feedingResult.value
      : <FeedingLogEntity>[];
  final sleeps = sleepResult is Success<List<SleepLogEntity>>
      ? sleepResult.value
      : <SleepLogEntity>[];
  final diapers = diaperResult is Success<List<DiaperLogEntity>>
      ? diaperResult.value
      : <DiaperLogEntity>[];
  final growthRecords = growthResult is Success<List<GrowthRecordEntity>>
      ? growthResult.value
      : <GrowthRecordEntity>[];
  final medicines = medicineResult is Success<List<MedicineLogEntity>>
      ? medicineResult.value
      : <MedicineLogEntity>[];
  final vaccines = vaccineResult is Success<List<VaccineRecordEntity>>
      ? vaccineResult.value
      : <VaccineRecordEntity>[];

  return const ExportService().generateRawCsv(
    feedings: feedings,
    sleeps: sleeps,
    diapers: diapers,
    growthRecords: growthRecords,
    medicines: medicines,
    vaccines: vaccines,
  );
});

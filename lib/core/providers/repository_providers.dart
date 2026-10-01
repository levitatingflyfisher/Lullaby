import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/babies/data/repositories/baby_repository_impl.dart';
import '../../features/babies/domain/repositories/baby_repository.dart';
import '../../features/growth/data/repositories/growth_repository_impl.dart';
import '../../features/growth/domain/repositories/growth_repository.dart';
import '../../features/health/medicine/data/repositories/medicine_repository_impl.dart';
import '../../features/health/medicine/domain/repositories/medicine_repository.dart';
import '../../features/health/vaccine/data/repositories/vaccine_repository_impl.dart';
import '../../features/health/vaccine/domain/repositories/vaccine_repository.dart';
import '../../features/tracking/data/repositories/diaper_repository_impl.dart';
import '../../features/tracking/data/repositories/feeding_repository_impl.dart';
import '../../features/tracking/data/repositories/sleep_repository_impl.dart';
import '../../features/tracking/domain/repositories/diaper_repository.dart';
import '../../features/tracking/domain/repositories/feeding_repository.dart';
import '../../features/tracking/domain/repositories/sleep_repository.dart';
import '../../features/handoff/data/handoff_repository_impl.dart';
import '../../features/handoff/domain/handoff_repository.dart';
import 'database_provider.dart';
import 'sync_providers.dart';

final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BabyRepositoryImpl(db.babyDao, ref.watch(recordWriterProvider));
});

final feedingRepositoryProvider = Provider<FeedingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FeedingRepositoryImpl(db.feedingDao, ref.watch(recordWriterProvider));
});

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SleepRepositoryImpl(db.sleepDao, ref.watch(recordWriterProvider));
});

final diaperRepositoryProvider = Provider<DiaperRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DiaperRepositoryImpl(db.diaperDao, ref.watch(recordWriterProvider));
});

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GrowthRepositoryImpl(db.growthDao, ref.watch(recordWriterProvider));
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MedicineRepositoryImpl(db.medicineDao, ref.watch(recordWriterProvider));
});

final vaccineRepositoryProvider = Provider<VaccineRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VaccineRepositoryImpl(db.vaccineDao, ref.watch(recordWriterProvider));
});

final handoffRepositoryProvider = Provider<HandoffRepository>((ref) {
  return HandoffRepositoryImpl(
      ref.watch(databaseProvider), ref.watch(recordWriterProvider));
});

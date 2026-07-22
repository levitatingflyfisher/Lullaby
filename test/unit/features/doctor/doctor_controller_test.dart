import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/core/providers/repository_providers.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/controllers/doctor_controller.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/domain/repositories/growth_repository.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';
import 'package:lullaby/features/health/medicine/domain/repositories/medicine_repository.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';
import 'package:lullaby/features/health/vaccine/domain/repositories/vaccine_repository.dart';
import 'package:lullaby/features/stats/domain/services/stats_aggregator.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';

class _MockStatsAggregator extends Mock implements StatsAggregator {}

class _MockGrowthRepository extends Mock implements GrowthRepository {}

class _MockMedicineRepository extends Mock implements MedicineRepository {}

class _MockVaccineRepository extends Mock implements VaccineRepository {}

void main() {
  late _MockStatsAggregator aggregator;
  late _MockGrowthRepository growthRepo;
  late _MockMedicineRepository medicineRepo;
  late _MockVaccineRepository vaccineRepo;

  setUp(() {
    aggregator = _MockStatsAggregator();
    growthRepo = _MockGrowthRepository();
    medicineRepo = _MockMedicineRepository();
    vaccineRepo = _MockVaccineRepository();

    when(() => aggregator.getAverages(any(), any(), any())).thenAnswer(
        (_) async => (avgFeeds: 0.0, avgSleepHours: 0.0, avgDiapers: 0.0));
    when(() => medicineRepo.getInRange(any(), any(), any()))
        .thenAnswer((_) async => const Success(<MedicineLogEntity>[]));
    when(() => vaccineRepo.getAdministered(any()))
        .thenAnswer((_) async => const Success(<VaccineRecordEntity>[]));
  });

  ProviderContainer buildContainer() => ProviderContainer(overrides: [
        statsAggregatorProvider.overrideWithValue(aggregator),
        growthRepositoryProvider.overrideWithValue(growthRepo),
        medicineRepositoryProvider.overrideWithValue(medicineRepo),
        vaccineRepositoryProvider.overrideWithValue(vaccineRepo),
      ]);

  BabyEntity baby({Gender? gender}) => BabyEntity(
        id: 'baby1',
        name: 'Alice',
        dateOfBirth: DateTime(2024, 1, 1),
        gender: gender,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        modifiedAt: DateTime(2024, 1, 1),
      );

  GrowthRecordEntity growthAt(DateTime measuredAt) => GrowthRecordEntity(
        id: 'g1',
        babyId: 'baby1',
        measuredAt: measuredAt,
        weightKg: 12.0,
        createdAt: measuredAt,
        modifiedAt: measuredAt,
      );

  group('doctorSummaryProvider WHO-percentile notes', () {
    test(
        'flags growthOutsideWhoRange even when the baby has no recorded sex '
        '(the range note must not depend on the gender guard)', () async {
      // Measurement at ~30 months — outside the WHO 0–24 month tables.
      when(() => growthRepo.getLatest('baby1')).thenAnswer(
          (_) async => Success(growthAt(DateTime(2026, 7, 1))));

      final container = buildContainer();
      addTearDown(container.dispose);
      final summary = await container
          .read(doctorSummaryProvider(baby(gender: null)).future);

      expect(summary, isNotNull);
      expect(summary!.growthOutsideWhoRange, isTrue,
          reason: 'The out-of-range note is owed regardless of whether a '
              'sex is recorded — the age alone makes percentiles unknowable.');
      expect(summary.weightPercentile, isNull);
    });

    test(
        'flags percentilesNeedRecordedSex when the measurement is in range '
        'and the missing sex is the only blocker', () async {
      // Measurement at ~6 months — well inside the WHO tables.
      when(() => growthRepo.getLatest('baby1')).thenAnswer(
          (_) async => Success(growthAt(DateTime(2024, 7, 1))));

      final container = buildContainer();
      addTearDown(container.dispose);
      final summary = await container
          .read(doctorSummaryProvider(baby(gender: null)).future);

      expect(summary, isNotNull);
      expect(summary!.growthOutsideWhoRange, isFalse);
      expect(summary.percentilesNeedRecordedSex, isTrue,
          reason: 'Percentiles are missing only because no sex is recorded — '
              'the summary must say so instead of staying silent.');
      expect(summary.weightPercentile, isNull);
    });

    test(
        'does NOT flag percentilesNeedRecordedSex when a sex is recorded '
        '(percentiles compute normally)', () async {
      when(() => growthRepo.getLatest('baby1')).thenAnswer(
          (_) async => Success(growthAt(DateTime(2024, 7, 1))));

      final container = buildContainer();
      addTearDown(container.dispose);
      final summary = await container
          .read(doctorSummaryProvider(baby(gender: Gender.male)).future);

      expect(summary, isNotNull);
      expect(summary!.percentilesNeedRecordedSex, isFalse);
      expect(summary.growthOutsideWhoRange, isFalse);
      expect(summary.weightPercentile, isNotNull);
    });

    test(
        'does NOT flag percentilesNeedRecordedSex when the range is already '
        'the blocker (one honest note at a time)', () async {
      when(() => growthRepo.getLatest('baby1')).thenAnswer(
          (_) async => Success(growthAt(DateTime(2026, 7, 1))));

      final container = buildContainer();
      addTearDown(container.dispose);
      final summary = await container
          .read(doctorSummaryProvider(baby(gender: null)).future);

      expect(summary, isNotNull);
      expect(summary!.growthOutsideWhoRange, isTrue);
      expect(summary.percentilesNeedRecordedSex, isFalse);
    });
  });
}

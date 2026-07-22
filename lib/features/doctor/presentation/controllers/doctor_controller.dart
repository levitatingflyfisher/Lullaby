import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../growth/domain/entities/growth_record.dart';
import '../../../growth/domain/entities/who_percentile_data.dart';
import '../../../babies/domain/entities/baby.dart';
import '../../../health/medicine/domain/entities/medicine_log.dart';
import '../../../health/vaccine/domain/entities/vaccine_record.dart';
import '../../../stats/presentation/controllers/stats_controller.dart';

final doctorDateRangeProvider = StateProvider<DateTimeRange>(
  (ref) {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  },
);

class DoctorSummary {
  const DoctorSummary({
    required this.baby,
    required this.dateRange,
    required this.avgFeedsPerDay,
    required this.avgSleepHoursPerDay,
    required this.avgDiapersPerDay,
    this.latestGrowth,
    this.weightPercentile,
    this.heightPercentile,
    this.headPercentile,
    this.growthOutsideWhoRange = false,
    this.percentilesNeedRecordedSex = false,
    this.recentMedicines = const [],
    this.administeredVaccines = const [],
  });

  final BabyEntity baby;
  final DateTimeRange dateRange;
  final double avgFeedsPerDay;
  final double avgSleepHoursPerDay;
  final double avgDiapersPerDay;
  final GrowthRecordEntity? latestGrowth;
  final double? weightPercentile;
  final double? heightPercentile;
  final double? headPercentile;

  /// True when the latest measurement was taken outside the 0–24 month window
  /// the WHO tables cover — the percentiles above are null because no honest
  /// figure exists, and the UI should say so rather than stay silent.
  final bool growthOutsideWhoRange;

  /// True when the latest measurement is inside the WHO window but the baby
  /// has no recorded sex — the only thing standing between the user and a
  /// percentile. Distinct from [growthOutsideWhoRange] so the UI can name
  /// the actual blocker.
  final bool percentilesNeedRecordedSex;
  final List<MedicineLogEntity> recentMedicines;
  final List<VaccineRecordEntity> administeredVaccines;
}

// autoDispose so reopening the summary recomputes with current data (M9).
final doctorSummaryProvider =
    FutureProvider.autoDispose.family<DoctorSummary?, BabyEntity>((ref, baby) async {
  final range = ref.watch(doctorDateRangeProvider);
  final aggregator = ref.watch(statsAggregatorProvider);
  final growthRepo = ref.watch(growthRepositoryProvider);
  final medicineRepo = ref.watch(medicineRepositoryProvider);
  final vaccineRepo = ref.watch(vaccineRepositoryProvider);

  // showDateRangePicker returns the last selected day at 00:00, which the
  // aggregator treats as an exclusive bound — advance to the next midnight so
  // the final day is actually included in the averages (H5).
  final rangeEnd =
      DateTime(range.end.year, range.end.month, range.end.day + 1);
  final averages = await aggregator.getAverages(
    baby.id,
    range.start,
    rangeEnd,
  );

  final latestResult = await growthRepo.getLatest(baby.id);
  final latestGrowth = latestResult is Success<GrowthRecordEntity?>
      ? latestResult.value
      : null;

  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final medicineResult =
      await medicineRepo.getInRange(baby.id, thirtyDaysAgo, now);
  final recentMedicines = medicineResult is Success<List<MedicineLogEntity>>
      ? medicineResult.value
      : <MedicineLogEntity>[];

  final vaccineResult = await vaccineRepo.getAdministered(baby.id);
  final administeredVaccines =
      vaccineResult is Success<List<VaccineRecordEntity>>
          ? vaccineResult.value
          : <VaccineRecordEntity>[];

  double? weightPercentile;
  double? heightPercentile;
  double? headPercentile;
  var growthOutsideWhoRange = false;
  var percentilesNeedRecordedSex = false;

  final gender = baby.gender;
  if (latestGrowth != null) {
    // Percentiles must be read at the age the measurement was TAKEN, not the
    // baby's current age (H3) — an old measurement against today's age bands
    // produces a wildly wrong figure.
    final ageMonths =
        latestGrowth.measuredAt.difference(baby.dateOfBirth).inDays / 30.44;
    // The calculator itself returns null for ages outside its 0–24 month
    // tables; this flag lets the UI say WHY the percentile is missing
    // instead of silently omitting it. Checked before the gender guard —
    // an out-of-range measurement is out of range whether or not a sex is
    // recorded, and the note is owed either way.
    growthOutsideWhoRange = !PercentileCalculator.ageWithinWhoRange(ageMonths);
    if (gender == null) {
      // Only computed when the sex is known (M8). When the age IS in range,
      // the missing sex is the sole blocker — name it, distinctly from the
      // range note, so the user knows recording a sex would unlock figures.
      percentilesNeedRecordedSex = !growthOutsideWhoRange;
    } else {
      const calculator = PercentileCalculator();
      if (latestGrowth.weightKg != null) {
        weightPercentile = calculator.getPercentile(
            gender, ageMonths, latestGrowth.weightKg!, MeasurementType.weight);
      }
      if (latestGrowth.heightCm != null) {
        heightPercentile = calculator.getPercentile(
            gender, ageMonths, latestGrowth.heightCm!, MeasurementType.height);
      }
      if (latestGrowth.headCircumferenceCm != null) {
        headPercentile = calculator.getPercentile(
            gender,
            ageMonths,
            latestGrowth.headCircumferenceCm!,
            MeasurementType.headCircumference);
      }
    }
  }

  return DoctorSummary(
    baby: baby,
    dateRange: range,
    avgFeedsPerDay: averages.avgFeeds,
    avgSleepHoursPerDay: averages.avgSleepHours,
    avgDiapersPerDay: averages.avgDiapers,
    latestGrowth: latestGrowth,
    weightPercentile: weightPercentile,
    heightPercentile: heightPercentile,
    headPercentile: headPercentile,
    growthOutsideWhoRange: growthOutsideWhoRange,
    percentilesNeedRecordedSex: percentilesNeedRecordedSex,
    recentMedicines: recentMedicines,
    administeredVaccines: administeredVaccines,
  );
});

import '../../babies/domain/entities/baby.dart';
import 'entities/growth_record.dart';
import 'entities/who_percentile_data.dart';

/// WHO percentiles for one growth record, plus the reason when there are
/// none. The single place that turns a record into figures, shared by the
/// growth screen and the doctor summary so the two can never disagree.
class GrowthPercentiles {
  const GrowthPercentiles({
    this.weight,
    this.height,
    this.head,
    this.outsideWhoRange = false,
    this.needsRecordedSex = false,
  });

  final double? weight;
  final double? height;
  final double? head;

  /// The record was taken outside the 0–24 month window the WHO tables
  /// cover, so no honest figure exists.
  final bool outsideWhoRange;

  /// The record is inside the WHO window but the baby has no recorded sex —
  /// the only thing standing between the user and a percentile.
  final bool needsRecordedSex;

  static GrowthPercentiles of(GrowthRecordEntity record, BabyEntity baby) {
    // Percentiles must be read at the age the measurement was TAKEN, not the
    // baby's current age (H3) — an old measurement against today's age bands
    // produces a wildly wrong figure.
    final ageMonths =
        record.measuredAt.difference(baby.dateOfBirth).inDays / 30.44;
    // Checked before the sex guard: an out-of-range measurement is out of
    // range whether or not a sex is recorded, and the note is owed either way.
    final outside = !PercentileCalculator.ageWithinWhoRange(ageMonths);
    final gender = baby.gender;
    if (gender == null) {
      // Only computed when the sex is known (M8).
      return GrowthPercentiles(
          outsideWhoRange: outside, needsRecordedSex: !outside);
    }
    const calculator = PercentileCalculator();
    double? score(double? value, MeasurementType type) => value == null
        ? null
        : calculator.getPercentile(gender, ageMonths, value, type);
    return GrowthPercentiles(
      weight: score(record.weightKg, MeasurementType.weight),
      height: score(record.heightCm, MeasurementType.height),
      head: score(record.headCircumferenceCm, MeasurementType.headCircumference),
      outsideWhoRange: outside,
    );
  }
}

/// A percentile in plain words: "about the 60th percentile for weight".
///
/// [PercentileCalculator] reports anything at or below P3 as 1.0 and at or
/// above P97 as 99.0; those are sentinels, not measurements, so they read as
/// "below the 3rd" / "above the 97th" rather than a false "about the 1st".
String describePercentile(double percentile, String measure) {
  if (percentile <= 1.0) return 'below the 3rd percentile for $measure';
  if (percentile >= 99.0) return 'above the 97th percentile for $measure';
  return 'about the ${_ordinal(percentile.round())} percentile for $measure';
}

String _ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

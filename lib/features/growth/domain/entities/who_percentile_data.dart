import '../../../babies/domain/entities/baby.dart';

enum MeasurementType { weight, height, headCircumference }

class PercentileBand {
  const PercentileBand({
    required this.percentile,
    required this.values,
  });

  /// The percentile (e.g. 3, 15, 50, 85, 97).
  final int percentile;

  /// Values indexed by age in months (0–24).
  final List<double> values;
}

class PercentileCalculator {
  const PercentileCalculator();

  /// Whether [ageMonths] falls inside the 0–24 month window the WHO tables
  /// here cover. The single source of truth for "can we honestly score this?"
  static bool ageWithinWhoRange(double ageMonths) =>
      ageMonths >= 0 && ageMonths <= 24;

  /// Returns the approximate percentile (0–100) for a given measurement, or
  /// null when no honest figure exists: the age is outside the 0–24 month
  /// tables (clamping a 30-month-old onto the 24-month curves would fabricate
  /// a number), or the measurement matches no band (e.g. NaN).
  double? getPercentile(
    Gender gender,
    double ageMonths,
    double measurement,
    MeasurementType type,
  ) {
    // Written as a positive containment check so a NaN age also lands here
    // (every NaN comparison is false) instead of crashing in floor().
    if (!ageWithinWhoRange(ageMonths)) return null;

    final bands = getPercentileBands(gender, type);

    // Interpolate each band's value at the fractional age rather than snapping
    // to the nearest whole month, which is coarse in early infancy (M7).
    final points = <int, double>{};
    for (final band in bands) {
      points[band.percentile] = _valueAtAge(band.values, ageMonths);
    }

    return percentileFromBandPoints(points, measurement);
  }

  /// Interpolates a percentile from per-band values at a single age.
  ///
  /// Returns null when [points] is missing any canonical band (3/15/50/85/97)
  /// or when [measurement] lands in no band — with strictly
  /// ascending band values that only happens for NaN, which the old code
  /// silently reported as the 50th percentile. Kept static and public so the
  /// degenerate-band division guard is testable (real WHO tables never
  /// trigger it).
  static double? percentileFromBandPoints(
    Map<int, double> points,
    double measurement,
  ) {
    // A partial map has no honest answer either — return the documented
    // null rather than null-asserting into a crash on a missing band.
    final p3 = points[3];
    final p97 = points[97];
    if (p3 == null || p97 == null) return null;
    // If below 3rd percentile
    if (measurement <= p3) return 1.0;
    // If above 97th percentile
    if (measurement >= p97) return 99.0;

    // Linear interpolation between bands
    final percentiles = [3, 15, 50, 85, 97];
    for (int i = 0; i < percentiles.length - 1; i++) {
      final lowerP = percentiles[i];
      final upperP = percentiles[i + 1];
      final lowerV = points[lowerP];
      final upperV = points[upperP];
      if (lowerV == null || upperV == null) return null;

      if (measurement >= lowerV && measurement <= upperV) {
        // Degenerate band (lowerV == upperV): the fraction would be 0/0 = NaN.
        // The measurement sits on both percentiles at once; report the middle.
        if (upperV == lowerV) return (lowerP + upperP) / 2;
        final fraction = (measurement - lowerV) / (upperV - lowerV);
        return lowerP + fraction * (upperP - lowerP);
      }
    }

    // No band matched (NaN measurement, or non-monotone data): there is no
    // honest percentile — never invent a median.
    return null;
  }

  /// Linearly interpolates a band's value at a fractional age in months.
  static double _valueAtAge(List<double> values, double ageMonths) {
    final clamped = ageMonths.clamp(0.0, 24.0);
    final lower = clamped.floor();
    final upper = clamped.ceil();
    if (lower == upper) return values[lower];
    return values[lower] + (clamped - lower) * (values[upper] - values[lower]);
  }

  /// Returns percentile bands for chart rendering.
  List<PercentileBand> getPercentileBands(
    Gender gender,
    MeasurementType type,
  ) {
    final data = switch (type) {
      MeasurementType.weight => gender == Gender.male
          ? _boysWeightForAge
          : _girlsWeightForAge,
      MeasurementType.height => gender == Gender.male
          ? _boysLengthForAge
          : _girlsLengthForAge,
      MeasurementType.headCircumference => gender == Gender.male
          ? _boysHeadForAge
          : _girlsHeadForAge,
    };

    return [
      PercentileBand(percentile: 3, values: data[0]),
      PercentileBand(percentile: 15, values: data[1]),
      PercentileBand(percentile: 50, values: data[2]),
      PercentileBand(percentile: 85, values: data[3]),
      PercentileBand(percentile: 97, values: data[4]),
    ];
  }

  // ── WHO Child Growth Standards: Weight-for-age (kg), 0–24 months ──

  // Boys weight: [P3, P15, P50, P85, P97]
  static const _boysWeightForAge = <List<double>>[
    // P3
    [2.5, 3.4, 4.3, 5.0, 5.6, 6.0, 6.4, 6.7, 6.9, 7.1, 7.4, 7.6, 7.7, 7.9, 8.1, 8.3, 8.4, 8.6, 8.8, 8.9, 9.1, 9.2, 9.4, 9.5, 9.7],
    // P15
    [2.9, 3.9, 4.9, 5.7, 6.2, 6.7, 7.1, 7.4, 7.7, 7.9, 8.1, 8.3, 8.5, 8.7, 8.9, 9.1, 9.3, 9.5, 9.7, 9.8, 10.0, 10.2, 10.3, 10.5, 10.7],
    // P50
    [3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6, 9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3, 11.5, 11.8, 12.0, 12.2],
    // P85
    [3.9, 5.1, 6.3, 7.2, 7.8, 8.4, 8.8, 9.2, 9.6, 9.9, 10.2, 10.5, 10.8, 11.0, 11.3, 11.5, 11.7, 12.0, 12.2, 12.5, 12.7, 13.0, 13.2, 13.5, 13.7],
    // P97
    [4.4, 5.8, 7.1, 8.0, 8.7, 9.3, 9.8, 10.3, 10.7, 11.0, 11.4, 11.7, 12.0, 12.3, 12.6, 12.8, 13.1, 13.4, 13.7, 13.9, 14.2, 14.5, 14.7, 15.0, 15.3],
  ];

  // Girls weight: [P3, P15, P50, P85, P97]
  static const _girlsWeightForAge = <List<double>>[
    // P3
    [2.4, 3.2, 3.9, 4.5, 5.0, 5.4, 5.7, 6.0, 6.3, 6.5, 6.7, 6.9, 7.0, 7.2, 7.4, 7.6, 7.7, 7.9, 8.1, 8.2, 8.4, 8.6, 8.7, 8.9, 9.0],
    // P15
    [2.8, 3.6, 4.5, 5.2, 5.7, 6.1, 6.5, 6.8, 7.0, 7.3, 7.5, 7.7, 7.9, 8.1, 8.3, 8.5, 8.7, 8.8, 9.0, 9.2, 9.4, 9.6, 9.8, 9.9, 10.1],
    // P50
    [3.2, 4.2, 5.1, 5.8, 6.4, 6.9, 7.3, 7.6, 7.9, 8.2, 8.5, 8.7, 8.9, 9.2, 9.4, 9.6, 9.8, 10.0, 10.2, 10.4, 10.6, 10.9, 11.1, 11.3, 11.5],
    // P85
    [3.7, 4.8, 5.8, 6.6, 7.3, 7.8, 8.2, 8.6, 8.9, 9.3, 9.6, 9.9, 10.1, 10.4, 10.6, 10.9, 11.1, 11.4, 11.6, 11.9, 12.1, 12.4, 12.6, 12.8, 13.1],
    // P97
    [4.2, 5.5, 6.6, 7.5, 8.2, 8.8, 9.3, 9.8, 10.2, 10.5, 10.9, 11.2, 11.5, 11.8, 12.1, 12.4, 12.6, 12.9, 13.2, 13.5, 13.7, 14.0, 14.3, 14.6, 14.9],
  ];

  // ── WHO Child Growth Standards: Length-for-age (cm), 0–24 months ──

  // Boys length: [P3, P15, P50, P85, P97]
  static const _boysLengthForAge = <List<double>>[
    // P3
    [46.3, 51.1, 54.7, 57.6, 60.0, 62.0, 63.8, 65.4, 66.8, 68.2, 69.5, 70.7, 71.8, 72.8, 73.8, 74.8, 75.8, 76.7, 77.5, 78.4, 79.2, 80.0, 80.8, 81.5, 82.3],
    // P15
    [47.9, 52.7, 56.4, 59.3, 61.7, 63.7, 65.5, 67.1, 68.6, 70.0, 71.3, 72.5, 73.7, 74.8, 75.8, 76.8, 77.8, 78.7, 79.6, 80.5, 81.3, 82.2, 83.0, 83.8, 84.5],
    // P50
    [49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3, 74.5, 75.7, 76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2, 85.1, 86.0, 86.9, 87.8],
    // P85
    [51.8, 56.7, 60.5, 63.5, 66.0, 68.0, 69.8, 71.3, 72.8, 74.1, 75.4, 76.7, 77.9, 79.1, 80.2, 81.4, 82.5, 83.6, 84.7, 85.8, 86.9, 87.9, 88.9, 89.9, 90.8],
    // P97
    [53.4, 58.4, 62.2, 65.3, 67.8, 69.9, 71.6, 73.2, 74.7, 76.1, 77.4, 78.6, 79.9, 81.1, 82.3, 83.4, 84.6, 85.7, 86.9, 88.0, 89.1, 90.2, 91.3, 92.3, 93.4],
  ];

  // Girls length: [P3, P15, P50, P85, P97]
  static const _girlsLengthForAge = <List<double>>[
    // P3
    [45.6, 50.0, 53.2, 55.8, 57.9, 59.9, 61.5, 63.0, 64.3, 65.6, 66.8, 68.0, 69.2, 70.3, 71.3, 72.4, 73.3, 74.3, 75.2, 76.2, 77.0, 77.9, 78.7, 79.6, 80.4],
    // P15
    [47.2, 51.5, 54.9, 57.5, 59.7, 61.7, 63.4, 64.9, 66.3, 67.6, 68.8, 70.0, 71.3, 72.4, 73.5, 74.5, 75.5, 76.5, 77.5, 78.4, 79.3, 80.2, 81.1, 82.0, 82.8],
    // P50
    [49.1, 53.7, 57.1, 59.8, 62.1, 64.0, 65.7, 67.3, 68.7, 70.1, 71.5, 72.8, 74.0, 75.2, 76.4, 77.5, 78.6, 79.7, 80.7, 81.7, 82.7, 83.7, 84.6, 85.5, 86.4],
    // P85
    [51.1, 55.8, 59.3, 62.1, 64.3, 66.3, 68.0, 69.6, 71.1, 72.6, 74.0, 75.3, 76.6, 77.9, 79.1, 80.3, 81.5, 82.7, 83.9, 85.0, 86.1, 87.1, 88.1, 89.1, 90.0],
    // P97
    [52.7, 57.4, 61.1, 63.9, 66.2, 68.2, 70.0, 71.6, 73.2, 74.7, 76.1, 77.5, 78.9, 80.2, 81.5, 82.7, 84.0, 85.2, 86.5, 87.6, 88.7, 89.8, 90.8, 91.9, 92.9],
  ];

  // ── WHO Child Growth Standards: Head circumference-for-age (cm), 0–24 months ──

  // Boys head: [P3, P15, P50, P85, P97]
  static const _boysHeadForAge = <List<double>>[
    // P3
    [32.4, 35.2, 37.0, 38.3, 39.4, 40.3, 41.0, 41.7, 42.2, 42.6, 43.0, 43.4, 43.6, 43.9, 44.1, 44.4, 44.6, 44.7, 44.9, 45.1, 45.2, 45.3, 45.5, 45.6, 45.7],
    // P15
    [33.4, 36.2, 38.0, 39.3, 40.4, 41.3, 42.0, 42.6, 43.2, 43.6, 44.0, 44.3, 44.6, 44.9, 45.1, 45.3, 45.5, 45.7, 45.9, 46.0, 46.2, 46.3, 46.5, 46.6, 46.7],
    // P50
    [34.5, 37.3, 39.1, 40.5, 41.6, 42.6, 43.3, 43.9, 44.5, 44.9, 45.2, 45.6, 45.9, 46.1, 46.3, 46.6, 46.7, 46.9, 47.1, 47.2, 47.4, 47.5, 47.6, 47.8, 47.9],
    // P85
    [35.6, 38.4, 40.3, 41.7, 42.8, 43.8, 44.6, 45.2, 45.7, 46.1, 46.5, 46.9, 47.1, 47.4, 47.6, 47.8, 48.0, 48.2, 48.3, 48.5, 48.6, 48.8, 48.9, 49.0, 49.2],
    // P97
    [36.7, 39.5, 41.5, 42.9, 44.0, 45.0, 45.8, 46.4, 46.9, 47.4, 47.7, 48.1, 48.4, 48.6, 48.8, 49.0, 49.2, 49.4, 49.6, 49.7, 49.9, 50.0, 50.1, 50.3, 50.4],
  ];

  // Girls head: [P3, P15, P50, P85, P97]
  static const _girlsHeadForAge = <List<double>>[
    // P3
    [31.7, 34.3, 35.8, 37.1, 38.2, 39.0, 39.7, 40.4, 40.9, 41.3, 41.7, 42.0, 42.2, 42.5, 42.7, 42.9, 43.1, 43.3, 43.4, 43.6, 43.7, 43.9, 44.0, 44.1, 44.3],
    // P15
    [32.7, 35.3, 36.9, 38.2, 39.2, 40.1, 40.8, 41.4, 41.9, 42.3, 42.7, 43.0, 43.3, 43.5, 43.7, 43.9, 44.1, 44.3, 44.4, 44.6, 44.7, 44.9, 45.0, 45.2, 45.3],
    // P50
    [33.9, 36.5, 38.3, 39.5, 40.6, 41.5, 42.2, 42.8, 43.4, 43.8, 44.2, 44.5, 44.7, 45.0, 45.2, 45.4, 45.5, 45.7, 45.9, 46.0, 46.2, 46.3, 46.4, 46.6, 46.7],
    // P85
    [35.1, 37.8, 39.6, 40.9, 42.0, 42.9, 43.6, 44.3, 44.8, 45.2, 45.6, 45.9, 46.2, 46.4, 46.6, 46.8, 47.0, 47.2, 47.3, 47.5, 47.6, 47.8, 47.9, 48.0, 48.2],
    // P97
    [36.1, 38.9, 40.7, 42.1, 43.2, 44.1, 44.8, 45.5, 46.0, 46.5, 46.9, 47.2, 47.5, 47.7, 47.9, 48.1, 48.3, 48.5, 48.7, 48.8, 49.0, 49.1, 49.2, 49.4, 49.5],
  ];
}

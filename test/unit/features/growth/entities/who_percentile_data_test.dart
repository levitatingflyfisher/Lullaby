import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/who_percentile_data.dart';

void main() {
  const calculator = PercentileCalculator();

  group('PercentileCalculator.getPercentileBands', () {
    test('returns 5 bands for boys weight', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      expect(bands, hasLength(5));
      expect(bands.map((b) => b.percentile).toList(), [3, 15, 50, 85, 97]);
    });

    test('returns 5 bands for girls weight', () {
      final bands = calculator.getPercentileBands(Gender.female, MeasurementType.weight);
      expect(bands, hasLength(5));
    });

    test('each band has 25 values (0-24 months)', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      for (final band in bands) {
        expect(band.values, hasLength(25));
      }
    });

    test('P50 boys weight at 0 months is ~3.3 kg', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      final p50 = bands.firstWhere((b) => b.percentile == 50);
      expect(p50.values[0], closeTo(3.3, 0.1));
    });

    test('P50 girls length at 0 months is ~49 cm', () {
      final bands = calculator.getPercentileBands(Gender.female, MeasurementType.height);
      final p50 = bands.firstWhere((b) => b.percentile == 50);
      expect(p50.values[0], closeTo(49.1, 0.5));
    });

    test('P50 boys head at 0 months is ~34.5 cm', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.headCircumference);
      final p50 = bands.firstWhere((b) => b.percentile == 50);
      expect(p50.values[0], closeTo(34.5, 0.5));
    });

    test('bands are in ascending order (P3 < P50 < P97) for every month', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      final p3 = bands.firstWhere((b) => b.percentile == 3);
      final p50 = bands.firstWhere((b) => b.percentile == 50);
      final p97 = bands.firstWhere((b) => b.percentile == 97);
      for (int i = 0; i < 25; i++) {
        expect(p3.values[i], lessThan(p50.values[i]));
        expect(p50.values[i], lessThan(p97.values[i]));
      }
    });
  });

  group('PercentileCalculator.getPercentile', () {
    test('returns near 50 for P50 weight value at 0 months boys', () {
      // P50 boys at 0m is 3.3 kg
      final p = calculator.getPercentile(Gender.male, 0, 3.3, MeasurementType.weight);
      expect(p, closeTo(50, 5));
    });

    test('returns low percentile for below P3 value', () {
      final p = calculator.getPercentile(Gender.male, 0, 1.0, MeasurementType.weight);
      expect(p, lessThan(5));
    });

    test('returns high percentile for above P97 value', () {
      final p = calculator.getPercentile(Gender.male, 0, 10.0, MeasurementType.weight);
      expect(p, greaterThan(95));
    });

    test('returns ~15 for P15 weight value at 12 months boys', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      final p15value = bands.firstWhere((b) => b.percentile == 15).values[12];
      final p = calculator.getPercentile(Gender.male, 12, p15value, MeasurementType.weight);
      expect(p, closeTo(15, 5));
    });

    test('works for girls height', () {
      final bands = calculator.getPercentileBands(Gender.female, MeasurementType.height);
      final p50value = bands.firstWhere((b) => b.percentile == 50).values[6];
      final p = calculator.getPercentile(Gender.female, 6, p50value, MeasurementType.height);
      expect(p, closeTo(50, 5));
    });

    test('works at 24 months (edge case)', () {
      final bands = calculator.getPercentileBands(Gender.male, MeasurementType.weight);
      final p50value = bands.firstWhere((b) => b.percentile == 50).values[24];
      final p = calculator.getPercentile(Gender.male, 24, p50value, MeasurementType.weight);
      expect(p, closeTo(50, 5));
    });

    test('works at 0 months (edge case)', () {
      final bands = calculator.getPercentileBands(Gender.female, MeasurementType.headCircumference);
      final p50value = bands.firstWhere((b) => b.percentile == 50).values[0];
      final p = calculator.getPercentile(Gender.female, 0, p50value, MeasurementType.headCircumference);
      expect(p, closeTo(50, 5));
    });
  });

  group('PercentileCalculator.getPercentile honest edges', () {
    // The WHO Child Growth Standards tables here cover 0–24 months. Outside
    // that window there is no honest percentile to report: clamping a
    // 30-month-old onto the 24-month curves silently fabricates a figure.
    test('returns null for a 30-month-old (beyond the 0-24m tables)', () {
      final p = calculator.getPercentile(
          Gender.male, 30, 12.2, MeasurementType.weight);
      expect(p, isNull);
    });

    test('returns null for a negative age', () {
      final p = calculator.getPercentile(
          Gender.female, -1, 3.2, MeasurementType.weight);
      expect(p, isNull);
    });

    test('returns null for a NaN age (not an exception)', () {
      final p = calculator.getPercentile(
          Gender.male, double.nan, 8.0, MeasurementType.weight);
      expect(p, isNull);
    });

    test('returns null (not a fabricated P50) for a NaN measurement', () {
      // NaN compares false against every band, so the old code fell through
      // every branch and silently reported the 50th percentile.
      final p = calculator.getPercentile(
          Gender.male, 12, double.nan, MeasurementType.weight);
      expect(p, isNull);
    });
  });

  group('PercentileCalculator.percentileFromBandPoints', () {
    // Real WHO tables are strictly ascending, so adjacent bands never share a
    // value — but the interpolation must not rely on that: with equal band
    // values the old formula divided by zero and produced NaN.
    test('guards the equal-band division (no NaN)', () {
      final points = {3: 4.0, 15: 5.0, 50: 5.0, 85: 6.0, 97: 7.0};
      final p = PercentileCalculator.percentileFromBandPoints(points, 5.0);
      expect(p, isNotNull);
      expect(p!.isNaN, isFalse);
      expect(p, inInclusiveRange(15, 50));
    });

    test('returns null when the measurement lands in no band', () {
      final points = {3: 4.0, 15: 5.0, 50: 5.5, 85: 6.0, 97: 7.0};
      final p =
          PercentileCalculator.percentileFromBandPoints(points, double.nan);
      expect(p, isNull);
    });

    test('matches getPercentile for an ordinary interpolation', () {
      final points = {3: 4.0, 15: 5.0, 50: 6.0, 85: 7.0, 97: 8.0};
      final p = PercentileCalculator.percentileFromBandPoints(points, 5.5);
      expect(p, equals(32.5)); // halfway between P15 and P50
    });
  });

  group('PercentileCalculator.getPercentile golden regression', () {
    // Exact values captured from the implementation BEFORE the honest-edges
    // change (equals, not closeTo): in-range math must not move by a bit.
    test('in-range results are byte-identical to the pre-change math', () {
      final cases = <(Gender, double, double, MeasurementType, double)>[
        (Gender.male, 0.0, 3.3, MeasurementType.weight, 50.0),
        (Gender.male, 7.3, 8.5, MeasurementType.weight, 54.139784946236546),
        (Gender.female, 6.0, 65.7, MeasurementType.height, 50.0),
        (Gender.male, 23.5, 12.9, MeasurementType.weight, 68.66666666666669),
        (Gender.female, 0.4, 3.0, MeasurementType.weight, 11.399999999999995),
        (Gender.male, 24.0, 15.0, MeasurementType.weight, 94.75),
        (
          Gender.male,
          12.25,
          47.0,
          MeasurementType.headCircumference,
          80.00000000000006
        ),
        (
          Gender.female,
          18.7,
          46.0,
          MeasurementType.headCircumference,
          50.714285714285744
        ),
        (Gender.female, 11.9, 73.0, MeasurementType.height, 38.634686346863504),
        (Gender.male, 0.0, 2.5, MeasurementType.weight, 1.0), // <= P3 floor
        (Gender.male, 24.0, 20.0, MeasurementType.weight, 99.0), // >= P97 cap
        (Gender.female, 3.9, 6.1, MeasurementType.weight, 37.82608695652172),
      ];
      for (final (gender, age, measurement, type, expected) in cases) {
        expect(
          calculator.getPercentile(gender, age, measurement, type),
          equals(expected),
          reason: '$gender $type age=$age measurement=$measurement',
        );
      }
    });
  });
}

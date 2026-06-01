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
}

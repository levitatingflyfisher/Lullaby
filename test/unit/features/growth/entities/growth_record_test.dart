import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';

void main() {
  final now = DateTime(2025, 6, 15);

  GrowthRecordEntity makeRecord({
    String id = 'r1',
    double? weightKg = 5.5,
    double? heightCm = 60.0,
    double? headCircumferenceCm = 40.0,
    String? notes,
  }) =>
      GrowthRecordEntity(
        id: id,
        babyId: 'baby1',
        measuredAt: now,
        weightKg: weightKg,
        heightCm: heightCm,
        headCircumferenceCm: headCircumferenceCm,
        notes: notes,
        createdAt: now,
        modifiedAt: now,
      );

  group('GrowthRecordEntity', () {
    test('construction sets all fields correctly', () {
      final r = makeRecord();
      expect(r.id, 'r1');
      expect(r.babyId, 'baby1');
      expect(r.weightKg, 5.5);
      expect(r.heightCm, 60.0);
      expect(r.headCircumferenceCm, 40.0);
      expect(r.notes, isNull);
    });

    test('hasAnyMeasurement returns true when weight set', () {
      final r = makeRecord(heightCm: null, headCircumferenceCm: null);
      expect(r.hasAnyMeasurement, isTrue);
    });

    test('hasAnyMeasurement returns true when height set', () {
      final r = makeRecord(weightKg: null, headCircumferenceCm: null);
      expect(r.hasAnyMeasurement, isTrue);
    });

    test('hasAnyMeasurement returns true when head set', () {
      final r = makeRecord(weightKg: null, heightCm: null);
      expect(r.hasAnyMeasurement, isTrue);
    });

    test('hasAnyMeasurement returns false when all null', () {
      final r = makeRecord(weightKg: null, heightCm: null, headCircumferenceCm: null);
      expect(r.hasAnyMeasurement, isFalse);
    });

    test('equality — same fields are equal', () {
      final r1 = makeRecord();
      final r2 = makeRecord();
      expect(r1, equals(r2));
    });

    test('inequality — different id', () {
      final r1 = makeRecord(id: 'r1');
      final r2 = makeRecord(id: 'r2');
      expect(r1, isNot(equals(r2)));
    });

    test('copyWith changes only specified fields', () {
      final r = makeRecord();
      final updated = r.copyWith(weightKg: () => 6.0, notes: () => 'check');
      expect(updated.id, 'r1');
      expect(updated.weightKg, 6.0);
      expect(updated.notes, 'check');
      expect(updated.heightCm, 60.0);
    });

    test('copyWith nullable field can be cleared to null', () {
      final r = makeRecord(weightKg: 5.5);
      final cleared = r.copyWith(weightKg: () => null);
      expect(cleared.weightKg, isNull);
    });

    test('copyWith retains value when not specified', () {
      final r = makeRecord(notes: 'existing note');
      final updated = r.copyWith(weightKg: () => 6.0);
      expect(updated.notes, 'existing note');
    });
  });
}

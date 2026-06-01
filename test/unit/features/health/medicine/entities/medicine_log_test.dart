import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';

void main() {
  final base = MedicineLogEntity(
    id: 'log1',
    babyId: 'baby1',
    medicineName: 'Tylenol',
    dosage: 2.5,
    dosageUnit: 'ml',
    administeredAt: DateTime(2025, 6, 15, 10),
    notes: 'fever',
    createdAt: DateTime(2025, 6, 15),
    modifiedAt: DateTime(2025, 6, 15),
  );

  group('MedicineLogEntity', () {
    test('equality: same values are equal', () {
      final other = MedicineLogEntity(
        id: 'log1',
        babyId: 'baby1',
        medicineName: 'Tylenol',
        dosage: 2.5,
        dosageUnit: 'ml',
        administeredAt: DateTime(2025, 6, 15, 10),
        notes: 'fever',
        createdAt: DateTime(2025, 6, 15),
        modifiedAt: DateTime(2025, 6, 15),
      );
      expect(base, equals(other));
    });

    test('equality: different medicineName', () {
      final other = base.copyWith(medicineName: 'Ibuprofen');
      expect(base, isNot(equals(other)));
    });

    test('copyWith preserves unset fields', () {
      final copy = base.copyWith(medicineName: 'Motrin');
      expect(copy.id, base.id);
      expect(copy.babyId, base.babyId);
      expect(copy.medicineName, 'Motrin');
      expect(copy.dosage, base.dosage);
      expect(copy.dosageUnit, base.dosageUnit);
    });

    test('copyWith can null out optional fields', () {
      final copy = base.copyWith(
        dosage: () => null,
        dosageUnit: () => null,
        notes: () => null,
      );
      expect(copy.dosage, isNull);
      expect(copy.dosageUnit, isNull);
      expect(copy.notes, isNull);
    });

    test('copyWith can set optional fields', () {
      final noNote = MedicineLogEntity(
        id: 'log2',
        babyId: 'baby1',
        medicineName: 'Vitamin',
        administeredAt: DateTime(2025, 6, 15),
        createdAt: DateTime(2025, 6, 15),
        modifiedAt: DateTime(2025, 6, 15),
      );
      final copy = noNote.copyWith(notes: () => 'added note');
      expect(copy.notes, 'added note');
    });

    test('props includes all fields', () {
      expect(base.props, hasLength(9));
    });
  });
}

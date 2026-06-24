import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';

void main() {
  final base = VaccineRecordEntity(
    id: 'v1',
    babyId: 'baby1',
    vaccineName: 'DTaP',
    doseNumber: 1,
    scheduledDate: DateTime(2025, 3, 1),
    administeredDate: DateTime(2025, 3, 5),
    provider: 'City Clinic',
    notes: 'no reaction',
    createdAt: DateTime(2025, 3, 5),
    modifiedAt: DateTime(2025, 3, 5),
  );

  group('VaccineRecordEntity', () {
    test('isAdministered is true when administeredDate is set', () {
      expect(base.isAdministered, isTrue);
    });

    test('isAdministered is false when administeredDate is null', () {
      final upcoming = base.copyWith(administeredDate: () => null);
      expect(upcoming.isAdministered, isFalse);
    });

    test('equality: same values are equal', () {
      final other = VaccineRecordEntity(
        id: 'v1',
        babyId: 'baby1',
        vaccineName: 'DTaP',
        doseNumber: 1,
        scheduledDate: DateTime(2025, 3, 1),
        administeredDate: DateTime(2025, 3, 5),
        provider: 'City Clinic',
        notes: 'no reaction',
        createdAt: DateTime(2025, 3, 5),
        modifiedAt: DateTime(2025, 3, 5),
      );
      expect(base, equals(other));
    });

    test('equality: different vaccineName', () {
      final other = base.copyWith(vaccineName: 'MMR');
      expect(base, isNot(equals(other)));
    });

    test('copyWith preserves unset fields', () {
      final copy = base.copyWith(vaccineName: 'MMR');
      expect(copy.id, base.id);
      expect(copy.babyId, base.babyId);
      expect(copy.vaccineName, 'MMR');
      expect(copy.doseNumber, base.doseNumber);
      expect(copy.provider, base.provider);
    });

    test('copyWith can null out optional fields', () {
      final copy = base.copyWith(
        doseNumber: () => null,
        scheduledDate: () => null,
        administeredDate: () => null,
        provider: () => null,
        notes: () => null,
      );
      expect(copy.doseNumber, isNull);
      expect(copy.scheduledDate, isNull);
      expect(copy.administeredDate, isNull);
      expect(copy.provider, isNull);
      expect(copy.notes, isNull);
    });

    test('props includes all fields', () {
      expect(base.props, hasLength(10));
    });
  });
}

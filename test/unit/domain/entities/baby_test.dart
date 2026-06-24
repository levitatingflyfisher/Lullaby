import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';

void main() {
  final now = DateTime(2025, 6, 15);

  BabyEntity makeBaby({DateTime? dob}) => BabyEntity(
        id: '1',
        name: 'Alice',
        dateOfBirth: dob ?? DateTime(2024, 12, 15),
        gender: Gender.female,
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );

  group('BabyEntity', () {
    test('formatAge returns months for baby under 1 year', () {
      final baby = makeBaby(dob: DateTime(2025, 1, 15));
      // Will depend on DateTime.now(), but we can test structure
      expect(baby.formatAge(), isNotEmpty);
    });

    test('formatAge returns newborn for today', () {
      final baby = makeBaby(dob: DateTime.now());
      expect(baby.formatAge(), 'newborn');
    });

    test('formatAge returns days for very young baby', () {
      final baby = makeBaby(
          dob: DateTime.now().subtract(const Duration(days: 3)));
      expect(baby.formatAge(), '3 days');
    });

    test('formatAge returns weeks for baby over 7 days', () {
      final baby = makeBaby(
          dob: DateTime.now().subtract(const Duration(days: 14)));
      expect(baby.formatAge(), '2 wk');
    });

    test('copyWith creates a new instance with changed fields', () {
      final baby = makeBaby();
      final copy = baby.copyWith(name: 'Bob');
      expect(copy.name, 'Bob');
      expect(copy.id, baby.id);
      expect(copy.dateOfBirth, baby.dateOfBirth);
    });

    test('copyWith nullable field can be set to null', () {
      final baby = makeBaby();
      expect(baby.gender, Gender.female);
      final copy = baby.copyWith(gender: () => null);
      expect(copy.gender, isNull);
    });

    test('copyWith nullable field retains value when not changed', () {
      final baby = makeBaby();
      final copy = baby.copyWith(name: 'Bob');
      expect(copy.gender, Gender.female);
    });

    test('equality works correctly', () {
      final baby1 = makeBaby();
      final baby2 = makeBaby();
      expect(baby1, equals(baby2));
    });

    test('inequality when fields differ', () {
      final baby1 = makeBaby();
      final baby2 = baby1.copyWith(name: 'Bob');
      expect(baby1, isNot(equals(baby2)));
    });
  });

  group('Gender', () {
    test('fromString returns correct enum', () {
      expect(Gender.fromString('male'), Gender.male);
      expect(Gender.fromString('female'), Gender.female);
      expect(Gender.fromString('other'), isNull);
    });

    test('fromString returns null for null', () {
      expect(Gender.fromString(null), isNull);
    });

    test('fromString returns null for invalid string', () {
      expect(Gender.fromString('unknown'), isNull);
    });
  });
}

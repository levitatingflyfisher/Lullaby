import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';

void main() {
  final now = DateTime(2025, 6, 15, 14, 30);

  DiaperLogEntity makeLog({
    DiaperType type = DiaperType.wet,
    StoolColor? color,
  }) =>
      DiaperLogEntity(
        id: '1',
        babyId: 'baby1',
        time: now,
        type: type,
        color: color,
        createdAt: now,
        modifiedAt: now,
      );

  group('DiaperLogEntity', () {
    test('copyWith changes type', () {
      final log = makeLog();
      final updated = log.copyWith(type: DiaperType.dirty);
      expect(updated.type, DiaperType.dirty);
      expect(updated.id, log.id);
    });

    test('copyWith sets color', () {
      final log = makeLog();
      final updated = log.copyWith(color: () => StoolColor.yellow);
      expect(updated.color, StoolColor.yellow);
    });

    test('copyWith clears color', () {
      final log = makeLog(color: StoolColor.green);
      final updated = log.copyWith(color: () => null);
      expect(updated.color, isNull);
    });

    test('copyWith retains values when not specified', () {
      final log = makeLog(color: StoolColor.brown);
      final updated = log.copyWith(type: DiaperType.both);
      expect(updated.color, StoolColor.brown);
    });

    test('equality works', () {
      expect(makeLog(), equals(makeLog()));
    });

    test('inequality when different', () {
      expect(makeLog(), isNot(equals(makeLog(type: DiaperType.dirty))));
    });
  });

  group('DiaperType', () {
    test('fromString returns correct values', () {
      expect(DiaperType.fromString('wet'), DiaperType.wet);
      expect(DiaperType.fromString('dirty'), DiaperType.dirty);
      expect(DiaperType.fromString('both'), DiaperType.both);
      expect(DiaperType.fromString('dry'), DiaperType.dry);
    });

    test('fromString throws for invalid', () {
      expect(() => DiaperType.fromString('invalid'),
          throwsA(isA<FormatException>()));
    });

    test('displayName returns capitalized name', () {
      expect(DiaperType.wet.displayName, 'Wet');
      expect(DiaperType.dirty.displayName, 'Dirty');
      expect(DiaperType.both.displayName, 'Both');
      expect(DiaperType.dry.displayName, 'Dry');
    });
  });

  group('StoolColor', () {
    test('fromString returns correct value', () {
      expect(StoolColor.fromString('yellow'), StoolColor.yellow);
      expect(StoolColor.fromString('green'), StoolColor.green);
    });

    test('fromString returns null for null', () {
      expect(StoolColor.fromString(null), isNull);
    });

    test('fromString returns null for invalid', () {
      expect(StoolColor.fromString('invalid'), isNull);
    });

    test('displayName capitalizes', () {
      expect(StoolColor.yellow.displayName, 'Yellow');
      expect(StoolColor.brown.displayName, 'Brown');
    });
  });
}

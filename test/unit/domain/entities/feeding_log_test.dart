import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 0);

  FeedingLogEntity makeLog({
    FeedingType type = FeedingType.breast,
    DateTime? endTime,
    int? durationMinutes,
    BreastSide? side,
  }) =>
      FeedingLogEntity(
        id: '1',
        babyId: 'baby1',
        type: type,
        startTime: now,
        endTime: endTime,
        durationMinutes: durationMinutes,
        side: side ?? BreastSide.left,
        createdAt: now,
        modifiedAt: now,
      );

  group('FeedingLogEntity', () {
    test('isActive returns true for breast feeding without endTime', () {
      final log = makeLog();
      expect(log.isActive, isTrue);
    });

    test('isActive returns false for breast feeding with endTime', () {
      final log = makeLog(endTime: now.add(const Duration(minutes: 15)));
      expect(log.isActive, isFalse);
    });

    test('isActive returns false for bottle feeding without endTime', () {
      final log = makeLog(type: FeedingType.bottle);
      expect(log.isActive, isFalse);
    });

    test('computedDuration uses durationMinutes if set', () {
      final log = makeLog(durationMinutes: 20);
      expect(log.computedDuration, const Duration(minutes: 20));
    });

    test('computedDuration calculates from start/end if no durationMinutes',
        () {
      final log = makeLog(endTime: now.add(const Duration(minutes: 15)));
      expect(log.computedDuration, const Duration(minutes: 15));
    });

    test('computedDuration returns null when neither set', () {
      final log = makeLog();
      expect(log.computedDuration, isNull);
    });

    test('copyWith works for nullable fields', () {
      final log = makeLog(side: BreastSide.left);
      final updated = log.copyWith(side: () => BreastSide.right);
      expect(updated.side, BreastSide.right);
    });

    test('copyWith retains values when not changed', () {
      final log = makeLog(side: BreastSide.left);
      final updated = log.copyWith(type: FeedingType.bottle);
      expect(updated.side, BreastSide.left);
      expect(updated.type, FeedingType.bottle);
    });

    test('equality works', () {
      final a = makeLog();
      final b = makeLog();
      expect(a, equals(b));
    });
  });

  group('FeedingType', () {
    test('fromString returns correct value', () {
      expect(FeedingType.fromString('breast'), FeedingType.breast);
      expect(FeedingType.fromString('bottle'), FeedingType.bottle);
      expect(FeedingType.fromString('solid'), FeedingType.solid);
    });

    test('fromString throws for invalid', () {
      expect(() => FeedingType.fromString('invalid'),
          throwsA(isA<FormatException>()));
    });
  });

  group('BreastSide', () {
    test('fromString returns correct value', () {
      expect(BreastSide.fromString('left'), BreastSide.left);
      expect(BreastSide.fromString('right'), BreastSide.right);
      expect(BreastSide.fromString('both'), BreastSide.both);
    });

    test('fromString returns null for null', () {
      expect(BreastSide.fromString(null), isNull);
    });

    test('fromString returns null for invalid', () {
      expect(BreastSide.fromString('invalid'), isNull);
    });
  });
}

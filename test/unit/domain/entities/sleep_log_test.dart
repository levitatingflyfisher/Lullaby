import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';

void main() {
  final now = DateTime(2025, 6, 15, 22, 0);

  SleepLogEntity makeLog({
    DateTime? endTime,
    int? durationMinutes,
    SleepType type = SleepType.nap,
  }) =>
      SleepLogEntity(
        id: '1',
        babyId: 'baby1',
        startTime: now,
        endTime: endTime,
        durationMinutes: durationMinutes,
        type: type,
        createdAt: now,
        modifiedAt: now,
      );

  group('SleepLogEntity', () {
    test('isActive returns true when endTime is null', () {
      final log = makeLog();
      expect(log.isActive, isTrue);
    });

    test('isActive returns false when endTime is set', () {
      final log = makeLog(endTime: now.add(const Duration(hours: 2)));
      expect(log.isActive, isFalse);
    });

    test('computedDuration from durationMinutes', () {
      final log = makeLog(durationMinutes: 90);
      expect(log.computedDuration, const Duration(minutes: 90));
    });

    test('computedDuration from start/end', () {
      final log = makeLog(endTime: now.add(const Duration(hours: 2)));
      expect(log.computedDuration, const Duration(hours: 2));
    });

    test('computedDuration returns null when neither set', () {
      final log = makeLog();
      expect(log.computedDuration, isNull);
    });

    test('copyWith works', () {
      final log = makeLog();
      final updated = log.copyWith(type: SleepType.night);
      expect(updated.type, SleepType.night);
      expect(updated.id, log.id);
    });

    test('equality works', () {
      expect(makeLog(), equals(makeLog()));
    });
  });

  group('SleepType', () {
    test('fromString returns correct value', () {
      expect(SleepType.fromString('nap'), SleepType.nap);
      expect(SleepType.fromString('night'), SleepType.night);
    });

    test('fromString throws for invalid', () {
      expect(() => SleepType.fromString('invalid'),
          throwsA(isA<FormatException>()));
    });
  });

  group('SleepLocation', () {
    test('fromString returns correct value', () {
      expect(SleepLocation.fromString('crib'), SleepLocation.crib);
      expect(SleepLocation.fromString('bassinet'), SleepLocation.bassinet);
    });

    test('fromString returns null for null', () {
      expect(SleepLocation.fromString(null), isNull);
    });

    test('displayName returns human readable name', () {
      expect(SleepLocation.carSeat.displayName, 'Car seat');
      expect(SleepLocation.crib.displayName, 'Crib');
    });
  });
}

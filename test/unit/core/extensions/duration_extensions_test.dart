import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/extensions/duration_extensions.dart';

void main() {
  group('DurationExtensions', () {
    test('toHoursMinutes with only minutes', () {
      const d = Duration(minutes: 45);
      expect(d.toHoursMinutes(), '45m');
    });

    test('toHoursMinutes with hours and minutes', () {
      const d = Duration(hours: 2, minutes: 30);
      expect(d.toHoursMinutes(), '2h 30m');
    });

    test('toHoursMinutes with zero minutes shows 0m', () {
      const d = Duration(hours: 1);
      expect(d.toHoursMinutes(), '1h 0m');
    });

    test('toTimerDisplay formats correctly', () {
      const d = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(d.toTimerDisplay(), '01:23:45');
    });

    test('toTimerDisplay pads single digits', () {
      const d = Duration(minutes: 5, seconds: 3);
      expect(d.toTimerDisplay(), '00:05:03');
    });

    test('toTimerDisplay handles zero', () {
      expect(Duration.zero.toTimerDisplay(), '00:00:00');
    });

    test('toTimerDisplay handles large hours', () {
      const d = Duration(hours: 12, minutes: 0, seconds: 0);
      expect(d.toTimerDisplay(), '12:00:00');
    });
  });
}

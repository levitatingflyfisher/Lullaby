import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/extensions/date_extensions.dart';

void main() {
  group('DateTimeExtensions', () {
    test('toRelativeTime returns just now for recent', () {
      final time = DateTime.now().subtract(const Duration(seconds: 30));
      expect(time.toRelativeTime(), 'just now');
    });

    test('toRelativeTime returns minutes', () {
      final time = DateTime.now().subtract(const Duration(minutes: 5));
      expect(time.toRelativeTime(), '5m ago');
    });

    test('toRelativeTime returns hours', () {
      final time = DateTime.now().subtract(const Duration(hours: 3));
      expect(time.toRelativeTime(), '3h ago');
    });

    test('toRelativeTime returns days', () {
      final time = DateTime.now().subtract(const Duration(days: 2));
      expect(time.toRelativeTime(), '2d ago');
    });

    test('toRelativeTime returns weeks', () {
      final time = DateTime.now().subtract(const Duration(days: 14));
      expect(time.toRelativeTime(), '2w ago');
    });

    test('isSameDay returns true for same day', () {
      final a = DateTime(2025, 6, 15, 10, 0);
      final b = DateTime(2025, 6, 15, 22, 30);
      expect(a.isSameDay(b), isTrue);
    });

    test('isSameDay returns false for different days', () {
      final a = DateTime(2025, 6, 15);
      final b = DateTime(2025, 6, 16);
      expect(a.isSameDay(b), isFalse);
    });

    test('startOfDay returns midnight', () {
      final dt = DateTime(2025, 6, 15, 14, 30, 45);
      final start = dt.startOfDay;
      expect(start, DateTime(2025, 6, 15));
    });

    test('endOfDay returns end of day', () {
      final dt = DateTime(2025, 6, 15, 10, 0);
      final end = dt.endOfDay;
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/stats/domain/entities/daily_summary.dart';

void main() {
  final date = DateTime(2025, 6, 15);

  group('DailySummary', () {
    test('default values are zero', () {
      final s = DailySummary(date: date);
      expect(s.feedingCount, 0);
      expect(s.totalFeedingMinutes, 0);
      expect(s.sleepMinutes, 0);
      expect(s.diaperCount, 0);
      expect(s.diapersByType, isEmpty);
    });

    test('sleepHours converts minutes correctly', () {
      final s = DailySummary(date: date, sleepMinutes: 120);
      expect(s.sleepHours, 2.0);
    });

    test('sleepHours with partial hours', () {
      final s = DailySummary(date: date, sleepMinutes: 90);
      expect(s.sleepHours, closeTo(1.5, 0.001));
    });

    test('construction with all fields', () {
      final s = DailySummary(
        date: date,
        feedingCount: 8,
        totalFeedingMinutes: 120,
        sleepMinutes: 480,
        diaperCount: 6,
        diapersByType: {'wet': 4, 'dirty': 2},
      );
      expect(s.feedingCount, 8);
      expect(s.totalFeedingMinutes, 120);
      expect(s.sleepMinutes, 480);
      expect(s.diaperCount, 6);
      expect(s.diapersByType['wet'], 4);
      expect(s.diapersByType['dirty'], 2);
    });

    test('equality — same fields are equal', () {
      final s1 = DailySummary(date: date, feedingCount: 5);
      final s2 = DailySummary(date: date, feedingCount: 5);
      expect(s1, equals(s2));
    });

    test('inequality — different counts', () {
      final s1 = DailySummary(date: date, feedingCount: 5);
      final s2 = DailySummary(date: date, feedingCount: 6);
      expect(s1, isNot(equals(s2)));
    });
  });
}

import 'package:equatable/equatable.dart';

class DailySummary extends Equatable {
  const DailySummary({
    required this.date,
    this.feedingCount = 0,
    this.totalFeedingMinutes = 0,
    this.sleepMinutes = 0,
    this.diaperCount = 0,
    this.diapersByType = const {},
  });

  final DateTime date;
  final int feedingCount;
  final int totalFeedingMinutes;
  final int sleepMinutes;
  final int diaperCount;
  final Map<String, int> diapersByType;

  double get sleepHours => sleepMinutes / 60.0;

  @override
  List<Object?> get props => [
        date,
        feedingCount,
        totalFeedingMinutes,
        sleepMinutes,
        diaperCount,
        diapersByType,
      ];
}

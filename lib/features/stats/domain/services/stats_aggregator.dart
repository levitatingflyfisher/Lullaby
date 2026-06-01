import '../../../../core/errors/result.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../tracking/domain/entities/diaper_log.dart';
import '../../../tracking/domain/entities/feeding_log.dart';
import '../../../tracking/domain/entities/sleep_log.dart';
import '../../../tracking/domain/repositories/diaper_repository.dart';
import '../../../tracking/domain/repositories/feeding_repository.dart';
import '../../../tracking/domain/repositories/sleep_repository.dart';
import '../entities/daily_summary.dart';

class StatsAggregator {
  StatsAggregator({
    required this.feedingRepo,
    required this.sleepRepo,
    required this.diaperRepo,
  });

  final FeedingRepository feedingRepo;
  final SleepRepository sleepRepo;
  final DiaperRepository diaperRepo;

  Future<List<DailySummary>> getDailySummaries(
    String babyId,
    DateTime start,
    DateTime end,
  ) async {
    // The three reads are independent — start them together rather than
    // serially awaiting each round-trip.
    final feedingsFuture = feedingRepo.getInRange(babyId, start, end);
    final diapersFuture = diaperRepo.getInRange(babyId, start, end);
    // Fetch sleeps from one day earlier so an overnight session that started
    // just before [start] still contributes the minutes that fall in range.
    final sleepsFuture = sleepRepo.getInRange(
        babyId, start.startOfDay.subtract(const Duration(days: 1)), end);
    final feedingsResult = await feedingsFuture;
    final diapersResult = await diapersFuture;
    final sleepsResult = await sleepsFuture;

    final feedings =
        feedingsResult is Success<List<FeedingLogEntity>> ? feedingsResult.value : <FeedingLogEntity>[];
    final sleeps =
        sleepsResult is Success<List<SleepLogEntity>> ? sleepsResult.value : <SleepLogEntity>[];
    final diapers =
        diapersResult is Success<List<DiaperLogEntity>> ? diapersResult.value : <DiaperLogEntity>[];

    final summaries = <DailySummary>[];
    var current = start.startOfDay;
    while (current.isBefore(end)) {
      // Advance by calendar day (not a fixed 24h) so DST transitions don't
      // duplicate or skip a bucket (M10).
      final nextDay = DateTime(current.year, current.month, current.day + 1);

      final dayFeedings = feedings
          .where((f) =>
              !f.startTime.isBefore(current) && f.startTime.isBefore(nextDay))
          .toList();

      final dayDiapers = diapers
          .where((d) =>
              !d.time.isBefore(current) && d.time.isBefore(nextDay))
          .toList();

      var totalFeedingMinutes = 0;
      for (final f in dayFeedings) {
        totalFeedingMinutes += f.computedDuration?.inMinutes ?? 0;
      }

      // Split each sleep session at midnight: only the minutes that fall within
      // this calendar day count toward it (H8).
      var sleepMinutes = 0;
      for (final s in sleeps) {
        sleepMinutes += _sleepMinutesInDay(s, current, nextDay);
      }

      final diapersByType = <String, int>{};
      for (final d in dayDiapers) {
        diapersByType[d.type.name] = (diapersByType[d.type.name] ?? 0) + 1;
      }

      summaries.add(DailySummary(
        date: current,
        feedingCount: dayFeedings.length,
        totalFeedingMinutes: totalFeedingMinutes,
        sleepMinutes: sleepMinutes,
        diaperCount: dayDiapers.length,
        diapersByType: diapersByType,
      ));

      current = nextDay;
    }

    return summaries;
  }

  /// Minutes of sleep session [s] that fall within the half-open day
  /// [dayStart, dayEnd). Ongoing sessions (no duration yet) count up to now.
  int _sleepMinutesInDay(SleepLogEntity s, DateTime dayStart, DateTime dayEnd) {
    final dur = s.computedDuration;
    // Open sessions (no duration yet) are excluded from historical aggregation:
    // extending them to "now" would credit a never-closed session a full day of
    // sleep to every day since it started. The live dashboard total counts
    // in-progress sleep separately.
    if (dur == null) return 0;
    final sStart = s.startTime;
    final sEnd = sStart.add(dur);
    final overlapStart = sStart.isAfter(dayStart) ? sStart : dayStart;
    final overlapEnd = sEnd.isBefore(dayEnd) ? sEnd : dayEnd;
    if (!overlapEnd.isAfter(overlapStart)) return 0;
    return overlapEnd.difference(overlapStart).inMinutes;
  }

  Future<DailySummary> getWeeklySummary(
    String babyId,
    DateTime weekStart,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final dailies = await getDailySummaries(babyId, weekStart, weekEnd);
    return _aggregate(dailies, weekStart);
  }

  Future<({double avgFeeds, double avgSleepHours, double avgDiapers})>
      getAverages(String babyId, DateTime start, DateTime end) async {
    final dailies = await getDailySummaries(babyId, start, end);
    if (dailies.isEmpty) {
      return (avgFeeds: 0.0, avgSleepHours: 0.0, avgDiapers: 0.0);
    }

    final count = dailies.length;
    final totalFeeds =
        dailies.fold<int>(0, (sum, d) => sum + d.feedingCount);
    final totalSleepMinutes =
        dailies.fold<int>(0, (sum, d) => sum + d.sleepMinutes);
    final totalDiapers =
        dailies.fold<int>(0, (sum, d) => sum + d.diaperCount);

    return (
      avgFeeds: totalFeeds / count,
      avgSleepHours: totalSleepMinutes / count / 60.0,
      avgDiapers: totalDiapers / count,
    );
  }

  DailySummary _aggregate(List<DailySummary> dailies, DateTime date) {
    int totalFeedings = 0;
    int totalFeedingMinutes = 0;
    int totalSleepMinutes = 0;
    int totalDiapers = 0;
    final mergedDiaperTypes = <String, int>{};

    for (final d in dailies) {
      totalFeedings += d.feedingCount;
      totalFeedingMinutes += d.totalFeedingMinutes;
      totalSleepMinutes += d.sleepMinutes;
      totalDiapers += d.diaperCount;
      for (final entry in d.diapersByType.entries) {
        mergedDiaperTypes[entry.key] =
            (mergedDiaperTypes[entry.key] ?? 0) + entry.value;
      }
    }

    return DailySummary(
      date: date,
      feedingCount: totalFeedings,
      totalFeedingMinutes: totalFeedingMinutes,
      sleepMinutes: totalSleepMinutes,
      diaperCount: totalDiapers,
      diapersByType: mergedDiaperTypes,
    );
  }
}

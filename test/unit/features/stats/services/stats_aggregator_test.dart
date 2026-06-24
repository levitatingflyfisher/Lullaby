import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/stats/domain/services/stats_aggregator.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/features/tracking/domain/repositories/diaper_repository.dart';
import 'package:lullaby/features/tracking/domain/repositories/feeding_repository.dart';
import 'package:lullaby/features/tracking/domain/repositories/sleep_repository.dart';

// ── Fake repository implementations ──────────────────────────────────────────

class FakeFeedingRepo implements FeedingRepository {
  FakeFeedingRepo(this._logs);
  final List<FeedingLogEntity> _logs;

  @override
  Future<Result<List<FeedingLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    final filtered = _logs
        .where((f) =>
            !f.startTime.isBefore(start) && f.startTime.isBefore(end))
        .toList();
    return Success(filtered);
  }

  @override
  Future<Result<List<FeedingLogEntity>>> getAllForBaby(String babyId) async =>
      Success(_logs);
  @override
  Stream<List<FeedingLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value(_logs);
  @override
  Future<Result<FeedingLogEntity?>> getLastFeeding(String babyId) async =>
      const Success(null);
  @override
  Stream<FeedingLogEntity?> watchLastFeeding(String babyId) =>
      Stream.value(null);
  @override
  Future<Result<FeedingLogEntity?>> getActiveBreastFeeding(String babyId) async =>
      const Success(null);
  @override
  Future<Result<void>> createFeeding(FeedingLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> updateFeeding(FeedingLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> deleteFeeding(String id) async =>
      const Success(null);
}

class FakeSleepRepo implements SleepRepository {
  FakeSleepRepo(this._logs);
  final List<SleepLogEntity> _logs;

  @override
  Future<Result<List<SleepLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    final filtered = _logs
        .where((s) =>
            !s.startTime.isBefore(start) && s.startTime.isBefore(end))
        .toList();
    return Success(filtered);
  }

  @override
  Future<Result<List<SleepLogEntity>>> getAllForBaby(String babyId) async =>
      Success(_logs);
  @override
  Stream<List<SleepLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value(_logs);
  @override
  Future<Result<SleepLogEntity?>> getActiveSleep(String babyId) async =>
      const Success(null);
  @override
  Stream<SleepLogEntity?> watchActiveSleep(String babyId) =>
      Stream.value(null);
  @override
  Future<Result<SleepLogEntity?>> getLastSleep(String babyId) async =>
      const Success(null);
  @override
  Future<Result<void>> createSleep(SleepLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> updateSleep(SleepLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> deleteSleep(String id) async =>
      const Success(null);
}

class FakeDiaperRepo implements DiaperRepository {
  FakeDiaperRepo(this._logs);
  final List<DiaperLogEntity> _logs;

  @override
  Future<Result<List<DiaperLogEntity>>> getInRange(
      String babyId, DateTime start, DateTime end) async {
    final filtered = _logs
        .where((d) => !d.time.isBefore(start) && d.time.isBefore(end))
        .toList();
    return Success(filtered);
  }

  @override
  Future<Result<List<DiaperLogEntity>>> getAllForBaby(String babyId) async =>
      Success(_logs);
  @override
  Stream<List<DiaperLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value(_logs);
  @override
  Future<Result<int>> countInRange(
      String babyId, DateTime start, DateTime end) async =>
      const Success(0);
  @override
  Future<Result<int>> countByTypeInRange(
      String babyId, DiaperType type, DateTime start, DateTime end) async =>
      const Success(0);
  @override
  Future<Result<DiaperLogEntity?>> getLastDiaper(String babyId) async =>
      const Success(null);
  @override
  Future<Result<void>> createDiaper(DiaperLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> updateDiaper(DiaperLogEntity log) async =>
      const Success(null);
  @override
  Future<Result<void>> deleteDiaper(String id) async =>
      const Success(null);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

FeedingLogEntity makeFeeding(
    {required DateTime start, int? durationMinutes}) {
  final now = DateTime.now();
  return FeedingLogEntity(
    id: 'f${start.millisecondsSinceEpoch}',
    babyId: 'baby1',
    type: FeedingType.breast,
    startTime: start,
    durationMinutes: durationMinutes,
    createdAt: now,
    modifiedAt: now,
  );
}

SleepLogEntity makeSleep(
    {required DateTime start, int? durationMinutes}) {
  final now = DateTime.now();
  return SleepLogEntity(
    id: 's${start.millisecondsSinceEpoch}',
    babyId: 'baby1',
    startTime: start,
    type: SleepType.nap,
    durationMinutes: durationMinutes,
    createdAt: now,
    modifiedAt: now,
  );
}

DiaperLogEntity makeDiaper(
    {required DateTime time, DiaperType type = DiaperType.wet}) {
  final now = DateTime.now();
  return DiaperLogEntity(
    id: 'd${time.millisecondsSinceEpoch}',
    babyId: 'baby1',
    time: time,
    type: type,
    createdAt: now,
    modifiedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final day0 = DateTime(2025, 6, 15);
  final day1 = DateTime(2025, 6, 16);
  final day2 = DateTime(2025, 6, 17);

  group('StatsAggregator.getDailySummaries', () {
    test('returns one DailySummary per day in range', () async {
      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final summaries =
          await agg.getDailySummaries('baby1', day0, day2);
      // day0 and day1 (day2 is exclusive end)
      expect(summaries, hasLength(2));
    });

    test('counts feedings correctly per day', () async {
      final feedings = [
        makeFeeding(start: day0.add(const Duration(hours: 8))),
        makeFeeding(start: day0.add(const Duration(hours: 12))),
        makeFeeding(start: day1.add(const Duration(hours: 9))),
      ];

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo(feedings),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final summaries = await agg.getDailySummaries('baby1', day0, day2);
      expect(summaries[0].feedingCount, 2); // day0
      expect(summaries[1].feedingCount, 1); // day1
    });

    test('splits sleep minutes across midnight', () async {
      final sleeps = [
        // Fully within day0.
        makeSleep(
            start: day0.add(const Duration(hours: 10)),
            durationMinutes: 90),
        // 20:00 + 8h crosses midnight, ending 04:00 on day1.
        makeSleep(
            start: day0.add(const Duration(hours: 20)),
            durationMinutes: 480),
      ];

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo(sleeps),
        diaperRepo: FakeDiaperRepo([]),
      );

      final summaries = await agg.getDailySummaries('baby1', day0, day2);
      expect(summaries[0].sleepMinutes, 330); // 90 + (20:00–24:00 = 240)
      expect(summaries[1].sleepMinutes, 240); // 00:00–04:00
    });

    test('groups diapers by type', () async {
      final diapers = [
        makeDiaper(time: day0.add(const Duration(hours: 8)), type: DiaperType.wet),
        makeDiaper(time: day0.add(const Duration(hours: 10)), type: DiaperType.wet),
        makeDiaper(time: day0.add(const Duration(hours: 12)), type: DiaperType.dirty),
      ];

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo(diapers),
      );

      final summaries = await agg.getDailySummaries('baby1', day0, day1);
      expect(summaries[0].diaperCount, 3);
      expect(summaries[0].diapersByType['wet'], 2);
      expect(summaries[0].diapersByType['dirty'], 1);
    });

    test('returns empty summaries for days with no events', () async {
      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final summaries = await agg.getDailySummaries('baby1', day0, day1);
      expect(summaries, hasLength(1));
      expect(summaries[0].feedingCount, 0);
      expect(summaries[0].diaperCount, 0);
    });
  });

  group('StatsAggregator.getAverages', () {
    test('returns zeros when no data', () async {
      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final averages = await agg.getAverages('baby1', day0, day0);
      expect(averages.avgFeeds, 0.0);
      expect(averages.avgSleepHours, 0.0);
      expect(averages.avgDiapers, 0.0);
    });

    test('computes average feedings per day', () async {
      final feedings = [
        makeFeeding(start: day0.add(const Duration(hours: 8))),
        makeFeeding(start: day0.add(const Duration(hours: 12))),
        makeFeeding(start: day1.add(const Duration(hours: 9))),
        makeFeeding(start: day1.add(const Duration(hours: 14))),
      ];

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo(feedings),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final averages = await agg.getAverages('baby1', day0, day2);
      expect(averages.avgFeeds, 2.0); // 4 feedings / 2 days
    });

    test('computes average sleep hours per day', () async {
      final sleeps = [
        makeSleep(start: day0.add(const Duration(hours: 10)), durationMinutes: 120),
        makeSleep(start: day1.add(const Duration(hours: 10)), durationMinutes: 60),
      ];

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo([]),
        sleepRepo: FakeSleepRepo(sleeps),
        diaperRepo: FakeDiaperRepo([]),
      );

      final averages = await agg.getAverages('baby1', day0, day2);
      // day0: 120min, day1: 60min → avg = 90min = 1.5h
      expect(averages.avgSleepHours, closeTo(1.5, 0.01));
    });
  });

  group('StatsAggregator.getWeeklySummary', () {
    test('aggregates total feedings for a week', () async {
      final feedings = List.generate(
        7,
        (i) => makeFeeding(
            start: day0.add(Duration(days: i, hours: 8))),
      );

      final agg = StatsAggregator(
        feedingRepo: FakeFeedingRepo(feedings),
        sleepRepo: FakeSleepRepo([]),
        diaperRepo: FakeDiaperRepo([]),
      );

      final summary = await agg.getWeeklySummary('baby1', day0);
      expect(summary.feedingCount, 7);
    });
  });
}

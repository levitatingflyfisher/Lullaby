import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/stats/domain/entities/daily_summary.dart';
import 'package:lullaby/features/stats/presentation/controllers/stats_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/features/tracking/domain/repositories/diaper_repository.dart';
import 'package:lullaby/features/tracking/domain/repositories/feeding_repository.dart';
import 'package:lullaby/features/tracking/domain/repositories/sleep_repository.dart';
import 'package:lullaby/core/providers/repository_providers.dart';

// Minimal fakes — only getInRange and getAllForBaby need returning non-null.
class _FakeFeedingRepo implements FeedingRepository {
  @override
  Future<Result<List<FeedingLogEntity>>> getInRange(
          String babyId, DateTime start, DateTime end) async =>
      const Success([]);
  @override
  Future<Result<List<FeedingLogEntity>>> getAllForBaby(String babyId) async =>
      const Success([]);
  @override
  Stream<List<FeedingLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value([]);
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

class _FakeSleepRepo implements SleepRepository {
  @override
  Future<Result<List<SleepLogEntity>>> getInRange(
          String babyId, DateTime start, DateTime end) async =>
      const Success([]);
  @override
  Future<Result<List<SleepLogEntity>>> getAllForBaby(String babyId) async =>
      const Success([]);
  @override
  Stream<List<SleepLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value([]);
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

class _FakeDiaperRepo implements DiaperRepository {
  @override
  Future<Result<List<DiaperLogEntity>>> getInRange(
          String babyId, DateTime start, DateTime end) async =>
      const Success([]);
  @override
  Future<Result<List<DiaperLogEntity>>> getAllForBaby(String babyId) async =>
      const Success([]);
  @override
  Stream<List<DiaperLogEntity>> watchAllForBaby(String babyId) =>
      Stream.value([]);
  @override
  Future<Result<int>> countInRange(
          String babyId, DateTime start, DateTime end) async =>
      const Success(0);
  @override
  Future<Result<int>> countByTypeInRange(String babyId, DiaperType type,
          DateTime start, DateTime end) async =>
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

void main() {
  group('summariesInRangeProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          feedingRepositoryProvider.overrideWithValue(_FakeFeedingRepo()),
          sleepRepositoryProvider.overrideWithValue(_FakeSleepRepo()),
          diaperRepositoryProvider.overrideWithValue(_FakeDiaperRepo()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('returns a List<DailySummary> without throwing', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 8);
      final result = await container.read(
        summariesInRangeProvider((
          babyId: 'baby1',
          range: DateTimeRange(start: start, end: end),
        )).future,
      );
      expect(result, isA<List<DailySummary>>());
    });

    test('returns 7 DailySummary entries for a 7-day range', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 8);
      final result = await container.read(
        summariesInRangeProvider((
          babyId: 'baby1',
          range: DateTimeRange(start: start, end: end),
        )).future,
      );
      expect(result, hasLength(7));
    });

    test('first entry date matches range start', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 4);
      final result = await container.read(
        summariesInRangeProvider((
          babyId: 'baby1',
          range: DateTimeRange(start: start, end: end),
        )).future,
      );
      expect(result.first.date.year, 2026);
      expect(result.first.date.month, 3);
      expect(result.first.date.day, 1);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../tracking/domain/entities/diaper_log.dart';
import '../../../tracking/domain/entities/feeding_log.dart';
import '../../../tracking/domain/entities/sleep_log.dart';

final selectedDayProvider = StateProvider<DateTime>(
  (ref) => DateTime.now().startOfDay,
);

class DayEventCounts {
  const DayEventCounts({
    this.feedings = 0,
    this.sleeps = 0,
    this.diapers = 0,
  });

  final int feedings;
  final int sleeps;
  final int diapers;
}

// autoDispose so markers/day sheets recompute after a log is added, edited or
// deleted rather than caching for the whole session (M9).
final calendarEventsProvider = FutureProvider.autoDispose.family<
    Map<DateTime, DayEventCounts>, ({DateTime start, DateTime end})>(
  (ref, range) async {
    final babyProvider = ref.watch(
        _calendarBabyIdProvider);
    if (babyProvider == null) return {};

    final feedingRepo = ref.watch(feedingRepositoryProvider);
    final sleepRepo = ref.watch(sleepRepositoryProvider);
    final diaperRepo = ref.watch(diaperRepositoryProvider);

    final feedingsResult =
        await feedingRepo.getInRange(babyProvider, range.start, range.end);
    final sleepsResult =
        await sleepRepo.getInRange(babyProvider, range.start, range.end);
    final diapersResult =
        await diaperRepo.getInRange(babyProvider, range.start, range.end);

    final feedings = feedingsResult is Success<List<FeedingLogEntity>>
        ? feedingsResult.value
        : <FeedingLogEntity>[];
    final sleeps = sleepsResult is Success<List<SleepLogEntity>>
        ? sleepsResult.value
        : <SleepLogEntity>[];
    final diapers = diapersResult is Success<List<DiaperLogEntity>>
        ? diapersResult.value
        : <DiaperLogEntity>[];

    final map = <DateTime, DayEventCounts>{};

    for (final f in feedings) {
      final day = f.startTime.startOfDay;
      final existing = map[day] ?? const DayEventCounts();
      map[day] = DayEventCounts(
        feedings: existing.feedings + 1,
        sleeps: existing.sleeps,
        diapers: existing.diapers,
      );
    }

    for (final s in sleeps) {
      final day = s.startTime.startOfDay;
      final existing = map[day] ?? const DayEventCounts();
      map[day] = DayEventCounts(
        feedings: existing.feedings,
        sleeps: existing.sleeps + 1,
        diapers: existing.diapers,
      );
    }

    for (final d in diapers) {
      final day = d.time.startOfDay;
      final existing = map[day] ?? const DayEventCounts();
      map[day] = DayEventCounts(
        feedings: existing.feedings,
        sleeps: existing.sleeps,
        diapers: existing.diapers + 1,
      );
    }

    return map;
  },
);

// Internal provider for the active baby ID to use in calendar
final _calendarBabyIdProvider = Provider<String?>((ref) {
  // Import activeBabyProvider's value
  final baby = ref.watch(
      _activeBabyForCalendarProvider).valueOrNull;
  return baby?.id;
});

// Re-export the active baby provider for calendar
final _activeBabyForCalendarProvider = StreamProvider((ref) {
  final repo = ref.watch(babyRepositoryProvider);
  return repo.watchActiveBaby();
});

class DayEvents {
  const DayEvents({
    this.feedings = const [],
    this.sleeps = const [],
    this.diapers = const [],
  });

  final List<FeedingLogEntity> feedings;
  final List<SleepLogEntity> sleeps;
  final List<DiaperLogEntity> diapers;
}

final dayDetailProvider =
    FutureProvider.autoDispose.family<DayEvents, ({String babyId, DateTime day})>(
  (ref, params) async {
    final feedingRepo = ref.watch(feedingRepositoryProvider);
    final sleepRepo = ref.watch(sleepRepositoryProvider);
    final diaperRepo = ref.watch(diaperRepositoryProvider);

    final start = params.day.startOfDay;
    // Half-open [start, nextMidnight) so the day's last second isn't dropped
    // by exclusive `<` against second-precision storage (L1).
    final end = DateTime(params.day.year, params.day.month, params.day.day + 1);

    final feedingsResult =
        await feedingRepo.getInRange(params.babyId, start, end);
    final sleepsResult =
        await sleepRepo.getInRange(params.babyId, start, end);
    final diapersResult =
        await diaperRepo.getInRange(params.babyId, start, end);

    return DayEvents(
      feedings: feedingsResult is Success<List<FeedingLogEntity>>
          ? feedingsResult.value
          : [],
      sleeps: sleepsResult is Success<List<SleepLogEntity>>
          ? sleepsResult.value
          : [],
      diapers: diapersResult is Success<List<DiaperLogEntity>>
          ? diapersResult.value
          : [],
    );
  },
);

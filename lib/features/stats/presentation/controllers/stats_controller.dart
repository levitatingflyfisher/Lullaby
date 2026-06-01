import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/services/stats_aggregator.dart';

enum StatsPeriod {
  week(7, '7d'),
  twoWeeks(14, '14d'),
  month(30, '30d');

  const StatsPeriod(this.days, this.label);
  final int days;
  final String label;
}

final statsPeriodProvider = StateProvider<StatsPeriod>(
  (ref) => StatsPeriod.week,
);

final statsAggregatorProvider = Provider<StatsAggregator>((ref) {
  return StatsAggregator(
    feedingRepo: ref.watch(feedingRepositoryProvider),
    sleepRepo: ref.watch(sleepRepositoryProvider),
    diaperRepo: ref.watch(diaperRepositoryProvider),
  );
});

// autoDispose so the screen recomputes (fresh data + fresh "now") each time
// it's reopened, instead of serving a stale snapshot for the whole session (M9).
final dailySummariesProvider =
    FutureProvider.autoDispose.family<List<DailySummary>, String>((ref, babyId) async {
  final period = ref.watch(statsPeriodProvider);
  final aggregator = ref.watch(statsAggregatorProvider);

  final now = DateTime.now();
  // Whole local days ending today: exactly period.days buckets, with a full
  // first day. The previous `now - days` start was mid-day, which added an
  // extra partial bucket and undercounted the first day (H4).
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: period.days - 1));

  return aggregator.getDailySummaries(babyId, start, now);
});

final summariesInRangeProvider = FutureProvider.autoDispose.family<
    List<DailySummary>, ({String babyId, DateTimeRange range})>(
  (ref, args) async {
    final aggregator = ref.watch(statsAggregatorProvider);
    return aggregator.getDailySummaries(
      args.babyId,
      args.range.start,
      args.range.end,
    );
  },
);

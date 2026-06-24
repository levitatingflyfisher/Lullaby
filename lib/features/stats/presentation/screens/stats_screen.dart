import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/stats_controller.dart';
import '../widgets/diaper_frequency_chart.dart';
import '../widgets/feeding_trend_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/sleep_pattern_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);
    final period = ref.watch(statsPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final summariesAsync =
              ref.watch(dailySummariesProvider(activeBaby.id));

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PeriodSelector(
                  selected: period,
                  onChanged: (p) =>
                      ref.read(statsPeriodProvider.notifier).state = p,
                ),
              ),
              Expanded(
                child: summariesAsync.when(
                  data: (summaries) => ListView(
                    children: [
                      FeedingTrendChart(summaries: summaries),
                      SleepPatternChart(summaries: summaries),
                      DiaperFrequencyChart(summaries: summaries),
                      const SizedBox(height: 16),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

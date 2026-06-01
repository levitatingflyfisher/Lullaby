import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../../stats/presentation/controllers/stats_controller.dart';
import '../../../stats/presentation/widgets/diaper_frequency_chart.dart';
import '../../../stats/presentation/widgets/feeding_trend_chart.dart';
import '../../../stats/presentation/widgets/period_selector.dart';
import '../../../stats/presentation/widgets/sleep_pattern_chart.dart';
import 'growth_section.dart';

class ChartsTab extends ConsumerWidget {
  const ChartsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyAsync = ref.watch(activeBabyProvider);
    final period = ref.watch(statsPeriodProvider);

    return babyAsync.when(
      data: (baby) {
        if (baby == null) {
          return const Center(child: Text('No baby selected'));
        }

        final summariesAsync = ref.watch(dailySummariesProvider(baby.id));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const GrowthSection(),
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
    );
  }
}

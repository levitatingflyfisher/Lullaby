import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../growth/presentation/controllers/growth_controller.dart';
import '../../../growth/presentation/widgets/growth_curve_chart.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../../../core/widgets/load_failure.dart';

class GrowthSection extends ConsumerWidget {
  const GrowthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyAsync = ref.watch(activeBabyProvider);

    return babyAsync.when(
      data: (baby) {
        if (baby == null) return const SizedBox.shrink();

        final recordsAsync = ref.watch(growthRecordsProvider(baby.id));

        return recordsAsync.when(
          data: (records) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (records.isEmpty)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.straighten,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        const Text('No growth measurements yet'),
                      ],
                    ),
                  ),
                )
              else
                GrowthCurveChart(
                  records: records,
                  dateOfBirth: baby.dateOfBirth,
                  gender: baby.gender,
                ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/growth'),
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Growth details'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/growth/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add measurement'),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => LoadFailure.inline(
            what: 'the growth chart',
            error: e,
            stackTrace: st,
            onRetry: () => ref.invalidate(growthRecordsProvider(baby.id)),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => LoadFailure.inline(
        what: 'the growth chart',
        error: e,
        stackTrace: st,
        onRetry: () => ref.invalidate(activeBabyProvider),
      ),
    );
  }
}

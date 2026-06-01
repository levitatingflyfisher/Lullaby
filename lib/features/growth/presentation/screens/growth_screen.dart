import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/growth_controller.dart';
import '../widgets/growth_curve_chart.dart';

class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Growth')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/growth/add'),
        child: const Icon(Icons.add),
      ),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final recordsAsync =
              ref.watch(growthRecordsProvider(activeBaby.id));
          final latestAsync =
              ref.watch(latestGrowthProvider(activeBaby.id));

          return ListView(
            children: [
              // Latest measurement card
              latestAsync.when(
                data: (latest) {
                  if (latest == null) {
                    return Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.straighten,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('No measurements yet'),
                            const SizedBox(height: 8),
                            const Text('Tap + to add the first measurement'),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Latest Measurement',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (latest.weightKg != null)
                                _MeasurementChip(
                                  label: 'Weight',
                                  value:
                                      '${latest.weightKg!.toStringAsFixed(1)} kg',
                                  icon: Icons.monitor_weight_outlined,
                                ),
                              if (latest.heightCm != null)
                                _MeasurementChip(
                                  label: 'Height',
                                  value:
                                      '${latest.heightCm!.toStringAsFixed(1)} cm',
                                  icon: Icons.height,
                                ),
                              if (latest.headCircumferenceCm != null)
                                _MeasurementChip(
                                  label: 'Head',
                                  value:
                                      '${latest.headCircumferenceCm!.toStringAsFixed(1)} cm',
                                  icon: Icons.circle_outlined,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              // Growth curve chart + records list
              recordsAsync.when(
                data: (records) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GrowthCurveChart(
                      records: records,
                      dateOfBirth: activeBaby.dateOfBirth,
                      gender: activeBaby.gender,
                    ),
                    ...records.map((record) => Dismissible(
                          key: Key(record.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Theme.of(context).colorScheme.error,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete measurement?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(ctx).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(growthControllerProvider.notifier)
                                .deleteRecord(record.id);
                          },
                          child: ListTile(
                            leading: const Icon(Icons.straighten),
                            title: Text(
                                DateFormat.yMMMd().format(record.measuredAt)),
                            subtitle: Text([
                              if (record.weightKg != null)
                                '${record.weightKg!.toStringAsFixed(1)} kg',
                              if (record.heightCm != null)
                                '${record.heightCm!.toStringAsFixed(1)} cm',
                              if (record.headCircumferenceCm != null)
                                '${record.headCircumferenceCm!.toStringAsFixed(1)} cm HC',
                            ].join(' · ')),
                            onTap: () => context.push(
                                '/growth/add',
                                extra: record),
                          ),
                        )),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  const _MeasurementChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

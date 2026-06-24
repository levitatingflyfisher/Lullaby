import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../features/settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/medicine_controller.dart';

class MedicineScreen extends ConsumerWidget {
  const MedicineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/health/medicine/add'),
        child: const Icon(Icons.add),
      ),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final logsAsync = ref.watch(medicineLogsProvider(activeBaby.id));

          return logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      const Text('No medications logged'),
                      const SizedBox(height: 8),
                      const Text('Tap + to add a medication'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final dosageText = log.dosage != null
                      ? '${log.dosage} ${log.dosageUnit ?? ''}'.trim()
                      : null;

                  return Dismissible(
                    key: Key(log.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete entry?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
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
                          .read(medicineControllerProvider.notifier)
                          .delete(log.id);
                    },
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.medication),
                      ),
                      title: Text(log.medicineName),
                      subtitle: Text(
                        [
                          ?dosageText,
                          DateFormat('MMM d, yyyy h:mm a')
                              .format(log.administeredAt),
                        ].join(' · '),
                      ),
                      trailing: log.notes != null
                          ? const Icon(Icons.notes, size: 16)
                          : null,
                      onTap: () =>
                          context.push('/health/medicine/add', extra: log),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

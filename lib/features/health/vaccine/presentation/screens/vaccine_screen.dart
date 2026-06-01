import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../features/settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/vaccine_record.dart';
import '../controllers/vaccine_controller.dart';

class VaccineScreen extends ConsumerStatefulWidget {
  const VaccineScreen({super.key});

  @override
  ConsumerState<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends ConsumerState<VaccineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccines'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Given'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/health/vaccines/add'),
        child: const Icon(Icons.add),
      ),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final allAsync = ref.watch(vaccineRecordsProvider(activeBaby.id));

          return allAsync.when(
            data: (all) {
              final upcoming = all
                  .where((v) =>
                      v.scheduledDate != null && v.administeredDate == null)
                  .toList();
              final given =
                  all.where((v) => v.administeredDate != null).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _VaccineList(
                    records: upcoming,
                    emptyMessage: 'No upcoming vaccines',
                    showMarkAdministered: true,
                  ),
                  _VaccineList(
                    records: given,
                    emptyMessage: 'No vaccines recorded',
                    showMarkAdministered: false,
                  ),
                ],
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

class _VaccineList extends ConsumerWidget {
  const _VaccineList({
    required this.records,
    required this.emptyMessage,
    required this.showMarkAdministered,
  });

  final List<VaccineRecordEntity> records;
  final String emptyMessage;
  final bool showMarkAdministered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vaccines_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(emptyMessage),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dateText = record.isAdministered
            ? 'Given: ${DateFormat('MMM d, yyyy').format(record.administeredDate!)}'
            : record.scheduledDate != null
                ? 'Scheduled: ${DateFormat('MMM d, yyyy').format(record.scheduledDate!)}'
                : null;

        return Dismissible(
          key: Key(record.id),
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
              title: const Text('Delete vaccine record?'),
              content: const Text('This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
          onDismissed: (_) {
            ref.read(vaccineControllerProvider.notifier).delete(record.id);
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: record.isAdministered
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              child: Icon(
                record.isAdministered ? Icons.check : Icons.schedule,
                color: record.isAdministered ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(record.vaccineName +
                (record.doseNumber != null
                    ? ' (Dose ${record.doseNumber})'
                    : '')),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateText != null) Text(dateText),
                if (record.provider != null)
                  Text(record.provider!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            trailing: showMarkAdministered
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Mark as given',
                    onPressed: () =>
                        _markAdministered(context, ref, record),
                  )
                : null,
            onTap: () =>
                context.push('/health/vaccines/add', extra: record),
          ),
        );
      },
    );
  }

  Future<void> _markAdministered(
      BuildContext context, WidgetRef ref, VaccineRecordEntity record) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    await ref
        .read(vaccineControllerProvider.notifier)
        .markAdministered(record.id, record, picked);
  }
}

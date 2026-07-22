import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../export/export_bottom_sheet.dart';
import '../../../health/medicine/domain/entities/medicine_log.dart';
import '../../../health/vaccine/domain/entities/vaccine_record.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../../stats/presentation/controllers/stats_controller.dart'
    show summariesInRangeProvider;
import '../controllers/doctor_controller.dart';

class DoctorSummaryScreen extends ConsumerWidget {
  const DoctorSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);
    final range = ref.watch(doctorDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Summary'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final activeBaby = baby.valueOrNull;
              if (activeBaby == null) {
                return const IconButton(
                  icon: Icon(Icons.share),
                  onPressed: null,
                );
              }
              final summaryAsync =
                  ref.watch(doctorSummaryProvider(activeBaby));
              final dailyAsync = summaryAsync.whenData(
                (s) => s == null
                    ? null
                    : ref.watch(summariesInRangeProvider((
                        babyId: s.baby.id,
                        range: s.dateRange,
                      ))),
              );
              final summary = summaryAsync.valueOrNull;
              final dailies = dailyAsync.valueOrNull?.valueOrNull;
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: summary == null || dailies == null
                    ? null
                    : () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => ExportBottomSheet(
                            summary: summary,
                            dailySummaries: dailies,
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final summaryAsync =
              ref.watch(doctorSummaryProvider(activeBaby));

          return summaryAsync.when(
            data: (summary) {
              if (summary == null) {
                return const Center(child: Text('Unable to load summary'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Baby header
                  _SectionCard(
                    children: [
                      Text(
                        summary.baby.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${summary.baby.formatAge()}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'DOB: ${DateFormat.yMMMd().format(summary.baby.dateOfBirth)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  // Date range selector
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        '${DateFormat.MMMd().format(range.start)} - ${DateFormat.MMMd().format(range.end)}',
                      ),
                      subtitle: const Text('Tap to change date range'),
                      onTap: () => _pickDateRange(context, ref, range),
                    ),
                  ),

                  // Feeding summary
                  _SectionCard(
                    children: [
                      _SectionTitle(
                          icon: Icons.restaurant, title: 'Feeding'),
                      _StatRow(
                        label: 'Average per day',
                        value: summary.avgFeedsPerDay.toStringAsFixed(1),
                      ),
                    ],
                  ),

                  // Sleep summary
                  _SectionCard(
                    children: [
                      _SectionTitle(icon: Icons.bedtime, title: 'Sleep'),
                      _StatRow(
                        label: 'Average per day',
                        value:
                            '${summary.avgSleepHoursPerDay.toStringAsFixed(1)} hours',
                      ),
                    ],
                  ),

                  // Diaper summary
                  _SectionCard(
                    children: [
                      _SectionTitle(
                          icon: Icons.baby_changing_station,
                          title: 'Diapers'),
                      _StatRow(
                        label: 'Average per day',
                        value: summary.avgDiapersPerDay.toStringAsFixed(1),
                      ),
                    ],
                  ),

                  // Growth section
                  _SectionCard(
                    children: [
                      _SectionTitle(
                          icon: Icons.straighten, title: 'Growth'),
                      if (summary.latestGrowth != null) ...[
                        if (summary.latestGrowth!.weightKg != null)
                          _StatRow(
                            label: 'Weight',
                            value:
                                '${summary.latestGrowth!.weightKg!.toStringAsFixed(1)} kg'
                                '${summary.weightPercentile != null ? ' (P${summary.weightPercentile!.round()})' : ''}',
                          ),
                        if (summary.latestGrowth!.heightCm != null)
                          _StatRow(
                            label: 'Height',
                            value:
                                '${summary.latestGrowth!.heightCm!.toStringAsFixed(1)} cm'
                                '${summary.heightPercentile != null ? ' (P${summary.heightPercentile!.round()})' : ''}',
                          ),
                        if (summary.latestGrowth!.headCircumferenceCm !=
                            null)
                          _StatRow(
                            label: 'Head',
                            value:
                                '${summary.latestGrowth!.headCircumferenceCm!.toStringAsFixed(1)} cm'
                                '${summary.headPercentile != null ? ' (P${summary.headPercentile!.round()})' : ''}',
                          ),
                        if (summary.growthOutsideWhoRange)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'WHO percentiles cover 0–24 months; '
                              'this measurement is outside that range.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (summary.percentilesNeedRecordedSex)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'WHO percentiles need a recorded sex; add '
                              "one in the baby's profile to see them.",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No growth measurements recorded'),
                        ),
                    ],
                  ),

                  // Medications section
                  _SectionCard(
                    children: [
                      _SectionTitle(
                          icon: Icons.medication, title: 'Recent Medications'),
                      if (summary.recentMedicines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No medications in the last 30 days'),
                        )
                      else
                        ...summary.recentMedicines
                            .map((m) => _MedicineRow(medicine: m)),
                    ],
                  ),

                  // Vaccines section
                  _SectionCard(
                    children: [
                      _SectionTitle(
                          icon: Icons.vaccines, title: 'Vaccines Given'),
                      if (summary.administeredVaccines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No vaccines recorded'),
                        )
                      else
                        ...summary.administeredVaccines
                            .map((v) => _VaccineRow(vaccine: v)),
                    ],
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _pickDateRange(
      BuildContext context, WidgetRef ref, DateTimeRange current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked != null) {
      ref.read(doctorDateRangeProvider.notifier).state = picked;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.medicine});
  final MedicineLogEntity medicine;

  @override
  Widget build(BuildContext context) {
    final dosage = medicine.dosage != null
        ? '${medicine.dosage} ${medicine.dosageUnit ?? ''}'.trim()
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(medicine.medicineName)),
          if (dosage != null)
            Text(dosage,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d').format(medicine.administeredAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _VaccineRow extends StatelessWidget {
  const _VaccineRow({required this.vaccine});
  final VaccineRecordEntity vaccine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(vaccine.vaccineName +
                (vaccine.doseNumber != null
                    ? ' (Dose ${vaccine.doseNumber})'
                    : '')),
          ),
          if (vaccine.administeredDate != null)
            Text(
              DateFormat('MMM d, yyyy').format(vaccine.administeredDate!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

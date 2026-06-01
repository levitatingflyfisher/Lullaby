import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_extensions.dart';
import '../../../timeline/presentation/controllers/timeline_controller.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No activity yet today.\nTap a button above to start logging!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        ...events.map((event) => _ActivityTile(event: event)),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (event.type) {
      TimelineEventType.feeding => (Icons.restaurant, const Color(0xFF4CAF50)),
      TimelineEventType.sleep => (Icons.bedtime, const Color(0xFF5C6BC0)),
      TimelineEventType.diaper =>
        (Icons.baby_changing_station, const Color(0xFFFFA726)),
      TimelineEventType.growth => (Icons.straighten, const Color(0xFF26A69A)),
      TimelineEventType.medicine => (Icons.medication, const Color(0xFF7E57C2)),
      TimelineEventType.vaccine => (Icons.vaccines, const Color(0xFF42A5F5)),
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(event.title),
      subtitle: Text(event.subtitle),
      trailing: Text(
        event.time.toRelativeTime(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      dense: true,
      onTap: () {
        if (event.feedingLog != null) {
          context.push('/feeding', extra: event.feedingLog);
        } else if (event.sleepLog != null) {
          context.push('/sleep', extra: event.sleepLog);
        } else if (event.diaperLog != null) {
          context.push('/diaper', extra: event.diaperLog);
        } else if (event.growthRecord != null) {
          context.push('/growth/add', extra: event.growthRecord);
        } else if (event.medicineLog != null) {
          context.push('/health/medicine/add', extra: event.medicineLog);
        } else if (event.vaccineLog != null) {
          context.push('/health/vaccines/add', extra: event.vaccineLog);
        }
      },
    );
  }
}

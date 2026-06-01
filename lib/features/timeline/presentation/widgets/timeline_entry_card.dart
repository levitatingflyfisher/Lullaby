import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../presentation/controllers/timeline_controller.dart';

class TimelineEntryCard extends StatelessWidget {
  const TimelineEntryCard({super.key, required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (event.type) {
      TimelineEventType.feeding => (Icons.restaurant, const Color(0xFF4CAF50)),
      TimelineEventType.sleep => (Icons.bedtime, const Color(0xFF5C6BC0)),
      TimelineEventType.diaper =>
        (Icons.baby_changing_station, const Color(0xFFFFA726)),
      TimelineEventType.growth => (Icons.straighten, const Color(0xFF26A69A)),
      TimelineEventType.medicine => (Icons.medication, const Color(0xFF7E57C2)),
      TimelineEventType.vaccine => (Icons.vaccines, const Color(0xFF42A5F5)),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(event.title),
        subtitle: Text(event.subtitle),
        trailing: Text(
          DateFormat.jm().format(event.time),
          style: theme.textTheme.bodySmall,
        ),
        onTap: switch (event.type) {
          TimelineEventType.feeding => () =>
              context.push('/feeding', extra: event.feedingLog),
          TimelineEventType.sleep => () =>
              context.push('/sleep', extra: event.sleepLog),
          TimelineEventType.diaper => () =>
              context.push('/diaper', extra: event.diaperLog),
          TimelineEventType.growth ||
          TimelineEventType.medicine ||
          TimelineEventType.vaccine =>
            null,
        },
      ),
    );
  }
}

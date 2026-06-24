import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../timeline/presentation/controllers/timeline_controller.dart';
import '../../../timeline/presentation/widgets/timeline_entry_card.dart';
import '../../../tracking/domain/entities/feeding_log.dart';
import '../../../tracking/domain/entities/sleep_log.dart';
import '../controllers/calendar_controller.dart';

class DayEventsSheet extends ConsumerWidget {
  const DayEventsSheet({
    super.key,
    required this.babyId,
    required this.day,
  });

  final String babyId;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync =
        ref.watch(dayDetailProvider((babyId: babyId, day: day)));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                DateFormat.yMMMd().format(day),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  final timelineEvents = <TimelineEvent>[
                    ...events.feedings.map(_feedingToEvent),
                    ...events.sleeps.map(_sleepToEvent),
                    ...events.diapers.map((d) => TimelineEvent(
                          id: d.id,
                          type: TimelineEventType.diaper,
                          time: d.time,
                          title: 'Diaper',
                          subtitle: d.type.displayName,
                          diaperLog: d,
                        )),
                  ];
                  timelineEvents.sort((a, b) => b.time.compareTo(a.time));

                  if (timelineEvents.isEmpty) {
                    return const Center(child: Text('No events this day'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: timelineEvents.length,
                    itemBuilder: (context, index) =>
                        TimelineEntryCard(event: timelineEvents[index]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
    );
  }

  TimelineEvent _feedingToEvent(FeedingLogEntity log) {
    final subtitle = switch (log.type) {
      FeedingType.breast =>
        'Breast${log.side != null ? ' (${log.side!.name})' : ''}${log.computedDuration != null ? ' - ${log.computedDuration!.inMinutes}min' : ''}',
      FeedingType.bottle =>
        'Bottle${log.amountMl != null ? ' - ${log.amountMl!.round()}ml' : ''}',
      FeedingType.solid =>
        'Solid food${log.notes != null ? ' - ${log.notes}' : ''}',
    };
    return TimelineEvent(
      id: log.id,
      type: TimelineEventType.feeding,
      time: log.startTime,
      title: 'Feeding',
      subtitle: subtitle,
      feedingLog: log,
    );
  }

  TimelineEvent _sleepToEvent(SleepLogEntity log) {
    final duration = log.computedDuration;
    final subtitle =
        '${log.type == SleepType.nap ? 'Nap' : 'Night'}${duration != null ? ' - ${duration.inHours}h ${duration.inMinutes.remainder(60)}m' : ' (ongoing)'}';
    return TimelineEvent(
      id: log.id,
      type: TimelineEventType.sleep,
      time: log.startTime,
      title: 'Sleep',
      subtitle: subtitle,
      sleepLog: log,
    );
  }
}

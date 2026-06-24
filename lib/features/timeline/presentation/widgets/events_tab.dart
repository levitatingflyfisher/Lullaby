import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/date_extensions.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/timeline_controller.dart';
import 'timeline_entry_card.dart';
import 'timeline_filter_chips.dart';

class EventsTab extends ConsumerWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);

    return baby.when(
      data: (activeBaby) {
        if (activeBaby == null) {
          return const Center(child: Text('Add a baby to see events'));
        }

        final eventsAsync = ref.watch(timelineProvider(activeBaby.id));

        return Column(
          children: [
            const TimelineFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const Center(child: Text('No events yet'));
                  }

                  final fmt = DateFormat.yMMMd();
                  final grouped = <String, List<TimelineEvent>>{};
                  for (final event in events) {
                    final key = fmt.format(event.time);
                    grouped.putIfAbsent(key, () => []).add(event);
                  }

                  return ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final date = grouped.keys.elementAt(index);
                      final dayEvents = grouped[date]!;
                      final isToday =
                          dayEvents.first.time.isSameDay(DateTime.now());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              isToday ? 'Today' : date,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ),
                          ...dayEvents.map((e) => TimelineEntryCard(event: e)),
                        ],
                      );
                    },
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

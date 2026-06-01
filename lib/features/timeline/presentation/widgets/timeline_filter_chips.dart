import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/controllers/timeline_controller.dart';

class TimelineFilterChips extends ConsumerWidget {
  const TimelineFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(timelineFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TimelineFilter.values.map((filter) {
          final selected = current == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.name[0].toUpperCase() + filter.name.substring(1)),
              selected: selected,
              onSelected: (_) =>
                  ref.read(timelineFilterProvider.notifier).state = filter,
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/extensions/date_extensions.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/day_events_sheet.dart';
import '../widgets/event_markers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(activeBabyProvider);

    final firstDayOfMonth =
        DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

    final eventsAsync = ref.watch(calendarEventsProvider(
        (start: firstDayOfMonth, end: lastDayOfMonth)));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return const Center(child: Text('No baby selected'));
          }

          final eventCounts = eventsAsync.valueOrNull ?? {};

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) =>
                    _selectedDay != null &&
                    _selectedDay!.isSameDay(day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  ref.read(selectedDayProvider.notifier).state =
                      selectedDay.startOfDay;
                  _showDayEvents(context, activeBaby.id, selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final counts = eventCounts[day.startOfDay];
                    if (counts == null) return null;
                    return Positioned(
                      bottom: 1,
                      child: EventMarkers(counts: counts),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDayEvents(BuildContext context, String babyId, DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayEventsSheet(
        babyId: babyId,
        day: day,
      ),
    );
  }
}

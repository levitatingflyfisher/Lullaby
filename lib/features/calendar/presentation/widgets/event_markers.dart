import 'package:flutter/material.dart';

import '../../../../app/theme/color_schemes.dart';
import '../controllers/calendar_controller.dart';

class EventMarkers extends StatelessWidget {
  const EventMarkers({super.key, required this.counts});

  final DayEventCounts counts;

  @override
  Widget build(BuildContext context) {
    final dots = <Color>[];
    if (counts.feedings > 0) dots.add(AppColorSchemes.feedColor);
    if (counts.sleeps > 0) dots.add(AppColorSchemes.sleepColor);
    if (counts.diapers > 0) dots.add(AppColorSchemes.diaperColor);

    if (dots.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dots
          .map((color) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ))
          .toList(),
    );
  }
}

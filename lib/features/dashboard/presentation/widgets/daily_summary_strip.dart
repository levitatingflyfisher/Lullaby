import 'package:flutter/material.dart';
import '../../../../app/theme/color_schemes.dart';

class DailySummaryStrip extends StatelessWidget {
  const DailySummaryStrip({
    super.key,
    required this.lastFeedTime,
    required this.sleepDuration,
    required this.diaperCount,
  });

  final String lastFeedTime;
  final String sleepDuration;
  final int diaperCount;

  @override
  Widget build(BuildContext context) {
    // A Wrap, not a horizontal scroller: the three facts a parent opens the
    // app to read must all be on screen together at any width and text
    // scale, flowing onto a second line rather than off the edge (dmmt-07).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          DailySummaryPill(
            icon: Icons.restaurant,
            label: 'Last feed: $lastFeedTime',
            color: AppColorSchemes.feedColor,
          ),
          DailySummaryPill(
            icon: Icons.bedtime,
            label: 'Sleep: $sleepDuration',
            color: AppColorSchemes.sleepColor,
          ),
          DailySummaryPill(
            icon: Icons.baby_changing_station,
            label: 'Diapers: $diaperCount',
            color: AppColorSchemes.diaperColor,
          ),
        ],
      ),
    );
  }
}

/// One fact in the strip, drawn like an outlined chip but free to wrap.
///
/// Not a Chip: a Chip fixes its height to one line, so at text scale 2.0
/// "Last feed: 2 hours ago" was sheared off inside it. This pill lets the
/// label run onto a second line instead.
class DailySummaryPill extends StatelessWidget {
  const DailySummaryPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: theme.textTheme.labelLarge)),
          ],
        ),
      ),
    );
  }
}

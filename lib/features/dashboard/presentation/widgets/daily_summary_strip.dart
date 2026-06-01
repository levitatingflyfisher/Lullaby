import 'package:flutter/material.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SummaryChip(
            icon: Icons.restaurant,
            label: 'Last feed: $lastFeedTime',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            icon: Icons.bedtime,
            label: 'Sleep: $sleepDuration',
            color: const Color(0xFF5C6BC0),
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            icon: Icons.baby_changing_station,
            label: 'Diapers: $diaperCount',
            color: const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

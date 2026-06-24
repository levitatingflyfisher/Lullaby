import 'package:flutter/material.dart';

import '../controllers/stats_controller.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsPeriod>(
      segments: StatsPeriod.values
          .map((p) => ButtonSegment(
                value: p,
                label: Text(p.label),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

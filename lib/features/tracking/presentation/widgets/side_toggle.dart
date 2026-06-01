import 'package:flutter/material.dart';

import '../../domain/entities/feeding_log.dart';

class SideToggle extends StatelessWidget {
  const SideToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final BreastSide selected;
  final ValueChanged<BreastSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BreastSide>(
      segments: const [
        ButtonSegment(value: BreastSide.left, label: Text('Left')),
        ButtonSegment(value: BreastSide.right, label: Text('Right')),
        ButtonSegment(value: BreastSide.both, label: Text('Both')),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

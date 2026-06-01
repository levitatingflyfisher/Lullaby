import 'package:flutter/material.dart';

import '../../domain/entities/diaper_log.dart';

class DiaperTypeSelector extends StatelessWidget {
  const DiaperTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DiaperType selected;
  final ValueChanged<DiaperType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DiaperType>(
      segments: const [
        ButtonSegment(value: DiaperType.wet, label: Text('Wet')),
        ButtonSegment(value: DiaperType.dirty, label: Text('Dirty')),
        ButtonSegment(value: DiaperType.both, label: Text('Both')),
        ButtonSegment(value: DiaperType.dry, label: Text('Dry')),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

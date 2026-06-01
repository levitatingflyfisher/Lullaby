import 'package:flutter/material.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/quick_log_button.dart';

/// The dashboard's quick-log row (Feed / Sleep / Diaper), isolated so the
/// overflow widget test and the responsive golden test share one source of
/// truth instead of each hand-building the same three buttons.
Widget buildQuickLogRow() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        QuickLogButton(
            icon: Icons.restaurant,
            label: 'Feed',
            color: Colors.green,
            onTap: _noop),
        QuickLogButton(
            icon: Icons.bedtime,
            label: 'Sleep',
            color: Colors.indigo,
            onTap: _noop),
        QuickLogButton(
            icon: Icons.baby_changing_station,
            label: 'Diaper',
            color: Colors.amber,
            onTap: _noop),
      ],
    ),
  );
}

void _noop() {}

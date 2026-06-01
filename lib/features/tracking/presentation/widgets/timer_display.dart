import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Text(
      elapsed.toTimerDisplay(),
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontFeatures: [const FontFeature.tabularFigures()],
            fontWeight: FontWeight.w300,
          ),
    );
  }
}

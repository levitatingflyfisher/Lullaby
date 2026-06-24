import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../tracking/presentation/controllers/timer_controller.dart';

class ActiveTimerCard extends StatelessWidget {
  const ActiveTimerCard({
    super.key,
    required this.timer,
    required this.onStop,
  });

  final ActiveTimer timer;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = timer.type == TimerType.feeding
        ? const Color(0xFF4CAF50)
        : const Color(0xFF5C6BC0);

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              timer.type == TimerType.feeding
                  ? Icons.restaurant
                  : Icons.bedtime,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.label,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    timer.elapsed.toTimerDisplay(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFeatures: [const FontFeature.tabularFigures()],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onStop,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
            ),
          ],
        ),
      ),
    );
  }
}

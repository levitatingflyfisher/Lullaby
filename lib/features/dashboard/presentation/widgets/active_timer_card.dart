import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../tracking/presentation/controllers/timer_controller.dart';
import '../../../../app/theme/color_schemes.dart';

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
        ? AppColorSchemes.feedColor
        : AppColorSchemes.sleepColor;

    final icon = Icon(
      timer.type == TimerType.feeding ? Icons.restaurant : Icons.bedtime,
      color: color,
    );
    final labelStyle = theme.textTheme.titleSmall;
    final clockStyle = theme.textTheme.headlineSmall?.copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
      fontWeight: FontWeight.bold,
    );
    final label = Text(timer.label, style: labelStyle);
    // The clock is one line always: it shrinks to fit rather than wrapping
    // a digit per line.
    final clock = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        timer.elapsed.toTimerDisplay(),
        style: clockStyle,
        maxLines: 1,
        softWrap: false,
      ),
    );
    final stop = FilledButton.icon(
      onPressed: onStop,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
      ),
      icon: const Icon(Icons.stop),
      label: const Text('STOP'),
    );

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // One row when the label, the clock and STOP fit side by side;
            // otherwise (narrow screen, large text) stack them, with STOP
            // full width underneath.
            final scaler = MediaQuery.textScalerOf(context);
            double widthOf(String text, TextStyle? style) => (TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: TextDirection.ltr,
                  textScaler: scaler,
                  maxLines: 1,
                )..layout())
                    .width;
            final textWidth = [
              widthOf(timer.label, labelStyle),
              widthOf(timer.elapsed.toTimerDisplay(), clockStyle),
            ].reduce((a, b) => a > b ? a : b);
            final stopWidth =
                widthOf('STOP', theme.textTheme.labelLarge) + 24 + 18 + 8 + 16;
            final rowWidth = 24 + 12 + textWidth + 12 + stopWidth;

            if (rowWidth <= constraints.maxWidth) {
              return Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, clock],
                    ),
                  ),
                  const SizedBox(width: 12),
                  stop,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: label),
                  ],
                ),
                clock,
                const SizedBox(height: 8),
                stop,
              ],
            );
          },
        ),
      ),
    );
  }
}

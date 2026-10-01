import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class QuickLogButton extends StatelessWidget {
  const QuickLogButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.fitLabel,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// The widest label in this button's row; the labels all take the text
  /// scale at which it fits, so they match. Defaults to [label].
  final String? fitLabel;

  /// The reader's text scale, lowered just enough for [fitLabel] to fit the
  /// button's width on one line (never below 1x).
  TextScaler _labelScaler(BuildContext context, TextStyle? style) {
    final scaler = MediaQuery.textScalerOf(context);
    final tp = TextPainter(
      text: TextSpan(text: fitLabel ?? label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = tp.width;
    tp.dispose();
    const box = AppConstants.quickLogButtonSize;
    if (width <= box) return scaler;
    final size = style?.fontSize ?? 14;
    final factor = scaler.scale(size) / size * box / width;
    return TextScaler.linear(factor < 1 ? 1 : factor * 0.98);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );
    // The whole column (circle and word) is one tap target and one button in
    // the accessibility tree, so aiming at the word works too (audit rank 10).
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: color.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                child: SizedBox(
                  width: AppConstants.quickLogButtonSize,
                  height: AppConstants.quickLogButtonSize,
                  child: Icon(icon, size: 36, color: color),
                ),
              ),
              const SizedBox(height: 8),
              // Bound the label to the button's width so a long label or large
              // accessibility text scale can't widen the column and overflow
              // the row of buttons on narrow screens.
              // The word stays whole: past the width its text grows less
              // rather than breaking mid-word ("Slee / p") at large text.
              // Sized to [fitLabel] so a row of buttons shares one size.
              SizedBox(
                width: AppConstants.quickLogButtonSize,
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: _labelScaler(context, style)),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

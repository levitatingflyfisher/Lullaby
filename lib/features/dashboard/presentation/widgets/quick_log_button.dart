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
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
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
              SizedBox(
                width: AppConstants.quickLogButtonSize,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
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

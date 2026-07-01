import 'package:flutter/material.dart';

import '../../domain/entities/baby.dart';
import 'baby_photo.dart';

class BabyAvatar extends StatelessWidget {
  const BabyAvatar({
    super.key,
    required this.baby,
    this.radius = 40,
  });

  final BabyEntity baby;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Resolved through the baby_photo trio: on web this is always null (a
    // stored path points at some device's disk), so the widget never touches
    // dart:io and calmly falls back to the initial-letter avatar.
    final photo = babyPhotoImage(baby.photoPath);
    if (photo != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: photo,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        baby.name.isNotEmpty ? baby.name[0].toUpperCase() : '?',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

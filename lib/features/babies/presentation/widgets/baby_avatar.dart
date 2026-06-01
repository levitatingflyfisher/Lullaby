import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/baby.dart';

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

    if (baby.photoPath != null) {
      final file = File(baby.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/babies/presentation/widgets/baby_avatar.dart';

void main() {
  final now = DateTime(2025, 6, 15);

  group('BabyAvatar', () {
    testWidgets('shows initial when no photo', (tester) async {
      final baby = BabyEntity(
        id: '1',
        name: 'Alice',
        dateOfBirth: DateTime(2024, 12, 1),
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BabyAvatar(baby: baby),
        ),
      ));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('uses correct radius', (tester) async {
      final baby = BabyEntity(
        id: '1',
        name: 'Bob',
        dateOfBirth: DateTime(2024, 12, 1),
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BabyAvatar(baby: baby, radius: 60),
        ),
      ));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 60);
    });

    testWidgets('shows ? for empty name', (tester) async {
      final baby = BabyEntity(
        id: '1',
        name: '',
        dateOfBirth: DateTime(2024, 12, 1),
        isActive: true,
        createdAt: now,
        modifiedAt: now,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BabyAvatar(baby: baby),
        ),
      ));

      expect(find.text('?'), findsOneWidget);
    });
  });
}

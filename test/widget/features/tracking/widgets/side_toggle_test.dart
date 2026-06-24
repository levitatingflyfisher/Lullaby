import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/presentation/widgets/side_toggle.dart';

void main() {
  group('SideToggle', () {
    testWidgets('renders all 3 segments', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SideToggle(
            selected: BreastSide.left,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      BreastSide? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SideToggle(
            selected: BreastSide.left,
            onChanged: (side) => selected = side,
          ),
        ),
      ));

      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      expect(selected, BreastSide.right);
    });
  });
}

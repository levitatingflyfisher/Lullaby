import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/quick_log_button.dart';

void main() {
  group('QuickLogButton', () {
    testWidgets('renders icon and label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickLogButton(
            icon: Icons.restaurant,
            label: 'Feed',
            color: Colors.green,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickLogButton(
            icon: Icons.restaurant,
            label: 'Feed',
            color: Colors.green,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickLogButton(
            icon: Icons.baby_changing_station,
            label: 'Diaper',
            color: Colors.amber,
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      ));

      await tester.longPress(find.byType(InkWell));
      expect(longPressed, isTrue);
    });

    testWidgets('has correct size', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickLogButton(
            icon: Icons.restaurant,
            label: 'Feed',
            color: Colors.green,
            onTap: () {},
          ),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 88.0);
      expect(sizedBox.height, 88.0);
    });

    // Audit rank 10 (item 34 follow-up): the label sat outside the InkWell,
    // so aiming at the word "Feed" hit nothing.
    testWidgets('tapping the label word triggers onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickLogButton(
              icon: Icons.restaurant,
              label: 'Feed',
              color: Colors.green,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Feed'));
      expect(tapped, isTrue);
    });

    testWidgets('exposes one button named by its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickLogButton(
              icon: Icons.restaurant,
              label: 'Feed',
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      ));

      expect(
          tester.getSemantics(find.text('Feed')),
          matchesSemantics(
            label: 'Feed',
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ));
      handle.dispose();
    });
  });
}

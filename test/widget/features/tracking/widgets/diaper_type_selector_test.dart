import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/presentation/widgets/diaper_type_selector.dart';

void main() {
  group('DiaperTypeSelector', () {
    testWidgets('renders all 4 segments', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiaperTypeSelector(
            selected: DiaperType.wet,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('Wet'), findsOneWidget);
      expect(find.text('Dirty'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('Dry'), findsOneWidget);
    });

    testWidgets('calls onChanged when segment tapped', (tester) async {
      DiaperType? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiaperTypeSelector(
            selected: DiaperType.wet,
            onChanged: (type) => selected = type,
          ),
        ),
      ));

      await tester.tap(find.text('Dirty'));
      await tester.pumpAndSettle();
      expect(selected, DiaperType.dirty);
    });
  });
}

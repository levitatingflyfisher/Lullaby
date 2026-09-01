import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/widgets/growth_curve_chart.dart';

/// Audit rank 11 (dmmt-10, mind-11, dfh-04, visual-13): at text scale 1.3
/// the left axis printed "2kg" over "1kg" and the bottom axis ran
/// "12m15m18m21m24m" together. No two axis labels may touch, at any of the
/// sizes a parent might use, on any of the three tabs.
void main() {
  final dob = DateTime(2024, 12, 1);
  final record = GrowthRecordEntity(
    id: 'r1',
    babyId: 'b1',
    measuredAt: DateTime(2025, 6, 1),
    weightKg: 7.2,
    heightCm: 65,
    headCircumferenceCm: 42,
    createdAt: DateTime(2025, 6, 1),
    modifiedAt: DateTime(2025, 6, 1),
  );

  Future<void> pump(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GrowthCurveChart(
            records: [record],
            dateOfBirth: dob,
            gender: Gender.female,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<Rect> labelRects(WidgetTester tester) => [
        for (final e in find
            .descendant(
                of: find.byType(LineChart), matching: find.byType(Text))
            .evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];

  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(360, 800), 1.3),
    (const Size(360, 800), 2.0),
    (const Size(320, 800), 3.0),
  ]) {
    testWidgets('no axis labels touch at ${size.width.toInt()}dp x $scale',
        (tester) async {
      await pump(tester, size, scale);
      for (final tab in ['Weight', 'Height', 'Head']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rects = labelRects(tester);
        expect(rects.length, greaterThanOrEqualTo(4),
            reason: '$tab: the axes should still carry labels');
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse,
                reason: '$tab at $scale: label $i ${rects[i]} touches '
                    'label $j ${rects[j]}');
          }
        }
      }
    });
  }
}

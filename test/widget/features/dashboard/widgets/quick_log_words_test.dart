import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/app/theme/theme.dart';
import 'package:lullaby/features/dashboard/presentation/widgets/quick_log_button.dart';

/// At 3x text the quick-log words broke mid-word under their circles
/// ("Slee / p", "Diap / er"; parked from the rollout). A one-word label
/// stays one whole word, shrinking to the button's width if it must.
void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('quick-log words stay whole at ${scale}x', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final w in ['Feed', 'Sleep', 'Diaper'])
                QuickLogButton(
                    icon: Icons.circle,
                    label: w,
                    fitLabel: 'Diaper',
                    color: Colors.blue,
                    onTap: () {}),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final w in ['Feed', 'Sleep', 'Diaper']) {
        final para = tester.renderObject<RenderParagraph>(find.text(w));
        final tops = para
            .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: w.length))
            .map((b) => b.top.round())
            .toSet();
        expect(tops, hasLength(1), reason: '"$w" breaks at ${scale}x');
        expect(para.didExceedMaxLines, isFalse, reason: '"$w" is cut');
        expect(para.size.width, lessThanOrEqualTo(88.5), reason: '"$w" spills');
      }
      // One row, one size.
      final scales = {
        for (final w in ['Feed', 'Sleep', 'Diaper'])
          tester.renderObject<RenderParagraph>(find.text(w)).textScaler.scale(10)
      };
      expect(scales, hasLength(1));
    });
  }
}

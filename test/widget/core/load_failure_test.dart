import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/widgets/load_failure.dart';
import 'package:openhearth_design/openhearth_design.dart';

void main() {
  final raw = StateError('SqliteException(11): database disk image is malformed');

  Widget host(Widget child, {double scale = 1.0}) => MaterialApp(
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(body: child),
      );

  group('LoadFailure (full)', () {
    testWidgets('names what failed in plain words and hides the exception',
        (tester) async {
      await tester.pumpWidget(host(LoadFailure(what: 'the growth chart', error: raw)));

      expect(find.byType(OhErrorState), findsOneWidget);
      expect(find.text('Couldn’t load the growth chart'), findsOneWidget);
      expect(find.text(OhErrorMessages.generic), findsOneWidget);
      expect(find.textContaining('SqliteException'), findsNothing);
      // The package default glyph is a cloud; Lullaby never uses a network.
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('Try again calls onRetry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(host(LoadFailure(
          what: 'recent activity', error: raw, onRetry: () => retried++)));
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });

  group('LoadFailure.inline', () {
    testWidgets(
        'sits inside a list at 320dp and text scale 2.0 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var retried = 0;

      await tester.pumpWidget(host(
        ListView(children: [
          const Text('Above'),
          LoadFailure.inline(
              what: 'recent activity', error: raw, onRetry: () => retried++),
          const Text('Below'),
        ]),
        scale: 2.0,
      ));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Couldn’t load recent activity'), findsOneWidget);
      expect(find.textContaining(OhErrorMessages.generic), findsOneWidget);
      expect(find.textContaining('SqliteException'), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });
}

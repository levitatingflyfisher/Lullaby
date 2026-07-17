import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullaby/features/babies/presentation/screens/baby_edit_screen.dart';

void main() {
  Widget buildSubject({bool? photoSupported}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              BabyEditScreen(photoSupportedOverride: photoSupported),
        ),
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BabyEditScreen photo affordance', () {
    testWidgets('offers "Choose photo" where photos are supported (native)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Choose photo'), findsOneWidget);
      expect(
          find.text('Baby photos are available in the Android app.'),
          findsNothing);
    });

    testWidgets(
        'hides the photo picker on web and says so honestly — a tap that '
        'throws is worse than no button', (tester) async {
      await tester.pumpWidget(buildSubject(photoSupported: false));
      await tester.pump();

      expect(find.text('Choose photo'), findsNothing);
      expect(
          find.text('Baby photos are available in the Android app.'),
          findsOneWidget);
      // The rest of the form still works.
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Add Baby'), findsWidgets);
    });
  });
}

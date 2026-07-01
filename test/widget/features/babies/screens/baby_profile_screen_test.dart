import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/babies/presentation/screens/baby_profile_screen.dart';
import 'package:lullaby/features/export/data/export_file_share.dart';
import 'package:lullaby/features/export/raw_export_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';

typedef _ShareCall = ({Uint8List bytes, String fileName, String mimeType});

void main() {
  final now = DateTime(2026, 3, 27);
  final fakeBaby = BabyEntity(
    id: 'b1',
    name: 'Alice',
    dateOfBirth: DateTime(2025, 9, 1),
    isActive: true,
    createdAt: now,
    modifiedAt: now,
  );

  Widget buildSubject({BabyEntity? baby}) {
    return ProviderScope(
      overrides: [
        activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
      ],
      child: const MaterialApp(home: BabyProfileScreen()),
    );
  }

  group('BabyProfileScreen', () {
    testWidgets('shows "Export all data" ListTile when baby is loaded',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Export all data'), findsOneWidget);
    });

    testWidgets('shows baby name', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows "No baby profile yet" when baby is null',
        (tester) async {
      await tester.pumpWidget(buildSubject(baby: null));
      await tester.pump();

      expect(find.text('No baby profile yet'), findsOneWidget);
    });

    testWidgets('download icon is present on export tile', (tester) async {
      await tester.pumpWidget(buildSubject(baby: fakeBaby));
      await tester.pump();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets(
        'export tile hands the raw CSV to the share seam as bytes '
        '(no dart:io, so it also works on the PWA)', (tester) async {
      final calls = <_ShareCall>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          activeBabyProvider.overrideWith((ref) => Stream.value(fakeBaby)),
          rawExportProvider
              .overrideWith((ref, babyId) async => 'type,started_at\nfeed,x'),
          exportFileShareProvider.overrideWithValue(
            ({required bytes, required fileName, required mimeType}) async {
              calls.add(
                  (bytes: bytes, fileName: fileName, mimeType: mimeType));
            },
          ),
        ],
        child: const MaterialApp(home: BabyProfileScreen()),
      ));
      await tester.pump();

      await tester.tap(find.text('Export all data'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.mimeType, 'text/csv');
      expect(calls.single.fileName, startsWith('lullaby_Alice_raw_'));
      expect(calls.single.fileName, endsWith('.csv'));
      expect(utf8.decode(calls.single.bytes), 'type,started_at\nfeed,x');
    });
  });
}

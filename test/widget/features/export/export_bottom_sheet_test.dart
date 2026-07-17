import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/controllers/doctor_controller.dart';
import 'package:lullaby/features/export/data/export_file_share.dart';
import 'package:lullaby/features/export/export_bottom_sheet.dart';

typedef _ShareCall = ({Uint8List bytes, String fileName, String mimeType});

void main() {
  final now = DateTime(2026, 3, 27);
  final baby = BabyEntity(
    id: 'b1',
    name: 'TestBaby',
    dateOfBirth: DateTime(2025, 9, 1),
    isActive: true,
    createdAt: now,
    modifiedAt: now,
  );
  final summary = DoctorSummary(
    baby: baby,
    dateRange:
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    avgFeedsPerDay: 8.0,
    avgSleepHoursPerDay: 14.5,
    avgDiapersPerDay: 6.0,
  );

  Widget buildSubject({List<_ShareCall>? shareCalls}) {
    return ProviderScope(
      overrides: [
        if (shareCalls != null)
          exportFileShareProvider.overrideWithValue(
            ({required bytes, required fileName, required mimeType}) async {
              shareCalls
                  .add((bytes: bytes, fileName: fileName, mimeType: mimeType));
            },
          ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ExportBottomSheet(
            summary: summary,
            dailySummaries: const [],
          ),
        ),
      ),
    );
  }

  group('ExportBottomSheet', () {
    testWidgets('renders PDF Summary list tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('PDF Summary'), findsOneWidget);
    });

    testWidgets('renders CSV Summary list tile', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('CSV Summary'), findsOneWidget);
    });

    testWidgets('both tiles are present simultaneously', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('PDF Summary'), findsOneWidget);
      expect(find.text('CSV Summary'), findsOneWidget);
    });

    testWidgets('PDF icon is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('CSV icon is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    // The exports run through the export_file_share seam — bytes in, share
    // out — so the sheet itself never touches dart:io and works on the PWA.
    testWidgets('CSV Summary hands CSV bytes to the share seam',
        (tester) async {
      final calls = <_ShareCall>[];
      await tester.pumpWidget(buildSubject(shareCalls: calls));

      await tester.tap(find.text('CSV Summary'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.mimeType, 'text/csv');
      expect(calls.single.fileName, startsWith('lullaby_TestBaby_'));
      expect(calls.single.fileName, endsWith('.csv'));
      expect(utf8.decode(calls.single.bytes),
          contains('date,feeding_count,feeding_minutes'));
    });

    testWidgets('PDF Summary hands PDF bytes to the share seam',
        (tester) async {
      final calls = <_ShareCall>[];
      await tester.pumpWidget(buildSubject(shareCalls: calls));

      await tester.tap(find.text('PDF Summary'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.mimeType, 'application/pdf');
      expect(calls.single.fileName, startsWith('lullaby_TestBaby_'));
      expect(calls.single.fileName, endsWith('.pdf'));
      // %PDF magic header
      expect(calls.single.bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });
  });
}

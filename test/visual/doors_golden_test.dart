import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/screens/doctor_summary_screen.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/presentation/controllers/growth_controller.dart';
import 'package:lullaby/features/growth/presentation/screens/growth_screen.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/timeline/presentation/screens/timeline_screen.dart';

import 'visual_golden_helper.dart';

const _sizes = <String, Size>{
  'phone': Size(360, 800),
  'narrow': Size(320, 800),
};

/// Layout from the dmmt-03 / dmmt-09 fixes: the Timeline top bar keeps its
/// title whole at large text (Calendar moved into Events), and the growth
/// card carries the WHO percentile in words. Swept at 320/360 dp and text
/// scales 1.0 and 3.0.
void main() {
  testWidgets('TimelineScreen top bar, title alone', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'timeline_top_bar',
      sizes: _sizes,
      textScales: const <double>[1.0, 3.0],
      home: ProviderScope(
        overrides: [
          activeBabyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const TimelineScreen(),
      ),
    );
  });

  testWidgets('GrowthScreen latest card with percentile lines',
      (tester) async {
    final girl = BabyEntity(
      id: 'b1',
      name: 'Nora',
      dateOfBirth: DateTime(2024, 12, 1),
      gender: Gender.female,
      createdAt: DateTime(2025, 1, 1),
      modifiedAt: DateTime(2025, 1, 1),
    );
    final record = GrowthRecordEntity(
      id: 'r1',
      babyId: 'b1',
      measuredAt: DateTime(2025, 6, 1),
      weightKg: 7.2,
      heightCm: 65.0,
      headCircumferenceCm: 42.0,
      createdAt: DateTime(2025, 6, 1),
      modifiedAt: DateTime(2025, 6, 1),
    );
    await goldenAtSizes(
      tester,
      name: 'growth_percentile_words',
      sizes: _sizes,
      textScales: const <double>[1.0, 3.0],
      home: ProviderScope(
        overrides: [
          activeBabyProvider.overrideWith((ref) => Stream.value(girl)),
          growthRecordsProvider
              .overrideWith((ref, babyId) => Stream.value([record])),
          latestGrowthProvider.overrideWith((ref, babyId) async => record),
        ],
        child: const GrowthScreen(),
      ),
    );
  });

  // The Share action became icon plus label (item 34 follow-up). No baby
  // keeps the body free of today's date, so the image is deterministic.
  testWidgets('DoctorSummaryScreen top bar with labelled Share',
      (tester) async {
    await goldenAtSizes(
      tester,
      name: 'doctor_summary_share_action',
      sizes: _sizes,
      textScales: const <double>[1.0, 3.0],
      home: ProviderScope(
        overrides: [
          activeBabyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const DoctorSummaryScreen(),
      ),
    );
  });
}

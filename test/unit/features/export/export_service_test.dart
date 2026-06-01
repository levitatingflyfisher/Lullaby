import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/doctor/presentation/controllers/doctor_controller.dart';
import 'package:lullaby/features/export/export_service.dart';
import 'package:lullaby/features/stats/domain/entities/daily_summary.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/health/medicine/domain/entities/medicine_log.dart';
import 'package:lullaby/features/health/vaccine/domain/entities/vaccine_record.dart';

final _now = DateTime(2026, 3, 27);
final _dob = DateTime(2025, 9, 1);

final _fakeBaby = BabyEntity(
  id: 'b1',
  name: 'TestBaby',
  dateOfBirth: _dob,
  isActive: true,
  createdAt: _now,
  modifiedAt: _now,
);

DoctorSummary _makeSummary({
  GrowthRecordEntity? latestGrowth,
  List<MedicineLogEntity> medicines = const [],
  List<VaccineRecordEntity> vaccines = const [],
}) {
  return DoctorSummary(
    baby: _fakeBaby,
    dateRange: DateTimeRange(
        start: _now.subtract(const Duration(days: 30)), end: _now),
    avgFeedsPerDay: 8.0,
    avgSleepHoursPerDay: 14.5,
    avgDiapersPerDay: 6.0,
    latestGrowth: latestGrowth,
    recentMedicines: medicines,
    administeredVaccines: vaccines,
  );
}

DailySummary _makeDaily(DateTime date,
    {int feedingCount = 8,
    int totalFeedingMinutes = 120,
    int sleepMinutes = 480,
    int diaperCount = 6,
    Map<String, int> diapersByType = const {'wet': 3, 'dirty': 2, 'both': 1}}) {
  return DailySummary(
    date: date,
    feedingCount: feedingCount,
    totalFeedingMinutes: totalFeedingMinutes,
    sleepMinutes: sleepMinutes,
    diaperCount: diaperCount,
    diapersByType: diapersByType,
  );
}

FeedingLogEntity _makeFeeding({
  FeedingType type = FeedingType.bottle,
  required DateTime startTime,
  int? durationMinutes,
  double? amountMl,
  BreastSide? side,
}) {
  return FeedingLogEntity(
    id: 'f1',
    babyId: 'b1',
    type: type,
    startTime: startTime,
    durationMinutes: durationMinutes,
    amountMl: amountMl,
    side: side,
    createdAt: _now,
    modifiedAt: _now,
  );
}

SleepLogEntity _makeSleep({required DateTime startTime, int? durationMinutes}) {
  return SleepLogEntity(
    id: 's1',
    babyId: 'b1',
    startTime: startTime,
    type: SleepType.nap,
    durationMinutes: durationMinutes,
    createdAt: _now,
    modifiedAt: _now,
  );
}

DiaperLogEntity _makeDiaper({required DateTime time}) {
  return DiaperLogEntity(
    id: 'd1',
    babyId: 'b1',
    time: time,
    type: DiaperType.wet,
    createdAt: _now,
    modifiedAt: _now,
  );
}

GrowthRecordEntity _makeGrowth({required DateTime measuredAt}) {
  return GrowthRecordEntity(
    id: 'g1',
    babyId: 'b1',
    measuredAt: measuredAt,
    weightKg: 5.2,
    heightCm: 62.0,
    headCircumferenceCm: 40.5,
    createdAt: _now,
    modifiedAt: _now,
  );
}

MedicineLogEntity _makeMedicine({required DateTime administeredAt}) {
  return MedicineLogEntity(
    id: 'm1',
    babyId: 'b1',
    medicineName: 'Tylenol',
    dosage: 5.0,
    dosageUnit: 'ml',
    administeredAt: administeredAt,
    createdAt: _now,
    modifiedAt: _now,
  );
}

VaccineRecordEntity _makeVaccine({DateTime? administeredDate}) {
  return VaccineRecordEntity(
    id: 'v1',
    babyId: 'b1',
    vaccineName: 'DTaP',
    doseNumber: 2,
    administeredDate: administeredDate,
    createdAt: _now,
    modifiedAt: _now,
  );
}

void main() {
  const svc = ExportService();

  group('ExportService.generateSummaryCsv', () {
    test('header row is correct', () {
      final csv = svc.generateSummaryCsv([]);
      final header = csv.split('\n').first;
      expect(header,
          'date,feeding_count,feeding_minutes,sleep_minutes,diaper_count,wet,dirty,both');
    });

    test('row count matches dailySummaries.length', () {
      final dailies = [
        _makeDaily(DateTime(2026, 3, 1)),
        _makeDaily(DateTime(2026, 3, 2)),
        _makeDaily(DateTime(2026, 3, 3)),
      ];
      final csv = svc.generateSummaryCsv(dailies);
      final dataLines =
          csv.split('\n').where((l) => l.isNotEmpty).skip(1).toList();
      expect(dataLines, hasLength(3));
    });

    test('date is formatted as yyyy-MM-dd', () {
      final csv = svc.generateSummaryCsv([_makeDaily(DateTime(2026, 3, 1))]);
      expect(csv, contains('2026-03-01'));
    });

    test('feeding_count and sleep_minutes values are correct', () {
      final daily = _makeDaily(DateTime(2026, 3, 1),
          feedingCount: 9, sleepMinutes: 510);
      final csv = svc.generateSummaryCsv([daily]);
      final dataRow = csv.split('\n')[1];
      final cols = dataRow.split(',');
      expect(cols[1], '9');
      expect(cols[3], '510');
    });

    test('diapersByType wet/dirty/both resolved from map', () {
      final daily = _makeDaily(DateTime(2026, 3, 1),
          diapersByType: {'wet': 4, 'dirty': 1, 'both': 2});
      final csv = svc.generateSummaryCsv([daily]);
      final dataRow = csv.split('\n')[1];
      final cols = dataRow.split(',');
      expect(cols[5], '4');
      expect(cols[6], '1');
      expect(cols[7], '2');
    });

    test('diapersByType defaults to 0 when key absent', () {
      final daily =
          _makeDaily(DateTime(2026, 3, 1), diapersByType: {'wet': 3});
      final csv = svc.generateSummaryCsv([daily]);
      final dataRow = csv.split('\n')[1];
      final cols = dataRow.split(',');
      expect(cols[6], '0');
      expect(cols[7], '0');
    });

    test('returns header only when dailySummaries is empty', () {
      final csv = svc.generateSummaryCsv([]);
      final nonEmpty = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(nonEmpty, hasLength(1));
    });

    test('null fields produce empty string not "null"', () {
      final csv = svc.generateSummaryCsv([]);
      expect(csv, isNot(contains('null')));
    });
  });

  group('ExportService._csvCell (via generateRawCsv)', () {
    test('_csvCell("a,b") returns quoted value', () {
      final med = MedicineLogEntity(
        id: 'm1',
        babyId: 'b1',
        medicineName: 'a,b',
        administeredAt: DateTime(2026, 3, 1, 8),
        createdAt: _now,
        modifiedAt: _now,
      );
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [med],
        vaccines: [],
      );
      expect(csv, contains('"a,b"'));
    });

    test('_csvCell with embedded double-quote escapes as ""', () {
      final med = MedicineLogEntity(
        id: 'm1',
        babyId: 'b1',
        medicineName: 'say "hi"',
        administeredAt: DateTime(2026, 3, 1, 8),
        createdAt: _now,
        modifiedAt: _now,
      );
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [med],
        vaccines: [],
      );
      expect(csv, contains('"say ""hi"""'));
    });
  });

  group('ExportService.generateRawCsv', () {
    test('header row is "type,timestamp,details"', () {
      final csv = svc.generateRawCsv(
          feedings: [],
          sleeps: [],
          diapers: [],
          growthRecords: [],
          medicines: [],
          vaccines: []);
      expect(csv.split('\n').first, 'type,timestamp,details');
    });

    test('feeding row has type=="feeding"', () {
      final csv = svc.generateRawCsv(
        feedings: [
          _makeFeeding(startTime: DateTime(2026, 3, 1, 8), amountMl: 120)
        ],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [],
      );
      final dataRows =
          csv.split('\n').where((l) => l.isNotEmpty).skip(1).toList();
      expect(dataRows, hasLength(1));
      expect(dataRows.first.startsWith('feeding,'), isTrue);
    });

    test('vaccine with null administeredDate is excluded', () {
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [_makeVaccine(administeredDate: null)],
      );
      final dataRows =
          csv.split('\n').where((l) => l.isNotEmpty).skip(1).toList();
      expect(dataRows, isEmpty);
    });

    test('rows sorted ascending by timestamp', () {
      final t1 = DateTime(2026, 3, 1, 9);
      final t2 = DateTime(2026, 3, 1, 8);
      final csv = svc.generateRawCsv(
        feedings: [_makeFeeding(startTime: t1)],
        sleeps: [_makeSleep(startTime: t2)],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [],
      );
      final dataRows =
          csv.split('\n').where((l) => l.isNotEmpty).skip(1).toList();
      expect(dataRows, hasLength(2));
      expect(dataRows[0].startsWith('sleep,'), isTrue);
      expect(dataRows[1].startsWith('feeding,'), isTrue);
    });

    test('bottle feeding details contains "bottle"', () {
      final csv = svc.generateRawCsv(
        feedings: [
          _makeFeeding(
              type: FeedingType.bottle,
              startTime: DateTime(2026, 3, 1, 8),
              amountMl: 120)
        ],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [],
      );
      expect(csv, contains('bottle'));
    });

    test('all six row types are present in output', () {
      final t = DateTime(2026, 3, 1, 8);
      final csv = svc.generateRawCsv(
        feedings: [_makeFeeding(startTime: t)],
        sleeps: [_makeSleep(startTime: t.add(const Duration(hours: 1)))],
        diapers: [_makeDiaper(time: t.add(const Duration(hours: 2)))],
        growthRecords: [
          _makeGrowth(measuredAt: t.add(const Duration(hours: 3)))
        ],
        medicines: [
          _makeMedicine(administeredAt: t.add(const Duration(hours: 4)))
        ],
        vaccines: [
          _makeVaccine(administeredDate: t.add(const Duration(hours: 5)))
        ],
      );
      expect(csv, contains('\nfeeding,'));
      expect(csv, contains('\nsleep,'));
      expect(csv, contains('\ndiaper,'));
      expect(csv, contains('\ngrowth,'));
      expect(csv, contains('\nmedicine,'));
      expect(csv, contains('\nvaccine,'));
    });

    test('sleep details contains location name when location is set', () {
      final sleep = SleepLogEntity(
        id: 's2',
        babyId: 'b1',
        startTime: DateTime(2026, 3, 1, 9),
        type: SleepType.nap,
        durationMinutes: 45,
        location: SleepLocation.crib,
        createdAt: _now,
        modifiedAt: _now,
      );
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [sleep],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [],
      );
      expect(csv, contains('crib'));
    });

    test('growth details contains kg and cm values', () {
      final growth = _makeGrowth(measuredAt: DateTime(2026, 3, 15, 10));
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [growth],
        medicines: [],
        vaccines: [],
      );
      expect(csv, contains('5.2kg'));
      expect(csv, contains('62.0cm'));
      expect(csv, contains('40.5cm head'));
    });

    test('medicine details contains dose amount and unit', () {
      final med = _makeMedicine(administeredAt: DateTime(2026, 3, 10, 9));
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [med],
        vaccines: [],
      );
      expect(csv, contains('Tylenol'));
      expect(csv, contains('5.0'));
      expect(csv, contains('ml'));
    });

    test('vaccine with administeredDate is included', () {
      final vaccine = _makeVaccine(administeredDate: DateTime(2026, 2, 1, 14));
      final csv = svc.generateRawCsv(
        feedings: [],
        sleeps: [],
        diapers: [],
        growthRecords: [],
        medicines: [],
        vaccines: [vaccine],
      );
      final dataRows =
          csv.split('\n').where((l) => l.isNotEmpty).skip(1).toList();
      expect(dataRows, hasLength(1));
      expect(dataRows.first, startsWith('vaccine,'));
      expect(dataRows.first, contains('DTaP'));
      expect(dataRows.first, contains('dose 2'));
    });
  });

  group('ExportService.generateSummaryPdf', () {
    test('returns non-empty Uint8List', () async {
      final bytes = await svc.generateSummaryPdf(_makeSummary());
      expect(bytes, isNotEmpty);
    });

    test('first 4 bytes are %PDF magic bytes', () async {
      final bytes = await svc.generateSummaryPdf(_makeSummary());
      expect(bytes[0], 0x25);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x44);
      expect(bytes[3], 0x46);
    });

    test('does not throw when latestGrowth is null', () async {
      await expectLater(
        svc.generateSummaryPdf(_makeSummary(latestGrowth: null)),
        completes,
      );
    });

    test('does not throw when recentMedicines is empty', () async {
      await expectLater(
        svc.generateSummaryPdf(_makeSummary(medicines: [])),
        completes,
      );
    });

    test('does not throw when administeredVaccines is empty', () async {
      await expectLater(
        svc.generateSummaryPdf(_makeSummary(vaccines: [])),
        completes,
      );
    });
  });
}

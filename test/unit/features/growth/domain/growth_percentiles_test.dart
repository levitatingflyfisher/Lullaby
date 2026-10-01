import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/growth/domain/entities/growth_record.dart';
import 'package:lullaby/features/growth/domain/entities/who_percentile_data.dart';
import 'package:lullaby/features/growth/domain/growth_percentiles.dart';

void main() {
  group('describePercentile', () {
    test('rounds to an ordinal with "about"', () {
      expect(
        describePercentile(60.4, 'weight'),
        'about the 60th percentile for weight',
      );
      expect(
        describePercentile(50, 'height'),
        'about the 50th percentile for height',
      );
    });

    test('ordinal suffixes, including the teens', () {
      expect(describePercentile(1.6, 'weight'), contains('the 2nd '));
      expect(describePercentile(11, 'weight'), contains('the 11th '));
      expect(describePercentile(12, 'weight'), contains('the 12th '));
      expect(describePercentile(13, 'weight'), contains('the 13th '));
      expect(describePercentile(21, 'weight'), contains('the 21st '));
      expect(describePercentile(22, 'weight'), contains('the 22nd '));
      expect(describePercentile(23, 'weight'), contains('the 23rd '));
      expect(describePercentile(83, 'weight'), contains('the 83rd '));
    });

    // The calculator reports 1.0 for anything at or below P3 and 99.0 at or
    // above P97: sentinels, not measurements. "About the 1st" would be false.
    test('the calculator sentinels read as below 3rd / above 97th', () {
      expect(
        describePercentile(1.0, 'weight'),
        'below the 3rd percentile for weight',
      );
      expect(
        describePercentile(99.0, 'head size'),
        'above the 97th percentile for head size',
      );
    });
  });

  group('GrowthPercentiles.of', () {
    final dob = DateTime(2025, 1, 1);
    BabyEntity baby({Gender? gender}) => BabyEntity(
      id: 'b',
      name: 'Nora',
      dateOfBirth: dob,
      gender: gender,
      createdAt: dob,
      modifiedAt: dob,
    );
    GrowthRecordEntity record(DateTime at) => GrowthRecordEntity(
      id: 'r',
      babyId: 'b',
      measuredAt: at,
      weightKg: 7.0,
      heightCm: 65.0,
      createdAt: at,
      modifiedAt: at,
    );

    test('scores weight and height at the age the record was taken', () {
      final p = GrowthPercentiles.of(
        record(DateTime(2025, 7, 1)),
        baby(gender: Gender.female),
      );
      expect(p.weight, isNotNull);
      expect(p.height, isNotNull);
      expect(p.head, isNull);
      expect(p.outsideWhoRange, isFalse);
      expect(p.needsRecordedSex, isFalse);
    });

    test('no recorded sex: no figures, and says so', () {
      final p = GrowthPercentiles.of(record(DateTime(2025, 7, 1)), baby());
      expect(p.weight, isNull);
      expect(p.needsRecordedSex, isTrue);
      expect(p.outsideWhoRange, isFalse);
    });

    test('past 24 months: no figures, and says so', () {
      final p = GrowthPercentiles.of(
        record(DateTime(2027, 6, 1)),
        baby(gender: Gender.male),
      );
      expect(p.weight, isNull);
      expect(p.outsideWhoRange, isTrue);
      expect(p.needsRecordedSex, isFalse);
    });
  });

  // Age is counted in calendar days. Duration arithmetic loses an hour across
  // a DST change, so Dec 1 -> Jun 1 came out as 181 days on a phone in a DST
  // zone and 182 in UTC: a different percentile (and a golden that only
  // matched on the machine that baked it). Discriminates when run in a DST
  // zone, as on the bake box.
  group('growthAgeMonths', () {
    test('counts calendar days, not a DST-shortened Duration', () {
      expect(
        growthAgeMonths(DateTime(2024, 12, 1), DateTime(2025, 6, 1)),
        182 / 30.44,
      );
    });

    test('ignores the time of day the measurement was taken', () {
      expect(
        growthAgeMonths(DateTime(2024, 12, 1), DateTime(2025, 6, 1, 0, 30)),
        growthAgeMonths(DateTime(2024, 12, 1, 23), DateTime(2025, 6, 1)),
      );
    });

    // A record restored from a backup or sync can carry a UTC-flagged
    // instant; its calendar day is the one the user saw on the phone.
    test('reads a UTC-flagged instant on its local calendar day', () {
      expect(
          growthAgeMonths(DateTime(2024, 12, 1).toUtc(),
              DateTime(2025, 6, 1, 20).toUtc()),
          182 / 30.44);
    });

    test('GrowthPercentiles.of reads the table at that calendar age', () {
      final dob = DateTime(2024, 12, 1);
      final at = DateTime(2025, 6, 1);
      final p = GrowthPercentiles.of(
        GrowthRecordEntity(
          id: 'r',
          babyId: 'b',
          measuredAt: at,
          weightKg: 7.2,
          createdAt: at,
          modifiedAt: at,
        ),
        BabyEntity(
          id: 'b',
          name: 'Nora',
          dateOfBirth: dob,
          gender: Gender.female,
          createdAt: dob,
          modifiedAt: dob,
        ),
      );
      expect(
        p.weight,
        const PercentileCalculator().getPercentile(
          Gender.female,
          182 / 30.44,
          7.2,
          MeasurementType.weight,
        ),
      );
    });
  });
}

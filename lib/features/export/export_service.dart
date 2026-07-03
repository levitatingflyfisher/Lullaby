import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../doctor/presentation/controllers/doctor_controller.dart';
import '../growth/domain/entities/growth_record.dart';
import '../health/medicine/domain/entities/medicine_log.dart';
import '../health/vaccine/domain/entities/vaccine_record.dart';
import '../stats/domain/entities/daily_summary.dart';
import '../tracking/domain/entities/diaper_log.dart';
import '../tracking/domain/entities/feeding_log.dart';
import '../tracking/domain/entities/sleep_log.dart';

class ExportService {
  const ExportService();

  String generateSummaryCsv(List<DailySummary> dailySummaries) {
    final buf = StringBuffer();
    buf.writeln('date,feeding_count,feeding_minutes,sleep_minutes,'
        'diaper_count,wet,dirty,both');

    final fmt = DateFormat('yyyy-MM-dd');
    for (final d in dailySummaries) {
      final wet = d.diapersByType['wet'] ?? 0;
      final dirty = d.diapersByType['dirty'] ?? 0;
      final both = d.diapersByType['both'] ?? 0;
      buf.writeln(
        '${_csvCell(fmt.format(d.date))},'
        '${d.feedingCount},'
        '${d.totalFeedingMinutes},'
        '${d.sleepMinutes},'
        '${d.diaperCount},'
        '$wet,'
        '$dirty,'
        '$both',
      );
    }
    return buf.toString();
  }

  String generateRawCsv({
    required List<FeedingLogEntity> feedings,
    required List<SleepLogEntity> sleeps,
    required List<DiaperLogEntity> diapers,
    required List<GrowthRecordEntity> growthRecords,
    required List<MedicineLogEntity> medicines,
    required List<VaccineRecordEntity> vaccines,
  }) {
    final rows = <_RawRow>[];

    for (final f in feedings) {
      final details = [
        f.type.name,
        if (f.durationMinutes != null) '${f.durationMinutes}min',
        if (f.amountMl != null) '${f.amountMl}ml',
        if (f.side != null) f.side!.name,
      ].join(' ').trim();
      rows.add(_RawRow('feeding', f.startTime.toIso8601String(), details));
    }

    for (final s in sleeps) {
      final details = [
        s.type.name,
        if (s.durationMinutes != null) '${s.durationMinutes}min',
        if (s.location != null) s.location!.name,
      ].join(' ').trim();
      rows.add(_RawRow('sleep', s.startTime.toIso8601String(), details));
    }

    for (final d in diapers) {
      final details = [
        d.type.name,
        if (d.color != null) d.color!.name,
      ].join(' ').trim();
      rows.add(_RawRow('diaper', d.time.toIso8601String(), details));
    }

    for (final g in growthRecords) {
      final details = [
        if (g.weightKg != null) '${g.weightKg}kg',
        if (g.heightCm != null) '${g.heightCm}cm',
        if (g.headCircumferenceCm != null) '${g.headCircumferenceCm}cm head',
      ].join(' ').trim();
      rows.add(_RawRow('growth', g.measuredAt.toIso8601String(), details));
    }

    for (final m in medicines) {
      final details = [
        m.medicineName,
        if (m.dosage != null) '${m.dosage} ${m.dosageUnit ?? ''}'.trim(),
      ].join(' ').trim();
      rows.add(_RawRow(
          'medicine', m.administeredAt.toIso8601String(), details));
    }

    for (final v in vaccines) {
      if (v.administeredDate == null) continue;
      final details = [
        v.vaccineName,
        if (v.doseNumber != null) 'dose ${v.doseNumber}',
      ].join(' ').trim();
      rows.add(_RawRow(
          'vaccine', v.administeredDate!.toIso8601String(), details));
    }

    rows.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buf = StringBuffer();
    buf.writeln('type,timestamp,details');
    for (final r in rows) {
      buf.writeln(
          '${_csvCell(r.type)},${_csvCell(r.timestamp)},${_csvCell(r.details)}');
    }
    return buf.toString();
  }

  Future<Uint8List> generateSummaryPdf(DoctorSummary summary) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('MMM d, yyyy');
    final shortFmt = DateFormat('MMM d');

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Lullaby — ${summary.baby.name}',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${shortFmt.format(summary.dateRange.start)} – '
            '${shortFmt.format(summary.dateRange.end)}  |  '
            'Generated: ${dateFmt.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Divider(),
          pw.Text('SUMMARY',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
              'Avg feeds/day: ${summary.avgFeedsPerDay.toStringAsFixed(1)}   '
              'Avg sleep: ${summary.avgSleepHoursPerDay.toStringAsFixed(1)} hrs/day   '
              'Avg diapers/day: ${summary.avgDiapersPerDay.toStringAsFixed(1)}'),
          pw.SizedBox(height: 12),
          if (summary.latestGrowth != null) ...[
            pw.Text('GROWTH',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Measurement', 'Value'],
              data: [
                if (summary.latestGrowth!.weightKg != null)
                  [
                    'Weight',
                    '${summary.latestGrowth!.weightKg!.toStringAsFixed(1)} kg '
                        '(${(summary.latestGrowth!.weightKg! * 2.20462).toStringAsFixed(1)} lb)'
                        '${summary.weightPercentile != null ? '  P${summary.weightPercentile!.round()}' : ''}',
                  ],
                if (summary.latestGrowth!.heightCm != null)
                  [
                    'Height',
                    '${summary.latestGrowth!.heightCm!.toStringAsFixed(1)} cm '
                        '(${(summary.latestGrowth!.heightCm! / 2.54).toStringAsFixed(1)} in)'
                        '${summary.heightPercentile != null ? '  P${summary.heightPercentile!.round()}' : ''}',
                  ],
                if (summary.latestGrowth!.headCircumferenceCm != null)
                  [
                    'Head',
                    '${summary.latestGrowth!.headCircumferenceCm!.toStringAsFixed(1)} cm '
                        '(${(summary.latestGrowth!.headCircumferenceCm! / 2.54).toStringAsFixed(1)} in)'
                        '${summary.headPercentile != null ? '  P${summary.headPercentile!.round()}' : ''}',
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          if (summary.recentMedicines.isNotEmpty) ...[
            pw.Text('MEDICATIONS (last 30 days)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Dose', 'Date'],
              data: summary.recentMedicines
                  .map((m) => [
                        m.medicineName,
                        m.dosage != null
                            ? '${m.dosage} ${m.dosageUnit ?? ''}'.trim()
                            : '',
                        shortFmt.format(m.administeredAt),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 12),
          ],
          if (summary.administeredVaccines.isNotEmpty) ...[
            pw.Text('VACCINES (administered)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Dose #', 'Date', 'Provider'],
              data: summary.administeredVaccines
                  .where((v) => v.administeredDate != null)
                  .map((v) => [
                        v.vaccineName,
                        v.doseNumber?.toString() ?? '',
                        dateFmt.format(v.administeredDate!),
                        v.provider ?? '',
                      ])
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  String _csvCell(String s) {
    // Neutralize spreadsheet formula injection (OWASP): a cell beginning with a
    // formula trigger is apostrophe-prefixed so a free-text medicine/vaccine
    // name can't execute as a formula when the medical CSV opens in a spreadsheet.
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) {
      s = "'$s";
    }
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

class _RawRow {
  _RawRow(this.type, this.timestamp, this.details);
  final String type;
  final String timestamp;
  final String details;
}

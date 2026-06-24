import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../doctor/presentation/controllers/doctor_controller.dart';
import '../stats/domain/entities/daily_summary.dart';
import 'export_service.dart';

class ExportBottomSheet extends ConsumerStatefulWidget {
  const ExportBottomSheet({
    super.key,
    required this.summary,
    required this.dailySummaries,
  });

  final DoctorSummary summary;
  final List<DailySummary> dailySummaries;

  @override
  ConsumerState<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends ConsumerState<ExportBottomSheet> {
  bool _busy = false;

  Future<void> _exportPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      const svc = ExportService();
      final bytes = await svc.generateSummaryPdf(widget.summary);
      final dir = await getTemporaryDirectory();
      final name = 'lullaby_${widget.summary.baby.name}_'
          '${_datePart(widget.summary.dateRange.start)}_'
          '${_datePart(widget.summary.dateRange.end)}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      try {
        await Share.shareXFiles([XFile(file.path)]);
      } finally {
        if (await file.exists()) await file.delete();
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      const svc = ExportService();
      final csv = svc.generateSummaryCsv(widget.dailySummaries);
      final dir = await getTemporaryDirectory();
      final name = 'lullaby_${widget.summary.baby.name}_'
          '${_datePart(widget.summary.dateRange.start)}_'
          '${_datePart(widget.summary.dateRange.end)}.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsString(csv);
      try {
        await Share.shareXFiles([XFile(file.path)]);
      } finally {
        if (await file.exists()) await file.delete();
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _datePart(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('PDF Summary'),
            onTap: _busy ? null : _exportPdf,
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('CSV Summary'),
            onTap: _busy ? null : _exportCsv,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

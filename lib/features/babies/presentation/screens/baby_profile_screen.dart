import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../widgets/baby_avatar.dart';
import '../../domain/entities/baby.dart';
import '../../../export/data/export_file_share.dart';
import '../../../export/raw_export_controller.dart';

class BabyProfileScreen extends ConsumerStatefulWidget {
  const BabyProfileScreen({super.key});

  @override
  ConsumerState<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends ConsumerState<BabyProfileScreen> {
  bool _isExporting = false;

  Future<void> _exportAll(BabyEntity baby) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      ref.invalidate(rawExportProvider(baby.id));
      final csv = await ref.read(rawExportProvider(baby.id).future);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'lullaby_${baby.name}_raw_$today.csv';
      // Bytes go through the export_file_share seam: temp-file share sheet
      // on native, Web Share / download on the PWA — never dart:io here.
      final share = ref.read(exportFileShareProvider);
      await share(
        bytes: utf8.encode(csv),
        fileName: fileName,
        mimeType: 'text/csv',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final babyAsync = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/baby/edit', extra: babyAsync.valueOrNull),
          ),
        ],
      ),
      body: babyAsync.when(
        data: (baby) {
          if (baby == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No baby profile yet'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/baby/edit'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Baby'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: BabyAvatar(baby: baby, radius: 60)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  baby.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  baby.formatAge(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (baby.gender != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    baby.gender!.name[0].toUpperCase() +
                        baby.gender!.name.substring(1),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export all data'),
                subtitle: const Text('Save or share a CSV of all events'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isExporting ? null : () => _exportAll(baby),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

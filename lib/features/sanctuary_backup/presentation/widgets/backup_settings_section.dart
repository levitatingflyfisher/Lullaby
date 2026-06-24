import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/auth_providers.dart';
import '../controllers/backup_controller.dart';
import 'phrase_entry_dialog.dart';
import 'seed_phrase_modal.dart';

/// A settings section for encrypted backup: seed phrase setup, export, restore,
/// and identity reset.
///
/// Drop this into the Settings screen's ListView.
class BackupSettingsSection extends ConsumerWidget {
  const BackupSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final backupState = ref.watch(backupControllerProvider);
    final isLoading = backupState is AsyncLoading;

    return authAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (authState) {
        final hasKey = authState.masterEncryptionKey != null;
        final seedAcked = authState.seedAcknowledged;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Encrypted Backup',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),

            // Set up seed phrase (only if no key yet)
            if (!hasKey)
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Set up encrypted backup'),
                subtitle: const Text(
                  'Generate 12 recovery words to protect your data',
                ),
                enabled: !isLoading,
                onTap: () => _generatePhrase(context, ref),
              ),

            // Mid-setup recovery: key exists but acknowledgement was never
            // completed (user dismissed the re-entry dialog). Without this
            // tile the user has no way forward except "Reset identity" since
            // Export is hidden until seedAcked=true.
            if (hasKey && !seedAcked)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Complete backup setup'),
                subtitle: const Text(
                  'Re-enter your recovery words to finish setup',
                ),
                enabled: !isLoading,
                onTap: () => _confirmPhraseReEntry(context, ref),
              ),

            // Export (available after seed acknowledged)
            if (hasKey && seedAcked)
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Export backup'),
                subtitle: authState.lastBackupAt != null
                    ? Text(
                        'Last backup: ${_formatDate(authState.lastBackupAt!)}')
                    : const Text('Save an encrypted copy of all your data'),
                enabled: !isLoading,
                onTap: () => _exportBackup(context, ref),
              ),

            // Restore (always available)
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Restore from backup'),
              subtitle: const Text('Load data from an .ohbk file'),
              enabled: !isLoading,
              onTap: () => _restoreBackup(context, ref, hasKey),
            ),

            // Reset identity (danger zone, only if key exists)
            if (hasKey)
              ListTile(
                leading: Icon(Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Reset identity',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                subtitle: const Text('Wipes recovery words (keeps your data)'),
                enabled: !isLoading,
                onTap: () => _resetIdentity(context, ref),
              ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Future<void> _generatePhrase(BuildContext context, WidgetRef ref) async {
    final phrase =
        await ref.read(backupControllerProvider.notifier).generateSeedPhrase();
    if (phrase == null || !context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // The recovery words must be acknowledged via the button, not
      // barrier-dismissed or swiped away.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => SeedPhraseModal(
        phrase: phrase,
        onAcknowledged: () {},
      ),
    );

    if (!context.mounted) return;
    await _confirmPhraseReEntry(context, ref);
  }

  Future<void> _confirmPhraseReEntry(
      BuildContext context, WidgetRef ref) async {
    while (context.mounted) {
      final reEntry = await PhraseEntryDialog.show(
        context,
        title: 'Re-enter your recovery words',
        body: 'Type the 12 words you just wrote down. This proves your '
            'paper copy is correct — without it, a typo could cost you all '
            'your data later.',
        confirmLabel: 'Confirm',
      );
      if (reEntry == null || !context.mounted) return;

      final ok = await ref
          .read(backupControllerProvider.notifier)
          .confirmSeedAcknowledged(reEntry);
      if (!context.mounted) return;
      if (ok) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Words didn't match. Check your paper copy and try again."),
        ),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(backupControllerProvider.notifier).exportBackup();
    if (result == null || !context.mounted) return;

    await Share.shareXFiles([
      XFile.fromData(result.bytes,
          mimeType: 'application/octet-stream', name: result.filename),
    ]);
  }

  Future<void> _restoreBackup(
      BuildContext context, WidgetRef ref, bool hasKey) async {
    // 1. Pick the .ohbk file.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null ||
        picked.files.isEmpty ||
        picked.files.first.bytes == null) {
      return;
    }
    final blob = picked.files.first.bytes!;

    if (!context.mounted) return;

    final notifier = ref.read(backupControllerProvider.notifier);

    // 2. If the user already has a key we use it; otherwise prompt for phrase.
    RestoreOutcome outcome;
    if (hasKey) {
      final confirm = await _confirmDestructive(context);
      if (!confirm || !context.mounted) return;
      outcome = await notifier.restoreFromBlob(blob);

      // M2: this device's key didn't unlock the backup (it was made under a
      // different phrase) — offer to enter the words it was created with.
      if (outcome == RestoreOutcome.wrongPhrase && context.mounted) {
        final phrase = await PhraseEntryDialog.show(
          context,
          title: "Enter the backup's recovery words",
          body: 'This backup was made with a different set of words than this '
              'device has. Enter the 12 words from when it was created.',
        );
        if (phrase == null || !context.mounted) return;
        outcome = await notifier.restoreWithPhrase(blob, phrase);
      }
    } else {
      final phrase = await PhraseEntryDialog.show(context);
      if (phrase == null || !context.mounted) return;
      final confirm = await _confirmDestructive(context);
      if (!confirm || !context.mounted) return;
      outcome = await notifier.restoreWithPhrase(blob, phrase);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_restoreMessage(outcome))),
    );
  }

  String _restoreMessage(RestoreOutcome outcome) => switch (outcome) {
        RestoreOutcome.success => 'Data restored successfully.',
        RestoreOutcome.wrongPhrase =>
          "Those words didn't unlock this backup. Try the words from when it "
              'was made.',
        RestoreOutcome.corruptFile =>
          "This file looks damaged or isn't a Lullaby backup.",
        RestoreOutcome.tooNewBackup =>
          'This backup was made by a newer version of Lullaby. Update the app, '
              'then restore.',
        RestoreOutcome.noKey =>
          'Set up encrypted backup first, or enter your recovery words.',
        RestoreOutcome.failed => 'Restore failed. Please try again.',
      };

  Future<void> _resetIdentity(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset identity?'),
        content: const Text(
          'This will erase your recovery words from this device. '
          'Your baby data will NOT be deleted, but you won\'t be able to '
          'make encrypted backups until you set up a new phrase.\n\n'
          'Any existing backup files will only be recoverable with the '
          'old recovery words.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(backupControllerProvider.notifier).resetIdentity();
    }
  }

  Future<bool> _confirmDestructive(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'Restoring will delete all current babies, feedings, sleeps, '
          'diapers, growth records, medicines, and vaccines, then replace '
          'them with data from the backup file.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace everything'),
          ),
        ],
      ),
    );
    return result == true;
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../core/providers/sync_providers.dart';
import '../data/household_sync.dart';
import 'sync_words.dart';

/// Changes a merge set aside after a long time offline (hearthSync's review
/// list): nothing is overwritten silently, so each one is shown here until a
/// parent decides.
class SyncReviewScreen extends ConsumerWidget {
  const SyncReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(householdSyncProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Changes to look over')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: ValueListenableBuilder<SyncSnapshot>(
          valueListenable: sync.snapshot,
          builder: (context, s, _) {
            if (s.review.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nothing to look over. Every change found its place.',
                      textAlign: TextAlign.center),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                for (final item in s.review) _ReviewCard(item: item, sync: sync),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.sync});

  final ReviewItem item;
  final HouseholdSync sync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canKeepMine = item.kind == 'field';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reviewTitle(item), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(reviewBody(item), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (canKeepMine)
                  TextButton(
                    onPressed: () => sync.keepMine(item),
                    child: const Text('Use mine'),
                  ),
                FilledButton.tonal(
                  onPressed: () => sync.dismiss(item),
                  child: Text(canKeepMine ? 'Keep theirs' : 'OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

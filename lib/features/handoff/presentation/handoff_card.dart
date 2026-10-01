import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/result.dart';
import '../../../core/providers/repository_providers.dart';
import '../domain/handoff_note.dart';

/// The newest handoff notes about a baby, newest first.
final recentHandoffNotesProvider =
    StreamProvider.autoDispose.family<List<HandoffNote>, String>(
        (ref, babyId) => ref.watch(handoffRepositoryProvider).watchRecent(babyId));

String _when(DateTime at, DateTime now) {
  final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
  final time = DateFormat.jm().format(at);
  return sameDay ? time : '${DateFormat.MMMd().format(at)}, $time';
}

String _byline(HandoffNote n, DateTime now) =>
    n.author == null ? _when(n.writtenAt, now) : '${n.author} · ${_when(n.writtenAt, now)}';

/// Home's "Note for the next shift": the latest line one parent left the
/// other, and the way to leave one. With sync on it reaches the other phone.
class HandoffCard extends ConsumerWidget {
  const HandoffCard({super.key, required this.babyId});

  final String babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentHandoffNotesProvider(babyId));
    final theme = Theme.of(context);
    final latest = notes.valueOrNull?.firstOrNull;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showHandoffSheet(context, babyId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Note for the next shift', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    if (latest == null)
                      Text('None yet. Tap to leave one.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                    else ...[
                      Text(latest.text,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      Text(_byline(latest, DateTime.now()),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// The notes sheet: write a new line at the top (where the keyboard and the
/// thumb are), earlier notes below.
Future<void> showHandoffSheet(BuildContext context, String babyId) =>
    showModalBottomSheet<void>(
      context: context,
      // Above the bottom navigation and any snack bar, so the whole sheet
      // (field, button, earlier notes) is visible.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HandoffSheet(babyId: babyId),
    );

class _HandoffSheet extends ConsumerStatefulWidget {
  const _HandoffSheet({required this.babyId});
  final String babyId;

  @override
  ConsumerState<_HandoffSheet> createState() => _HandoffSheetState();
}

class _HandoffSheetState extends ConsumerState<_HandoffSheet> {
  final _text = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(handoffRepositoryProvider).add(widget.babyId, _text.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        _text.clear();
      case Err(:final failure):
        setState(() => _error = failure.message == 'Write something first.'
            ? failure.message
            : 'Couldn’t save the note. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = ref.watch(recentHandoffNotesProvider(widget.babyId));
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Note for the next shift', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'A line for whoever takes over: last feed, mood, anything to watch.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('handoff-text'),
              controller: _text,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'What should the next person know?',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('handoff-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.send),
              label: const Text('Leave note'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 24),
            if (notes.valueOrNull case final list? when list.isNotEmpty) ...[
              Text('Earlier', style: theme.textTheme.titleSmall),
              for (final n in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n.text),
                  subtitle: Text(_byline(n, now)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

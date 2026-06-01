import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/feeding_log.dart';
import '../controllers/feeding_controller.dart';
import '../controllers/timer_controller.dart';
import '../widgets/side_toggle.dart';
import '../widgets/timer_display.dart';

class FeedingLogScreen extends ConsumerStatefulWidget {
  const FeedingLogScreen({super.key});

  @override
  ConsumerState<FeedingLogScreen> createState() => _FeedingLogScreenState();
}

class _FeedingLogScreenState extends ConsumerState<FeedingLogScreen> {
  FeedingType _type = FeedingType.breast;
  BreastSide _side = BreastSide.left;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _activeLogId;

  FeedingLogEntity? _existing;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is FeedingLogEntity) {
      _existing = extra;
      _type = extra.type;
      _side = extra.side ?? BreastSide.left;
      _amountController.text = extra.amountMl?.toStringAsFixed(0) ?? '';
      _notesController.text = extra.notes ?? '';
      _startTime = extra.startTime;
      _endTime = extra.endTime;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(
      BuildContext context, DateTime initial, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onPicked(combined.isAfter(DateTime.now()) ? DateTime.now() : combined);
  }

  Future<void> _saveEdit() async {
    if (_endTime != null && _endTime!.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    final existing = _existing!;
    final updated = existing.copyWith(
      type: _type,
      side: _type == FeedingType.breast ? () => _side : () => null,
      amountMl: _type == FeedingType.bottle
          ? () => double.tryParse(_amountController.text)
          : () => null,
      startTime: _startTime,
      endTime: _endTime != null ? () => _endTime : () => null,
      durationMinutes: _endTime != null
          ? () => _endTime!.difference(_startTime).inMinutes
          : () => null,
      notes: _notesController.text.isNotEmpty ? () => _notesController.text : () => null,
    );
    await ref.read(feedingControllerProvider.notifier).updateLog(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;

    if (isEdit) {
      return _buildEditMode(context);
    }

    return _buildCreateMode(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(feedingControllerProvider.notifier)
          .deleteLog(_existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildEditMode(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Feeding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<FeedingType>(
            segments: const [
              ButtonSegment(value: FeedingType.breast, label: Text('Breast')),
              ButtonSegment(value: FeedingType.bottle, label: Text('Bottle')),
              ButtonSegment(value: FeedingType.solid, label: Text('Solid')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 24),

          if (_type == FeedingType.breast) ...[
            SideToggle(
              selected: _side,
              onChanged: (side) => setState(() => _side = side),
            ),
            const SizedBox(height: 16),
          ],

          if (_type == FeedingType.bottle) ...[
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],

          ListTile(
            title: const Text('Start time'),
            subtitle: Text(_formatDateTime(_startTime)),
            trailing: const Icon(Icons.schedule),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            onTap: () => _pickDateTime(
                context, _startTime, (dt) => setState(() => _startTime = dt)),
          ),
          const SizedBox(height: 12),

          if (_type == FeedingType.breast) ...[
            ListTile(
              title: const Text('End time (optional)'),
              subtitle: Text(_endTime != null ? _formatDateTime(_endTime!) : 'Not set'),
              trailing: const Icon(Icons.schedule),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: () => _pickDateTime(
                  context, _endTime ?? _startTime,
                  (dt) => setState(() => _endTime = dt)),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton(
              onPressed: _saveEdit,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMode(BuildContext context) {
    final timers = ref.watch(activeTimersProvider);
    final feedingTimer = timers
        .where((t) => t.type == TimerType.feeding && t.logId == _activeLogId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Feeding')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Type selector
          SegmentedButton<FeedingType>(
            segments: const [
              ButtonSegment(value: FeedingType.breast, label: Text('Breast')),
              ButtonSegment(value: FeedingType.bottle, label: Text('Bottle')),
              ButtonSegment(value: FeedingType.solid, label: Text('Solid')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 24),

          // Type-specific fields
          if (_type == FeedingType.breast) ...[
            SideToggle(
              selected: _side,
              onChanged: (side) => setState(() => _side = side),
            ),
            const SizedBox(height: 24),
            if (feedingTimer != null) ...[
              Center(child: TimerDisplay(elapsed: feedingTimer.elapsed)),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(feedingControllerProvider.notifier)
                        .stopBreastFeeding(_activeLogId!);
                    setState(() => _activeLogId = null);
                    if (mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ] else
              Center(
                child: FilledButton.icon(
                  onPressed: () async {
                    final log = await ref
                        .read(feedingControllerProvider.notifier)
                        .startBreastFeeding(_side);
                    if (log != null) {
                      setState(() => _activeLogId = log.id);
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ),
          ],

          if (_type == FeedingType.bottle) ...[
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () {
                  final amount =
                      double.tryParse(_amountController.text) ?? 0;
                  if (amount > 0) {
                    ref
                        .read(feedingControllerProvider.notifier)
                        .logBottleFeeding(
                          amountMl: amount,
                          notes: _notesController.text.isNotEmpty
                              ? _notesController.text
                              : null,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],

          if (_type == FeedingType.solid) ...[
            Center(
              child: FilledButton(
                onPressed: () {
                  ref.read(feedingControllerProvider.notifier).logSolidFeeding(
                        notes: _notesController.text.isNotEmpty
                            ? _notesController.text
                            : null,
                      );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $hour:$min';
  }
}

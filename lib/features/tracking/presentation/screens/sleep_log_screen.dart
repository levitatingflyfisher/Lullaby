import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/sleep_log.dart';
import '../controllers/sleep_controller.dart';
import '../controllers/timer_controller.dart';
import '../widgets/timer_display.dart';

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen> {
  SleepType _type = SleepType.nap;
  SleepLocation? _location;
  final _notesController = TextEditingController();

  SleepLogEntity? _existing;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is SleepLogEntity) {
      _existing = extra;
      _type = extra.type;
      _location = extra.location;
      _notesController.text = extra.notes ?? '';
      _startTime = extra.startTime;
      _endTime = extra.endTime;
    }
  }

  @override
  void dispose() {
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
      location: () => _location,
      startTime: _startTime,
      endTime: _endTime != null ? () => _endTime : () => null,
      durationMinutes: _endTime != null
          ? () => _endTime!.difference(_startTime).inMinutes
          : () => null,
      notes: _notesController.text.isNotEmpty ? () => _notesController.text : () => null,
    );
    await ref.read(sleepControllerProvider.notifier).updateLog(updated);
    if (mounted) Navigator.pop(context);
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (_existing != null) {
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
      await ref.read(sleepControllerProvider.notifier).deleteLog(_existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildEditMode(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sleep'),
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
          SegmentedButton<SleepType>(
            segments: const [
              ButtonSegment(value: SleepType.nap, label: Text('Nap')),
              ButtonSegment(value: SleepType.night, label: Text('Night')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<SleepLocation>(
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
            ),
            initialValue: _location,
            items: SleepLocation.values
                .map((loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.displayName),
                    ))
                .toList(),
            onChanged: (loc) => _location = loc,
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

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
    final baby = ref.watch(activeBabyProvider).valueOrNull;
    final timers = ref.watch(activeTimersProvider);
    final sleepTimer =
        timers.where((t) => t.type == TimerType.sleep).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Sleep')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<SleepType>(
            segments: const [
              ButtonSegment(value: SleepType.nap, label: Text('Nap')),
              ButtonSegment(value: SleepType.night, label: Text('Night')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 24),

          // Location picker
          DropdownButtonFormField<SleepLocation>(
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
            ),
            initialValue: _location,
            items: SleepLocation.values
                .map((loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.displayName),
                    ))
                .toList(),
            onChanged: (loc) => _location = loc,
          ),
          const SizedBox(height: 24),

          if (sleepTimer != null) ...[
            Center(child: TimerDisplay(elapsed: sleepTimer.elapsed)),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  if (sleepTimer.logId != null) {
                    ref
                        .read(sleepControllerProvider.notifier)
                        .stopSleep(sleepTimer.logId!);
                  }
                  Navigator.pop(context);
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
                onPressed: baby != null
                    ? () {
                        ref
                            .read(sleepControllerProvider.notifier)
                            .startSleep(type: _type);
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Sleep'),
              ),
            ),
        ],
      ),
    );
  }
}

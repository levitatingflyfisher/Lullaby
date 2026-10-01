import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../domain/entities/feeding_log.dart';
import '../controllers/feeding_controller.dart';
import '../controllers/timer_controller.dart';
import '../widgets/side_toggle.dart';
import '../widgets/timer_display.dart';
import '../../../../app/undo_host.dart';
import '../../../../core/errors/result.dart';

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
  void initState() {
    super.initState();
    _notesController.addListener(_saveNotesToOpenFeed);
  }

  String? _lastSavedNotes;

  /// While a breast feed started here is open, keep its notes saved as they
  /// are typed: the Home timer card can stop the feed without this form, and
  /// its Stop carries no notes. Only the notes column is written.
  void _saveNotesToOpenFeed() {
    final logId = _activeLogId;
    final text = _notesController.text;
    if (logId == null || text == _lastSavedNotes) return;
    _lastSavedNotes = text;
    ref.read(feedingControllerProvider.notifier).saveFeedNotes(logId, text);
  }

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
    } else if (extra is FeedingType) {
      // Create mode opened from the Feed sheet: the parent already chose the
      // type, so don't ask again (doet-01).
      _type = extra;
    }
  }

  @override
  void dispose() {
    _notesController.removeListener(_saveNotesToOpenFeed);
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

  /// A deliberate delete (the form's own Delete action): no question first,
  /// and an Undo that stays until the parent acts on it (operator ruling Q1).
  Future<void> _delete() async {
    final deleted = _existing!;
    final controller = ref.read(feedingControllerProvider.notifier);
    final undo = ref.read(undoControllerProvider);
    final result = await controller.deleteLog(deleted.id);
    if (!mounted) return;
    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t delete this feed. Please try again.')),
      );
      return;
    }
    offerUndo(
      undo,
      message: 'Feed deleted',
      what: 'the feed',
      restore: () => controller.restoreLog(deleted),
    );
    Navigator.pop(context);
  }

  Widget _buildEditMode(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Feeding'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            // Urgency colour with the bin and the word (ohStyle colour roles).
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: _delete,
          ),
        ],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<FeedingType>(
              // Below 360dp the check mark would break "Breast" mid-word in
              // Nunito; the fill still shows the choice (operator ruling).
              showSelectedIcon: MediaQuery.sizeOf(context).width >= 360,
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
      body: OhPage(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            SegmentedButton<FeedingType>(
              // Below 360dp the check mark would break "Breast" mid-word in
              // Nunito; the fill still shows the choice (operator ruling).
              showSelectedIcon: MediaQuery.sizeOf(context).width >= 360,
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
                          .stopBreastFeeding(
                            _activeLogId!,
                            notes: _notesController.text.isNotEmpty
                                ? _notesController.text
                                : null,
                          );
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
                          .startBreastFeeding(
                            _side,
                            notes: _notesController.text.isNotEmpty
                                ? _notesController.text
                                : null,
                          );
                      if (log != null) {
                        // Start already stored whatever was typed so far.
                        _lastSavedNotes = _notesController.text;
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
              // Save stays disabled until the amount is a positive number, so
              // a tap never silently does nothing (doet-02).
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder: (context, value, _) {
                  final amount = double.tryParse(value.text) ?? 0;
                  return Center(
                    child: FilledButton(
                      onPressed: amount > 0
                          ? () {
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
                          : null,
                      child: const Text('Save'),
                    ),
                  );
                },
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

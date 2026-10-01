import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../domain/entities/diaper_log.dart';
import '../controllers/diaper_controller.dart';
import '../widgets/diaper_type_selector.dart';
import '../../../../app/undo_host.dart';
import '../../../../core/errors/result.dart';

class DiaperLogScreen extends ConsumerStatefulWidget {
  const DiaperLogScreen({super.key});

  @override
  ConsumerState<DiaperLogScreen> createState() => _DiaperLogScreenState();
}

class _DiaperLogScreenState extends ConsumerState<DiaperLogScreen> {
  DiaperType _type = DiaperType.wet;
  StoolColor? _color;
  final _notesController = TextEditingController();

  DiaperLogEntity? _existing;
  DateTime _time = DateTime.now();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is DiaperLogEntity) {
      _existing = extra;
      _type = extra.type;
      _color = extra.color;
      _notesController.text = extra.notes ?? '';
      _time = extra.time;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _time.isAfter(now) ? now : _time,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (time == null) return;
    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _time =
          combined.isAfter(DateTime.now()) ? DateTime.now() : combined;
    });
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $hour:$min';
  }

  /// A deliberate delete (the form's own Delete action): no question first,
  /// and an Undo that stays until the parent acts on it (operator ruling Q1).
  Future<void> _delete() async {
    final deleted = _existing!;
    final controller = ref.read(diaperControllerProvider.notifier);
    final undo = ref.read(undoControllerProvider);
    final result = await controller.deleteLog(deleted.id);
    if (!mounted) return;
    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t delete this diaper change. Please try again.')),
      );
      return;
    }
    offerUndo(
      undo,
      message: 'Diaper change deleted',
      what: 'the diaper change',
      restore: () => controller.restoreLog(deleted),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Diaper' : 'Log Diaper'),
        actions: [
          if (isEdit)
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
            DiaperTypeSelector(
              selected: _type,
              onChanged: (type) => setState(() {
                _type = type;
                if (type == DiaperType.wet) _color = null;
              }),
            ),
            const SizedBox(height: 24),

            if (_type == DiaperType.dirty || _type == DiaperType.both) ...[
              DropdownButtonFormField<StoolColor>(
                decoration: const InputDecoration(
                  labelText: 'Color (optional)',
                  border: OutlineInputBorder(),
                ),
                initialValue: _color,
                items: StoolColor.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.displayName),
                        ))
                    .toList(),
                onChanged: (c) => _color = c,
              ),
              const SizedBox(height: 16),
            ],

            if (isEdit) ...[
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_formatDateTime(_time)),
                trailing: const Icon(Icons.schedule),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                onTap: () => _pickDateTime(context),
              ),
              const SizedBox(height: 16),
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
                onPressed: () {
                  if (isEdit) {
                    final updated = _existing!.copyWith(
                      type: _type,
                      color: () => _color,
                      time: _time,
                      notes: _notesController.text.isNotEmpty
                          ? () => _notesController.text
                          : () => null,
                    );
                    ref
                        .read(diaperControllerProvider.notifier)
                        .updateLog(updated);
                  } else {
                    ref.read(diaperControllerProvider.notifier).logDiaper(
                          type: _type,
                          color: _color,
                          notes: _notesController.text.isNotEmpty
                              ? _notesController.text
                              : null,
                        );
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

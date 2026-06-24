import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/medicine_log.dart';
import '../../../../../features/settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/medicine_controller.dart';

const _dosageUnits = ['ml', 'mg', 'drops', 'tablet'];

class MedicineAddScreen extends ConsumerStatefulWidget {
  const MedicineAddScreen({super.key});

  @override
  ConsumerState<MedicineAddScreen> createState() => _MedicineAddScreenState();
}

class _MedicineAddScreenState extends ConsumerState<MedicineAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  String? _dosageUnit;
  DateTime _administeredAt = DateTime.now();

  MedicineLogEntity? _existing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (GoRouter.maybeOf(context) == null) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is MedicineLogEntity) {
      _existing = extra;
      _nameController.text = extra.medicineName;
      _dosageController.text = extra.dosage?.toString() ?? '';
      _dosageUnit = extra.dosageUnit;
      _administeredAt = extra.administeredAt;
      _notesController.text = extra.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _administeredAt.isAfter(now) ? now : _administeredAt,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_administeredAt),
    );
    if (time == null) return;

    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _administeredAt =
          combined.isAfter(DateTime.now()) ? DateTime.now() : combined;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(medicineControllerProvider.notifier);
    // Normalize comma decimals ("2,5" → 2.5) before parsing; the field
    // validator has already rejected non-numeric input (M11).
    final dosageText = _dosageController.text.trim().replaceAll(',', '.');
    final dosage = dosageText.isNotEmpty ? double.tryParse(dosageText) : null;

    if (_existing != null) {
      await controller.update(_existing!.copyWith(
        medicineName: _nameController.text.trim(),
        dosage: () => dosage,
        dosageUnit: () => _dosageUnit,
        administeredAt: _administeredAt,
        notes: () => _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
      return;
    }

    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return;

    await controller.add(
      babyId: baby.id,
      medicineName: _nameController.text.trim(),
      dosage: dosage,
      dosageUnit: _dosageUnit,
      administeredAt: _administeredAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (mounted) Navigator.pop(context);
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
          .read(medicineControllerProvider.notifier)
          .delete(_existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the active baby changes while the form is open
    ref.watch(activeBabyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Edit Medication' : 'Add Medication'),
        actions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed =
                          double.tryParse(value.trim().replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _dosageUnit,
                    items: _dosageUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _dosageUnit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Date & Time'),
              subtitle:
                  Text(DateFormat('MMM d, yyyy h:mm a').format(_administeredAt)),
              trailing: const Icon(Icons.access_time),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/vaccine_record.dart';
import '../../../../../features/settings/presentation/controllers/active_baby_controller.dart';
import '../controllers/vaccine_controller.dart';

const _commonVaccines = [
  'DTaP',
  'MMR',
  'Hep B',
  'Polio',
  'Hib',
  'PCV',
  'Varicella',
  'Flu',
];

class VaccineAddScreen extends ConsumerStatefulWidget {
  const VaccineAddScreen({super.key});

  @override
  ConsumerState<VaccineAddScreen> createState() => _VaccineAddScreenState();
}

class _VaccineAddScreenState extends ConsumerState<VaccineAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _providerController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;
  DateTime? _administeredDate;

  VaccineRecordEntity? _existing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (GoRouter.maybeOf(context) == null) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is VaccineRecordEntity) {
      _existing = extra;
      _nameController.text = extra.vaccineName;
      _doseController.text = extra.doseNumber?.toString() ?? '';
      _scheduledDate = extra.scheduledDate;
      _administeredDate = extra.administeredDate;
      _providerController.text = extra.provider ?? '';
      _notesController.text = extra.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickScheduled() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickAdministered() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _administeredDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _administeredDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(vaccineControllerProvider.notifier);
    final doseNumber = _doseController.text.isNotEmpty
        ? int.tryParse(_doseController.text)
        : null;

    if (_existing != null) {
      await controller.update(_existing!.copyWith(
        vaccineName: _nameController.text.trim(),
        doseNumber: () => doseNumber,
        scheduledDate: () => _scheduledDate,
        administeredDate: () => _administeredDate,
        provider: () => _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
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
      vaccineName: _nameController.text.trim(),
      doseNumber: doseNumber,
      scheduledDate: _scheduledDate,
      administeredDate: _administeredDate,
      provider: _providerController.text.trim().isEmpty
          ? null
          : _providerController.text.trim(),
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
          .read(vaccineControllerProvider.notifier)
          .delete(_existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the active baby changes while the form is open
    ref.watch(activeBabyProvider);
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Edit Vaccine' : 'Add Vaccine'),
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
            // Quick-select chips (create mode only)
            if (_existing == null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _commonVaccines.map((v) {
                  return ActionChip(
                    label: Text(v),
                    onPressed: () {
                      _nameController.text = v;
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vaccine name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose number (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Scheduled date (optional)'),
              subtitle: Text(_scheduledDate != null
                  ? fmt.format(_scheduledDate!)
                  : 'Not set'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scheduledDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _scheduledDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickScheduled,
            ),
            const SizedBox(height: 12),

            ListTile(
              title: const Text('Administered date (optional)'),
              subtitle: Text(_administeredDate != null
                  ? fmt.format(_administeredDate!)
                  : 'Not yet given'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_administeredDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _administeredDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickAdministered,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _providerController,
              decoration: const InputDecoration(
                labelText: 'Provider/clinic (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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

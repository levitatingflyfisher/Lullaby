import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/result.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../domain/entities/growth_record.dart';
import '../controllers/growth_controller.dart';

class GrowthAddScreen extends ConsumerStatefulWidget {
  const GrowthAddScreen({super.key});

  @override
  ConsumerState<GrowthAddScreen> createState() => _GrowthAddScreenState();
}

class _GrowthAddScreenState extends ConsumerState<GrowthAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _measuredAt;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headController = TextEditingController();
  final _notesController = TextEditingController();

  GrowthRecordEntity? _existing;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _measuredAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (GoRouter.maybeOf(context) == null) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is GrowthRecordEntity) {
      _existing = extra;
      _measuredAt = extra.measuredAt;
      _weightController.text = extra.weightKg?.toString() ?? '';
      _heightController.text = extra.heightCm?.toString() ?? '';
      _headController.text = extra.headCircumferenceCm?.toString() ?? '';
      _notesController.text = extra.notes ?? '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(growthControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Edit Measurement' : 'Add Measurement'),
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
            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_measuredAt)),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final val = double.tryParse(v);
                  if (val == null || val <= 0 || val > 30) {
                    return 'Enter a valid weight (0-30 kg)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Height
            TextFormField(
              controller: _heightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final val = double.tryParse(v);
                  if (val == null || val <= 0 || val > 120) {
                    return 'Enter a valid height (0-120 cm)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Head circumference
            TextFormField(
              controller: _headController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Head circumference (cm)',
                prefixIcon: Icon(Icons.circle_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final val = double.tryParse(v);
                  if (val == null || val <= 0 || val > 60) {
                    return 'Enter a valid measurement (0-60 cm)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: controllerState.isLoading ? null : _save,
              child: controllerState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _measuredAt = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final weight = _weightController.text.isNotEmpty
        ? double.tryParse(_weightController.text)
        : null;
    final height = _heightController.text.isNotEmpty
        ? double.tryParse(_heightController.text)
        : null;
    final head = _headController.text.isNotEmpty
        ? double.tryParse(_headController.text)
        : null;
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    if (weight == null && height == null && head == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement')),
      );
      return;
    }

    final controller = ref.read(growthControllerProvider.notifier);

    if (_existing != null) {
      controller
          .updateRecord(_existing!.copyWith(
            measuredAt: _measuredAt,
            weightKg: () => weight,
            heightCm: () => height,
            headCircumferenceCm: () => head,
            notes: () => notes,
          ))
          .then((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    final baby = ref.read(activeBabyProvider).valueOrNull;
    if (baby == null) return;

    controller
        .createRecord(
          babyId: baby.id,
          measuredAt: _measuredAt,
          weightKg: weight,
          heightCm: height,
          headCircumferenceCm: head,
          notes: notes,
        )
        .then((result) {
      if (result is Success && mounted) {
        context.pop();
      }
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete measurement?'),
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
          .read(growthControllerProvider.notifier)
          .deleteRecord(_existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

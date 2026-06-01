import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/baby.dart';
import '../controllers/baby_controller.dart';

const _uuid = Uuid();

class BabyEditScreen extends ConsumerStatefulWidget {
  const BabyEditScreen({super.key});

  @override
  ConsumerState<BabyEditScreen> createState() => _BabyEditScreenState();
}

class _BabyEditScreenState extends ConsumerState<BabyEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _dateOfBirth = DateTime.now();
  Gender? _gender;
  bool _isEditing = false;
  String? _photoPath;
  BabyEntity? _editingBaby;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final routeExtra = GoRouterState.of(context).extra;
    final baby = routeExtra is BabyEntity ? routeExtra : null;
    if (baby != null) {
      _editingBaby = baby;
      _nameController.text = baby.name;
      _dateOfBirth = baby.dateOfBirth;
      _gender = baby.gender;
      _isEditing = true;
      _photoPath = baby.photoPath;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // image_picker returns a path in the OS cache/temp dir, which is purged
    // under storage pressure (the avatar would silently vanish). Copy it into
    // permanent app storage and persist that path instead.
    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(docsDir.path, 'avatars'));
    await avatarsDir.create(recursive: true);
    final ext = p.extension(picked.path);
    final dest = p.join(avatarsDir.path, '${_uuid.v4()}$ext');
    await File(picked.path).copy(dest);

    if (mounted) setState(() => _photoPath = dest);
  }

  /// The avatar image, or null if no photo is set or the file is missing.
  ImageProvider? get _photoImage {
    final path = _photoPath;
    if (path != null && File(path).existsSync()) return FileImage(File(path));
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Baby' : 'Add Baby'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _photoImage,
                  child: _photoImage == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose photo'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Date of Birth'),
              subtitle: Text(DateFormat.yMMMd().format(_dateOfBirth)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dateOfBirth = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<Gender>(
              decoration: const InputDecoration(
                labelText: 'Sex (optional)',
                border: OutlineInputBorder(),
              ),
              initialValue: _gender,
              items: Gender.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                            g.name[0].toUpperCase() + g.name.substring(1)),
                      ))
                  .toList(),
              onChanged: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save' : 'Add Baby'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(babyControllerProvider.notifier);

    if (_isEditing) {
      if (_editingBaby != null) {
        final updated = _editingBaby!.copyWith(
          name: _nameController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: () => _gender,
          photoPath: () => _photoPath,
        );
        await controller.updateBaby(updated);
      }
    } else {
      final result = await controller.createBaby(
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        photoPath: _photoPath,
      );
      if (result is Success<BabyEntity>) {
        await controller.setActiveBaby(result.value.id);
      }
    }

    if (mounted) Navigator.pop(context);
  }
}

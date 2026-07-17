import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'baby_photo.dart';
import '../controllers/baby_controller.dart';
import '../../../home_widget/presentation/controllers/home_widget_controller.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';

class BabySwitcherSheet extends ConsumerWidget {
  const BabySwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babies = ref.watch(babyListProvider);
    final activeBaby = ref.watch(activeBabyProvider).valueOrNull;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Select Baby',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          babies.when(
            data: (list) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final baby = list[index];
                final isActive = activeBaby?.id == baby.id;
                // Via the baby_photo trio: null on web (no dart:io), null on
                // native when the file is gone — either way the initial shows.
                final photo = babyPhotoImage(baby.photoPath);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photo,
                    child: photo == null
                        ? Text(baby.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(baby.name),
                  subtitle: Text(baby.formatAge()),
                  trailing: isActive
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () async {
                    if (!isActive) {
                      await ref
                          .read(babyControllerProvider.notifier)
                          .setActiveBaby(baby.id);
                      unawaited(ref.read(homeWidgetControllerProvider).triggerUpdate());
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add baby'),
            onTap: () {
              Navigator.pop(context);
              context.push('/baby/edit');
            },
          ),
        ],
      ),
    );
  }
}

void showBabySwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => const BabySwitcherSheet(),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}

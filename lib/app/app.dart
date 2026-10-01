import 'dart:developer' as developer;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../core/providers/sync_providers.dart';
import '../features/home_widget/presentation/controllers/home_widget_controller.dart';
import '../features/settings/presentation/controllers/active_baby_controller.dart';
import '../features/settings/presentation/controllers/theme_controller.dart';
import '../services/home_widget_service.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'undo_host.dart';

class LullabyApp extends ConsumerStatefulWidget {
  const LullabyApp({super.key});

  @override
  ConsumerState<LullabyApp> createState() => _LullabyAppState();
}

class _LullabyAppState extends ConsumerState<LullabyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeWidgetService.init();
    // Silent freshness snapshot (BACKUP_RETENTION_SPEC §3): if the newest
    // vault snapshot is >7 days old and a key exists, take one. Post-frame
    // + fire-and-forget — never blocks boot, never surfaces errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupControllerProvider.notifier).runStartupMaintenance();
      // If sync is on, open the household's log and start pulling now, not
      // at the first write. With sync off this is one table-name lookup.
      ref.read(householdSyncProvider).boot().catchError((Object e) {
        developer.log('sync did not start', name: 'lullaby.sync', error: e);
      });
    });
    // Update the widget once the active baby has actually loaded. The previous
    // post-frame callback ran while activeBabyProvider was still loading, so it
    // blanked the widget (baby id '') on every cold start.
    ref.listenManual(
      activeBabyProvider,
      (previous, next) {
        if (next.hasValue) {
          ref.read(homeWidgetControllerProvider).triggerUpdate();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeWidgetControllerProvider).triggerUpdate();
      // Back on screen: fetch what the other phone did meanwhile.
      ref.read(householdSyncProvider).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider).themeMode;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Lullaby',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          routerConfig: router,
          // Each screen caps its own content with OhPage (640dp) inside its
          // Scaffold, so bars stay full width and only the content is boxed.
          builder: (context, child) =>
              UndoHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

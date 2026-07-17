import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../features/home_widget/presentation/controllers/home_widget_controller.dart';
import '../features/settings/presentation/controllers/active_baby_controller.dart';
import '../features/settings/presentation/controllers/theme_controller.dart';
import '../services/home_widget_service.dart';
import 'router.dart';
import 'theme/theme.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Lullaby',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          routerConfig: router,
          builder: (context, child) {
            final inner = child ?? const SizedBox.shrink();
            if (MediaQuery.of(context).size.width <= 760) return inner;
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(child: SizedBox(width: 760, child: inner)),
            );
          },
        );
      },
    );
  }
}

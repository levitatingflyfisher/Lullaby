import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../settings/presentation/controllers/active_baby_controller.dart';
import '../../../tracking/domain/entities/feeding_log.dart';
import '../../../tracking/presentation/controllers/diaper_controller.dart';
import '../../../tracking/presentation/controllers/feeding_controller.dart';
import '../../../tracking/presentation/controllers/sleep_controller.dart';
import '../../../tracking/presentation/controllers/timer_controller.dart';
import '../../../timeline/presentation/controllers/timeline_controller.dart';
import '../widgets/active_timer_card.dart';
import '../widgets/daily_summary_strip.dart';
import '../widgets/quick_log_button.dart';
import '../widgets/recent_activity_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lullaby'),
            if (baby.valueOrNull != null)
              Text(
                baby.valueOrNull!.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: baby.when(
        data: (activeBaby) {
          if (activeBaby == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Welcome to Lullaby!',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Add your baby to get started.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/baby/edit'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Baby'),
                  ),
                ],
              ),
            );
          }

          final timelineAsync =
              ref.watch(allEventsProvider(activeBaby.id));
          final lastFeedAsync =
              ref.watch(lastFeedingProvider(activeBaby.id));

          return ListView(
            children: [
              // Active timers — isolated in their own subtree so the
              // per-second tick rebuilds only the cards, not the daily summary
              // or recent-activity list (H10).
              const _ActiveTimersSection(),

              // Quick log buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    QuickLogButton(
                      icon: Icons.restaurant,
                      label: 'Feed',
                      color: AppColorSchemes.feedColor,
                      onTap: () => _showFeedingSheet(context),
                    ),
                    QuickLogButton(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      color: AppColorSchemes.sleepColor,
                      onTap: () => _toggleSleep(context, ref, activeBaby.id),
                    ),
                    QuickLogButton(
                      icon: Icons.baby_changing_station,
                      label: 'Diaper',
                      color: AppColorSchemes.diaperColor,
                      onTap: () => _quickLogDiaper(context, ref),
                      onLongPress: () => context.push('/diaper'),
                    ),
                  ],
                ),
              ),

              // Daily summary
              _DailySummary(
                babyId: activeBaby.id,
                lastFeedAsync: lastFeedAsync,
              ),
              const SizedBox(height: 16),

              // Recent activity
              timelineAsync.when(
                data: (events) => RecentActivityList(
                  events:
                      events.take(AppConstants.recentActivityCount).toList(),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showFeedingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.woman),
              title: const Text('Breast'),
              onTap: () {
                Navigator.pop(context);
                context.push('/feeding');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_drink),
              title: const Text('Bottle'),
              onTap: () {
                Navigator.pop(context);
                context.push('/feeding');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Solid'),
              onTap: () {
                Navigator.pop(context);
                context.push('/feeding');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSleep(
      BuildContext context, WidgetRef ref, String babyId) {
    final timers = ref.read(activeTimersProvider);
    final sleepTimer =
        timers.where((t) => t.type == TimerType.sleep).firstOrNull;

    if (sleepTimer != null) {
      final sleepCtrl = ref.read(sleepControllerProvider.notifier);
      if (sleepTimer.logId != null) {
        sleepCtrl.stopSleep(sleepTimer.logId!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep logged')),
      );
    } else {
      ref.read(sleepControllerProvider.notifier).startSleep();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep timer started')),
      );
    }
  }

  void _quickLogDiaper(BuildContext context, WidgetRef ref) {
    ref.read(diaperControllerProvider.notifier).quickLogWet().then((log) {
      if (log != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wet diaper logged'),
            action: SnackBarAction(
              label: 'EDIT',
              onPressed: () => context.push('/diaper'),
            ),
          ),
        );
      }
    });
  }

}

/// Renders the active-timer cards and watches [activeTimersProvider] in
/// isolation, so the once-a-second tick only rebuilds this subtree (H10).
class _ActiveTimersSection extends ConsumerWidget {
  const _ActiveTimersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timers = ref.watch(activeTimersProvider);
    if (timers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 8),
        ...timers.map((timer) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ActiveTimerCard(
                timer: timer,
                onStop: () => _stopTimer(ref, timer),
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  void _stopTimer(WidgetRef ref, ActiveTimer timer) {
    if (timer.type == TimerType.feeding && timer.logId != null) {
      ref
          .read(feedingControllerProvider.notifier)
          .stopBreastFeeding(timer.logId!);
    } else if (timer.type == TimerType.sleep && timer.logId != null) {
      ref.read(sleepControllerProvider.notifier).stopSleep(timer.logId!);
    }
  }
}

class _DailySummary extends ConsumerWidget {
  const _DailySummary({
    required this.babyId,
    required this.lastFeedAsync,
  });

  final String babyId;
  final AsyncValue<FeedingLogEntity?> lastFeedAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastFeedTime = lastFeedAsync.when(
      data: (feed) =>
          feed != null ? feed.startTime.toRelativeTime() : 'No feeds',
      loading: () => '...',
      error: (_, _) => '?',
    );

    return FutureBuilder(
      future: Future.wait([
        ref.read(sleepControllerProvider.notifier).getTodaySleepDuration(babyId),
        ref
            .read(diaperControllerProvider.notifier)
            .getTodayDiaperCount(babyId)
            .then((c) => c),
      ]),
      builder: (context, snapshot) {
        final sleepDuration =
            snapshot.data != null ? (snapshot.data![0] as Duration).toHoursMinutes() : '...';
        final diaperCount =
            snapshot.data != null ? snapshot.data![1] as int : 0;

        return DailySummaryStrip(
          lastFeedTime: lastFeedTime,
          sleepDuration: sleepDuration,
          diaperCount: diaperCount,
        );
      },
    );
  }
}

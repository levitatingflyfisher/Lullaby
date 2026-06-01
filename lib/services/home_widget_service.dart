import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:home_widget/home_widget.dart';

import '../features/babies/domain/entities/baby.dart';
import '../features/tracking/domain/entities/diaper_log.dart';
import '../features/tracking/domain/entities/feeding_log.dart';
import '../features/tracking/domain/entities/sleep_log.dart';
import '../features/tracking/presentation/controllers/timer_controller.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const _appGroupId = 'group.com.example.lullaby';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> update({
    required BabyEntity? baby,
    required FeedingLogEntity? lastFeeding,
    required SleepLogEntity? lastSleep,
    required DiaperLogEntity? lastDiaper,
    required ActiveTimer? activeTimer,
  }) async {
    // Timestamps are written in UTC (with a trailing 'Z') because the native
    // widget parses them with java.time.Instant.parse, which rejects
    // offset-less local-time strings and otherwise hides the timer row.
    await HomeWidget.saveWidgetData<String>(
        'lullaby.baby_name', baby?.name ?? '–');
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_feed_time', lastFeeding?.startTime.toUtc().toIso8601String());
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_sleep_time', lastSleep?.startTime.toUtc().toIso8601String());
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_diaper_time', lastDiaper?.time.toUtc().toIso8601String());
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_feed_ago', agoForTesting(lastFeeding?.startTime));
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_sleep_ago', agoForTesting(lastSleep?.startTime));
    await HomeWidget.saveWidgetData<String>(
        'lullaby.last_diaper_ago', agoForTesting(lastDiaper?.time));
    await HomeWidget.saveWidgetData<String>(
        'lullaby.active_timer_type', activeTimer?.type.name);
    await HomeWidget.saveWidgetData<String>(
        'lullaby.active_timer_start',
        activeTimer?.startTime.toUtc().toIso8601String());
    await HomeWidget.updateWidget(
        name: 'LullabyWidget', iOSName: 'LullabyWidget');
  }

  /// Exposed for testing. Production callers use [update].
  @visibleForTesting
  static String agoForTesting(DateTime? dt) => _ago(dt);

  static String _ago(DateTime? dt) {
    if (dt == null) return '–';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final h = diff.inHours;
    if (diff.inDays < 1) {
      final m = diff.inMinutes % 60;
      return m > 0 ? '${h}h ${m}m ago' : '${h}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

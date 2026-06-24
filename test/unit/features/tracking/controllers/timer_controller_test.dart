import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/core/providers/repository_providers.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/home_widget/presentation/controllers/home_widget_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/domain/entities/sleep_log.dart';
import 'package:lullaby/features/tracking/domain/repositories/feeding_repository.dart';
import 'package:lullaby/features/tracking/domain/repositories/sleep_repository.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

class _NoOpHomeWidgetController extends HomeWidgetController {
  _NoOpHomeWidgetController(super.ref);
  @override
  Future<void> triggerUpdate() async {}
}

class _StubSleepRepo implements SleepRepository {
  _StubSleepRepo({this.active});
  final SleepLogEntity? active;

  @override
  Future<Result<SleepLogEntity?>> getActiveSleep(String babyId) async =>
      Success(active);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFeedingRepo implements FeedingRepository {
  _StubFeedingRepo({this.active});
  final FeedingLogEntity? active;

  @override
  Future<Result<FeedingLogEntity?>> getActiveBreastFeeding(String babyId) async =>
      Success(active);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ActiveTimersNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        homeWidgetControllerProvider.overrideWith(
          (ref) => _NoOpHomeWidgetController(ref),
        ),
        activeBabyProvider.overrideWith((ref) => Stream.value(null)),
        sleepRepositoryProvider.overrideWithValue(_StubSleepRepo()),
        feedingRepositoryProvider.overrideWithValue(_StubFeedingRepo()),
      ]);
    });

    tearDown(() => container.dispose());

    ActiveTimer makeTimer({
      String id = 't1',
      TimerType type = TimerType.feeding,
      String? logId,
    }) =>
        ActiveTimer(
          id: id,
          type: type,
          startTime: DateTime.now(),
          label: 'Test Timer',
          elapsed: Duration.zero,
          logId: logId,
        );

    test('initial state is empty', () {
      final timers = container.read(activeTimersProvider);
      expect(timers, isEmpty);
    });

    test('startTimer adds a timer', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer());
      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(1));
    });

    test('startTimer supports multiple timers', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer(id: 't1', type: TimerType.feeding));
      notifier.startTimer(makeTimer(id: 't2', type: TimerType.sleep));
      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(2));
    });

    test('stopTimer removes the timer', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer());
      final stopped = notifier.stopTimer('t1');
      expect(stopped, isNotNull);
      expect(stopped!.id, 't1');
      expect(container.read(activeTimersProvider), isEmpty);
    });

    test('stopTimer returns null for non-existent', () {
      final notifier = container.read(activeTimersProvider.notifier);
      final stopped = notifier.stopTimer('nonexistent');
      expect(stopped, isNull);
    });

    test('getTimerByLogId returns correct timer', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer(id: 't1', logId: 'log1'));
      notifier.startTimer(makeTimer(id: 't2', logId: 'log2'));

      final found = notifier.getTimerByLogId('log2');
      expect(found, isNotNull);
      expect(found!.id, 't2');
    });

    test('getTimerByLogId returns null when not found', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer(id: 't1', logId: 'log1'));

      final found = notifier.getTimerByLogId('nonexistent');
      expect(found, isNull);
    });

    test('getTimerByType returns correct timer', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer(id: 't1', type: TimerType.feeding));
      notifier.startTimer(makeTimer(id: 't2', type: TimerType.sleep));

      final feeding = notifier.getTimerByType(TimerType.feeding);
      expect(feeding, isNotNull);
      expect(feeding!.id, 't1');
    });

    test('stopTimer only removes targeted timer', () {
      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(makeTimer(id: 't1', type: TimerType.feeding));
      notifier.startTimer(makeTimer(id: 't2', type: TimerType.sleep));

      notifier.stopTimer('t1');
      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(1));
      expect(timers.first.id, 't2');
    });
  });

  group('ActiveTimersNotifier rehydration', () {
    final now = DateTime.now();
    final baby = BabyEntity(
      id: 'b1',
      name: 'Test',
      dateOfBirth: DateTime(2024, 1, 1),
      isActive: true,
      createdAt: now,
      modifiedAt: now,
    );

    ProviderContainer makeContainer({
      SleepLogEntity? activeSleep,
      FeedingLogEntity? activeFeed,
    }) =>
        ProviderContainer(overrides: [
          homeWidgetControllerProvider
              .overrideWith((ref) => _NoOpHomeWidgetController(ref)),
          activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
          sleepRepositoryProvider
              .overrideWithValue(_StubSleepRepo(active: activeSleep)),
          feedingRepositoryProvider
              .overrideWithValue(_StubFeedingRepo(active: activeFeed)),
        ]);

    test('rehydrates active sleep log as timer', () async {
      final container = makeContainer(
        activeSleep: SleepLogEntity(
          id: 'sleep1',
          babyId: baby.id,
          startTime: now.subtract(const Duration(minutes: 10)),
          type: SleepType.nap,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      addTearDown(container.dispose);

      container.read(activeTimersProvider);
      await pumpEventQueue();

      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(1));
      expect(timers.first.type, TimerType.sleep);
      expect(timers.first.logId, 'sleep1');
    });

    test('rehydrates active breast feed as timer', () async {
      final container = makeContainer(
        activeFeed: FeedingLogEntity(
          id: 'feed1',
          babyId: baby.id,
          type: FeedingType.breast,
          startTime: now.subtract(const Duration(minutes: 5)),
          side: BreastSide.left,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      addTearDown(container.dispose);

      container.read(activeTimersProvider);
      await pumpEventQueue();

      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(1));
      expect(timers.first.type, TimerType.feeding);
      expect(timers.first.logId, 'feed1');
      expect(timers.first.label, contains('left'));
    });

    test('rehydrates both when present', () async {
      final container = makeContainer(
        activeSleep: SleepLogEntity(
          id: 'sleep1',
          babyId: baby.id,
          startTime: now,
          type: SleepType.night,
          createdAt: now,
          modifiedAt: now,
        ),
        activeFeed: FeedingLogEntity(
          id: 'feed1',
          babyId: baby.id,
          type: FeedingType.breast,
          startTime: now,
          side: BreastSide.right,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      addTearDown(container.dispose);

      container.read(activeTimersProvider);
      await pumpEventQueue();

      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(2));
    });

    test('rehydration yields empty state when nothing active', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(activeTimersProvider);
      await pumpEventQueue();

      expect(container.read(activeTimersProvider), isEmpty);
    });

    test('rehydration does not duplicate a timer already started manually',
        () async {
      final container = makeContainer(
        activeFeed: FeedingLogEntity(
          id: 'feed1',
          babyId: baby.id,
          type: FeedingType.breast,
          startTime: now,
          side: BreastSide.left,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeTimersProvider.notifier);
      notifier.startTimer(ActiveTimer(
        id: 'manual',
        type: TimerType.feeding,
        startTime: now,
        label: 'Breast (left)',
        elapsed: Duration.zero,
        logId: 'feed1',
      ));

      await pumpEventQueue();

      final timers = container.read(activeTimersProvider);
      expect(timers, hasLength(1));
      expect(timers.first.id, 'manual');
    });
  });

  group('ActiveTimer', () {
    test('tick updates elapsed duration', () {
      final timer = ActiveTimer(
        id: 't1',
        type: TimerType.feeding,
        startTime: DateTime.now().subtract(const Duration(seconds: 5)),
        label: 'Test',
        elapsed: Duration.zero,
      );

      final ticked = timer.tick();
      expect(ticked.elapsed.inSeconds, greaterThanOrEqualTo(4));
    });

    test('equality works', () {
      final now = DateTime(2025, 6, 15, 10, 0);
      final a = ActiveTimer(
        id: 't1',
        type: TimerType.feeding,
        startTime: now,
        label: 'Test',
        elapsed: const Duration(seconds: 5),
      );
      final b = ActiveTimer(
        id: 't1',
        type: TimerType.feeding,
        startTime: now,
        label: 'Test',
        elapsed: const Duration(seconds: 5),
      );
      expect(a, equals(b));
    });
  });
}

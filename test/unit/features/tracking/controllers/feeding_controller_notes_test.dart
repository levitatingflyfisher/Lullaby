import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/core/providers/repository_providers.dart';
import 'package:lullaby/features/babies/domain/entities/baby.dart';
import 'package:lullaby/features/home_widget/presentation/controllers/home_widget_controller.dart';
import 'package:lullaby/features/settings/presentation/controllers/active_baby_controller.dart';
import 'package:lullaby/features/tracking/domain/entities/feeding_log.dart';
import 'package:lullaby/features/tracking/domain/repositories/feeding_repository.dart';
import 'package:lullaby/features/tracking/presentation/controllers/feeding_controller.dart';
import 'package:lullaby/features/tracking/presentation/controllers/timer_controller.dart';

class _NoOpHomeWidgetController extends HomeWidgetController {
  _NoOpHomeWidgetController(super.ref);
  @override
  Future<void> triggerUpdate() async {}
}

// Keeps the timers notifier from rehydrating against the real database
// (it would otherwise query sleep logs after the test has finished).
class _NoRehydrateTimers extends ActiveTimersNotifier {
  @override
  List<ActiveTimer> build() => const [];
}

class _RecordingFeedingRepo implements FeedingRepository {
  _RecordingFeedingRepo(this.active);
  final FeedingLogEntity? active;
  FeedingLogEntity? updated;
  FeedingLogEntity? created;

  @override
  Future<Result<FeedingLogEntity?>> getActiveBreastFeeding(
          String babyId) async =>
      Success(active);

  final notesWrites = <(String, String?)>[];

  @override
  Future<Result<void>> updateNotes(String id, String? notes) async {
    notesWrites.add((id, notes));
    return const Success(null);
  }

  @override
  Future<Result<void>> createFeeding(FeedingLogEntity log) async {
    created = log;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateFeeding(FeedingLogEntity log) async {
    updated = log;
    return const Success(null);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// lullaby:doet-02 — notes typed during a breast feed were discarded because
/// stopBreastFeeding took none.
void main() {
  final start = DateTime.now().subtract(const Duration(minutes: 12));
  FeedingLogEntity openFeed({String? notes}) => FeedingLogEntity(
        id: 'f1',
        babyId: 'b1',
        type: FeedingType.breast,
        startTime: start,
        side: BreastSide.left,
        notes: notes,
        createdAt: start,
        modifiedAt: start,
      );

  Future<FeedingLogEntity?> stop(FeedingLogEntity active,
      {String? notes}) async {
    final repo = _RecordingFeedingRepo(active);
    final container = ProviderContainer(overrides: [
      homeWidgetControllerProvider
          .overrideWith((ref) => _NoOpHomeWidgetController(ref)),
      activeBabyProvider.overrideWith((ref) => Stream.value(null)),
      feedingRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container
        .read(feedingControllerProvider.notifier)
        .stopBreastFeeding('f1', notes: notes);
    return repo.updated;
  }

  test('stopping with notes saves them on the feed', () async {
    final saved = await stop(openFeed(), notes: 'fussy on the left');
    expect(saved, isNotNull);
    expect(saved!.notes, 'fussy on the left');
    expect(saved.endTime, isNotNull);
  });

  test('stopping without notes (timer card) keeps existing notes', () async {
    final saved = await stop(openFeed(notes: 'earlier note'));
    expect(saved!.notes, 'earlier note');
  });

  test('starting with notes already typed puts them on the new feed',
      () async {
    final repo = _RecordingFeedingRepo(null);
    final baby = BabyEntity(
      id: 'b1',
      name: 'Nora',
      dateOfBirth: start,
      createdAt: start,
      modifiedAt: start,
    );
    final container = ProviderContainer(overrides: [
      homeWidgetControllerProvider
          .overrideWith((ref) => _NoOpHomeWidgetController(ref)),
      activeBabyProvider.overrideWith((ref) => Stream.value(baby)),
      feedingRepositoryProvider.overrideWithValue(repo),
      activeTimersProvider.overrideWith(() => _NoRehydrateTimers()),
    ]);
    addTearDown(container.dispose);
    await container.read(activeBabyProvider.future);
    await container
        .read(feedingControllerProvider.notifier)
        .startBreastFeeding(BreastSide.right, notes: 'latched well');
    expect(repo.created?.notes, 'latched well');
  });

  test('saveFeedNotes writes only the notes of that feed', () async {
    final repo = _RecordingFeedingRepo(openFeed());
    final container = ProviderContainer(overrides: [
      homeWidgetControllerProvider
          .overrideWith((ref) => _NoOpHomeWidgetController(ref)),
      activeBabyProvider.overrideWith((ref) => Stream.value(null)),
      feedingRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(feedingControllerProvider.notifier);
    await notifier.saveFeedNotes('f1', 'typed after start');
    await notifier.saveFeedNotes('f1', '');
    expect(repo.notesWrites, [('f1', 'typed after start'), ('f1', null)]);
    expect(repo.updated, isNull, reason: 'must not rewrite the whole row');
  });
}

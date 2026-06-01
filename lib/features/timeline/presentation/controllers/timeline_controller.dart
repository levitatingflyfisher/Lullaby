import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../growth/domain/entities/growth_record.dart';
import '../../../health/medicine/domain/entities/medicine_log.dart';
import '../../../health/vaccine/domain/entities/vaccine_record.dart';
import '../../../tracking/domain/entities/diaper_log.dart';
import '../../../tracking/domain/entities/feeding_log.dart';
import '../../../tracking/domain/entities/sleep_log.dart';

enum TimelineEventType { feeding, sleep, diaper, growth, medicine, vaccine }

enum TimelineFilter { all, feeding, sleep, diaper, growth, medicine, vaccine }

class TimelineEvent extends Equatable {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.time,
    required this.title,
    required this.subtitle,
    this.feedingLog,
    this.sleepLog,
    this.diaperLog,
    this.growthRecord,
    this.medicineLog,
    this.vaccineLog,
  });

  final String id;
  final TimelineEventType type;
  final DateTime time;
  final String title;
  final String subtitle;
  final FeedingLogEntity? feedingLog;
  final SleepLogEntity? sleepLog;
  final DiaperLogEntity? diaperLog;
  final GrowthRecordEntity? growthRecord;
  final MedicineLogEntity? medicineLog;
  final VaccineRecordEntity? vaccineLog;

  @override
  List<Object?> get props => [id, type, time];
}

final timelineFilterProvider = StateProvider<TimelineFilter>(
    (ref) => TimelineFilter.all);

final timelineProvider =
    StreamProvider.family<List<TimelineEvent>, String>((ref, babyId) {
  final filter = ref.watch(timelineFilterProvider);
  final feedingRepo = ref.watch(feedingRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  final diaperRepo = ref.watch(diaperRepositoryProvider);
  final growthRepo = ref.watch(growthRepositoryProvider);
  final medicineRepo = ref.watch(medicineRepositoryProvider);
  final vaccineRepo = ref.watch(vaccineRepositoryProvider);

  bool show(TimelineFilter type) =>
      filter == TimelineFilter.all || filter == type;

  return _buildEventStream(
    feedingStream: show(TimelineFilter.feeding)
        ? feedingRepo.watchAllForBaby(babyId)
        : Stream.value(<FeedingLogEntity>[]),
    sleepStream: show(TimelineFilter.sleep)
        ? sleepRepo.watchAllForBaby(babyId)
        : Stream.value(<SleepLogEntity>[]),
    diaperStream: show(TimelineFilter.diaper)
        ? diaperRepo.watchAllForBaby(babyId)
        : Stream.value(<DiaperLogEntity>[]),
    growthStream: show(TimelineFilter.growth)
        ? growthRepo.watchAllForBaby(babyId)
        : Stream.value(<GrowthRecordEntity>[]),
    medicineStream: show(TimelineFilter.medicine)
        ? medicineRepo.watchAllForBaby(babyId)
        : Stream.value(<MedicineLogEntity>[]),
    vaccineStream: show(TimelineFilter.vaccine)
        ? vaccineRepo.watchAllForBaby(babyId)
        : Stream.value(<VaccineRecordEntity>[]),
  );
});

/// Like [timelineProvider] but always returns all event types.
/// Used by the dashboard so Timeline filter chips don't affect it.
final allEventsProvider =
    StreamProvider.family<List<TimelineEvent>, String>((ref, babyId) {
  final feedingRepo = ref.watch(feedingRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  final diaperRepo = ref.watch(diaperRepositoryProvider);
  final growthRepo = ref.watch(growthRepositoryProvider);
  final medicineRepo = ref.watch(medicineRepositoryProvider);
  final vaccineRepo = ref.watch(vaccineRepositoryProvider);

  return _buildEventStream(
    feedingStream: feedingRepo.watchAllForBaby(babyId),
    sleepStream: sleepRepo.watchAllForBaby(babyId),
    diaperStream: diaperRepo.watchAllForBaby(babyId),
    growthStream: growthRepo.watchAllForBaby(babyId),
    medicineStream: medicineRepo.watchAllForBaby(babyId),
    vaccineStream: vaccineRepo.watchAllForBaby(babyId),
  );
});

Stream<List<TimelineEvent>> _buildEventStream({
  required Stream<List<FeedingLogEntity>> feedingStream,
  required Stream<List<SleepLogEntity>> sleepStream,
  required Stream<List<DiaperLogEntity>> diaperStream,
  required Stream<List<GrowthRecordEntity>> growthStream,
  required Stream<List<MedicineLogEntity>> medicineStream,
  required Stream<List<VaccineRecordEntity>> vaccineStream,
}) {
  // combineLatest over six never-completing Drift watch streams: re-emit
  // whenever ANY source changes, using the latest value of each. The previous
  // nested asyncExpand paused each outer stream until its inner stream
  // completed — which watch streams never do — so after the first cascade only
  // vaccine changes propagated and the feed froze (C1).
  List<FeedingLogEntity>? feedings;
  List<SleepLogEntity>? sleeps;
  List<DiaperLogEntity>? diapers;
  List<GrowthRecordEntity>? growth;
  List<MedicineLogEntity>? medicines;
  List<VaccineRecordEntity>? vaccines;

  late final StreamController<List<TimelineEvent>> controller;
  final subscriptions = <StreamSubscription<dynamic>>[];

  void emit() {
    // Wait until every source has produced its first value (matches the old
    // behaviour: all six streams emit once on subscription).
    if (feedings == null ||
        sleeps == null ||
        diapers == null ||
        growth == null ||
        medicines == null ||
        vaccines == null) {
      return;
    }
    final events = <TimelineEvent>[
      ...feedings!.map(_feedingToEvent),
      ...sleeps!.map(_sleepToEvent),
      ...diapers!.map(_diaperToEvent),
      ...growth!.map(_growthToEvent),
      ...medicines!.map(_medicineToEvent),
      ...vaccines!.map(_vaccineToEvent),
    ];
    events.sort((a, b) {
      final byTime = b.time.compareTo(a.time); // most recent first
      if (byTime != 0) return byTime;
      final byType = a.type.index.compareTo(b.type.index);
      if (byType != 0) return byType;
      return a.id.compareTo(b.id); // stable tie-break for same-instant events
    });
    controller.add(events);
  }

  controller = StreamController<List<TimelineEvent>>(
    onListen: () {
      void onError(Object e, StackTrace st) => controller.addError(e, st);
      subscriptions.addAll([
        feedingStream.listen((v) {
          feedings = v;
          emit();
        }, onError: onError),
        sleepStream.listen((v) {
          sleeps = v;
          emit();
        }, onError: onError),
        diaperStream.listen((v) {
          diapers = v;
          emit();
        }, onError: onError),
        growthStream.listen((v) {
          growth = v;
          emit();
        }, onError: onError),
        medicineStream.listen((v) {
          medicines = v;
          emit();
        }, onError: onError),
        vaccineStream.listen((v) {
          vaccines = v;
          emit();
        }, onError: onError),
      ]);
    },
    onCancel: () async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    },
  );

  return controller.stream;
}

TimelineEvent _feedingToEvent(FeedingLogEntity log) {
  final subtitle = switch (log.type) {
    FeedingType.breast =>
        'Breast${log.side != null ? ' (${log.side!.name})' : ''}${log.computedDuration != null ? ' - ${log.computedDuration!.inMinutes}min' : ''}',
    FeedingType.bottle =>
        'Bottle${log.amountMl != null ? ' - ${log.amountMl!.round()}ml' : ''}',
    FeedingType.solid => 'Solid food${log.notes != null ? ' - ${log.notes}' : ''}',
  };
  return TimelineEvent(
    id: log.id,
    type: TimelineEventType.feeding,
    time: log.startTime,
    title: 'Feeding',
    subtitle: subtitle,
    feedingLog: log,
  );
}

TimelineEvent _sleepToEvent(SleepLogEntity log) {
  final duration = log.computedDuration;
  final subtitle =
      '${log.type == SleepType.nap ? 'Nap' : 'Night'}${duration != null ? ' - ${duration.inHours}h ${duration.inMinutes.remainder(60)}m' : ' (ongoing)'}';
  return TimelineEvent(
    id: log.id,
    type: TimelineEventType.sleep,
    time: log.startTime,
    title: 'Sleep',
    subtitle: subtitle,
    sleepLog: log,
  );
}

TimelineEvent _diaperToEvent(DiaperLogEntity log) {
  return TimelineEvent(
    id: log.id,
    type: TimelineEventType.diaper,
    time: log.time,
    title: 'Diaper',
    subtitle: log.type.displayName,
    diaperLog: log,
  );
}

TimelineEvent _growthToEvent(GrowthRecordEntity r) {
  final parts = <String>[
    if (r.weightKg != null) '${r.weightKg!.toStringAsFixed(1)} kg',
    if (r.heightCm != null) '${r.heightCm!.toStringAsFixed(1)} cm',
    if (r.headCircumferenceCm != null)
      '${r.headCircumferenceCm!.toStringAsFixed(1)} cm HC',
  ];
  return TimelineEvent(
    id: r.id,
    type: TimelineEventType.growth,
    time: r.measuredAt,
    title: 'Measurements',
    subtitle: parts.isNotEmpty ? parts.join(' · ') : 'Recorded',
    growthRecord: r,
  );
}

TimelineEvent _medicineToEvent(MedicineLogEntity m) {
  final subtitle = m.dosage != null
      ? '${m.dosage!.toStringAsFixed(m.dosage! % 1 == 0 ? 0 : 1)}${m.dosageUnit != null ? ' ${m.dosageUnit}' : ''}'
      : 'Administered';
  return TimelineEvent(
    id: m.id,
    type: TimelineEventType.medicine,
    time: m.administeredAt,
    title: m.medicineName,
    subtitle: subtitle,
    medicineLog: m,
  );
}

TimelineEvent _vaccineToEvent(VaccineRecordEntity v) {
  final title = v.doseNumber != null
      ? '${v.vaccineName} (dose ${v.doseNumber})'
      : v.vaccineName;
  return TimelineEvent(
    id: v.id,
    type: TimelineEventType.vaccine,
    time: v.administeredDate ?? v.scheduledDate ?? v.modifiedAt,
    title: title,
    subtitle: v.isAdministered ? 'Given' : 'Scheduled',
    vaccineLog: v,
  );
}

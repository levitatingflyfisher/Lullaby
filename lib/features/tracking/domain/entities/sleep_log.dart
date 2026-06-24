import 'package:equatable/equatable.dart';

enum SleepType {
  nap,
  night;

  static SleepType fromString(String value) =>
      SleepType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => throw FormatException('Unknown SleepType: $value'),
      );
}

enum SleepLocation {
  crib,
  bassinet,
  bed,
  stroller,
  carSeat,
  arms,
  other;

  static SleepLocation? fromString(String? value) {
    if (value == null) return null;
    return SleepLocation.values.where((l) => l.name == value).firstOrNull;
  }

  String get displayName {
    return switch (this) {
      SleepLocation.crib => 'Crib',
      SleepLocation.bassinet => 'Bassinet',
      SleepLocation.bed => 'Bed',
      SleepLocation.stroller => 'Stroller',
      SleepLocation.carSeat => 'Car seat',
      SleepLocation.arms => 'Arms',
      SleepLocation.other => 'Other',
    };
  }
}

class SleepLogEntity extends Equatable {
  const SleepLogEntity({
    required this.id,
    required this.babyId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.type,
    this.location,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final SleepType type;
  final SleepLocation? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  bool get isActive => endTime == null;

  Duration? get computedDuration {
    if (durationMinutes != null) return Duration(minutes: durationMinutes!);
    if (endTime != null) return endTime!.difference(startTime);
    return null;
  }

  SleepLogEntity copyWith({
    String? id,
    String? babyId,
    DateTime? startTime,
    DateTime? Function()? endTime,
    int? Function()? durationMinutes,
    SleepType? type,
    SleepLocation? Function()? location,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return SleepLogEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
      durationMinutes:
          durationMinutes != null ? durationMinutes() : this.durationMinutes,
      type: type ?? this.type,
      location: location != null ? location() : this.location,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, babyId, startTime, endTime, durationMinutes, type, location, notes,
        createdAt, modifiedAt,
      ];
}

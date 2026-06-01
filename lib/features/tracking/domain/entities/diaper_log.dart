import 'package:equatable/equatable.dart';

enum DiaperType {
  wet,
  dirty,
  both,
  dry;

  static DiaperType fromString(String value) =>
      DiaperType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => throw FormatException('Unknown DiaperType: $value'),
      );

  String get displayName {
    return switch (this) {
      DiaperType.wet => 'Wet',
      DiaperType.dirty => 'Dirty',
      DiaperType.both => 'Both',
      DiaperType.dry => 'Dry',
    };
  }
}

enum StoolColor {
  yellow,
  green,
  brown,
  black,
  red,
  white;

  static StoolColor? fromString(String? value) {
    if (value == null) return null;
    return StoolColor.values.where((c) => c.name == value).firstOrNull;
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class DiaperLogEntity extends Equatable {
  const DiaperLogEntity({
    required this.id,
    required this.babyId,
    required this.time,
    required this.type,
    this.color,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final DateTime time;
  final DiaperType type;
  final StoolColor? color;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  DiaperLogEntity copyWith({
    String? id,
    String? babyId,
    DateTime? time,
    DiaperType? type,
    StoolColor? Function()? color,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DiaperLogEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      time: time ?? this.time,
      type: type ?? this.type,
      color: color != null ? color() : this.color,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [id, babyId, time, type, color, notes, createdAt, modifiedAt];
}

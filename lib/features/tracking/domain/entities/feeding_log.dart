import 'package:equatable/equatable.dart';

enum FeedingType {
  breast,
  bottle,
  solid;

  static FeedingType fromString(String value) =>
      FeedingType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => throw FormatException('Unknown FeedingType: $value'),
      );
}

enum BreastSide {
  left,
  right,
  both;

  static BreastSide? fromString(String? value) {
    if (value == null) return null;
    return BreastSide.values.where((s) => s.name == value).firstOrNull;
  }
}

class FeedingLogEntity extends Equatable {
  const FeedingLogEntity({
    required this.id,
    required this.babyId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.side,
    this.amountMl,
    this.amountOz,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final FeedingType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final BreastSide? side;
  final double? amountMl;
  final double? amountOz;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  bool get isActive => endTime == null && type == FeedingType.breast;

  Duration? get computedDuration {
    if (durationMinutes != null) return Duration(minutes: durationMinutes!);
    if (endTime != null) return endTime!.difference(startTime);
    return null;
  }

  FeedingLogEntity copyWith({
    String? id,
    String? babyId,
    FeedingType? type,
    DateTime? startTime,
    DateTime? Function()? endTime,
    int? Function()? durationMinutes,
    BreastSide? Function()? side,
    double? Function()? amountMl,
    double? Function()? amountOz,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return FeedingLogEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
      durationMinutes:
          durationMinutes != null ? durationMinutes() : this.durationMinutes,
      side: side != null ? side() : this.side,
      amountMl: amountMl != null ? amountMl() : this.amountMl,
      amountOz: amountOz != null ? amountOz() : this.amountOz,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, babyId, type, startTime, endTime, durationMinutes, side, amountMl,
        amountOz, notes, createdAt, modifiedAt,
      ];
}

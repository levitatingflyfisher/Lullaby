import 'package:equatable/equatable.dart';

class GrowthRecordEntity extends Equatable {
  const GrowthRecordEntity({
    required this.id,
    required this.babyId,
    required this.measuredAt,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final DateTime measuredAt;
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  bool get hasAnyMeasurement =>
      weightKg != null || heightCm != null || headCircumferenceCm != null;

  GrowthRecordEntity copyWith({
    String? id,
    String? babyId,
    DateTime? measuredAt,
    double? Function()? weightKg,
    double? Function()? heightCm,
    double? Function()? headCircumferenceCm,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return GrowthRecordEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg != null ? weightKg() : this.weightKg,
      heightCm: heightCm != null ? heightCm() : this.heightCm,
      headCircumferenceCm: headCircumferenceCm != null
          ? headCircumferenceCm()
          : this.headCircumferenceCm,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        babyId,
        measuredAt,
        weightKg,
        heightCm,
        headCircumferenceCm,
        notes,
        createdAt,
        modifiedAt,
      ];
}

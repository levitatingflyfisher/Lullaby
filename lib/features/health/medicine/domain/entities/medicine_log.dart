import 'package:equatable/equatable.dart';

class MedicineLogEntity extends Equatable {
  const MedicineLogEntity({
    required this.id,
    required this.babyId,
    required this.medicineName,
    this.dosage,
    this.dosageUnit,
    required this.administeredAt,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final String medicineName;
  final double? dosage;
  final String? dosageUnit;
  final DateTime administeredAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  MedicineLogEntity copyWith({
    String? id,
    String? babyId,
    String? medicineName,
    double? Function()? dosage,
    String? Function()? dosageUnit,
    DateTime? administeredAt,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return MedicineLogEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage != null ? dosage() : this.dosage,
      dosageUnit: dosageUnit != null ? dosageUnit() : this.dosageUnit,
      administeredAt: administeredAt ?? this.administeredAt,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        babyId,
        medicineName,
        dosage,
        dosageUnit,
        administeredAt,
        notes,
        createdAt,
        modifiedAt,
      ];
}

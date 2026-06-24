import 'package:equatable/equatable.dart';

class VaccineRecordEntity extends Equatable {
  const VaccineRecordEntity({
    required this.id,
    required this.babyId,
    required this.vaccineName,
    this.doseNumber,
    this.scheduledDate,
    this.administeredDate,
    this.provider,
    this.notes,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String babyId;
  final String vaccineName;
  final int? doseNumber;
  final DateTime? scheduledDate;
  final DateTime? administeredDate;
  final String? provider;
  final String? notes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  bool get isAdministered => administeredDate != null;

  VaccineRecordEntity copyWith({
    String? id,
    String? babyId,
    String? vaccineName,
    int? Function()? doseNumber,
    DateTime? Function()? scheduledDate,
    DateTime? Function()? administeredDate,
    String? Function()? provider,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return VaccineRecordEntity(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      vaccineName: vaccineName ?? this.vaccineName,
      doseNumber: doseNumber != null ? doseNumber() : this.doseNumber,
      scheduledDate: scheduledDate != null ? scheduledDate() : this.scheduledDate,
      administeredDate:
          administeredDate != null ? administeredDate() : this.administeredDate,
      provider: provider != null ? provider() : this.provider,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        babyId,
        vaccineName,
        doseNumber,
        scheduledDate,
        administeredDate,
        provider,
        notes,
        createdAt,
        modifiedAt,
      ];
}

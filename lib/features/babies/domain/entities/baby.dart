import 'package:equatable/equatable.dart';

enum Gender {
  male,
  female;

  static Gender? fromString(String? value) {
    if (value == null) return null;
    return Gender.values.where((g) => g.name == value).firstOrNull;
  }
}

class BabyEntity extends Equatable {
  const BabyEntity({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.gender,
    this.photoPath,
    this.isActive = true,
    required this.createdAt,
    required this.modifiedAt,
  });

  final String id;
  final String name;
  final DateTime dateOfBirth;
  final Gender? gender;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime modifiedAt;

  /// Age counted in calendar days, never as a Duration: across a DST change
  /// a local Duration is an hour short, so a week-old baby read as "6 days".
  String formatAge({DateTime? now}) {
    final b = dateOfBirth.toLocal();
    final n = (now ?? DateTime.now()).toLocal();
    final days = DateTime.utc(
      n.year,
      n.month,
      n.day,
    ).difference(DateTime.utc(b.year, b.month, b.day)).inDays;
    final months = (days / 30.44).floor();
    final years = (months / 12).floor();
    final remainingMonths = months % 12;

    if (years > 0) {
      return remainingMonths > 0
          ? '$years yr $remainingMonths mo'
          : '$years yr';
    }
    if (months > 0) return '$months mo';
    final weeks = (days / 7).floor();
    if (weeks > 0) return '$weeks wk';
    if (days > 0) return '$days day${days == 1 ? '' : 's'}';
    return 'newborn';
  }

  BabyEntity copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    Gender? Function()? gender,
    String? Function()? photoPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return BabyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender != null ? gender() : this.gender,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    dateOfBirth,
    gender,
    photoPath,
    isActive,
    createdAt,
    modifiedAt,
  ];
}

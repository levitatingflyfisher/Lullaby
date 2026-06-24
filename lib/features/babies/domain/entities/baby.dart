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

  String formatAge() {
    final now = DateTime.now();
    final diff = now.difference(dateOfBirth);
    final months = (diff.inDays / 30.44).floor();
    final years = (months / 12).floor();
    final remainingMonths = months % 12;

    if (years > 0) {
      return remainingMonths > 0
          ? '$years yr $remainingMonths mo'
          : '$years yr';
    }
    if (months > 0) return '$months mo';
    final weeks = (diff.inDays / 7).floor();
    if (weeks > 0) return '$weeks wk';
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
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
  List<Object?> get props =>
      [id, name, dateOfBirth, gender, photoPath, isActive, createdAt, modifiedAt];
}

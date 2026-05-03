import 'dart:convert';

class FamilyProfile {
  final String id;
  final String nik;
  final String name;
  final String gender;
  final DateTime birthDate;
  final String? bloodType;
  final String? address;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyProfile({
    required this.id,
    required this.nik,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.bloodType,
    this.address,
    this.phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
      'blood_type': bloodType,
      'address': address,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FamilyProfile.fromMap(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      nik: map['nik'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      bloodType: map['blood_type'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory FamilyProfile.fromApi(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      nik: map['nik'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      bloodType: map['bloodType'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FamilyProfile.fromJson(String source) =>
      FamilyProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get formattedNik {
    if (nik.length != 16) return nik;
    return '${nik.substring(0, 6)} **** **** ${nik.substring(12)}';
  }

  FamilyProfile copyWith({
    String? id,
    String? nik,
    String? name,
    String? gender,
    DateTime? birthDate,
    String? bloodType,
    String? address,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyProfile(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'dart:convert';
import '../config/env.dart';

class FamilyProfile {
  final String id;
  final String? nik;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final String? bloodType;
  final String? address;
  final String? phone;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyProfile({
    required this.id,
    this.nik,
    required this.name,
    required this.gender,
    this.birthDate,
    this.bloodType,
    this.address,
    this.phone,
    this.avatarPath,
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
      'birth_date': birthDate?.toIso8601String(),
      'blood_type': bloodType,
      'address': address,
      'phone': phone,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FamilyProfile.fromMap(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      nik: map['nik'] as String?,
      name: map['name'] as String,
      gender: _normalizeGender(map['gender'] as String),
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      bloodType: map['blood_type'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory FamilyProfile.fromApi(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      nik: map['nik'] as String?,
      name: map['name'] as String,
      gender: _normalizeGender(map['gender'] as String),
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate'] as String) : null,
      bloodType: map['bloodType'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      avatarPath: map['avatarPath'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FamilyProfile.fromJson(String source) =>
      FamilyProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  String get formattedNik {
    if (nik == null || nik!.length != 16) return nik ?? '-';
    return '${nik!.substring(0, 6)} **** **** ${nik!.substring(12)}';
  }

  String? get avatarUrl {
    if (avatarPath == null || avatarPath!.isEmpty) return null;
    return '${Env.serverBaseUrl}$avatarPath';
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
    String? avatarPath,
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
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizeGender(String raw) {
    return raw.toLowerCase() == 'wanita' ? 'Wanita' : 'Pria';
  }
}

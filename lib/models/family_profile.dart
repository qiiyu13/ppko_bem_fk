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
  // Health variables — keys from ScreeningOptions, all optional
  final String? education;
  final String? occupation;
  final String? maritalStatus;
  final double? income;
  final String? familyDiseaseHistory;
  final String? smokingStatus;
  final String? physicalActivity;
  final String? fruitConsumption;
  final String? vegetableConsumption;
  final String? sweetFoodConsumption;
  final String? sweetDrinkConsumption;
  final String? fattyFoodConsumption;
  final String? fastFoodConsumption;
  final double? sleepDuration;
  final String? medicationRoutine;
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
    this.education,
    this.occupation,
    this.maritalStatus,
    this.income,
    this.familyDiseaseHistory,
    this.smokingStatus,
    this.physicalActivity,
    this.fruitConsumption,
    this.vegetableConsumption,
    this.sweetFoodConsumption,
    this.sweetDrinkConsumption,
    this.fattyFoodConsumption,
    this.fastFoodConsumption,
    this.sleepDuration,
    this.medicationRoutine,
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
      'education': education,
      'occupation': occupation,
      'marital_status': maritalStatus,
      'income': income,
      'family_disease_history': familyDiseaseHistory,
      'smoking_status': smokingStatus,
      'physical_activity': physicalActivity,
      'fruit_consumption': fruitConsumption,
      'vegetable_consumption': vegetableConsumption,
      'sweet_food_consumption': sweetFoodConsumption,
      'sweet_drink_consumption': sweetDrinkConsumption,
      'fatty_food_consumption': fattyFoodConsumption,
      'fast_food_consumption': fastFoodConsumption,
      'sleep_duration': sleepDuration,
      'medication_routine': medicationRoutine,
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
      education: map['education'] as String?,
      occupation: map['occupation'] as String?,
      maritalStatus: map['marital_status'] as String?,
      income: (map['income'] as num?)?.toDouble(),
      familyDiseaseHistory: map['family_disease_history'] as String?,
      smokingStatus: map['smoking_status'] as String?,
      physicalActivity: map['physical_activity'] as String?,
      fruitConsumption: map['fruit_consumption'] as String?,
      vegetableConsumption: map['vegetable_consumption'] as String?,
      sweetFoodConsumption: map['sweet_food_consumption'] as String?,
      sweetDrinkConsumption: map['sweet_drink_consumption'] as String?,
      fattyFoodConsumption: map['fatty_food_consumption'] as String?,
      fastFoodConsumption: map['fast_food_consumption'] as String?,
      sleepDuration: (map['sleep_duration'] as num?)?.toDouble(),
      medicationRoutine: map['medication_routine'] as String?,
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
      education: map['education'] as String?,
      occupation: map['occupation'] as String?,
      maritalStatus: map['maritalStatus'] as String?,
      income: (map['income'] as num?)?.toDouble(),
      familyDiseaseHistory: map['familyDiseaseHistory'] as String?,
      smokingStatus: map['smokingStatus'] as String?,
      physicalActivity: map['physicalActivity'] as String?,
      fruitConsumption: map['fruitConsumption'] as String?,
      vegetableConsumption: map['vegetableConsumption'] as String?,
      sweetFoodConsumption: map['sweetFoodConsumption'] as String?,
      sweetDrinkConsumption: map['sweetDrinkConsumption'] as String?,
      fattyFoodConsumption: map['fattyFoodConsumption'] as String?,
      fastFoodConsumption: map['fastFoodConsumption'] as String?,
      sleepDuration: (map['sleepDuration'] as num?)?.toDouble(),
      medicationRoutine: map['medicationRoutine'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  /// camelCase keys matching the backend API (multipart forms can't express
  /// null cleanly, but the route validators treat empty string as unset).
  Map<String, dynamic> toApiMap() {
    return {
      'nik': nik,
      'name': name,
      'gender': gender.toLowerCase(),
      'birthDate': birthDate?.toIso8601String(),
      'bloodType': bloodType,
      'address': address,
      'phone': phone,
      'education': education,
      'occupation': occupation,
      'maritalStatus': maritalStatus,
      'income': income,
      'familyDiseaseHistory': familyDiseaseHistory,
      'smokingStatus': smokingStatus,
      'physicalActivity': physicalActivity,
      'fruitConsumption': fruitConsumption,
      'vegetableConsumption': vegetableConsumption,
      'sweetFoodConsumption': sweetFoodConsumption,
      'sweetDrinkConsumption': sweetDrinkConsumption,
      'fattyFoodConsumption': fattyFoodConsumption,
      'fastFoodConsumption': fastFoodConsumption,
      'sleepDuration': sleepDuration,
      'medicationRoutine': medicationRoutine,
    };
  }

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
    String? education,
    String? occupation,
    String? maritalStatus,
    double? income,
    String? familyDiseaseHistory,
    String? smokingStatus,
    String? physicalActivity,
    String? fruitConsumption,
    String? vegetableConsumption,
    String? sweetFoodConsumption,
    String? sweetDrinkConsumption,
    String? fattyFoodConsumption,
    String? fastFoodConsumption,
    double? sleepDuration,
    String? medicationRoutine,
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
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      income: income ?? this.income,
      familyDiseaseHistory: familyDiseaseHistory ?? this.familyDiseaseHistory,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      physicalActivity: physicalActivity ?? this.physicalActivity,
      fruitConsumption: fruitConsumption ?? this.fruitConsumption,
      vegetableConsumption: vegetableConsumption ?? this.vegetableConsumption,
      sweetFoodConsumption: sweetFoodConsumption ?? this.sweetFoodConsumption,
      sweetDrinkConsumption: sweetDrinkConsumption ?? this.sweetDrinkConsumption,
      fattyFoodConsumption: fattyFoodConsumption ?? this.fattyFoodConsumption,
      fastFoodConsumption: fastFoodConsumption ?? this.fastFoodConsumption,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      medicationRoutine: medicationRoutine ?? this.medicationRoutine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizeGender(String raw) {
    return raw.toLowerCase() == 'wanita' ? 'Wanita' : 'Pria';
  }
}

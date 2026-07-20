import 'package:flutter/material.dart';
import '../constants/screening_options.dart';
import '../models/family_profile.dart';
import 'health_option_dropdown.dart';
import 'profile_form_field.dart';

/// Mutable holder for the 15 profile health variables (demografi + gaya
/// hidup). Screens keep one instance and pass it to [HealthVariablesSection].
class HealthVariableValues {
  String? education;
  String? occupation;
  String? maritalStatus;
  String? familyDiseaseHistory;
  String? smokingStatus;
  String? physicalActivity;
  String? fruitConsumption;
  String? vegetableConsumption;
  String? sweetFoodConsumption;
  String? sweetDrinkConsumption;
  String? fattyFoodConsumption;
  String? fastFoodConsumption;
  String? medicationRoutine;
  final TextEditingController incomeController;
  final TextEditingController sleepController;

  HealthVariableValues({FamilyProfile? profile})
      : incomeController = TextEditingController(
          text: profile?.income?.toStringAsFixed(0) ?? '',
        ),
        sleepController = TextEditingController(
          text: profile?.sleepDuration?.toString() ?? '',
        ) {
    education = profile?.education;
    occupation = profile?.occupation;
    maritalStatus = profile?.maritalStatus;
    familyDiseaseHistory = profile?.familyDiseaseHistory;
    smokingStatus = profile?.smokingStatus;
    physicalActivity = profile?.physicalActivity;
    fruitConsumption = profile?.fruitConsumption;
    vegetableConsumption = profile?.vegetableConsumption;
    sweetFoodConsumption = profile?.sweetFoodConsumption;
    sweetDrinkConsumption = profile?.sweetDrinkConsumption;
    fattyFoodConsumption = profile?.fattyFoodConsumption;
    fastFoodConsumption = profile?.fastFoodConsumption;
    medicationRoutine = profile?.medicationRoutine;
  }

  double? get income => double.tryParse(incomeController.text.trim().replaceAll(',', '.'));
  double? get sleepDuration => double.tryParse(sleepController.text.trim().replaceAll(',', '.'));

  /// camelCase keys for ProfileService.createProfile(healthVariables:).
  Map<String, dynamic> toApiMap() => {
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

  /// Only the 10 perilaku keys — what a screening snapshots.
  Map<String, dynamic> toBehaviorApiMap() => {
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

  /// Prefill from a raw profile JSON map (admin patient-detail response).
  void loadBehaviorFrom(Map<String, dynamic> profile) {
    smokingStatus = profile['smokingStatus'] as String?;
    physicalActivity = profile['physicalActivity'] as String?;
    fruitConsumption = profile['fruitConsumption'] as String?;
    vegetableConsumption = profile['vegetableConsumption'] as String?;
    sweetFoodConsumption = profile['sweetFoodConsumption'] as String?;
    sweetDrinkConsumption = profile['sweetDrinkConsumption'] as String?;
    fattyFoodConsumption = profile['fattyFoodConsumption'] as String?;
    fastFoodConsumption = profile['fastFoodConsumption'] as String?;
    final sd = (profile['sleepDuration'] as num?)?.toDouble();
    sleepController.text = sd?.toString() ?? '';
    medicationRoutine = profile['medicationRoutine'] as String?;
  }

  void dispose() {
    incomeController.dispose();
    sleepController.dispose();
  }
}

/// Only the "Perilaku & Gaya Hidup" fields — used by the medical screening
/// form (demografi belongs to the profile, not the screening).
class BehaviorSection extends StatelessWidget {
  final HealthVariableValues values;
  final VoidCallback onChanged;

  const BehaviorSection({
    super.key,
    required this.values,
    required this.onChanged,
  });

  void _set(VoidCallback fn) {
    fn();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HealthOptionDropdown(
          label: 'Merokok',
          options: ScreeningOptions.smokingStatus,
          value: values.smokingStatus,
          onChanged: (v) => _set(() => values.smokingStatus = v),
        ),
        HealthOptionDropdown(
          label: 'Aktivitas fisik',
          options: ScreeningOptions.physicalActivity,
          value: values.physicalActivity,
          onChanged: (v) => _set(() => values.physicalActivity = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi buah',
          options: ScreeningOptions.fruitConsumption,
          value: values.fruitConsumption,
          onChanged: (v) => _set(() => values.fruitConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi sayur',
          options: ScreeningOptions.vegetableConsumption,
          value: values.vegetableConsumption,
          onChanged: (v) => _set(() => values.vegetableConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan manis',
          options: ScreeningOptions.sweetFoodConsumption,
          value: values.sweetFoodConsumption,
          onChanged: (v) => _set(() => values.sweetFoodConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi minuman manis',
          options: ScreeningOptions.sweetDrinkConsumption,
          value: values.sweetDrinkConsumption,
          onChanged: (v) => _set(() => values.sweetDrinkConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan berlemak',
          options: ScreeningOptions.fattyFoodConsumption,
          value: values.fattyFoodConsumption,
          onChanged: (v) => _set(() => values.fattyFoodConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan cepat saji',
          options: ScreeningOptions.fastFoodConsumption,
          value: values.fastFoodConsumption,
          onChanged: (v) => _set(() => values.fastFoodConsumption = v),
        ),
        ProfileFormField(
          controller: values.sleepController,
          label: 'Durasi tidur per hari (jam)',
          hint: 'cth. 7',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        HealthOptionDropdown(
          label: 'Rutin minum obat diabetes/ hipertensi/ stroke/ jantung',
          options: ScreeningOptions.medicationRoutine,
          value: values.medicationRoutine,
          onChanged: (v) => _set(() => values.medicationRoutine = v),
        ),
      ],
    );
  }
}

/// "Demografi" + "Gaya Hidup" form sections. All fields optional.
class HealthVariablesSection extends StatelessWidget {
  final HealthVariableValues values;
  final VoidCallback onChanged;

  const HealthVariablesSection({
    super.key,
    required this.values,
    required this.onChanged,
  });

  void _set(VoidCallback fn) {
    fn();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const HealthSectionHeader(
          title: 'Demografi',
          subtitle: 'Data sosial ekonomi (opsional)',
        ),
        HealthOptionDropdown(
          label: 'Pendidikan',
          options: ScreeningOptions.education,
          value: values.education,
          onChanged: (v) => _set(() => values.education = v),
        ),
        HealthOptionDropdown(
          label: 'Pekerjaan',
          options: ScreeningOptions.occupation,
          value: values.occupation,
          onChanged: (v) => _set(() => values.occupation = v),
        ),
        HealthOptionDropdown(
          label: 'Status Perkawinan',
          options: ScreeningOptions.maritalStatus,
          value: values.maritalStatus,
          onChanged: (v) => _set(() => values.maritalStatus = v),
        ),
        ProfileFormField(
          controller: values.incomeController,
          label: 'Pendapatan per bulan (Rp)',
          hint: 'Contoh: 2500000',
          keyboardType: TextInputType.number,
        ),
        HealthOptionDropdown(
          label: 'Keluarga dengan diabetes/ hipertensi/ stroke/ jantung',
          options: ScreeningOptions.familyDiseaseHistory,
          value: values.familyDiseaseHistory,
          onChanged: (v) => _set(() => values.familyDiseaseHistory = v),
        ),
        const SizedBox(height: 8),
        const HealthSectionHeader(
          title: 'Gaya Hidup',
          subtitle: 'Perilaku berisiko saat ini (opsional)',
        ),
        HealthOptionDropdown(
          label: 'Merokok',
          options: ScreeningOptions.smokingStatus,
          value: values.smokingStatus,
          onChanged: (v) => _set(() => values.smokingStatus = v),
        ),
        HealthOptionDropdown(
          label: 'Aktivitas fisik',
          options: ScreeningOptions.physicalActivity,
          value: values.physicalActivity,
          onChanged: (v) => _set(() => values.physicalActivity = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi buah',
          options: ScreeningOptions.fruitConsumption,
          value: values.fruitConsumption,
          onChanged: (v) => _set(() => values.fruitConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi sayur',
          options: ScreeningOptions.vegetableConsumption,
          value: values.vegetableConsumption,
          onChanged: (v) => _set(() => values.vegetableConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan manis',
          options: ScreeningOptions.sweetFoodConsumption,
          value: values.sweetFoodConsumption,
          onChanged: (v) => _set(() => values.sweetFoodConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi minuman manis',
          options: ScreeningOptions.sweetDrinkConsumption,
          value: values.sweetDrinkConsumption,
          onChanged: (v) => _set(() => values.sweetDrinkConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan berlemak',
          options: ScreeningOptions.fattyFoodConsumption,
          value: values.fattyFoodConsumption,
          onChanged: (v) => _set(() => values.fattyFoodConsumption = v),
        ),
        HealthOptionDropdown(
          label: 'Konsumsi makanan cepat saji',
          options: ScreeningOptions.fastFoodConsumption,
          value: values.fastFoodConsumption,
          onChanged: (v) => _set(() => values.fastFoodConsumption = v),
        ),
        ProfileFormField(
          controller: values.sleepController,
          label: 'Durasi tidur per hari (jam)',
          hint: 'Contoh: 7',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        HealthOptionDropdown(
          label: 'Rutin minum obat diabetes/ hipertensi/ stroke/ jantung',
          options: ScreeningOptions.medicationRoutine,
          value: values.medicationRoutine,
          onChanged: (v) => _set(() => values.medicationRoutine = v),
        ),
      ],
    );
  }
}

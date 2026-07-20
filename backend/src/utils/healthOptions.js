// Allowed values for the health-variable fields on FamilyProfile and
// MedicalScreening. Stored as lowercase keys; Indonesian labels live in the
// app (lib/constants/screening_options.dart) — keep the two in sync.
const EDUCATION_VALUES = ['tidak_sekolah', 'sd', 'smp', 'sma', 'diploma', 'pt'];
const OCCUPATION_VALUES = ['tidak_bekerja', 'sekolah', 'pns_tni_polri', 'pegawai_swasta', 'wiraswasta', 'petani', 'pedagang', 'lainnya'];
const MARITAL_STATUS_VALUES = ['menikah', 'belum_menikah', 'cerai_hidup', 'cerai_mati'];
const FAMILY_DISEASE_HISTORY_VALUES = ['ada', 'tidak'];
const SMOKING_STATUS_VALUES = ['bukan_perokok', 'serumah_perokok', 'mantan_perokok', 'perokok_aktif'];
const PHYSICAL_ACTIVITY_VALUES = ['rendah', 'sedang', 'tinggi'];
const FRUIT_VEG_CONSUMPTION_VALUES = ['rendah', 'cukup'];
const FOOD_CONSUMPTION_VALUES = ['sering', 'jarang'];
const MEDICATION_ROUTINE_VALUES = ['sehat', 'tidak_rutin', 'rutin'];

// field -> allowed values, for express-validator isIn checks
const PROFILE_OPTION_FIELDS = {
  education: EDUCATION_VALUES,
  occupation: OCCUPATION_VALUES,
  maritalStatus: MARITAL_STATUS_VALUES,
  familyDiseaseHistory: FAMILY_DISEASE_HISTORY_VALUES,
  smokingStatus: SMOKING_STATUS_VALUES,
  physicalActivity: PHYSICAL_ACTIVITY_VALUES,
  fruitConsumption: FRUIT_VEG_CONSUMPTION_VALUES,
  vegetableConsumption: FRUIT_VEG_CONSUMPTION_VALUES,
  sweetFoodConsumption: FOOD_CONSUMPTION_VALUES,
  sweetDrinkConsumption: FOOD_CONSUMPTION_VALUES,
  fattyFoodConsumption: FOOD_CONSUMPTION_VALUES,
  fastFoodConsumption: FOOD_CONSUMPTION_VALUES,
  medicationRoutine: MEDICATION_ROUTINE_VALUES,
};

// Perilaku fields that screenings snapshot (demografi stays profile-only)
const SCREENING_OPTION_FIELDS = {
  smokingStatus: SMOKING_STATUS_VALUES,
  physicalActivity: PHYSICAL_ACTIVITY_VALUES,
  fruitConsumption: FRUIT_VEG_CONSUMPTION_VALUES,
  vegetableConsumption: FRUIT_VEG_CONSUMPTION_VALUES,
  sweetFoodConsumption: FOOD_CONSUMPTION_VALUES,
  sweetDrinkConsumption: FOOD_CONSUMPTION_VALUES,
  fattyFoodConsumption: FOOD_CONSUMPTION_VALUES,
  fastFoodConsumption: FOOD_CONSUMPTION_VALUES,
  medicationRoutine: MEDICATION_ROUTINE_VALUES,
};

module.exports = { PROFILE_OPTION_FIELDS, SCREENING_OPTION_FIELDS };

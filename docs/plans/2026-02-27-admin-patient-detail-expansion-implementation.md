# Admin Patient Detail Screen Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand the admin patient detail screen to show complete health metrics (height, BMI, uric acid) in addition to existing BP, glucose, and weight data.

**Architecture:** Add a second row of vital stats cards to display height, BMI, and uric acid. Expand the mock data model to include height and lab values. Calculate BMI from weight and height.

**Tech Stack:** Flutter, Dart

---

### Task 1: Add Extended Mock Data

**Files:**
- Modify: `lib/screens/admin/admin_patient_detail_screen.dart:13-21`

**Step 1: Add height, uricAcid, and cholesterol to _extendedData**

Replace the current `_extendedData` getter with:

```dart
Map<String, dynamic> get _extendedData {
  return {
    'age': 68,
    'gender': 'Laki-laki',
    'glucose': 110,
    'weight': 62,
    'height': 165,
    'uricAcid': 5.8,
    'cholesterol': 185,
    ...patient,
  };
}
```

**Step 2: Add BMI calculation helper**

Add after `_extendedData`:

```dart
double get _bmi {
  final heightInMeters = (_extendedData['height'] as int) / 100;
  return _extendedData['weight'] / (heightInMeters * heightInMeters);
}

String get _bmiCategory {
  if (_bmi < 18.5) return 'Kurus';
  if (_bmi < 25) return 'Normal';
  if (_bmi < 30) return 'Gemuk';
  return 'Obesitas';
}
```

**Step 3: Commit**

```bash
git add lib/screens/admin/admin_patient_detail_screen.dart
git commit -m "feat: add extended mock data for height, uric acid, cholesterol"
```

---

### Task 2: Add Second Row of Vital Stats Cards

**Files:**
- Modify: `lib/screens/admin/admin_patient_detail_screen.dart:186-224`

**Step 1: Update _buildVitalStatsRow to return Column with two rows**

Replace `_buildVitalStatsRow` method:

```dart
Widget _buildVitalStatsRow(Map<String, dynamic> data) {
  return Column(
    children: [
      // Row 1: Tensi, Gula, Berat
      Row(
        children: [
          Expanded(
            child: _buildVitalCard(
              label: 'TENSI',
              value: '${data['systolic']}/${data['diastolic']}',
              status: 'Tinggi',
              borderColor: attentionOrange,
              statusColor: attentionOrange,
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: _buildVitalCard(
              label: 'GULA',
              value: '${data['glucose']}',
              status: 'Normal',
              borderColor: AppColors.success,
              statusColor: AppColors.success,
              unit: '',
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: _buildVitalCard(
              label: 'BERAT',
              value: '${data['weight']}',
              status: 'Stabil',
              borderColor: AppColors.primary,
              statusColor: AppColors.primary,
              unit: 'kg',
            ),
          ),
        ],
      ),
      SizedBox(height: ResponsiveSize.paddingSmall),
      // Row 2: Tinggi, BMI, Asam Urat
      Row(
        children: [
          Expanded(
            child: _buildVitalCard(
              label: 'TINGGI',
              value: '${data['height']}',
              status: '-',
              borderColor: AppColors.primary,
              statusColor: AppColors.primary,
              unit: 'cm',
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: _buildVitalCard(
              label: 'BMI',
              value: _bmi.toStringAsFixed(1),
              status: _bmiCategory,
              borderColor: _bmi < 25 ? AppColors.success : attentionOrange,
              statusColor: _bmi < 25 ? AppColors.success : attentionOrange,
              unit: '',
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          Expanded(
            child: _buildVitalCard(
              label: 'ASAM URAT',
              value: '${data['uricAcid']}',
              status: 'Normal',
              borderColor: AppColors.success,
              statusColor: AppColors.success,
              unit: '',
            ),
          ),
        ],
      ),
    ],
  );
}
```

**Step 2: Run Flutter analyze to verify**

```bash
flutter analyze lib/screens/admin/admin_patient_detail_screen.dart
```

Expected: No errors

**Step 3: Commit**

```bash
git add lib/screens/admin/admin_patient_detail_screen.dart
git commit -feat: add second row of vital stats (height, BMI, uric acid)
```

---

### Task 3: Verify Build

**Step 1: Run Flutter build**

```bash
flutter build apk --debug 2>&1 | head -50
```

Expected: Build succeeds

**Step 2: Commit**

```bash
git commit -m "feat: complete admin patient detail screen expansion"
```

# Design: Expand Admin Patient Detail Screen with Complete Health Metrics

**Date:** 2026-02-27  
**File:** `lib/screens/admin/admin_patient_detail_screen.dart`

## Goal

Expand the admin patient detail screen to show complete health metrics (currently only BP-focused) to match the data available in `laporan_saya_screen.dart`.

## Current State

- Profile section (avatar, name, age, gender)
- Vital Stats Row: 3 cards (Tensi, Gula, Berat)
- BP History section only

## Proposed Changes

### 1. Extended Patient Data Model
Add missing mock data fields:
- `height` (int, in cm)
- `uricAcid` (double)
- `cholesterol` (double)
- Calculate BMI from weight and height

### 2. Vital Stats Section - Two Rows

**Row 1:** Keep current layout
- TENSI (Blood Pressure): `${systolic}/${diastolic}` mmHg
- GULA (Blood Sugar): `${glucose}` mg/dL
- BERAT (Weight): `${weight}` kg

**Row 2:** New row with additional metrics
- TINGGI (Height): `${height}` cm
- BMI: `${bmi}` (${category}) - calculated from weight/height
- ASAM URAT (Uric Acid): `${uricAcid}` mg/dL

**Note:** Kolesterol will be shown in the history section (similar to BP history) or can be added as a 3rd row if needed.

### 3. History Section
- Expand BP History to show all screening data (Weight, Height, Blood Sugar, Uric Acid, Cholesterol) in expandable cards

### 4. Action Buttons (Optional - not in current scope)
- Download and Share buttons (deferred to future iteration)

## Implementation Notes

- Reuse existing `_buildVitalCard` widget
- Add BMI calculation helper similar to `laporan_saya_screen.dart`
- Maintain consistent status colors for each metric
- Keep the same card styling and responsive behavior

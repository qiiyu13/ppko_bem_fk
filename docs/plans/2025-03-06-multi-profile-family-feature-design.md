# Multi-Profile Family Feature Design

**Date:** 2025-03-06  
**Status:** Approved  
**Approach:** Device-Only Storage (No Backend Required)

---

## Overview

Transform the Mediku app from a single-user experience to a family-centric application where multiple family members can share one device. Each family member has their own isolated profile with separate health data, appointments, and metrics.

---

## Goals

1. Support unlimited family member profiles on a single device
2. Each profile has completely isolated health data
3. Easy profile switching from home tab header
4. Profile management (add/remove) in profile tab
5. No backend required - works entirely offline
6. Simple migration from current single-profile hardcoded data

---

## Architecture

### Data Model

```dart
// Family Profile
class FamilyProfile {
  final String id;           // UUID
  final String nik;          // 16-digit NIK
  final String name;         // Full name
  final String gender;       // Pria/Wanita
  final DateTime birthDate;  // For age calculation
  final String bloodType;    // A+, B+, O+, AB+, etc.
  final String address;      // Full address
  final String phone;        // Contact number
  final DateTime createdAt;  // When profile was added
}

// Active Profile State
class ActiveProfileState {
  final String activeProfileId;  // Currently selected profile ID
  final List<FamilyProfile> profiles;  // All family profiles
}
```

### Storage Strategy

**SQLite Database** (via `sqflite` package):
- `family_profiles` table: Store all family member profiles
- `health_metrics` table: Store metrics per profile (linked by profile_id)
- `appointments` table: Store appointments per profile
- `active_profile` table: Store currently selected profile ID

**Why SQLite over SharedPreferences:**
- Structured relational data
- Query capabilities for filtering by profile
- Better performance with growing data
- Supports complex health metric history

---

## User Flow

### 1. First-Time Setup
- User logs in with existing NIK (current welcome screen)
- Automatically create first profile from NIK
- Save profile to local database
- Set as active profile

### 2. Daily Usage - Profile Switching
- Open app → lands on Home Tab
- See current profile name in header
- Tap dropdown → see all family profiles
- Select different profile → app reloads with that profile's data
- All tabs now show selected profile's data

### 3. Adding New Family Member
- Go to Profile Tab
- Tap "Tambah Anggota Keluarga" button
- Enter NIK and basic info
- Save → new profile created
- Can immediately switch to new profile

### 4. Managing Profiles
- Profile Tab shows list of all family members
- Tap any profile to switch to it
- Long-press to edit or delete
- Current active profile highlighted

---

## UI Changes

### Home Tab (`home_tab.dart`)
**Current:**
```dart
Text('Pak Budi!', style: TextStyle(...))  // Hardcoded name
```

**New:**
- Replace greeting section with profile selector dropdown
- Dropdown shows: "👤 Pak Budi ▼"
- Opens bottom sheet with all profiles
- Selecting profile triggers app-wide state update
- All metrics/charts reload for selected profile

### Profile Tab (`profil_tab.dart`)
**Current:**
- Single profile card with static data
- Edit button

**New:**
- Header: "Anggota Keluarga" with count badge
- List of all family profiles as cards
- Each card shows: photo/icon, name, NIK (masked)
- Current active profile has "Active" badge
- Tap to switch
- Floating Action Button: "+ Tambah Anggota"
- Edit profile details by tapping card

---

## State Management

Since the app currently uses vanilla StatefulWidget, we'll introduce a simple service-based approach:

### Profile Service
```dart
class ProfileService {
  // Singleton
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // State
  FamilyProfile? _activeProfile;
  List<FamilyProfile> _profiles = [];

  // Methods
  Future<void> loadProfiles();
  Future<void> setActiveProfile(String profileId);
  Future<void> addProfile(FamilyProfile profile);
  Future<void> updateProfile(FamilyProfile profile);
  Future<void> deleteProfile(String profileId);
  
  // Getters
  FamilyProfile? get activeProfile => _activeProfile;
  List<FamilyProfile> get profiles => _profiles;
  
  // Stream for UI updates
  Stream<FamilyProfile?> get activeProfileStream;
}
```

### UI Updates
- Screens listen to ProfileService stream
- When active profile changes, rebuild with new data
- Database queries always filter by `profile_id`

---

## Database Schema

```sql
-- Family profiles table
CREATE TABLE family_profiles (
  id TEXT PRIMARY KEY,
  nik TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  gender TEXT NOT NULL,
  birth_date TEXT NOT NULL,
  blood_type TEXT,
  address TEXT,
  phone TEXT,
  created_at TEXT NOT NULL
);

-- Track active profile
CREATE TABLE app_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- Insert: ('active_profile_id', 'profile-uuid-here')

-- Health metrics per profile
CREATE TABLE health_metrics (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  metric_type TEXT NOT NULL,
  value REAL NOT NULL,
  unit TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES family_profiles(id)
);

-- Appointments per profile
CREATE TABLE appointments (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  title TEXT NOT NULL,
  date TEXT NOT NULL,
  location TEXT,
  notes TEXT,
  FOREIGN KEY (profile_id) REFERENCES family_profiles(id)
);
```

---

## Migration Strategy

1. **Install sqflite dependency**
2. **Create database helper** on app startup
3. **Migration check:** If no profiles exist, create default profile from hardcoded data
4. **Gradual refactor:** Update screens one by one to use ProfileService
5. **Remove hardcoded data** once all screens migrated

---

## Security Considerations

- All data stays on device
- NIK stored in plain text (acceptable for local-only app)
- No authentication between profiles (family sharing device)
- Database file protected by Android/iOS sandbox

---

## Future Enhancements (Phase 2)

- Backend sync with device registration
- Cloud backup of profiles
- Sync across multiple family devices
- Profile photos/avatars
- Biometric authentication per profile

---

## Success Criteria

1. ✅ Can add unlimited family profiles
2. ✅ Profile switcher visible in Home Tab
3. ✅ Each profile sees only their health data
4. ✅ Profile management in Profile Tab
5. ✅ Data persists across app restarts
6. ✅ No internet connection required

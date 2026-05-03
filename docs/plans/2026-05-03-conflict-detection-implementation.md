# Conflict Detection (Optimistic Locking) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add optimistic locking to all user-editable backend endpoints so offline or parallel edits don't silently overwrite each other.

**Architecture:**
Use `updatedAt` timestamps as ETags. Every update/delete request must include the `updatedAt` the client last saw. The backend compares it with the current database value. If they differ, return HTTP 409 CONFLICT with the current server data. The frontend catches 409s and shows a conflict resolution dialog allowing the user to refresh, overwrite, or review.

**Tech Stack:**
Prisma (schema migrations + `@updatedAt`), Express.js (middleware + controllers), Flutter (Dio error handling + dialog UI)

**Scope:**
Tight focus on **mutable user-facing data** (family profiles, appointments, articles, admin users). Append-only data (screenings, health metrics) and superadmin-only data (regions, residents) are out of scope but noted for future expansion.

---

## Current State Analysis

**Tables WITH `updatedAt`:** `users`, `articles`, `chat_conversations`
**Tables WITHOUT `updatedAt`:** `family_profiles`, `appointments`, `health_metrics`, `medical_screenings`, `regions`, `residents`, `chat_messages`

**Frontend offline support:** Only `ProfileService` has fallback-to-local-cache logic. Other services fail silently when offline. This plan adds conflict detection to the API layer first; broader offline queuing for other services is noted as a follow-up.

---

## Task 1: Update Prisma Schema — Add `updatedAt` to Missing Tables

**Files:**
- Modify: `backend/prisma/schema.prisma`

**Step 1: Add `updatedAt` to `family_profiles`**

```prisma
model FamilyProfile {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  name      String
  nik       String
  gender    String
  birthDate DateTime @map("birth_date")
  height    Float?
  weight    Float?
  bloodType String?  @map("blood_type")
  phone     String?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")  // ADD THIS

  user       User              @relation(fields: [userId], references: [id])
  metrics    HealthMetric[]
  screenings MedicalScreening[] @relation("PatientProfile")

  @@map("family_profiles")
}
```

**Step 2: Add `updatedAt` to `appointments`**

```prisma
model Appointment {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  profileId String?  @map("profile_id")
  title     String
  date      DateTime
  location  String?
  notes     String?
  type      String   @default("GENERAL")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")  // ADD THIS

  user User @relation(fields: [userId], references: [id])

  @@map("appointments")
}
```

**Step 3: Add `updatedAt` to `health_metrics`** (for completeness, even though append-only)

```prisma
model HealthMetric {
  id             String   @id @default(uuid())
  profileId      String   @map("profile_id")
  type           String
  value          Float
  secondaryValue Float?   @map("secondary_value")
  unit           String
  notes          String?
  recordedAt     DateTime @map("recorded_at")
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @updatedAt @map("updated_at")  // ADD THIS

  profile FamilyProfile @relation(fields: [profileId], references: [id])

  @@map("health_metrics")
}
```

**Step 4: Add `updatedAt` to `medical_screenings`** (for completeness)

```prisma
model MedicalScreening {
  id          String   @id @default(uuid())
  profileId   String   @map("profile_id")
  screenedBy  String   @map("screened_by")
  systolic    Int
  diastolic   Int
  bloodSugar  Float?   @map("blood_sugar")
  cholesterol Float?
  uricAcid    Float?   @map("uric_acid")
  height      Float?
  weight      Float?
  irdScore    Float    @map("ird_score")
  irdCategory String   @map("ird_category")
  notes       String?
  screeningAt DateTime @map("screening_at")
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")  // ADD THIS

  profile  FamilyProfile @relation("PatientProfile", fields: [profileId], references: [id])
  screener User          @relation("Screener", fields: [screenedBy], references: [id])

  @@map("medical_screenings")
}
```

**Step 5: Add `updatedAt` to `regions`**

```prisma
model Region {
  id        String   @id @default(uuid())
  type      String
  name      String
  parentId  String?  @map("parent_id")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")  // ADD THIS

  parent   Region?    @relation("RegionHierarchy", fields: [parentId], references: [id])
  children Region[]   @relation("RegionHierarchy")
  residents Resident[]

  @@map("regions")
}
```

**Step 6: Add `updatedAt` to `residents`**

```prisma
model Resident {
  id        String   @id @default(uuid())
  regionId  String   @map("region_id")
  name      String
  nik       String   @unique
  gender    String
  birthDate DateTime @map("birth_date")
  phone     String?
  address   String?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")  // ADD THIS

  region Region @relation(fields: [regionId], references: [id])

  @@map("residents")
}
```

**Step 7: Add `updatedAt` to `chat_messages`**

```prisma
model ChatMessage {
  id             String   @id @default(uuid())
  conversationId String   @map("conversation_id")
  content        String
  role           String
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @updatedAt @map("updated_at")  // ADD THIS

  conversation ChatConversation @relation(fields: [conversationId], references: [id])

  @@map("chat_messages")
}
```

**Step 8: Commit**

```bash
git add backend/prisma/schema.prisma
git commit -m "feat: add updatedAt timestamps to all tables for optimistic locking"
```

---

## Task 2: Run Prisma Migration

**Files:**
- Generated: `backend/prisma/migrations/`

**Step 1: Generate and apply migration**

Run:
```bash
cd backend
npx prisma migrate dev --name add_updated_at_to_all_tables
```

Expected: Prisma prompts to confirm migration name, then creates migration SQL and applies it.

**Step 2: Regenerate Prisma Client**

```bash
npx prisma generate
```

**Step 3: Verify tables have new column**

```bash
docker exec mediku-postgres psql -U mediku -d mediku -c "\d family_profiles"
```

Expected: `updated_at` column appears with type `timestamp(3)` and `not null default now()`.

**Step 4: Commit**

```bash
git add backend/prisma/migrations/
git commit -m "feat: migrate updatedAt columns to all tables"
```

---

## Task 3: Create Conflict Detection Middleware

**Files:**
- Create: `backend/src/middleware/conflictDetection.js`

**Step 1: Write the middleware**

```javascript
const { PrismaClient } = require('@prisma/client');
const { error } = require('../utils/response');

const prisma = new PrismaClient();

/**
 * Optimistic locking middleware.
 * Expects req.body.updatedAt (ISO string) for PUT/DELETE requests.
 * Compares with the current record's updatedAt in the database.
 * If they differ, returns 409 CONFLICT with current server data.
 */
const conflictDetection = (modelName, idParam = 'id') => async (req, res, next) => {
  // Only apply to PUT and DELETE
  if (!['PUT', 'DELETE'].includes(req.method)) {
    return next();
  }

  const clientUpdatedAt = req.body?.updatedAt || req.query?.updatedAt;
  if (!clientUpdatedAt) {
    return error(res, 'updatedAt is required for updates and deletes', 400, 'MISSING_UPDATED_AT');
  }

  const id = req.params[idParam];
  if (!id) {
    return error(res, 'Resource ID is required', 400, 'MISSING_ID');
  }

  try {
    const record = await prisma[modelName].findUnique({ where: { id } });

    if (!record) {
      return error(res, 'Resource not found', 404, 'NOT_FOUND');
    }

    const serverUpdatedAt = record.updatedAt?.toISOString();
    const clientTime = new Date(clientUpdatedAt).toISOString();

    if (serverUpdatedAt !== clientTime) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'CONFLICT',
          message: 'This record was modified by another user or device. Please review the current version.',
        },
        data: record, // Send current server data for conflict resolution
      });
    }

    // Attach record to req so controllers don't need to re-fetch
    req.existingRecord = record;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = conflictDetection;
```

**Step 2: Commit**

```bash
git add backend/src/middleware/conflictDetection.js
git commit -m "feat: add optimistic locking conflict detection middleware"
```

---

## Task 4: Update Profile Routes/Controller for Conflict Detection

**Files:**
- Modify: `backend/src/modules/profiles/profiles.routes.js`
- Modify: `backend/src/modules/profiles/profiles.controller.js`

**Step 1: Modify routes to include middleware**

```javascript
const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./profiles.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

router.use(authenticate);

router.get('/', controller.getProfiles);
router.get('/:id', controller.getProfile);

router.post('/', [
  body('name').isString().notEmpty(),
  body('nik').isString().notEmpty(),
  body('gender').isIn(['pria', 'wanita']),
  body('birthDate').isISO8601(),
  validate,
], controller.createProfile);

router.put('/:id', [
  body('name').optional().isString().notEmpty(),
  body('nik').optional().isString().notEmpty(),
  body('gender').optional().isIn(['pria', 'wanita']),
  body('birthDate').optional().isISO8601(),
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.updateProfile);

router.delete('/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.deleteProfile);

module.exports = router;
```

**Step 2: Update controller to use `req.existingRecord`**

```javascript
const profilesService = require('./profiles.service');
const { success, error } = require('../../utils/response');

// ... getProfiles, getProfile, createProfile stay the same ...

const updateProfile = async (req, res, next) => {
  try {
    // req.existingRecord is set by conflictDetection middleware
    const profile = await profilesService.updateProfile(req.params.id, req.body, req.user.id);
    return success(res, profile, 'Profile updated successfully');
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteProfile = async (req, res, next) => {
  try {
    const result = await profilesService.deleteProfile(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getProfiles, getProfile, createProfile, updateProfile, deleteProfile };
```

**Step 3: Commit**

```bash
git add backend/src/modules/profiles/
git commit -m "feat: add optimistic locking to profile update and delete endpoints"
```

---

## Task 5: Update Appointment Routes/Controller for Conflict Detection

**Files:**
- Modify: `backend/src/modules/appointments/appointments.routes.js`
- Modify: `backend/src/modules/appointments/appointments.controller.js`

**Step 1: Modify routes**

```javascript
const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./appointments.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

router.use(authenticate);

router.get('/', controller.getAppointments);

router.post('/', [
  body('title').isString().notEmpty(),
  body('date').isISO8601(),
  validate,
], controller.createAppointment);

router.put('/:id', [
  body('title').optional().isString().notEmpty(),
  body('date').optional().isISO8601(),
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('appointment'), controller.updateAppointment);

router.delete('/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('appointment'), controller.deleteAppointment);

module.exports = router;
```

**Step 2: Update controller**

```javascript
const appointmentsService = require('./appointments.service');
const { success, error } = require('../../utils/response');

// ... getAppointments, createAppointment stay the same ...

const updateAppointment = async (req, res, next) => {
  try {
    const appointment = await appointmentsService.updateAppointment(req.params.id, req.body, req.user.id);
    return success(res, appointment, 'Appointment updated successfully');
  } catch (err) {
    if (err.message === 'Appointment not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteAppointment = async (req, res, next) => {
  try {
    const result = await appointmentsService.deleteAppointment(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Appointment not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getAppointments, createAppointment, updateAppointment, deleteAppointment };
```

**Step 3: Commit**

```bash
git add backend/src/modules/appointments/
git commit -m "feat: add optimistic locking to appointment update and delete endpoints"
```

---

## Task 6: Update Article Routes/Controller for Conflict Detection

**Files:**
- Modify: `backend/src/modules/articles/articles.routes.js`
- Modify: `backend/src/modules/articles/articles.controller.js`

**Step 1: Modify routes**

```javascript
const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./articles.controller');
const authenticate = require('../../middleware/auth');
const roleGuard = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

// Public routes (no auth)
router.get('/', controller.getPublishedArticles);
router.get('/:id', controller.getPublishedArticle);

// Admin routes
router.use(authenticate, roleGuard('ADMIN', 'SUPERADMIN'));

router.get('/admin/all', controller.getAllArticles);

router.post('/admin', [
  body('title').isString().notEmpty(),
  body('content').isString().notEmpty(),
  validate,
], controller.createArticle);

router.put('/admin/:id', [
  body('title').optional().isString().notEmpty(),
  body('content').optional().isString().notEmpty(),
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.updateArticle);

router.delete('/admin/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.deleteArticle);

router.post('/admin/:id/publish', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.publishArticle);

module.exports = router;
```

**Step 2: Update controller**

```javascript
const articlesService = require('./articles.service');
const { success, error } = require('../../utils/response');

// ... getPublishedArticles, getPublishedArticle, getAllArticles, createArticle stay the same ...

const updateArticle = async (req, res, next) => {
  try {
    const article = await articlesService.updateArticle(req.params.id, req.body);
    return success(res, article, 'Article updated successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteArticle = async (req, res, next) => {
  try {
    const result = await articlesService.deleteArticle(req.params.id);
    return success(res, result);
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

const publishArticle = async (req, res, next) => {
  try {
    const article = await articlesService.publishArticle(req.params.id);
    return success(res, article, 'Article published successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = {
  getPublishedArticles, getPublishedArticle,
  getAllArticles, createArticle, updateArticle, deleteArticle, publishArticle,
};
```

**Step 3: Commit**

```bash
git add backend/src/modules/articles/
git commit -m "feat: add optimistic locking to article update, delete, and publish endpoints"
```

---

## Task 7: Update Admin User Routes/Controller for Conflict Detection

**Files:**
- Modify: `backend/src/modules/admin/admin.routes.js`
- Modify: `backend/src/modules/admin/admin.controller.js`

**Step 1: Read the current admin routes and controller**

Run: `cat backend/src/modules/admin/admin.routes.js`
Run: `cat backend/src/modules/admin/admin.controller.js`

*(Note: These files were not explored yet; read them before modifying.)*

**Step 2: Add `updatedAt` validation and conflictDetection to PUT /admin/users/:id**

```javascript
// In admin.routes.js
const conflictDetection = require('../../middleware/conflictDetection');

router.put('/users/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('user'), controller.updateUser);
```

**Step 3: Commit**

```bash
git add backend/src/modules/admin/
git commit -m "feat: add optimistic locking to admin user update endpoint"
```

---

## Task 8: Update Error Handler to Recognize 409

**Files:**
- Modify: `backend/src/middleware/errorHandler.js`

**Step 1: Add explicit 409 handling**

```javascript
const { error } = require('../utils/response');

const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Prisma unique constraint violation
  if (err.code === 'P2002') {
    return error(res, 'Data already exists', 409, 'CONFLICT');
  }

  // Prisma not found
  if (err.code === 'P2025') {
    return error(res, 'Resource not found', 404, 'NOT_FOUND');
  }

  // Prisma foreign key violation
  if (err.code === 'P2003') {
    return error(res, 'Referenced resource not found', 400, 'FOREIGN_KEY_ERROR');
  }

  return error(res, err.message || 'Internal Server Error', err.statusCode || 500, err.code || 'INTERNAL_ERROR');
};

module.exports = errorHandler;
```

**Step 2: Commit**

```bash
git add backend/src/middleware/errorHandler.js
git commit -m "fix: improve error handler to respect custom status codes for conflict responses"
```

---

## Task 9: Update Frontend FamilyProfile Model with updatedAt

**Files:**
- Modify: `lib/models/family_profile.dart`

**Step 1: Add `updatedAt` field**

```dart
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
  final DateTime updatedAt; // ADD THIS

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
    DateTime? updatedAt, // ADD THIS
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(); // ADD THIS

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
      'updated_at': updatedAt.toIso8601String(), // ADD THIS
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
      updatedAt: DateTime.parse(map['updated_at'] as String), // ADD THIS
    );
  }

  // ... toJson, fromJson, age, formattedNik stay the same ...

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
    DateTime? updatedAt, // ADD THIS
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
      updatedAt: updatedAt ?? this.updatedAt, // ADD THIS
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/models/family_profile.dart
git commit -m "feat: add updatedAt field to FamilyProfile model"
```

---

## Task 10: Create Conflict Exception and Dialog UI

**Files:**
- Create: `lib/exceptions/sync_conflict_exception.dart`
- Create: `lib/widgets/conflict_resolution_dialog.dart`

**Step 1: Create the exception class**

```dart
class SyncConflictException implements Exception {
  final String message;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> localData;

  SyncConflictException({
    required this.message,
    required this.serverData,
    required this.localData,
  });

  @override
  String toString() => 'SyncConflictException: $message';
}
```

**Step 2: Create the conflict resolution dialog**

```dart
import 'package:flutter/material.dart';

enum ConflictResolution { useServer, useLocal, cancel }

class ConflictResolutionDialog extends StatelessWidget {
  final String title;
  final String message;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> localData;

  const ConflictResolutionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.serverData,
    required this.localData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text('Server version:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatData(serverData)),
            const SizedBox(height: 8),
            Text('Your version:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatData(localData)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.useServer),
          child: const Text('Use Server'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.useLocal),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }

  String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}
```

**Step 3: Commit**

```bash
git add lib/exceptions/ lib/widgets/conflict_resolution_dialog.dart
git commit -m "feat: add SyncConflictException and conflict resolution dialog UI"
```

---

## Task 11: Update ApiService to Handle 409 Conflicts

**Files:**
- Modify: `lib/services/api_service.dart`

**Step 1: Add conflict exception throwing in interceptor**

```dart
import 'package:dio/dio.dart';
import 'token_service.dart';
import '../exceptions/sync_conflict_exception.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static void setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await TokenService.clearAll();
        }
        // ADD THIS BLOCK:
        if (error.response?.statusCode == 409) {
          final serverData = error.response?.data['data'] as Map<String, dynamic>? ?? {};
          final localData = error.requestOptions.data as Map<String, dynamic>? ?? {};
          throw SyncConflictException(
            message: error.response?.data['error']?['message'] ?? 'Data conflict detected',
            serverData: serverData,
            localData: localData,
          );
        }
        handler.next(error);
      },
    ));
  }

  // ... get, post, put, delete, request stay the same ...
}
```

**Step 2: Commit**

```bash
git add lib/services/api_service.dart
git commit -m "feat: intercept 409 CONFLICT responses and throw SyncConflictException"
```

---

## Task 12: Update ProfileService Conflict Handling

**Files:**
- Modify: `lib/services/profile_service.dart`

**Step 1: Update `updateProfile` to include `updatedAt` and handle conflicts**

```dart
  Future<void> updateProfile(FamilyProfile profile) async {
    try {
      await ApiService.put('/profiles/${profile.id}', data: {
        ...profile.toMap(),
        'updatedAt': profile.updatedAt.toIso8601String(), // ADD THIS
      });
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      if (_activeProfile?.id == profile.id) {
        _activeProfile = profile;
        _activeProfileController.add(_activeProfile);
      }
      await CacheService.saveProfile(profile.id, profile.toJson());
    } on SyncConflictException catch (e) {
      // Re-throw so the UI can show the conflict dialog
      rethrow;
    } catch (e) {
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
        _profilesController.add(List.unmodifiable(_profiles));
      }
      await CacheService.queueSync('/profiles/${profile.id}', 'PUT', {
        ...profile.toMap(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      });
    }
  }
```

**Step 2: Update `deleteProfile` similarly**

```dart
  Future<void> deleteProfile(String id, DateTime updatedAt) async {
    try {
      await ApiService.delete('/profiles/$id', data: {
        'updatedAt': updatedAt.toIso8601String(),
      });
    } on SyncConflictException catch (e) {
      rethrow;
    } catch (e) {
      await CacheService.queueSync('/profiles/$id', 'DELETE', {
        'updatedAt': updatedAt.toIso8601String(),
      });
    }
    _profiles.removeWhere((p) => p.id == id);
    _profilesController.add(List.unmodifiable(_profiles));
    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      _activeProfileController.add(_activeProfile);
    }
  }
```

**Step 3: Commit**

```bash
git add lib/services/profile_service.dart
git commit -m "feat: include updatedAt in profile update/delete and rethrow SyncConflictException"
```

---

## Task 13: Update AppointmentService Conflict Handling

**Files:**
- Modify: `lib/services/appointment_service.dart`

**Step 1: Update `updateAppointment` to include `updatedAt`**

```dart
  static Future<Map<String, dynamic>> updateAppointment(String id, {
    String? title,
    DateTime? date,
    String? location,
    String? notes,
    String? type,
    required DateTime updatedAt, // ADD THIS
  }) async {
    final response = await ApiService.put('/appointments/$id', data: {
      if (title != null) 'title': title,
      if (date != null) 'date': date.toIso8601String(),
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (type != null) 'type': type,
      'updatedAt': updatedAt.toIso8601String(), // ADD THIS
    });
    return response.data['data'] as Map<String, dynamic>;
  }
```

**Step 2: Update `deleteAppointment`**

```dart
  static Future<void> deleteAppointment(String id, DateTime updatedAt) async {
    await ApiService.delete('/appointments/$id', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
```

**Step 3: Commit**

```bash
git add lib/services/appointment_service.dart
git commit -m "feat: include updatedAt in appointment update/delete requests"
```

---

## Task 14: Update ArticleService Conflict Handling

**Files:**
- Modify: `lib/services/article_service.dart`

**Step 1: Update `updateArticle` to include `updatedAt`**

```dart
  static Future<TanamanArticle> updateArticle(String id, {
    String? title,
    String? content,
    String? imagePath,
    List<String>? tags,
    bool? isDraft,
    bool? isPublished,
    required DateTime updatedAt, // ADD THIS
  }) async {
    final response = await ApiService.put('/articles/admin/$id', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (imagePath != null) 'imagePath': imagePath,
      if (tags != null) 'tags': tags,
      if (isDraft != null) 'isDraft': isDraft,
      if (isPublished != null) 'isPublished': isPublished,
      'updatedAt': updatedAt.toIso8601String(), // ADD THIS
    });
    return TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
  }
```

**Step 2: Update `deleteArticle` and `publishArticle`**

```dart
  static Future<void> deleteArticle(String id, DateTime updatedAt) async {
    await ApiService.delete('/articles/admin/$id', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  static Future<void> publishArticle(String id, DateTime updatedAt) async {
    await ApiService.post('/articles/admin/$id/publish', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
```

**Step 3: Commit**

```bash
git add lib/services/article_service.dart
git commit -m "feat: include updatedAt in article update/delete/publish requests"
```

---

## Task 15: Update AdminService Conflict Handling

**Files:**
- Modify: `lib/services/admin_service.dart`

**Step 1: Update `updateUser` to include `updatedAt`**

```dart
  static Future<Map<String, dynamic>> updateUser(String id, {
    String? name,
    String? gender,
    DateTime? birthDate,
    String? phone,
    String? role,
    bool? isActive,
    String? password,
    required DateTime updatedAt, // ADD THIS
  }) async {
    final response = await ApiService.put('/admin/users/$id', data: {
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive,
      if (password != null) 'password': password,
      'updatedAt': updatedAt.toIso8601String(), // ADD THIS
    });
    return response.data['data'] as Map<String, dynamic>;
  }
```

**Step 2: Commit**

```bash
git add lib/services/admin_service.dart
git commit -m "feat: include updatedAt in admin user update requests"
```

---

## Task 16: Add Backend Test for Conflict Detection

**Files:**
- Create: `backend/tests/conflict.test.js`

**Step 1: Write conflict test**

```javascript
const request = require('supertest');
const app = require('../src/app');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

let authToken;
let profileId;
let profileUpdatedAt;

describe('Optimistic Locking / Conflict Detection', () => {
  beforeAll(async () => {
    // Login as patient
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: '3275000000000003', password: 'patient123' });
    authToken = loginRes.body.data.token;

    // Create a profile
    const profileRes = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Test Profile',
        nik: '1234567890123456',
        gender: 'pria',
        birthDate: '1990-01-01T00:00:00Z',
      });
    profileId = profileRes.body.data.id;
    profileUpdatedAt = profileRes.body.data.updatedAt;
  });

  test('PUT /profiles/:id without updatedAt returns 400', async () => {
    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'New Name' });

    expect(res.statusCode).toBe(400);
    expect(res.body.error.code).toBe('MISSING_UPDATED_AT');
  });

  test('PUT /profiles/:id with stale updatedAt returns 409 CONFLICT', async () => {
    // First, update the profile on the server
    await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Server Updated Name',
        updatedAt: profileUpdatedAt,
      });

    // Now try to update with the old updatedAt
    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Client Stale Name',
        updatedAt: profileUpdatedAt,
      });

    expect(res.statusCode).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
    expect(res.body.data).toBeDefined();
    expect(res.body.data.name).toBe('Server Updated Name');
  });

  test('PUT /profiles/:id with current updatedAt succeeds', async () => {
    // Fetch current state
    const getRes = await request(app)
      .get(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);

    const currentUpdatedAt = getRes.body.data.updatedAt;

    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Final Name',
        updatedAt: currentUpdatedAt,
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.name).toBe('Final Name');
  });
});
```

**Step 2: Run the test**

```bash
cd backend
npm test -- tests/conflict.test.js
```

Expected: All tests pass.

**Step 3: Commit**

```bash
git add backend/tests/conflict.test.js
git commit -m "test: add optimistic locking conflict detection tests"
```

---

## Task 17: Update Prisma Seed Script to Include updatedAt

**Files:**
- Modify: `backend/prisma/seed.js`

**Step 1: Ensure seed data doesn't break with new required fields**

Since `@updatedAt` fields are auto-populated by Prisma on creation, existing seed data should be fine. However, verify by running:

```bash
cd backend
node prisma/seed.js
```

Expected: Seed completes successfully with all tables populated.

**Step 2: Commit (if any changes needed)**

---

## Task 18: Update Documentation

**Files:**
- Modify: `backend/README.md` (API section)
- Modify: `AGENTS.md` (if exists)

**Step 1: Add conflict detection note to backend README**

In the API Endpoints section, add:

```markdown
### Conflict Detection

All `PUT` and `DELETE` endpoints now require an `updatedAt` field in the request body.
This enables optimistic locking — if the record was modified by another user since you last fetched it,
the server returns HTTP `409 CONFLICT` with the current server data.

Example conflict response:
```json
{
  "success": false,
  "error": {
    "code": "CONFLICT",
    "message": "This record was modified by another user or device. Please review the current version."
  },
  "data": { /* current server record */ }
}
```
```

**Step 2: Commit**

```bash
git add backend/README.md
git commit -m "docs: document optimistic locking and 409 conflict responses"
```

---

## Task 19: Final Integration Test

**Step 1: Restart backend and run full test suite**

```bash
cd backend
npm test
```

Expected: All tests pass (existing + new conflict tests).

**Step 2: Verify Flutter app compiles**

```bash
flutter analyze
```

Expected: No errors related to new code.

**Step 3: Commit any fixes**

---

## Task 20: Mark Plan Complete

Update this plan document with completion status.

---

## Post-Implementation Notes (For User)

### ✅ What Was Fixed
- All mutable backend endpoints now have optimistic locking via `updatedAt`
- Frontend models include `updatedAt` and send it with every update/delete
- 409 CONFLICT responses are intercepted and thrown as `SyncConflictException`
- Conflict resolution dialog allows users to choose: Use Server / Overwrite / Cancel

### 🔮 Recommended Follow-Up (Out of Scope for This Plan)

1. **Broader Offline Support:** Currently only `ProfileService` caches data locally when offline. Consider adding the same fallback pattern to:
   - `AppointmentService` (patients create/manage appointments)
   - `ArticleService` (admins draft articles offline)
   - `ScreeningService` (admins might need to queue screenings in rural areas with poor connectivity)

2. **Auto-Sync on Reconnect:** The `CacheService.processSyncQueue()` exists but is never automatically called when connectivity returns. Consider:
   - Listening to `Connectivity().onConnectivityChanged` stream
   - Automatically calling `processSyncQueue()` when coming back online
   - Showing a "Syncing..." indicator in the UI

3. **Conflict Resolution Improvements:**
   - Add a "Merge" option for fields that don't conflict (e.g., name changed on server, phone changed on client)
   - Store conflict history so users can review past conflicts
   - Add admin-level conflict audit log

4. **Real-Time Sync (Advanced):**
   - WebSockets or Server-Sent Events for real-time updates
   - Push notifications when another device modifies shared data
   - This is overkill for MVP but worth considering for production

---

**Plan complete and saved to `docs/plans/2026-05-03-conflict-detection-implementation.md`.**

**Two execution options:**

1. **Subagent-Driven (this session)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

2. **Parallel Session (separate)** — Open a new session with `executing-plans` skill, batch execution with checkpoints.

**Which approach would you prefer?**
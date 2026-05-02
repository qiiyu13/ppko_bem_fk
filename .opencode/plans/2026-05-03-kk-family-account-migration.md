# KK-Based Family Account Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate from individual NIK-based accounts to KK (Kartu Keluarga)-based family accounts where users register with a family card number and manually create profiles for each family member including themselves.

**Architecture:** User model becomes a family account container (KK number + password + phone + responsible name). FamilyProfile model remains unchanged with individual NIK per person. Registration creates User only — users must manually create their own profile via POST /profiles with their NIK.

**Tech Stack:** Express.js, Prisma ORM, PostgreSQL, JWT, bcrypt, Jest + Supertest

**Design Doc:** `docs/plans/YYYY-MM-DD-kk-family-account-design.md`

---

### Task 1: Update Database Schema (User Model)

**Files:**
- Modify: `backend/prisma/schema.prisma` (User model)
- Test: `npm test` (verify tests fail after schema change)

**Step 1: Update User model in schema**

Replace the entire User model in `backend/prisma/schema.prisma`:

```prisma
model User {
  id              String   @id @default(uuid())
  kkNumber        String   @unique @map("kk_number")
  password        String
  phone           String?
  responsibleName String   @map("responsible_name")
  role            Role     @default(PATIENT)
  isActive        Boolean  @default(true) @map("is_active")
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")

  familyProfiles  FamilyProfile[]
  screenings      MedicalScreening[] @relation("Screener")
  createdArticles Article[]          @relation("Author")
  appointments    Appointment[]
  conversations   ChatConversation[]

  @@map("users")
}
```

**Changes:**
- Remove: `nik`, `gender`, `birthDate`, `bloodType`, `address`
- Add: `kkNumber` (unique), `responsibleName`
- Keep: `phone`, `password`, `role`, `isActive`, `createdAt`, `updatedAt`, all relations

**Step 2: Create and apply migration**

Run:
```bash
cd backend
npx prisma migrate dev --name kk_family_account
```
Expected: Migration created and applied successfully

**Step 3: Regenerate Prisma client**

Run:
```bash
npx prisma generate
```
Expected: Prisma Client generated

**Step 4: Verify tests fail (expected)**

Run:
```bash
npm test
```
Expected: Auth tests FAIL because auth module still uses old `nik` field

---

### Task 2: Update Auth Module

**Files:**
- Modify: `backend/src/modules/auth/auth.service.js`
- Modify: `backend/src/modules/auth/auth.controller.js`
- Modify: `backend/src/modules/auth/auth.routes.js`

**Step 1: Update auth.service.js**

Replace entire file with:

```js
const { PrismaClient } = require('@prisma/client');
const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');

const prisma = new PrismaClient();

const register = async ({ kkNumber, responsibleName, password, phone }) => {
  const existing = await prisma.user.findUnique({ where: { kkNumber } });
  if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });

  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { kkNumber, responsibleName, password: hashedPassword, phone },
    select: { id: true, kkNumber: true, responsibleName: true, role: true },
  });

  const token = generateToken({ userId: user.id, role: user.role });
  return { user, token };
};

const login = async ({ kkNumber, password }) => {
  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const valid = await comparePassword(password, user.password);
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const token = generateToken({ userId: user.id, role: user.role });
  return {
    user: { id: user.id, kkNumber: user.kkNumber, responsibleName: user.responsibleName, role: user.role },
    token,
  };
};

const getMe = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, kkNumber: true, responsibleName: true, phone: true, role: true },
  });
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return user;
};

module.exports = { register, login, getMe };
```

**Step 2: Update auth.controller.js**

Replace entire file with:

```js
const authService = require('./auth.service');
const { success, error } = require('../../utils/response');

const register = async (req, res, next) => {
  try {
    const result = await authService.register(req.body);
    return success(res, result, 'Registration successful', 201);
  } catch (err) {
    if (err.code === 'P2002') return error(res, 'KK number already registered', 409, 'CONFLICT');
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.login(req.body);
    return success(res, result, 'Login successful');
  } catch (err) {
    if (err.message === 'Invalid credentials') return error(res, 'Invalid KK number or password', 401, 'INVALID_CREDENTIALS');
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    const user = await authService.getMe(req.user.id);
    return success(res, user);
  } catch (err) {
    next(err);
  }
};

module.exports = { register, login, getMe };
```

**Step 3: Update auth.routes.js**

Replace entire file with:

```js
const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./auth.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.post('/register', [
  body('kkNumber').isString().matches(/^\d{16}$/).withMessage('KK number must be 16 digits'),
  body('responsibleName').isString().notEmpty(),
  body('password').isString().isLength({ min: 6 }),
  validate,
], controller.register);

router.post('/login', [
  body('kkNumber').isString().notEmpty(),
  body('password').isString().notEmpty(),
  validate,
], controller.login);

router.get('/me', authenticate, controller.getMe);

module.exports = router;
```

**Changes:**
- `nik` → `kkNumber` in all endpoints
- Registration requires: `kkNumber` (16 digits), `responsibleName`, `password`, `phone` (optional)
- Login requires: `kkNumber`, `password`
- Validation: KK number must be exactly 16 digits

---

### Task 3: Update Auth Tests

**Files:**
- Modify: `backend/tests/auth.test.js`

**Step 1: Update auth.test.js**

Replace entire file with:

```js
const request = require('supertest');
const app = require('../src/app');

let authToken;
const testKK = '3275' + Date.now().toString().slice(-7) + '0001'.slice(0, 4);

describe('Auth Endpoints', () => {
  afterAll(async () => {
    // Cleanup: no DB cleanup needed for integration tests
  });

  it('should register a new family account', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKK, responsibleName: 'Pak Budi', password: 'test123', phone: '08123456789' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.role).toBe('PATIENT');
    expect(res.body.data.user.kkNumber).toBe(testKK);
  });

  it('should reject duplicate KK number', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKK, responsibleName: 'Pak Budi 2', password: 'test123' });
    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  it('should reject invalid KK number format', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: '123', responsibleName: 'Test', password: 'test123' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should login with valid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKK, password: 'test123' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    authToken = res.body.data.token;
  });

  it('should reject invalid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKK, password: 'wrongpassword' });
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('should get current user with token', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.kkNumber).toBe(testKK);
  });

  it('should reject /me without token', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('should reject /me with invalid token', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer invalidtoken');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('INVALID_TOKEN');
  });
});
```

**Step 2: Run auth tests**

Run:
```bash
npm test -- tests/auth.test.js
```
Expected: All 8 tests PASS

---

### Task 4: Update Seed Script

**Files:**
- Modify: `backend/prisma/seed.js`

**Step 1: Update seed.js**

Replace the entire file with:

```js
const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');
const { calculateIrd } = require('../src/utils/ird');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...\n');

  // Clean existing data (respect FK order)
  await prisma.chatMessage.deleteMany();
  await prisma.chatConversation.deleteMany();
  await prisma.healthMetric.deleteMany();
  await prisma.medicalScreening.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.familyProfile.deleteMany();
  await prisma.article.deleteMany();
  await prisma.resident.deleteMany();
  await prisma.region.deleteMany();
  await prisma.user.deleteMany();

  console.log('✅ Cleaned existing data');

  // ─── Users (Family Accounts) ───
  const superadmin = await prisma.user.create({
    data: {
      id: 'superadmin-001',
      kkNumber: '3275000000000001',
      responsibleName: 'Super Admin',
      password: await hashPassword('superadmin123'),
      role: 'SUPERADMIN',
      phone: '08123456789',
    },
  });

  const admin = await prisma.user.create({
    data: {
      id: 'admin-001',
      kkNumber: '3275000000000002',
      responsibleName: 'Admin User',
      password: await hashPassword('admin123'),
      role: 'ADMIN',
      phone: '08123456780',
    },
  });

  const patient = await prisma.user.create({
    data: {
      id: 'patient-001',
      kkNumber: '3275000000000003',
      responsibleName: 'Keluarga Budi',
      password: await hashPassword('patient123'),
      role: 'PATIENT',
      phone: '08123456781',
    },
  });

  console.log('✅ Created family accounts: SUPERADMIN, ADMIN, PATIENT');

  // ─── Family Profiles ───
  const profile1 = await prisma.familyProfile.create({
    data: {
      id: 'profile-001',
      userId: patient.id,
      name: 'Budi Santoso',
      nik: '12131415',
      gender: 'pria',
      birthDate: new Date('1990-01-01'),
      height: 170,
      weight: 75,
      bloodType: 'O',
      phone: '08123456781',
    },
  });

  const profile2 = await prisma.familyProfile.create({
    data: {
      id: 'profile-002',
      userId: patient.id,
      name: 'Siti Aminah',
      nik: '12131416',
      gender: 'wanita',
      birthDate: new Date('1988-05-15'),
      height: 160,
      weight: 65,
      bloodType: 'A',
      phone: '08123456782',
    },
  });

  const profile3 = await prisma.familyProfile.create({
    data: {
      id: 'profile-003',
      userId: patient.id,
      name: 'Dewi Lestari',
      nik: '12131417',
      gender: 'wanita',
      birthDate: new Date('1985-10-20'),
      height: 165,
      weight: 60,
      bloodType: 'B',
      phone: '08123456783',
    },
  });

  console.log('✅ Created 3 family profiles');

  // ─── Health Metrics ───
  await prisma.healthMetric.createMany({
    data: [
      { profileId: profile1.id, type: 'blood_pressure', value: 120, secondaryValue: 80, unit: 'mmHg', notes: 'Normal', recordedAt: new Date('2026-04-01') },
      { profileId: profile1.id, type: 'blood_pressure', value: 130, secondaryValue: 85, unit: 'mmHg', notes: 'Slightly elevated', recordedAt: new Date('2026-04-15') },
      { profileId: profile1.id, type: 'blood_sugar', value: 110, unit: 'mg/dL', recordedAt: new Date('2026-04-01') },
      { profileId: profile1.id, type: 'cholesterol', value: 200, unit: 'mg/dL', recordedAt: new Date('2026-04-01') },
      { profileId: profile2.id, type: 'blood_pressure', value: 115, secondaryValue: 75, unit: 'mmHg', recordedAt: new Date('2026-04-10') },
    ],
  });

  console.log('✅ Created health metrics');

  // ─── Medical Screenings with IRD ───
  const screeningData1 = {
    bloodSugar: 180, systolic: 130, diastolic: 85,
    cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
  };
  const ird1 = calculateIrd(screeningData1);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile1.id,
      screenedBy: admin.id,
      systolic: 130, diastolic: 85,
      bloodSugar: 180, cholesterol: 220, uricAcid: 6.5,
      height: 170, weight: 75,
      irdScore: ird1.irdScore,
      irdCategory: ird1.irdCategory,
      notes: 'Pemeriksaan rutin April 2026',
      screeningAt: new Date('2026-04-15'),
    },
  });

  const screeningData2 = {
    bloodSugar: 120, systolic: 110, diastolic: 70,
    cholesterol: 180, uricAcid: 4.5, height: 160, weight: 55, gender: 'wanita',
  };
  const ird2 = calculateIrd(screeningData2);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile2.id,
      screenedBy: admin.id,
      systolic: 110, diastolic: 70,
      bloodSugar: 120, cholesterol: 180, uricAcid: 4.5,
      height: 160, weight: 55,
      irdScore: ird2.irdScore,
      irdCategory: ird2.irdCategory,
      notes: 'Pemeriksaan wanita sehat',
      screeningAt: new Date('2026-04-20'),
    },
  });

  const screeningData3 = {
    bloodSugar: 250, systolic: 150, diastolic: 95,
    cholesterol: 280, uricAcid: 8.0, height: 165, weight: 90, gender: 'wanita',
  };
  const ird3 = calculateIrd(screeningData3);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile3.id,
      screenedBy: superadmin.id,
      systolic: 150, diastolic: 95,
      bloodSugar: 250, cholesterol: 280, uricAcid: 8.0,
      height: 165, weight: 90,
      irdScore: ird3.irdScore,
      irdCategory: ird3.irdCategory,
      notes: 'Risiko tinggi, perlu kontrol',
      screeningAt: new Date('2026-04-25'),
    },
  });

  console.log(`✅ Created 3 screenings with IRD:`);
  console.log(`   - ${profile1.name}: ${ird1.irdScore} (${ird1.irdCategory})`);
  console.log(`   - ${profile2.name}: ${ird2.irdScore} (${ird2.irdCategory})`);
  console.log(`   - ${profile3.name}: ${ird3.irdScore} (${ird3.irdCategory})`);

  // ─── Articles ───
  await prisma.article.create({
    data: {
      id: 'article-001',
      authorId: admin.id,
      title: 'Mengenal Diabetes Mellitus',
      content: 'Diabetes mellitus adalah penyakit kronis yang ditandai dengan peningkatan kadar gula darah...',
      tags: ['diabetes', 'kesehatan'],
      isPublished: true,
      isDraft: false,
      publishDate: new Date('2026-04-01'),
    },
  });

  await prisma.article.create({
    data: {
      id: 'article-002',
      authorId: admin.id,
      title: 'Tips Pola Hidup Sehat',
      content: 'Pola hidup sehat dimulai dari makanan bergizi, olahraga teratur, dan istirahat cukup...',
      tags: ['gaya hidup', 'tips'],
      isPublished: true,
      isDraft: false,
      publishDate: new Date('2026-04-10'),
    },
  });

  await prisma.article.create({
    data: {
      id: 'article-003',
      authorId: superadmin.id,
      title: 'Manfaat Tanaman Obat Keluarga (TOGA)',
      content: 'Daun sirsak, jahe, dan kunyit memiliki banyak manfaat untuk kesehatan...',
      tags: ['toga', 'herbal'],
      isPublished: false,
      isDraft: true,
    },
  });

  console.log('✅ Created 3 articles (2 published, 1 draft)');

  // ─── Regions ───
  const rw = await prisma.region.create({
    data: { id: 'region-001', type: 'RW', name: 'RW 05' },
  });

  const rt = await prisma.region.create({
    data: { id: 'region-002', type: 'RT', name: 'RT 02', parentId: rw.id },
  });

  console.log('✅ Created RW/RT structure');

  // ─── Residents ───
  await prisma.resident.create({
    data: {
      regionId: rt.id,
      name: 'Pak Budi',
      nik: '1111222233334444',
      gender: 'pria',
      birthDate: new Date('1970-01-01'),
      phone: '08111111111',
      address: 'Jl. Melati No. 5',
    },
  });

  await prisma.resident.create({
    data: {
      regionId: rt.id,
      name: 'Ibu Ani',
      nik: '5555666677778888',
      gender: 'wanita',
      birthDate: new Date('1975-05-10'),
      phone: '08222222222',
      address: 'Jl. Melati No. 7',
    },
  });

  console.log('✅ Created 2 residents');

  // ─── Appointments ───
  await prisma.appointment.create({
    data: {
      userId: patient.id,
      title: 'Pemeriksaan Gula Darah',
      date: new Date('2026-05-15T09:00:00Z'),
      location: 'Puskesmas Sehat',
      type: 'SCREENING',
    },
  });

  console.log('✅ Created 1 appointment');

  console.log('\n🎉 Seed completed successfully!');
  console.log('\nLogin credentials:');
  console.log('  SUPERADMIN: KK=3275000000000001, password=superadmin123');
  console.log('  ADMIN:      KK=3275000000000002, password=admin123');
  console.log('  PATIENT:    KK=3275000000000003, password=patient123');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

**Step 2: Run seed script**

Run:
```bash
node prisma/seed.js
```
Expected: All seed steps complete with new KK-based credentials

---

### Task 5: Update Documentation

**Files:**
- Modify: `backend/docs/LOCAL_TESTING.md`
- Modify: `backend/docs/DEPLOYMENT.md`
- Modify: `backend/README.md`

**Step 1: Update LOCAL_TESTING.md**

Replace the "Default Login Credentials" section with:

```markdown
### Default Login Credentials

| Role | KK Number | Password |
|------|-----------|----------|
| SUPERADMIN | `3275000000000001` | `superadmin123` |
| ADMIN | `3275000000000002` | `admin123` |
| PATIENT | `3275000000000003` | `patient123` |
```

Replace the "Test Authentication Flow" section with:

```bash
### Register

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275123456789012","responsibleName":"Keluarga Budi","password":"password123","phone":"08123456789"}'
```

### Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275000000000003","password":"patient123"}'
```
```

**Step 2: Update DEPLOYMENT.md**

Replace the "Test Authentication" section with:

```bash
# Login as admin
curl -X POST https://api.mediku.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275000000000002","password":"admin123"}'
```

Replace the "Security Checklist" section with:

```markdown
- [ ] Remove test accounts or change default passwords (3275000000000001, 3275000000000002, 3275000000000003)
```

**Step 3: Update README.md**

Replace the "Default Credentials" section with:

```markdown
| Role | KK Number | Password |
|------|-----------|----------|
| SUPERADMIN | `3275000000000001` | `superadmin123` |
| ADMIN | `3275000000000002` | `admin123` |
| PATIENT | `3275000000000003` | `patient123` |
```

---

### Task 6: Run Full Test Suite

**Files:**
- Test: All test files

**Step 1: Run all tests**

Run:
```bash
npm test
```
Expected: All 26 tests PASS (4 test suites)

**Step 2: Verify server starts**

Run:
```bash
timeout 5 node src/index.js &
sleep 2
curl http://localhost:3000/api/v1/health
```
Expected: `{"success": true, "message": "OK", ...}`

---

### Task 7: Manual End-to-End Test

**Step 1: Test registration with KK**

Run:
```bash
# Register new family account
REGISTER=$(curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275999999999999","responsibleName":"Test Family","password":"test123","phone":"08123456789"}')
echo "$REGISTER" | python3 -m json.tool
```
Expected: 201, returns user + token

**Step 2: Login with KK**

Run:
```bash
LOGIN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275999999999999","password":"test123"}')
TOKEN=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
echo "$LOGIN" | python3 -m json.tool
```
Expected: 200, returns user + token

**Step 3: Verify /me returns KK data**

Run:
```bash
curl -s http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: Returns `kkNumber`, `responsibleName`, `phone` (no `nik`)

**Step 4: Create own profile (requires NIK)**

Run:
```bash
PROFILE=$(curl -s -X POST http://localhost:3000/api/v1/profiles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","nik":"1234567890123456","gender":"pria","birthDate":"1990-01-01","height":170,"weight":75}')
echo "$PROFILE" | python3 -m json.tool
PROFILE_ID=$(echo "$PROFILE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
```
Expected: 201, profile created with NIK

**Step 5: Add family member**

Run:
```bash
curl -s -X POST http://localhost:3000/api/v1/profiles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Siti Aminah","nik":"6543210987654321","gender":"wanita","birthDate":"1992-05-15","height":160,"weight":55}' | python3 -m json.tool
```
Expected: 201, second profile created

**Step 6: List profiles**

Run:
```bash
curl -s http://localhost:3000/api/v1/profiles \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: 2 profiles returned

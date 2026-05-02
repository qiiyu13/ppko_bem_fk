# MEDIKU Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a production-ready Express.js REST API backend with PostgreSQL to replace local SQLite/mock data in the MEDIKU Flutter app.

**Architecture:** Modular monolith with feature-based modules (auth, profiles, metrics, screenings, appointments, articles, admin, regions). Express.js with layered pattern: routes -> controller -> service -> Prisma ORM -> PostgreSQL. JWT-based authentication with role-based access control (patient, admin, superadmin).

**Tech Stack:** Express.js, Prisma ORM, PostgreSQL, JWT (jsonwebtoken), bcrypt, express-validator, Jest + Supertest

**Infrastructure:** Hetzner CX22 (€3.99/bulan) + Coolify (open-source PaaS)

**Design Doc:** `.opencode/plans/2026-05-01-mediku-backend-design.md`

---

### Task 0: Server provisioning & Coolify setup

**Do this once, at the start.**

**Step 1: Order Hetzner CX22**
- Sign up at hetzner.com
- Order CX22: 2 vCPU, 4GB RAM, 40GB SSD, €3.99/month
- Choose Singapore or Finland location
- Add your SSH public key
- Note the server IP

**Step 2: Initial server setup**

SSH in:
```bash
ssh root@<server-ip>
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin
ufw allow 22 && ufw allow 80 && ufw allow 443 && ufw allow 3000
ufw enable
```

**Step 3: Install Coolify**

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

After install, open `http://<server-ip>:8000` in browser, create admin account.

**Step 4: Configure Coolify**
- In Coolify dashboard → **Servers** → add localhost server (it auto-detects Docker)
- In **Sources** → connect GitHub account → select `mediku-backend` repo
- In **Databases** → click **Add database** → choose **PostgreSQL 16** → give it a name like `mediku-db`
- Once created, Coolify shows the **internal connection URL** — save it for later
- In **Resources** → add new resource → choose your GitHub repo → set:
  - Build pack: `Dockerfile` (we'll create it later)
  - Port: `3000`
  - Environment variables: add `DATABASE_URL`, `JWT_SECRET`, `NODE_ENV=production`
- Coolify auto-generates SSL via Let's Encrypt

**Step 5: (Later, after code is ready)** Create a Dockerfile:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY prisma/ ./prisma/
RUN npx prisma generate
COPY src/ ./src/
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node src/index.js"]
```

Push code to GitHub → Coolify auto-deploys.

---

### Task 1: Project scaffolding & dependencies

**Files:**
- Create: `mediku-backend/package.json`
- Create: `mediku-backend/.env.example`
- Create: `mediku-backend/.env`
- Create: `mediku-backend/src/index.js`
- Create: `mediku-backend/src/config/index.js`
- Create: `mediku-backend/src/routes/index.js`

**Step 1: Initialize project**

Run: `mkdir -p mediku-backend && cd mediku-backend && npm init -y`

**Step 2: Install dependencies**

Run:
```bash
npm install express cors helmet express-rate-limit morgan dotenv
npm install @prisma/client jsonwebtoken bcryptjs express-validator uuid
npm install -D prisma nodemon jest supertest
```

**Step 3: Create package.json scripts**

```json
{
  "scripts": {
    "dev": "nodemon src/index.js",
    "start": "node src/index.js",
    "test": "jest --forceExit --detectOpenHandles",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:seed": "node prisma/seed.js"
  }
}
```

**Step 4: Create .env.example**

```
PORT=3000
DATABASE_URL="postgresql://user:password@localhost:5432/mediku"
JWT_SECRET="change-this-to-random-string"
JWT_EXPIRES_IN="7d"
CORS_ORIGIN="*"
NODE_ENV=development
```

**Step 5: Create src/config/index.js**

```js
require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  nodeEnv: process.env.NODE_ENV || 'development',
};
```

**Step 6: Create src/index.js**

```js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const config = require('./config');
const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');
const notFound = require('./middleware/notFound');

const app = express();

// Security
app.use(helmet());
app.use(cors({ origin: config.corsOrigin }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
}

// Routes
app.use('/api/v1', routes);

// Error handling
app.use(notFound);
app.use(errorHandler);

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
});

module.exports = app;
```

**Step 7: Create src/routes/index.js**

```js
const router = require('express').Router();

// Health check
router.get('/health', (req, res) => {
  res.json({ success: true, message: 'OK', timestamp: new Date().toISOString() });
});

// Mount modules
router.use('/auth', require('../modules/auth/auth.routes'));

module.exports = router;
```

**Step 8: Create Dockerfile** (for Coolify deployment)

Create `mediku-backend/Dockerfile`:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY prisma/ ./prisma/
RUN npx prisma generate
COPY src/ ./src/
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node src/index.js"]
```

**Step 9: Create .dockerignore**

```
node_modules/
.git/
.env
tests/
```

**Step 10: Verify server starts**

Run: `node src/index.js`
Expected: "Server running on port 3000"

---

### Task 2: Database schema with Prisma

**Files:**
- Create: `mediku-backend/prisma/schema.prisma`
- Create: `mediku-backend/prisma/seed.js`
- Create: `mediku-backend/.gitignore`

**Step 1: Create .gitignore**

```
node_modules/
.env
```

**Step 2: Create prisma/schema.prisma**

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  PATIENT
  ADMIN
  SUPERADMIN
}

model User {
  id        String   @id @default(uuid())
  nik       String   @unique
  name      String
  password  String
  gender    String?
  birthDate DateTime? @map("birth_date")
  bloodType String?   @map("blood_type")
  address   String?
  phone     String?
  role      Role     @default(PATIENT)
  isActive  Boolean  @default(true) @map("is_active")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  familyProfiles  FamilyProfile[]
  screenings      MedicalScreening[] @relation("Screener")
  createdArticles Article[]          @relation("Author")
  appointments    Appointment[]
  conversations   ChatConversation[]

  @@map("users")
}

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

  user    User              @relation(fields: [userId], references: [id])
  metrics HealthMetric[]

  @@map("family_profiles")
}

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

  profile FamilyProfile @relation(fields: [profileId], references: [id])

  @@map("health_metrics")
}

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

  profile  FamilyProfile @relation("PatientProfile", fields: [profileId], references: [id])
  screener User          @relation("Screener", fields: [screenedBy], references: [id])

  @@map("medical_screenings")
}

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

  user    User           @relation(fields: [userId], references: [id])

  @@map("appointments")
}

model Article {
  id          String    @id @default(uuid())
  authorId    String    @map("author_id")
  title       String
  content     String
  imagePath   String?   @map("image_path")
  tags        String[]
  isPublished Boolean   @default(false) @map("is_published")
  isDraft     Boolean   @default(true) @map("is_draft")
  publishDate DateTime? @map("publish_date")
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @updatedAt @map("updated_at")

  author User @relation("Author", fields: [authorId], references: [id])

  @@map("articles")
}

model Region {
  id        String   @id @default(uuid())
  type      String
  name      String
  parentId  String?  @map("parent_id")
  createdAt DateTime @default(now()) @map("created_at")

  parent    Region?    @relation("RegionHierarchy", fields: [parentId], references: [id])
  children  Region[]   @relation("RegionHierarchy")
  residents Resident[]

  @@map("regions")
}

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

  region Region @relation(fields: [regionId], references: [id])

  @@map("residents")
}

model ChatConversation {
  id             String   @id @default(uuid())
  userId         String   @map("user_id")
  startedAt      DateTime @default(now()) @map("started_at")
  lastActivityAt DateTime @updatedAt @map("last_activity_at")

  user     User          @relation(fields: [userId], references: [id])
  messages ChatMessage[]

  @@map("chat_conversations")
}

model ChatMessage {
  id             String   @id @default(uuid())
  conversationId String   @map("conversation_id")
  content        String
  role           String
  createdAt      DateTime @default(now()) @map("created_at")

  conversation ChatConversation @relation(fields: [conversationId], references: [id])

  @@map("chat_messages")
}
```

**Step 3: Run migration**

Run: `npx prisma migrate dev --name init`
Expected: Migration created and applied

---

### Task 3: Utility modules & middleware

**Files:**
- Create: `mediku-backend/src/utils/response.js`
- Create: `mediku-backend/src/utils/jwt.js`
- Create: `mediku-backend/src/utils/password.js`
- Create: `mediku-backend/src/utils/ird.js`
- Create: `mediku-backend/src/middleware/auth.js`
- Create: `mediku-backend/src/middleware/roleGuard.js`
- Create: `mediku-backend/src/middleware/validate.js`
- Create: `mediku-backend/src/middleware/errorHandler.js`
- Create: `mediku-backend/src/middleware/notFound.js`

**Step 1: Create src/utils/response.js**

```js
const success = (res, data = null, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({ success: true, data, message });
};

const error = (res, message = 'Internal Server Error', statusCode = 500, code = 'INTERNAL_ERROR') => {
  return res.status(statusCode).json({ success: false, error: { code, message } });
};

const paginated = (res, data, total, page, limit) => {
  return res.status(200).json({
    success: true,
    data,
    meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
  });
};

module.exports = { success, error, paginated };
```

**Step 2: Create src/utils/jwt.js**

```js
const jwt = require('jsonwebtoken');
const config = require('../config');

const generateToken = (payload) => {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
};

const verifyToken = (token) => {
  return jwt.verify(token, config.jwtSecret);
};

module.exports = { generateToken, verifyToken };
```

**Step 3: Create src/utils/password.js**

```js
const bcrypt = require('bcryptjs');

const hashPassword = async (password) => {
  return bcrypt.hash(password, 12);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

module.exports = { hashPassword, comparePassword };
```

**Step 3.5: Create src/utils/ird.js**

IRD (Index Risk Diabetes) is calculated from screening vitals. This utility must match the Flutter app's formula exactly.

```js
const calculateIrdScore = ({ bloodSugar, systolic, diastolic, cholesterol, uricAcid, height, weight, gender }) => {
  const bmi = weight / ((height / 100) ** 2);
  const auDenominator = gender.toLowerCase() === 'pria' ? 7.0 : 6.0;

  const gdsComponent = 0.3 * (bloodSugar / 200);
  const bpComponent = 0.2 * ((systolic / 140 + diastolic / 90) / 2);
  const kolComponent = 0.2 * (cholesterol / 240);
  const auComponent = 0.15 * (uricAcid / auDenominator);
  const bmiComponent = 0.15 * (bmi / 25);

  return gdsComponent + bpComponent + kolComponent + auComponent + bmiComponent;
};

const getIrdCategory = (irdScore) => {
  if (irdScore < 0.75) return 'Rendah';
  if (irdScore <= 1.0) return 'Sedang';
  return 'Berat';
};

const calculateIrd = (params) => {
  const irdScore = calculateIrdScore(params);
  const irdCategory = getIrdCategory(irdScore);
  return { irdScore: Math.round(irdScore * 100) / 100, irdCategory };
};

module.exports = { calculateIrdScore, getIrdCategory, calculateIrd };
```

**Step 4: Create src/middleware/auth.js**

```js
const { verifyToken } = require('../utils/jwt');
const { error } = require('../utils/response');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Access token required', 401, 'UNAUTHORIZED');
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyToken(token);
    req.user = { id: decoded.userId, role: decoded.role };
    next();
  } catch (err) {
    return error(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
  }
};

module.exports = authenticate;
```

**Step 5: Create src/middleware/roleGuard.js**

```js
const { error } = require('../utils/response');

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return error(res, 'Forbidden: insufficient permissions', 403, 'FORBIDDEN');
    }
    next();
  };
};

module.exports = authorize;
```

**Step 6: Create src/middleware/errorHandler.js**

```js
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

  return error(res, err.message || 'Internal Server Error', 500, 'INTERNAL_ERROR');
};

module.exports = errorHandler;
```

**Step 7: Create src/middleware/notFound.js**

```js
const { error } = require('../utils/response');

const notFound = (req, res) => {
  return error(res, `Route ${req.originalUrl} not found`, 404, 'NOT_FOUND');
};

module.exports = notFound;
```

---

### Task 4: Auth module (login, register, me)

**Files:**
- Create: `mediku-backend/src/modules/auth/auth.routes.js`
- Create: `mediku-backend/src/modules/auth/auth.controller.js`
- Create: `mediku-backend/src/modules/auth/auth.service.js`
- Modify: `mediku-backend/src/routes/index.js`

**Step 1: Create auth.service.js**

```js
const { PrismaClient } = require('@prisma/client');
const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');

const prisma = new PrismaClient();

const register = async ({ nik, name, password, gender, birthDate, phone }) => {
  const existing = await prisma.user.findUnique({ where: { nik } });
  if (existing) throw Object.assign(new Error('NIK already registered'), { code: 'P2002' });

  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { nik, name, password: hashedPassword, gender, birthDate: birthDate ? new Date(birthDate) : null, phone },
    select: { id: true, nik: true, name: true, role: true },
  });

  const token = generateToken({ userId: user.id, role: user.role });
  return { user, token };
};

const login = async ({ nik, password }) => {
  const user = await prisma.user.findUnique({ where: { nik } });
  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const valid = await comparePassword(password, user.password);
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const token = generateToken({ userId: user.id, role: user.role });
  return {
    user: { id: user.id, nik: user.nik, name: user.name, role: user.role },
    token,
  };
};

const getMe = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, nik: true, name: true, gender: true, birthDate: true, bloodType: true, address: true, phone: true, role: true },
  });
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return user;
};

module.exports = { register, login, getMe };
```

**Step 2: Create auth.controller.js**

```js
const authService = require('./auth.service');
const { success, error } = require('../../utils/response');

const register = async (req, res, next) => {
  try {
    const result = await authService.register(req.body);
    return success(res, result, 'Registration successful', 201);
  } catch (err) {
    if (err.code === 'P2002') return error(res, 'NIK already registered', 409, 'CONFLICT');
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.login(req.body);
    return success(res, result, 'Login successful');
  } catch (err) {
    if (err.message === 'Invalid credentials') return error(res, 'Invalid NIK or password', 401, 'INVALID_CREDENTIALS');
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

**Step 3: Create auth.routes.js**

```js
const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./auth.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.post('/register', [
  body('nik').isString().isLength({ min: 8, max: 16 }),
  body('name').isString().notEmpty(),
  body('password').isString().isLength({ min: 6 }),
  validate,
], controller.register);

router.post('/login', [
  body('nik').isString().notEmpty(),
  body('password').isString().notEmpty(),
  validate,
], controller.login);

router.get('/me', authenticate, controller.getMe);

module.exports = router;
```

**Step 4: Update src/routes/index.js** to mount auth module.

**Step 5: Create basic validate middleware (src/middleware/validate.js)**

```js
const { validationResult } = require('express-validator');
const { error } = require('../utils/response');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return error(res, errors.array()[0].msg, 400, 'VALIDATION_ERROR');
  }
  next();
};

module.exports = validate;
```

---

### Task 5: Profiles module (CRUD for family profiles)

**Files:**
- Create: `mediku-backend/src/modules/profiles/profiles.routes.js`
- Create: `mediku-backend/src/modules/profiles/profiles.controller.js`
- Create: `mediku-backend/src/modules/profiles/profiles.service.js`

Follow the same pattern as auth module (service -> controller -> routes).

**Service methods:**
- `getProfiles(userId)` — list all profiles for user
- `getProfile(id, userId)` — single profile
- `createProfile(data, userId)` — create new family profile
- `updateProfile(id, data, userId)` — update profile
- `deleteProfile(id, userId)` — delete profile

---

### Task 6: Health Metrics module

**Files:**
- Create: `mediku-backend/src/modules/metrics/metrics.routes.js`
- Create: `mediku-backend/src/modules/metrics/metrics.controller.js`
- Create: `mediku-backend/src/modules/metrics/metrics.service.js`

**Service methods:**
- `getMetrics(profileId, userId)` — list all metrics for a profile
- `createMetric(data)` — add a reading
- `getHistory(profileId, type)` — time-series data for charts
- `getLatest(profileId)` — latest reading per metric type

---

### Task 7: Articles module (public + admin)

**Files:**
- Create: `mediku-backend/src/modules/articles/articles.routes.js`
- Create: `mediku-backend/src/modules/articles/articles.controller.js`
- Create: `mediku-backend/src/modules/articles/articles.service.js`

**Public endpoints:**
- `GET /articles` — only published, non-draft, non-deleted
- `GET /articles/:id` — single article

**Admin endpoints (authenticate + authorize(ADMIN, SUPERADMIN)):**
- `GET /admin/articles` — all articles
- `POST /admin/articles` — create article
- `PUT /admin/articles/:id` — update
- `DELETE /admin/articles/:id` — soft delete
- `PATCH /admin/articles/:id/publish` — toggle publish/draft

---

### Task 8: Appointment module

**Files:**
- Create: `mediku-backend/src/modules/appointments/appointments.routes.js`
- Create: `mediku-backend/src/modules/appointments/appointments.controller.js`
- Create: `mediku-backend/src/modules/appointments/appointments.service.js`

**Service methods:**
- `getAppointments(userId, profileId)` — with optional profile filter
- `createAppointment(data, userId)`
- `updateAppointment(id, data, userId)`
- `deleteAppointment(id, userId)`

---

### Task 9: Screening module (superadmin)

**Files:**
- Create: `mediku-backend/src/modules/screenings/screenings.routes.js`
- Create: `mediku-backend/src/modules/screenings/screenings.controller.js`
- Create: `mediku-backend/src/modules/screenings/screenings.service.js`

**Service methods:**
- `createScreening(data, userId)` — superadmin enters screening result, auto-calculates IRD score and category using `calculateIrd()` from `src/utils/ird.js`. Requires: bloodSugar, systolic, diastolic, cholesterol, uricAcid, and the profile's gender/height/weight (fetched from FamilyProfile).
- `getScreenings(profileId)` — screening history with IRD scores
- `getStats()` — dashboard statistics, includes aggregation by irdCategory

---

### Task 10: Admin dashboard module

**Files:**
- Create: `mediku-backend/src/modules/admin/admin.routes.js`
- Create: `mediku-backend/src/modules/admin/admin.controller.js`
- Create: `mediku-backend/src/modules/admin/admin.service.js`

**Service methods:**
- `getPatients(search, irdCategory, page, limit)` — paginated patient list with filters, supports filtering by irdCategory (Rendah/Sedang/Berat)
- `getPatientDetail(id)` — single patient with all metrics and latest IRD score

---

### Task 11: User management module (superadmin)

**Files:**
- Create: `mediku-backend/src/modules/admin/users.routes.js` (or extend admin module)

**Service methods:**
- `getUsers(role)` — list admin/nakes accounts
- `createUser(data)` — admin creates new admin/nakes
- `updateUser(id, data)`
- `deleteUser(id)`

---

### Task 12: Regions & Residents module (superadmin)

**Files:**
- Create: `mediku-backend/src/modules/regions/regions.routes.js`
- Create: `mediku-backend/src/modules/regions/regions.controller.js`
- Create: `mediku-backend/src/modules/regions/regions.service.js`

**Service methods:**
- `getRegions()` — list all RW/RT structure
- `createRegion(data)`
- `getResidents(regionId)`
- `createResident(data)`
- `updateResident(id, data)`

---

### Task 13: Chat module (basic storage, no AI)

**Files:**
- Create: `mediku-backend/src/modules/chat/chat.routes.js`
- Create: `mediku-backend/src/modules/chat/chat.controller.js`
- Create: `mediku-backend/src/modules/chat/chat.service.js`

**Service methods:**
- `getConversations(userId)` — list all conversations
- `createConversation(userId)` — start new
- `getMessages(conversationId, userId)` — get messages
- `sendMessage(conversationId, content, userId)` — save user message
- `deleteConversation(id, userId)` — delete

---

### Task 14: Seed script

**Create:** `mediku-backend/prisma/seed.js`

Seed with:
- 1 SUPERADMIN user (nik: SUPER456, password: superadmin123)
- 1 ADMIN user (nik: ADMIN123, password: admin123)
- 1 PATIENT user (nik: 12131415, password: patient123)
- 3 family profiles for patient (include height/weight for BMI/IRD calculation)
- 2-3 medical screenings with computed irdScore and irdCategory
- 2-3 published articles
- 2 regions (RW/RT structure)
- A few sample metrics

Run: `npx prisma db seed`

---

### Task 15: Tests & Deployment

**Sub-task 15a: Write tests**

**Files:**
- Create: `mediku-backend/tests/auth.test.js`
- Create: `mediku-backend/tests/profiles.test.js`
- Create: `mediku-backend/tests/metrics.test.js`
- Create: `mediku-backend/tests/ird.test.js`

**Test structure per module:**
- Happy path test (success case)
- Validation error test (missing fields)
- Auth error test (no token, wrong role)

**IRD utility tests (`tests/ird.test.js`):**
```js
const { calculateIrdScore, getIrdCategory, calculateIrd } = require('../src/utils/ird');

describe('IRD Calculation', () => {
  it('should calculate IRD score for male (pria)', () => {
    const result = calculateIrd({
      bloodSugar: 180, systolic: 130, diastolic: 85,
      cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
    });
    expect(result.irdScore).toBeDefined();
    expect(result.irdCategory).toBeDefined();
    expect(['Rendah', 'Sedang', 'Berat']).toContain(result.irdCategory);
  });

  it('should calculate IRD score for female (wanita)', () => {
    const result = calculateIrd({
      bloodSugar: 120, systolic: 110, diastolic: 70,
      cholesterol: 180, uricAcid: 4.5, height: 160, weight: 55, gender: 'wanita',
    });
    expect(result.irdScore).toBeLessThan(1.0);
    expect(result.irdCategory).toBe('Rendah');
  });

  it('should categorize IRD correctly', () => {
    expect(getIrdCategory(0.5)).toBe('Rendah');
    expect(getIrdCategory(0.85)).toBe('Sedang');
    expect(getIrdCategory(1.2)).toBe('Berat');
  });
});
```

**Sub-task 15b: Deploy to Coolify**

**Step 1: Push to GitHub**
```bash
cd mediku-backend
git init
git add .
git commit -m "feat: initial backend"
git remote add origin https://github.com/<username>/mediku-backend.git
git push -u origin main
```

**Step 2: Coolify auto-deploys**
- Coolify detects push, pulls code, builds Docker image, starts container
- Check logs in Coolify dashboard
- If migration fails, run manually: `npx prisma migrate deploy`

**Step 3: Run seed**
- In Coolify dashboard → **Exec** → run: `node prisma/seed.js`

**Step 4: Verify**
- Open `https://<domain>/api/v1/health`
- Expected: `{ "success": true, "message": "OK", "timestamp": "..." }`

**Step 5: Test login**
```bash
curl -X POST https://<domain>/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nik":"12131415","password":"patient123"}'
```
Expected: returns JWT token

Example test pattern (Jest + Supertest):
```js
const request = require('supertest');
const app = require('../src/index');

describe('Auth', () => {
  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ nik: '12345678', name: 'Test', password: 'test123' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
  });

  it('should reject duplicate NIK', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ nik: '12345678', name: 'Test', password: 'test123' });
    expect(res.status).toBe(409);
  });
});
```

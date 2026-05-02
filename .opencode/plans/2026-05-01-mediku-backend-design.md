# Design: MEDIKU Backend API

**Date:** 2026-05-01
**Status:** Draft

## Goal

Replace local SQLite/mock data with a production-ready REST API backend, enabling multi-device access, proper authentication, and centralized data management.

## Tech Stack

| Aspek | Pilihan |
|-------|---------|
| Framework | Express.js |
| Language | JavaScript |
| Database | PostgreSQL |
| ORM | Prisma |
| Auth | JWT + bcrypt |
| Validation | express-validator |
| Security | helmet, cors, rate-limit |
| Testing | Jest + Supertest |
| Deployment | Hetzner CX22 (€3.99/bulan) + Coolify |
| Deployment Approach | Coolify open-source PaaS on VPS — auto-deploy from GitHub, 1-click PostgreSQL, auto SSL |

## Architecture

```
mediku-backend/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── index.js
│   ├── config/
│   │   └── index.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── roleGuard.js
│   │   ├── validate.js
│   │   ├── errorHandler.js
│   │   └── notFound.js
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.js
│   │   │   ├── auth.controller.js
│   │   │   └── auth.service.js
│   │   ├── profiles/
│   │   │   ├── profiles.routes.js
│   │   │   ├── profiles.controller.js
│   │   │   └── profiles.service.js
│   │   ├── metrics/
│   │   │   ├── metrics.routes.js
│   │   │   ├── metrics.controller.js
│   │   │   └── metrics.service.js
│   │   ├── screenings/
│   │   ├── appointments/
│   │   ├── articles/
│   │   ├── admin/
│   │   ├── regions/
│   │   └── notifications/
│   ├── routes/
│   │   └── index.js
│   └── utils/
│       ├── jwt.js
│       ├── password.js
│       ├── ird.js
│       └── response.js
├── tests/
├── .env.example
├── package.json
└── README.md
```

## Database Schema

### Tables
- **users** — All accounts (patient, admin, superadmin) with role enum
- **family_profiles** — Multiple profiles per user (family members)
- **health_metrics** — Blood pressure, cholesterol, blood sugar, uric acid readings
- **medical_screenings** — Official screening data entered by admin/superadmin, includes auto-calculated IRD (Index Risk Diabetes) score and category
- **appointments** — Screening, follow-up, general appointments
- **articles** — TOGA articles with publish/draft status
- **regions** — RW/RT hierarchy
- **residents** — Residents registered per region (superadmin)
- **chat_conversations** — AI assistant conversation grouping
- **chat_messages** — Individual messages per conversation

### Key Relationships
- User 1:N FamilyProfile
- FamilyProfile 1:N HealthMetric
- FamilyProfile 1:N MedicalScreening
- User 1:N Appointment
- User 1:N Article (as author)
- Region 1:N Resident
- Region self-referencing (RT belongs to RW)
- ChatConversation 1:N ChatMessage

## IRD (Index Risk Diabetes) Calculation

The backend automatically calculates IRD when a medical screening is created. This replaces the generic `riskLevel` field with more precise, standardized scoring.

### Formula
```
IRD = 0.30 × (bloodSugar / 200)
    + 0.20 × ((systolic / 140 + diastolic / 90) / 2)
    + 0.20 × (cholesterol / 240)
    + 0.15 × (uricAcid / auDenominator)
    + 0.15 × (BMI / 25)

Where:
  - auDenominator = 7.0 for male (pria), 6.0 for female (wanita)
  - BMI = weight / (height_in_meters)²
```

### Categories
| IRD Score | Category     | Risk Level |
|-----------|-------------|------------|
| < 0.75    | Rendah       | Low        |
| 0.75–1.00 | Sedang       | Medium     |
| > 1.00    | Berat         | High       |

### Why on the backend?
- **Single source of truth** — admin dashboard can filter/sort by IRD category
- **Consistent reports** — all clients see the same score
- **Queryable** — `/admin/patients?irdCategory=Berat` works because IRD is stored in DB
- **Auditable** — score is persisted, not recomputed per request

## API Endpoints

All endpoints prefixed with `/api/v1`.

### Auth
```
POST   /api/v1/auth/login
POST   /api/v1/auth/register
GET    /api/v1/auth/me
```

### Profiles
```
GET    /api/v1/profiles
POST   /api/v1/profiles
PUT    /api/v1/profiles/:id
DELETE /api/v1/profiles/:id
```

### Health Metrics
```
GET    /api/v1/metrics?profileId=
POST   /api/v1/metrics
GET    /api/v1/metrics/:type/history
```

### Medical Screenings
```
POST   /api/v1/screenings
GET    /api/v1/screenings?profileId=
GET    /api/v1/screenings/stats
GET    /api/v1/screenings/:id
```

Note: `irdScore` and `irdCategory` are auto-calculated by the backend when creating a screening. The client sends raw values (bloodSugar, systolic, diastolic, cholesterol, uricAcid, height, weight, gender) and the backend returns the computed IRD.

### Appointments
```
GET    /api/v1/appointments
POST   /api/v1/appointments
PUT    /api/v1/appointments/:id
DELETE /api/v1/appointments/:id
```

### Articles (Public)
```
GET    /api/v1/articles
GET    /api/v1/articles/:id
```

### Articles (Admin)
```
GET    /api/v1/admin/articles
POST   /api/v1/admin/articles
PUT    /api/v1/admin/articles/:id
DELETE /api/v1/admin/articles/:id
PATCH  /api/v1/admin/articles/:id/publish
```

### Chat
```
GET    /api/v1/chat/conversations
POST   /api/v1/chat/conversations
POST   /api/v1/chat/conversations/:id/messages
DELETE /api/v1/chat/conversations/:id
```

### Admin Dashboard
```
GET    /api/v1/admin/patients?search=&irdCategory=&page=
GET    /api/v1/admin/patients/:id
```

### User Management (Superadmin)
```
GET    /api/v1/admin/users
POST   /api/v1/admin/users
PUT    /api/v1/admin/users/:id
DELETE /api/v1/admin/users/:id
```

### Regions & Residents (Superadmin)
```
GET    /api/v1/regions
POST   /api/v1/regions
GET    /api/v1/residents?regionId=
POST   /api/v1/residents
PUT    /api/v1/residents/:id
```

### Notifications
```
GET    /api/v1/notifications
PATCH  /api/v1/notifications/:id/read
```

## Authentication & Authorization

### Flow
1. Login -> verify NIK + bcrypt password -> generate JWT (payload: `{ userId, role }`)
2. Client stores JWT, sends as `Authorization: Bearer <token>`
3. Auth middleware verifies JWT, attaches `req.user`
4. Role guard middleware checks role permissions

### Middleware Chain
```
Request -> rateLimiter -> cors -> helmet -> auth -> roleGuard(roles) -> controller
```

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "NIK sudah terdaftar"
  }
}
```

## Infrastructure & Deployment

### Server: Hetzner CX22 (€3.99/bulan ≈ Rp70rb)
- 2 vCPU, 4GB RAM, 40GB SSD
- Located in Singapore/Europe (ping baik dari Indonesia)
- Kontrol penuh via SSH

### Coolify (PaaS Open-Source)
- Install di VPS sekali, akses via web dashboard
- **Auto-deploy** dari GitHub — push code, Coolify pull & restart
- **1-click PostgreSQL** — bikin database dari UI, URL langsung ke .env
- **Auto SSL** — Let's Encrypt otomatis
- **Logs viewer** — gak perlu SSH buat lihat error
- **Zero-downtime deployment** — traffic gak putus waktu restart

### Kenapa Coolify?
| Butuh | VPS aja | VPS + Coolify |
|-------|---------|---------------|
| Deploy code | git pull + pm2 restart di SSH | Push ke GitHub, otomatis |
| Setup DB | Install PostgreSQL manual, config | Klik "Add database" di UI |
| HTTPS | Setup Nginx + certbot manual | Auto dari dashboard |
| Monitoring | Setup sendiri | Built-in log viewer |
| Multi-service | Susah | 1 VPS bisa jalanin banyak project |

### Deployment Flow
1. Setup VPS (Hetzner) — SSH key, firewall, Docker
2. Install Coolify — 1 command: `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash`
3. Di dashboard Coolify:
   - Add PostgreSQL service → dapat connection URL
   - Connect GitHub repo → auto-deploy on push
   - Setup domain/SSL
4. `.env` di Coolify: tinggal isi DATABASE_URL, JWT_SECRET, dll

## AI Chat Integration (Postponed)
AI assistant feature (`Tanya mediku!`) will use an external provider (OpenAI/Gemini) integrated at a later phase.

## Testing
- **Jest** + **Supertest**
- Separate test database
- Happy path + error case per endpoint
- Auth middleware tests

## Migration Strategy (Future)
1. Backend development + seeding
2. Update Flutter app: replace `DatabaseHelper` with HTTP client
3. Update auth: replace hardcoded NIK/passcode with login API
4. Staged rollout per feature

# Local Development & Testing Guide

> **Quick start:** Get the backend running locally in under 2 minutes.

---

## Prerequisites

- **Node.js** 18+ (check with `node -v`)
- **Docker** & **Docker Compose** (for PostgreSQL)
- **npm** (comes with Node.js)

---

## 1. Install Dependencies

```bash
cd backend
npm install
```

---

## 2. Start PostgreSQL

A `docker-compose.yml` is provided at the project root.

```bash
# From the project root (ppko_bem_fk/)
docker-compose up -d
```

This starts PostgreSQL on port **5433** (to avoid conflicts with other local Postgres instances).

```bash
# Verify it's running
docker ps
```

You should see `mediku-postgres` in the list.

---

## 3. Environment Variables

The `.env` file is already configured for local development:

```env
PORT=3000
DATABASE_URL="postgresql://mediku:mediku_dev_pass@localhost:5433/mediku"
JWT_SECRET="dev-secret-change-in-production"
JWT_EXPIRES_IN="7d"
CORS_ORIGIN="*"
NODE_ENV=development
```

> **For production**, change `JWT_SECRET` to a long random string and update `CORS_ORIGIN` to your Flutter app's domain.

---

## 4. Database Setup

### Generate Prisma Client

```bash
npx prisma generate
```

### Run Migrations

```bash
npx prisma migrate dev
```

> This creates all tables defined in `prisma/schema.prisma`.

### Verify Tables

```bash
docker exec mediku-postgres psql -U mediku -d mediku -c "\\dt"
```

You should see all 11 tables (`users`, `family_profiles`, `health_metrics`, etc.).

---

## 5. Seed the Database

Populate the database with sample data (users, profiles, screenings, articles, regions).

```bash
node prisma/seed.js
```

**Output:**
```
✅ Created users: SUPERADMIN, ADMIN, PATIENT
✅ Created 3 family profiles
✅ Created health metrics
✅ Created 3 screenings with IRD
✅ Created 3 articles (2 published, 1 draft)
✅ Created RW/RT structure
✅ Created 2 residents
✅ Created 1 appointment
```

### Default Login Credentials

| Role | KK Number | Password |
|------|-----------|----------|
| SUPERADMIN | `3275000000000001` | `superadmin123` |
| ADMIN | `3275000000000002` | `admin123` |
| PATIENT | `3275000000000003` | `patient123` |

---

## 6. Run the Server

### Development Mode (with auto-reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

The server will start on `http://localhost:3000`.

---

## 7. Quick Health Check

```bash
curl http://localhost:3000/api/v1/health
```

**Expected response:**
```json
{
  "success": true,
  "message": "OK",
  "timestamp": "2026-05-02T15:20:09.468Z"
}
```

---

## 8. Test Authentication Flow

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

**Save the `token` from the response for authenticated requests.**

### Get Current User

```bash
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <YOUR_TOKEN_HERE>"
```

---

## 9. Running the Test Suite

The project uses **Jest** + **Supertest** for integration testing.

```bash
npm test
```

This runs 4 test suites (26 tests total):
- `tests/ird.test.js` — IRD (Index Risk Diabetes) calculation logic
- `tests/auth.test.js` — Registration, login, token validation
- `tests/profiles.test.js` — CRUD operations for family profiles
- `tests/metrics.test.js` — Health metrics recording and retrieval

### Test Structure

Each module test covers:
- ✅ **Happy path** — successful creation, reading, updating
- ✅ **Validation errors** — missing/invalid fields
- ✅ **Auth errors** — missing token, invalid token, wrong role

---

## 10. Reset Everything

If you want to start fresh:

```bash
# Stop and remove database data
docker-compose down -v

# Restart PostgreSQL
docker-compose up -d

# Re-run migrations
npx prisma migrate dev

# Re-seed
node prisma/seed.js
```

---

## 11. Useful Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start server with nodemon (auto-reload) |
| `npm start` | Start server (production) |
| `npm test` | Run Jest test suite |
| `npx prisma migrate dev` | Create & apply migrations |
| `npx prisma generate` | Regenerate Prisma client |
| `npx prisma db seed` | Run seed script |
| `npx prisma studio` | Open Prisma Studio (GUI for database) |

---

## 12. API Overview

All endpoints are prefixed with `/api/v1`.

### Public Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/auth/register` | Register new user |
| `POST` | `/auth/login` | Login |
| `GET` | `/articles` | List published articles |
| `GET` | `/articles/:id` | Get single published article |

### Authenticated Endpoints (requires Bearer token)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/auth/me` | Get current user |
| `GET/POST/PUT/DELETE` | `/profiles` | Family profiles CRUD |
| `GET/POST` | `/metrics` | Health metrics |
| `GET` | `/metrics/:type/history` | Metric history |
| `GET` | `/appointments` | Appointments CRUD |
| `GET/POST` | `/chat/conversations` | Chat conversations |
| `GET/POST` | `/chat/conversations/:id/messages` | Chat messages |

### Admin Endpoints (requires ADMIN or SUPERADMIN role)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/screenings` | Create medical screening (auto-calculates IRD) |
| `GET` | `/screenings` | List screenings |
| `GET` | `/screenings/stats` | Screening statistics |
| `GET` | `/admin/patients` | Patient list with filters |
| `GET` | `/admin/patients/:id` | Patient detail |
| `GET/POST/PUT/DELETE` | `/admin/users` | User management |
| `GET/POST/PUT/DELETE` | `/articles/admin` | Article management |
| `PATCH` | `/articles/admin/:id/publish` | Publish article |

### Superadmin Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET/POST` | `/regions` | Region (RW/RT) management |
| `GET/POST/PUT` | `/regions/residents` | Resident management |

---

## Troubleshooting

### Port 5433 already in use

If Docker says port 5433 is taken, change it in `docker-compose.yml`:

```yaml
ports:
  - "5434:5432"  # Change host port
```

And update `.env`:
```env
DATABASE_URL="postgresql://mediku:mediku_dev_pass@localhost:5434/mediku"
```

### Prisma Client errors

If you see `PrismaClient is not initialized`:

```bash
npx prisma generate
```

### Tests failing with "Server running" log

This is normal — the app starts during tests. Tests clean up after themselves.

### JWT token expired

Default expiry is 7 days. For development, you can set `JWT_EXPIRES_IN="30d"` in `.env`.

---

## Next Steps

Once local testing is complete, see [`DEPLOYMENT.md`](./DEPLOYMENT.md) for deploying to production.

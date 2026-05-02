# MEDIKU Backend API

> Production-ready Express.js REST API with PostgreSQL for the MEDIKU health screening Flutter app.

---

## Quick Links

- **[Local Testing Guide](./docs/LOCAL_TESTING.md)** — Run the backend on your machine
- **[Deployment Guide](./docs/DEPLOYMENT.md)** — Deploy to Hetzner + Coolify

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Runtime** | Node.js 20 |
| **Framework** | Express.js 5 |
| **Database** | PostgreSQL 16 |
| **ORM** | Prisma |
| **Auth** | JWT (jsonwebtoken) + bcrypt |
| **Validation** | express-validator |
| **Security** | helmet, cors, express-rate-limit |
| **Testing** | Jest + Supertest |

---

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma      # Database models (10 tables)
│   └── seed.js            # Sample data generator
├── src/
│   ├── index.js           # Entry point (starts server)
│   ├── app.js             # Express app configuration
│   ├── config/
│   │   └── index.js       # Environment variables
│   ├── middleware/
│   │   ├── auth.js        # JWT verification
│   │   ├── roleGuard.js   # Role-based access control
│   │   ├── validate.js    # Request validation
│   │   ├── errorHandler.js
│   │   └── notFound.js
│   ├── modules/
│   │   ├── auth/          # Login, register, /me
│   │   ├── profiles/      # Family profiles CRUD
│   │   ├── metrics/       # Health metrics
│   │   ├── articles/      # Public + admin articles
│   │   ├── appointments/  # Appointment scheduling
│   │   ├── screenings/    # Medical screenings + IRD calc
│   │   ├── admin/         # Dashboard + user management
│   │   ├── regions/       # RW/RT + residents
│   │   └── chat/          # Conversation storage
│   ├── routes/
│   │   └── index.js       # Route aggregator
│   └── utils/
│       ├── jwt.js
│       ├── password.js
│       ├── ird.js         # IRD (Index Risk Diabetes) calculator
│       └── response.js    # Standard response helpers
├── tests/
│   ├── ird.test.js
│   ├── auth.test.js
│   ├── profiles.test.js
│   └── metrics.test.js
├── Dockerfile
├── docker-compose.yml     # (at project root)
├── .env                   # Local environment variables
├── .env.example
└── docs/
    ├── LOCAL_TESTING.md
    └── DEPLOYMENT.md
```

---

## IRD (Index Risk Diabetes)

The backend automatically calculates diabetes risk when a screening is created:

```
IRD = 0.30×(bloodSugar/200)
    + 0.20×((systolic/140 + diastolic/90)/2)
    + 0.20×(cholesterol/240)
    + 0.15×(uricAcid/auDenominator)
    + 0.15×(BMI/25)

Where auDenominator = 7.0 (male) or 6.0 (female)
```

| IRD Score | Category | Risk Level |
|-----------|----------|------------|
| < 0.75 | Rendah | Low |
| 0.75–1.00 | Sedang | Medium |
| > 1.00 | Berat | High |

---

## API Endpoints

All endpoints are prefixed with `/api/v1`.

### Public
- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /articles`
- `GET /articles/:id`

### Authenticated (Bearer token)
- `GET /auth/me`
- `GET/POST/PUT/DELETE /profiles`
- `GET/POST /metrics`
- `GET /appointments`
- `GET/POST /chat/conversations`

### Admin (ADMIN or SUPERADMIN)
- `POST /screenings` (auto-calculates IRD)
- `GET /screenings/stats`
- `GET/POST /admin/patients`
- `GET/POST/PUT/DELETE /admin/users`
- `GET/POST/PUT/DELETE /articles/admin`

### Superadmin
- `GET/POST /regions`
- `GET/POST/PUT /regions/residents`

---

## Default Credentials (after seed)

| Role | KK Number | Password |
|------|-----------|----------|
| SUPERADMIN | `3275000000000001` | `superadmin123` |
| ADMIN | `3275000000000002` | `admin123` |
| PATIENT | `3275000000000003` | `patient123` |

---

## Scripts

```bash
npm run dev        # Development with auto-reload
npm start          # Production start
npm test           # Run Jest test suite
npm run prisma:generate    # Regenerate Prisma client
npm run prisma:migrate     # Run database migrations
npm run prisma:seed        # Seed database with sample data
```

---

## Development

See [`docs/LOCAL_TESTING.md`](./docs/LOCAL_TESTING.md) for the full local development guide.

Quick start:

```bash
cd backend
npm install
docker-compose -f ../docker-compose.yml up -d  # Start PostgreSQL
npx prisma migrate dev                          # Create tables
node prisma/seed.js                             # Add sample data
npm run dev                                     # Start server
```

---

## Deployment

See [`docs/DEPLOYMENT.md`](./docs/DEPLOYMENT.md) for the full deployment guide.

**Summary:**
- Server: Hetzner CX22 (€3.99/month)
- PaaS: Coolify (auto-deploy from GitHub)
- Database: PostgreSQL via Coolify
- SSL: Let's Encrypt (auto)

---

## License

This project is private and proprietary.

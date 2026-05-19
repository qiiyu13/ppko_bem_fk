# Deployment Report — MEDIKU Backend to DigitalOcean

**Date:** 2026-05-19
**Engineer:** Muhammad Fiqi Firmansyah
**Lifespan:** 6-8 months (short-term project)

---

## Outcome

Backend live at **`https://api.209.97.164.137.nip.io`**.
Flutter release APKs built and ready for tester distribution.

---

## Infrastructure

| Component | Choice | Notes |
|-----------|--------|-------|
| VPS | DigitalOcean Droplet, Singapore (SGP1) | $200 student credit |
| IP | `209.97.164.137` | |
| OS | Ubuntu 24.04 LTS | |
| Domain | `api.209.97.164.137.nip.io` | Free wildcard DNS (nip.io) |
| SSL | Let's Encrypt | Standalone certbot |
| Runtime | Docker + docker compose | |
| Reverse proxy | nginx:alpine | TLS termination, /api/ + /ws routing |
| Database | PostgreSQL 16-alpine | Container-volume persisted |
| Backend | Node 20-alpine, Express 5, Prisma 6 | |

---

## Steps Completed

### 1. Pre-flight backend fixes (commit `chore(deploy): prep for DigitalOcean droplet`)
- Moved `prisma` from devDependencies to dependencies (`backend/package.json`) so CLI ships in prod image
- Added backend healthcheck in `docker-compose.prod.yml` (wget `/api/v1/health`)
- Set `server_name` in `nginx/nginx.conf` to `api.209.97.164.137.nip.io`
- Removed obsolete `version: '3.8'` from compose file

### 2. SSH access
- Generated keypair `~/.ssh/mediku` + `mediku.pub`
- Added to droplet at creation
- Resolved permission errors (key file `chmod 600`, used private key not `.pub`)

### 3. Server hardening
- Created `mediku` sudo user, disabled root SSH
- UFW firewall: allow 22, 80, 443
- Installed Docker via official get.docker.com script
- Added `mediku` to `docker` group

### 4. TLS certificate
- Installed certbot
- Issued cert for `api.209.97.164.137.nip.io` via standalone challenge
- Certs at `/etc/letsencrypt/live/api.209.97.164.137.nip.io/`

### 5. Application deploy
- Cloned repo to `~/ppko_bem_fk`
- Generated secrets: `POSTGRES_PASSWORD` (24-hex), `JWT_SECRET` (64-hex) via `openssl rand`
- Created `.env.prod` with all required vars; locked `chmod 600`
- Started stack:
  ```
  docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
  ```
- 10 Prisma migrations auto-applied on first boot
- Seeded DB via `docker compose exec backend node prisma/seed.js`

### 6. Flutter release pipeline
- Wired conditional release signing in `android/app/build.gradle.kts` (reads `android/key.properties` if present, falls back to debug)
- Created `android/key.properties.example`
- Updated `.gitignore` to exclude `key.properties`, `*.jks`, `*.keystore`, SSH keys
- Built 3 split-ABI release APKs with prod URLs baked in:
  - `app-arm64-v8a-release.apk` (62.8 MB) — most modern phones
  - `app-armeabi-v7a-release.apk` (60.0 MB) — older 32-bit
  - `app-x86_64-release.apk` (65.3 MB) — emulators

---

## Configuration Summary

### `.env.prod` (on droplet, NOT committed)
```
POSTGRES_USER=mediku
POSTGRES_PASSWORD=<openssl rand -hex 24>
POSTGRES_DB=mediku
JWT_SECRET=<openssl rand -hex 64>
JWT_EXPIRES_IN=7d
CORS_ORIGIN=https://api.209.97.164.137.nip.io
NODE_ENV=production
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
DAILY_CHAT_LIMIT=50
FIREBASE_SERVICE_ACCOUNT=<base64 JSON or empty>
SSL_CERT_PATH=/etc/letsencrypt/live/api.209.97.164.137.nip.io/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/api.209.97.164.137.nip.io/privkey.pem
```

### Flutter build flags
```
--dart-define=API_BASE_URL=https://api.209.97.164.137.nip.io/api/v1
--dart-define=WS_BASE_URL=wss://api.209.97.164.137.nip.io/ws
```

### Seed credentials (default — change before real users)
| Role | KK | Password |
|------|-----|----------|
| SUPERADMIN | `3275000000000001` | `superadmin123` |
| ADMIN | `3275000000000002` | `admin123` |
| PATIENT | `3275000000000003` | `patient123` |

---

## Operational Commands

All compose commands need `--env-file .env.prod`. Suggested alias:
```bash
alias dcp="docker compose --env-file .env.prod -f docker-compose.prod.yml"
```

| Task | Command |
|------|---------|
| Tail logs | `dcp logs -f` |
| Restart backend | `dcp restart backend` |
| Rebuild after pull | `dcp up -d --build` |
| Exec into backend | `dcp exec backend sh` |
| DB shell | `dcp exec postgres psql -U mediku -d mediku` |
| Stop stack | `dcp down` (volume persists) |

### Cert renewal cron (recommended, not yet set)
```
0 3 * * * certbot renew --quiet --deploy-hook "cd /home/mediku/ppko_bem_fk && docker compose --env-file .env.prod -f docker-compose.prod.yml restart nginx"
```

### Backups (recommended, not yet set)
```
0 2 * * * docker exec mediku-postgres pg_dump -U mediku mediku | gzip > ~/backups/mediku-$(date +\%F).sql.gz && find ~/backups -mtime +14 -delete
```

---

## Outstanding Items

| Item | Priority | Status |
|------|----------|--------|
| Generate release keystore + sign APKs | High | User to run `keytool` |
| Change default seed passwords | High | TODO before real users |
| DB backup cron | Medium | Not configured |
| Let's Encrypt renewal cron | Medium | Not configured |
| DO Reserved IP (lock IP across rebuilds) | Low | Optional |
| DO weekly snapshot ($2.40/mo) | Low | Optional |
| Firebase App Distribution for testers | Low | Optional, nicer UX |

---

## Decisions Log

- **Domain:** chose nip.io over paid registrar — project lifespan only 6-8mo, free, real Let's Encrypt cert
- **PaaS:** chose raw docker-compose over Coolify — simpler for short lifespan, fewer moving parts
- **Region:** Singapore (SGP1) — lowest latency from Indonesia (~20-40ms)
- **APK signing:** ship debug-signed first for quick tester install; release keystore deferred to user-controlled step (passwords + identity required)

---

## Risk Notes

- **nip.io DNS dependency** — if nip.io ever goes down, app unreachable until migrated to real domain. Acceptable given short lifespan.
- **Default credentials in seed** — must rotate before exposing to non-developers.
- **Single droplet, no HA** — acceptable for testing scope.
- **No automated backups yet** — manual `pg_dump` advised until cron configured.

# Migration Checklist — Mediku → mediku.appunnes.id

---

## 1. Infrastructure Setup

| # | Done? | Step | Command |
|---|-------|------|---------|
| 1 | ☐ | Install Docker & docker compose | `apt update && apt install -y docker.io docker-compose-v2` |
| 2 | ☐ | Copy project folder to server | `scp -r ppko_bem_fk/ user@server:~/` |
| 3 | ☐ | Point DNS A record | `mediku.appunnes.id` → new server IP |
| 4 | ☐ | Install SSL cert | `certbot certonly --standalone -d mediku.appunnes.id` |

---

## 2. Configure & Deploy

| # | Done? | File | Change |
|---|-------|------|--------|
| 5 | ☐ | `.env.prod` | `CORS_ORIGIN=https://mediku.appunnes.id` |
| 6 | ☐ | `.env.prod` | `SSL_CERT_PATH=/etc/letsencrypt/live/mediku.appunnes.id/fullchain.pem` |
| 7 | ☐ | `.env.prod` | `SSL_KEY_PATH=/etc/letsencrypt/live/mediku.appunnes.id/privkey.pem` |
| 8 | ☐ | `nginx/nginx.conf` | `server_name` (lines 60 & 66) → `mediku.appunnes.id` |
| 9 | ☐ | Start containers | `docker compose --env-file .env.prod -f docker-compose.prod.yml up -d` |

---

## 3. Verify

| # | Done? | Check | Expected |
|---|-------|-------|----------|
| 10 | ☐ | `https://mediku.appunnes.id/health` | HTTP `200` |
| 11 | ☐ | Test login / API calls | All endpoints respond |

---

**Status:** 0 / 11 complete

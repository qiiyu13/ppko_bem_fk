# Deployment Guide

> **Deploy the MEDIKU backend to a Hetzner VPS using Coolify (PaaS).**
>
> **Estimated time:** 30-45 minutes for first setup. Subsequent deploys are automatic.

---

## Overview

| Component | Choice | Cost |
|-----------|--------|------|
| **Server** | Hetzner CX22 (2 vCPU, 4GB RAM, 40GB SSD) | €3.99/month (~Rp70rb) |
| **PaaS** | Coolify (open-source, self-hosted) | Free |
| **Database** | PostgreSQL 16 (via Coolify) | Included |
| **SSL** | Let's Encrypt (auto via Coolify) | Free |

**Why Coolify?**
- Push to GitHub → auto-deploy
- 1-click PostgreSQL setup
- Built-in log viewer (no SSH needed)
- Zero-downtime deployments

---

## Step 1: Provision the VPS (Hetzner)

### 1.1 Sign Up & Order

1. Go to [hetzner.com](https://www.hetzner.com/cloud) and create an account
2. Order **CX22**:
   - 2 vCPU, 4GB RAM, 40GB SSD
   - Location: **Singapore** or **Falkenstein** (good ping from Indonesia)
   - OS: **Ubuntu 22.04**
3. Add your **SSH public key** during setup:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```
4. Note the **server IP address**

### 1.2 Initial Server Setup

SSH into your server:

```bash
ssh root@<YOUR_SERVER_IP>
```

Update and install Docker:

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin

# Enable Docker on boot
systemctl enable docker
systemctl start docker
```

Configure firewall:

```bash
ufw allow 22      # SSH
ufw allow 80      # HTTP
ufw allow 443     # HTTPS
ufw allow 8000    # Coolify web UI
ufw enable
```

---

## Step 2: Install Coolify

On the server, run:

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

This installs Coolify as a Docker container. After installation:

1. Open `http://<YOUR_SERVER_IP>:8000` in your browser
2. Create an admin account (email + password)
3. You're now in the Coolify dashboard

---

## Step 3: Configure Coolify

### 3.1 Add Your Server

1. In Coolify → **Servers** → Click **Add Server**
2. Choose **Localhost** (the server Coolify is running on)
3. Coolify auto-detects Docker — click **Validate & Save**

### 3.2 Connect GitHub

1. Go to **Sources** → **Add Source** → **GitHub**
2. Authorize Coolify to access your GitHub account
3. Select the repository: `your-username/mediku-backend`

### 3.3 Add PostgreSQL Database

1. Go to **Databases** → **Add Database**
2. Choose **PostgreSQL 16**
3. Name it: `mediku-db`
4. Coolify creates it and shows the **internal connection URL**, e.g.:
   ```
   postgresql://user:password@mediku-db:5432/mediku
   ```
5. **Save this URL** — you'll need it in the next step

---

## Step 4: Create the Backend Resource

1. Go to **Resources** → **Add Resource** → Select your GitHub repo
2. Configure:
   - **Build Pack:** `Dockerfile`
   - **Port:** `3000`
   - **Base Directory:** `backend` (since our backend is in the `backend/` folder)

### Environment Variables

Add these in the Coolify UI under **Environment**:

| Variable | Value | Example |
|----------|-------|---------|
| `NODE_ENV` | `production` | `production` |
| `PORT` | `3000` | `3000` |
| `DATABASE_URL` | Your Coolify DB URL | `postgresql://user:pass@mediku-db:5432/mediku` |
| `JWT_SECRET` | Random 64-char string | Generate with `openssl rand -base64 48` |
| `JWT_EXPIRES_IN` | `7d` | `7d` |
| `CORS_ORIGIN` | Your Flutter app's domain | `https://your-app.com` or `*` for dev |

> **How to generate a secure JWT_SECRET:**
> ```bash
> openssl rand -base64 48
> ```

### Domain & SSL

1. In the resource settings, add your domain:
   - `api.mediku.app` (or your domain)
2. Coolify automatically requests Let's Encrypt SSL
3. Enable **Auto-deploy on push**

---

## Step 5: Push to GitHub

From your local machine:

```bash
cd backend
git init
git add .
git commit -m "feat: initial backend API"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/mediku-backend.git
git push -u origin main
```

> If your backend is part of a monorepo (like this project), Coolify can deploy from a subfolder. Set **Base Directory** to `backend` in Coolify.

---

## Step 6: Verify Deployment

### 6.1 Check Build Logs

In Coolify dashboard → your resource → **Deployments**

You should see:
1. Git clone
2. Docker build
3. `npx prisma migrate deploy`
4. Server start

### 6.2 Test Health Endpoint

```bash
curl https://api.mediku.app/api/v1/health
```

Expected:
```json
{
  "success": true,
  "message": "OK",
  "timestamp": "..."
}
```

### 6.3 Run Seed Script

In Coolify dashboard → your resource → **Exec** (or SSH into the container):

```bash
node prisma/seed.js
```

### 6.4 Test Authentication

```bash
# Login as admin
curl -X POST https://api.mediku.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"kkNumber":"3275000000000002","password":"admin123"}'
```

Should return a JWT token.

---

## Step 7: Database Migrations on Production

When you update the schema and push code:

1. Update `prisma/schema.prisma`
2. Commit and push
3. Coolify auto-deploys
4. **The Dockerfile automatically runs:**
   ```dockerfile
   CMD ["sh", "-c", "npx prisma migrate deploy && node src/index.js"]
   ```

This applies pending migrations before starting the server.

---

## Step 8: Update Your Flutter App

Change your Flutter app's API base URL:

```dart
// Before (local)
const String baseUrl = 'http://localhost:3000/api/v1';

// After (production)
const String baseUrl = 'https://api.mediku.app/api/v1';
```

---

## Maintenance

### View Logs

Coolify dashboard → your resource → **Logs** (real-time, no SSH needed)

### Restart Service

Coolify dashboard → your resource → **Restart**

### Update Environment Variables

Coolify dashboard → your resource → **Environment** → edit → **Redeploy**

### Database Backups

Coolify dashboard → **Databases** → `mediku-db` → **Backup**

---

## Troubleshooting

### Build Fails: "Cannot find module"

Make sure `npm install` runs in the Dockerfile. The provided Dockerfile already does this:

```dockerfile
RUN npm ci --only=production
```

### Migration Fails

SSH into the server or use Coolify Exec:

```bash
npx prisma migrate status
npx prisma migrate deploy
```

### SSL Certificate Issues

In Coolify → your resource → **Settings** → toggle SSL off and on again to re-request.

### CORS Errors from Flutter App

Make sure `CORS_ORIGIN` includes your Flutter app's domain:
- Web app: `https://your-app.vercel.app`
- Mobile app: Use `*` during development, restrict in production

### Port Already in Use

If port 3000 is taken, change `PORT` env var to another port (e.g., `3001`) and update Coolify's exposed port.

---

## Security Checklist

Before going live:

- [ ] Change `JWT_SECRET` to a long random string
- [ ] Set `NODE_ENV=production`
- [ ] Restrict `CORS_ORIGIN` to your Flutter app's domain (not `*`)
- [ ] Enable firewall (only allow 22, 80, 443, 8000)
- [ ] Set up automated database backups in Coolify
- [ ] Remove test accounts or change default passwords (3275000000000001, 3275000000000002, 3275000000000003)

---

## Architecture Recap

```
Flutter App (mobile/web)
    ↓ HTTPS
Coolify Proxy (SSL + routing)
    ↓
Docker Container (Express.js + Node.js)
    ↓
PostgreSQL Container (same VPS)
```

All running on a single €3.99/month Hetzner VPS managed entirely through Coolify's web UI.

---

## Useful Resources

- [Coolify Documentation](https://coolify.io/docs/)
- [Hetzner Cloud Console](https://console.hetzner.cloud/)
- [Prisma Deployment Guide](https://www.prisma.io/docs/orm/prisma-client/deployment/deploy-prisma)

---

**Questions?** Check the [`LOCAL_TESTING.md`](./LOCAL_TESTING.md) guide for development tips.

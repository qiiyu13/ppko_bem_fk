# LAN & Remote Testing Guide

> **Run the MEDIKU backend on a spare Windows PC and test from any Android phone — locally or over the internet.**
>
> **Estimated time:** 30 minutes for first-time setup. After that, starting everything takes ~1 minute.

---

## Table of Contents

1. [Overview](#overview)
2. [Part 1: Windows PC Setup](#part-1-windows-pc-setup)
   - [1.1 Install Node.js](#11-install-nodejs)
   - [1.2 Install PostgreSQL](#12-install-postgresql)
   - [1.3 Install Git](#13-install-git)
3. [Part 2: Backend Setup](#part-2-backend-setup)
   - [2.1 Clone the Repository](#21-clone-the-repository)
   - [2.2 Create the Database](#22-create-the-database)
   - [2.3 Configure Environment Variables](#23-configure-environment-variables)
   - [2.4 Install Dependencies & Migrate](#24-install-dependencies--migrate)
   - [2.5 Seed the Database](#25-seed-the-database)
   - [2.6 Start the Server](#26-start-the-server)
   - [2.7 Verify the Server](#27-verify-the-server)
4. [Part 3: Network Access](#part-3-network-access)
   - [3.1 Option A: Same WiFi Only (LAN)](#31-option-a-same-wifi-only-lan)
   - [3.2 Option B: Anywhere via Ngrok (Recommended)](#32-option-b-anywhere-via-ngrok-recommended)
5. [Part 4: Build the Flutter APK](#part-4-build-the-flutter-apk)
   - [4.1 For LAN Testing](#41-for-lan-testing)
   - [4.2 For Ngrok Testing](#42-for-ngrok-testing)
6. [Part 5: Install on Android Phones](#part-5-install-on-android-phones)
7. [Part 6: Daily Workflow](#part-6-daily-workflow)
8. [Part 7: Troubleshooting](#part-7-troubleshooting)
9. [Default Login Credentials](#default-login-credentials)

---

## Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        YOUR NETWORK                              │
│                                                                  │
│  ┌─────────────────┐         ┌──────────────────────────────┐   │
│  │  Your Linux PC   │  WiFi  │  Windows PC (Dev Server)      │   │
│  │  (Flutter dev)   │◄──────►│  Node.js + PostgreSQL         │   │
│  └─────────────────┘         │  Port 3000                    │   │
│                               └──────────┬───────────────────┘   │
│  ┌─────────────────┐                     │                       │
│  │  Android Phone   │  WiFi              │                       │
│  │  (MEDIKU App)    │◄───────────────────┘                       │
│  └─────────────────┘                                             │
└──────────────────────────────────────────────────────────────────┘
                                    │
                                    │ ngrok tunnel (optional)
                                    ▼
                          ┌───────────────────┐
                          │  The Internet      │
                          │  Anyone can access  │
                          │  via ngrok URL      │
                          └───────────────────┘
```

**What you need:**
- A Windows PC with a LAN/ethernet connection (your "server")
- Your main Linux PC for Flutter development
- Android phone(s) for testing

---

## Part 1: Windows PC Setup

### 1.1 Install Node.js

1. Go to **https://nodejs.org/**
2. Download the **LTS** version (v20.x or newer)
3. Run the `.msi` installer
   - ✅ Check **"Automatically install necessary tools"** when prompted
   - Leave everything else as default
4. Verify installation — open **PowerShell** and run:

```powershell
node --version
# Expected: v20.x.x or newer

npm --version
# Expected: 10.x.x or newer
```

---

### 1.2 Install PostgreSQL

1. Go to **https://www.postgresql.org/download/windows/**
2. Click **"Download the installer"** (EnterpriseDB)
3. Download PostgreSQL **16** (latest)
4. Run the installer:
   - **Installation directory:** Leave as default
   - **Components:** Keep all checked (PostgreSQL Server, pgAdmin, Command Line Tools)
   - **Data directory:** Leave as default
   - **Password:** Set a password for the `postgres` superuser — **remember this!**
     - Suggestion: use `postgres` for dev simplicity
   - **Port:** Leave as default `5432`
   - **Locale:** Leave as default
5. Click through and finish installation

6. Verify — open **PowerShell** and run:

```powershell
psql --version
# Expected: psql (PostgreSQL) 16.x
```

> **If `psql` is not recognized**, add PostgreSQL to your PATH:
> 1. Open **Start Menu** → search "Environment Variables"
> 2. Click **"Edit the system environment variables"**
> 3. Click **"Environment Variables..."**
> 4. Under **System variables**, find `Path` → click **Edit**
> 5. Click **New** → add: `C:\Program Files\PostgreSQL\16\bin`
> 6. Click OK on all dialogs
> 7. **Close and reopen** PowerShell

---

### 1.3 Install Git

1. Go to **https://git-scm.com/download/win**
2. Download and run the installer
3. Use all default settings (click Next through everything)
4. Verify:

```powershell
git --version
# Expected: git version 2.x.x
```

---

## Part 2: Backend Setup

### 2.1 Clone the Repository

Open **PowerShell** on the Windows PC:

```powershell
# Navigate to where you want the project
cd C:\Users\YourName\Documents

# Clone the repository
git clone <your-github-repo-url> ppko_bem_fk

# Navigate to the backend
cd ppko_bem_fk\backend
```

> **If the repo is private**, you'll need to authenticate with GitHub.
> The easiest way is to use HTTPS with a Personal Access Token:
> 1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
> 2. Generate a new token with `repo` scope
> 3. Use it as the password when git asks for credentials

---

### 2.2 Create the Database

Open **PowerShell** (you may need to run as Administrator):

```powershell
# Connect to PostgreSQL as the superuser
psql -U postgres
```

Enter the password you set during PostgreSQL installation. Then run these SQL commands:

```sql
-- Create the application user
CREATE USER mediku WITH PASSWORD 'mediku_dev_pass';

-- Create the database
CREATE DATABASE mediku OWNER mediku;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mediku TO mediku;

-- Exit psql
\q
```

Verify the database was created:

```powershell
psql -U mediku -d mediku -c "SELECT 1 AS connected;"
```

Enter password `mediku_dev_pass`. If you see:

```
 connected
-----------
         1
```

You're good! ✅

---

### 2.3 Configure Environment Variables

Create the `.env` file inside the `backend` folder.

**Option A: Using PowerShell:**

```powershell
# Make sure you're in the backend directory
cd C:\Users\YourName\Documents\ppko_bem_fk\backend

# Create .env file
@"
PORT=3000
DATABASE_URL="postgresql://mediku:mediku_dev_pass@localhost:5432/mediku"
JWT_SECRET="dev-secret-change-in-production"
JWT_EXPIRES_IN="7d"
CORS_ORIGIN="*"
NODE_ENV=development
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
DAILY_CHAT_LIMIT=50
"@ | Out-File -FilePath .env -Encoding utf8
```

**Option B: Using Notepad:**

1. Open Notepad
2. Paste this content:

```
PORT=3000
DATABASE_URL="postgresql://mediku:mediku_dev_pass@localhost:5432/mediku"
JWT_SECRET="dev-secret-change-in-production"
JWT_EXPIRES_IN="7d"
CORS_ORIGIN="*"
NODE_ENV=development
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
DAILY_CHAT_LIMIT=50
```

3. Save as `backend\.env` (make sure "Save as type" is **All Files**, not Text Documents)

> **Note:** `OPENAI_API_KEY` is left empty. The AI chat feature will be disabled, but everything else works fine. Add your key if you want the AI assistant to work.

---

### 2.4 Install Dependencies & Migrate

In **PowerShell**, inside the `backend` directory:

```powershell
# Install Node.js dependencies
npm install

# Generate the Prisma client
npx prisma generate

# Run database migrations (creates all tables)
npx prisma migrate deploy
```

Expected output for migrate:

```
7 migrations found in prisma/migrations
...
All migrations have been successfully applied.
```

---

### 2.5 Seed the Database

This creates sample users you can log in with:

```powershell
node prisma/seed.js
```

Expected output:

```
🌱 Starting seed...
✅ Cleaned existing data
✅ Created family accounts: SUPERADMIN, ADMIN, PATIENT
✅ Created 3 family profiles
✅ Created health metrics
✅ Created 3 screenings with IRD
✅ Created 3 articles
✅ Created RW/RT structure
✅ Created 2 residents
✅ Created 1 appointment
🎉 Seed completed successfully!

Login credentials:
  SUPERADMIN: KK=3275000000000001, password=superadmin123
  ADMIN:      KK=3275000000000002, password=admin123
  PATIENT:    KK=3275000000000003, password=patient123
```

---

### 2.6 Start the Server

```powershell
npm run dev
```

Expected output:

```
WARNING: OPENAI_API_KEY is not set. AI chat assistant will be disabled.
Token blacklist initialized with 0 active entries
Server running on port 3000 [development]
WebSocket available at ws://localhost:3000/ws
```

> **Leave this PowerShell window open!** Closing it stops the server.
>
> **Tip:** If you want the server to keep running even if PowerShell is accidentally closed,
> you can use `npm install -g pm2` and then run `pm2 start src/index.js --name mediku`.

---

### 2.7 Verify the Server

Open a **new** PowerShell window (don't close the server one!) and run:

```powershell
curl http://localhost:3000/api/v1/health
```

Expected response:

```json
{"success":true,"message":"OK","timestamp":"...","database":"connected"}
```

If you see `"database":"connected"`, everything is running! ✅

---

## Part 3: Network Access

Choose one of the two options below.

### 3.1 Option A: Same WiFi Only (LAN)

Use this if all test phones are on the **same network** as the Windows PC.

#### Find the Windows PC's IP Address

On the Windows PC, open PowerShell:

```powershell
ipconfig
```

Look for your active network adapter and find the **IPv4 Address**:

```
Ethernet adapter Ethernet:
   IPv4 Address. . . . . . . . . : 192.168.1.50    ← THIS IS YOUR IP
   Subnet Mask . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . : 192.168.1.1
```

> **Write this IP down** — you'll need it for the Flutter build.

#### Set a Static IP (Recommended)

So the IP never changes:

1. **Settings → Network & Internet → Ethernet** (or WiFi)
2. Click your connection → **Edit** (next to IP assignment)
3. Change from **Automatic (DHCP)** to **Manual**
4. Toggle **IPv4** ON
5. Fill in:
   - **IP address:** `192.168.1.200` (pick an unused IP)
   - **Subnet prefix length:** `24`
   - **Gateway:** `192.168.1.1` (your router's IP, from `ipconfig` output above)
   - **Preferred DNS:** `8.8.8.8`
   - **Alternate DNS:** `8.8.4.4`
6. Click **Save**

#### Open Windows Firewall

Run this in **PowerShell as Administrator** (right-click PowerShell → "Run as Administrator"):

```powershell
New-NetFirewallRule -DisplayName "MEDIKU Backend" -Direction Inbound -Port 3000 -Protocol TCP -Action Allow
```

#### Test from Another Device

From your Linux PC or phone browser, go to:

```
http://192.168.1.200:3000/api/v1/health
```

If you see the JSON response, LAN access works ✅

Your server URL is: `http://192.168.1.200:3000`

---

### 3.2 Option B: Anywhere via Ngrok (Recommended)

Use this if testers are on **different networks** (mobile data, different WiFi, etc.).

#### Install Ngrok on Windows

1. Go to **https://ngrok.com/download**
2. Click **Download for Windows**
3. Extract the ZIP file — you'll get `ngrok.exe`
4. Move `ngrok.exe` to a convenient location, e.g., `C:\Tools\ngrok.exe`

#### Create a Free Account

1. Go to **https://dashboard.ngrok.com/signup**
2. Sign up with Google or email (free, no credit card)
3. After signing in, you'll see your **auth token** on the dashboard

#### Configure Ngrok

Open **PowerShell** and run:

```powershell
C:\Tools\ngrok.exe config add-authtoken YOUR_AUTH_TOKEN_HERE
```

Replace `YOUR_AUTH_TOKEN_HERE` with the token from the ngrok dashboard.

#### Start the Tunnel

**Make sure the backend server is already running** (from Part 2, Step 6), then open a **new** PowerShell window:

```powershell
C:\Tools\ngrok.exe http 3000
```

You'll see output like this:

```
Session Status    online
Account           your-email@gmail.com (Plan: Free)
Version           3.x.x
Region            Asia Pacific (ap)
Forwarding        https://a1b2-103-45-67-89.ngrok-free.app → http://localhost:3000

Connections       ttl     opn     rt1     rt5     p50     p90
                  0       0       0.00    0.00    0.00    0.00
```

> **Your public URL is the `https://` URL shown** — e.g., `https://a1b2-103-45-67-89.ngrok-free.app`
>
> **Write this URL down** — you'll need it for the Flutter build.

#### Test the Tunnel

From **any device** (even on mobile data), open a browser and go to:

```
https://a1b2-103-45-67-89.ngrok-free.app/api/v1/health
```

> **Note:** The first time you visit an ngrok URL, you may see a "Visit Site" interstitial page.
> This only appears in browsers, **not** in the Flutter app's API calls.

If you see the JSON health response, ngrok is working ✅

Your server URL is: `https://a1b2-103-45-67-89.ngrok-free.app`

#### Important: Keep Both Windows Open

You now have **two PowerShell windows** running on the Windows PC:

```
Window 1: npm run dev           ← Backend server (don't close!)
Window 2: ngrok http 3000       ← Ngrok tunnel  (don't close!)
```

**If you close ngrok and restart it, you get a new random URL and must rebuild the APK.**

---

## Part 4: Build the Flutter APK

On your **main Linux PC** (where Flutter is installed):

### 4.1 For LAN Testing

Using the static IP from Option A:

```bash
cd ~/Work/ppko_bem_fk

flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.200:3000/api/v1 \
  --dart-define=WS_BASE_URL=ws://192.168.1.200:3000/ws
```

### 4.2 For Ngrok Testing

Using the ngrok URL from Option B:

```bash
cd ~/Work/ppko_bem_fk

flutter build apk --release \
  --dart-define=API_BASE_URL=https://a1b2-103-45-67-89.ngrok-free.app/api/v1 \
  --dart-define=WS_BASE_URL=wss://a1b2-103-45-67-89.ngrok-free.app/ws
```

> **Note:** For ngrok, use `https` and `wss` (secure), not `http` and `ws`.

### Build Output

After the build completes (~2–5 minutes), the APK is located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

The file is approximately 20-40 MB.

---

## Part 5: Install on Android Phones

### Transfer the APK

Choose any method to send the APK to the phone:

| Method | How |
|--------|-----|
| **WhatsApp / Telegram** | Send the `.apk` file as a document |
| **Google Drive** | Upload → share link → download on phone |
| **USB cable** | Copy to phone → open with file manager |
| **ADB** | `adb install build/app/outputs/flutter-apk/app-release.apk` |

### Install the APK

1. Open the APK on the phone
2. If prompted: **"Install from unknown sources"** → go to Settings and enable it for your browser/file manager
3. Tap **Install**
4. Tap **Open**

### First-Time Usage

1. The app opens to the splash screen
2. Log in with one of the test accounts (see [credentials below](#default-login-credentials))
3. If connected to the right network (LAN) or internet (ngrok), you'll see the dashboard load

---

## Part 6: Daily Workflow

### Starting Everything (after initial setup)

On the **Windows PC**, open **two PowerShell windows**:

**Window 1 — Start the backend:**

```powershell
cd C:\Users\YourName\Documents\ppko_bem_fk\backend
npm run dev
```

**Window 2 — Start ngrok** (if using Option B):

```powershell
C:\Tools\ngrok.exe http 3000
```

> **If the ngrok URL changed**, rebuild the APK with the new URL (see Part 4).
>
> **If the ngrok URL is the same** (you didn't restart it), no rebuild needed.

### Stopping Everything

1. In the **ngrok** window: press `Ctrl + C`
2. In the **backend** window: press `Ctrl + C`

### Updating the Backend Code

When you push code changes from your Linux PC:

```powershell
# On the Windows PC, in the backend directory:
git pull
npm install          # only if package.json changed
npx prisma migrate deploy   # only if schema changed
npx prisma generate         # only if schema changed

# Restart the server
npm run dev
```

---

## Part 7: Troubleshooting

### "Cannot connect to server" from the phone

| Check | How to fix |
|-------|-----------|
| Is the backend running? | Check the PowerShell window — it should show "Server running on port 3000" |
| Is ngrok running? | Check the ngrok PowerShell window — it should show "Session Status: online" |
| Is the phone on the right network? | For LAN mode: phone must be on the same WiFi. For ngrok: any network works |
| Is the firewall open? | Run `New-NetFirewallRule` command from Part 3.1 again |
| Is the URL correct? | Open the URL in your phone's browser first to test |

### "Database connection error"

```powershell
# Check if PostgreSQL is running
Get-Service -Name postgresql*

# If stopped, start it:
Start-Service -Name postgresql-x64-16
```

### "psql: FATAL: password authentication failed"

The password for the `mediku` user doesn't match. Reset it:

```powershell
psql -U postgres
```

```sql
ALTER USER mediku WITH PASSWORD 'mediku_dev_pass';
\q
```

### "npx prisma migrate: error"

If migrations fail, try resetting the database:

```powershell
npx prisma migrate reset
```

> ⚠️ This **deletes all data** and re-runs all migrations + seed.

### Ngrok shows "ERR_NGROK_108" (session limit)

Free ngrok allows only **1 tunnel at a time**. Close any other ngrok sessions.

### The app was working but suddenly stopped

1. Check if the Windows PC went to **sleep** → disable sleep in Windows Settings:
   - Settings → System → Power & sleep → Set "Sleep" to **Never** (when plugged in)
2. Check if ngrok was closed/crashed → restart it (you'll get a new URL, so rebuild the APK)
3. Check if the backend crashed → restart with `npm run dev`

### "App crashes on launch"

The most common cause is a missing `google-services.json` for Firebase.
If you're not using Firebase phone auth for testing, you can temporarily comment out
the Firebase initialization in `lib/main.dart`:

```dart
// await Firebase.initializeApp();  // Comment out for local testing
```

Then rebuild the APK.

---

## Default Login Credentials

After running the seed script (`node prisma/seed.js`):

| Role | KK Number | Password | What they can do |
|------|-----------|----------|-----------------|
| **SUPERADMIN** | `3275000000000001` | `superadmin123` | Full system access, regions, user management |
| **ADMIN** | `3275000000000002` | `admin123` | Patient management, screenings, articles, scheduling |
| **PATIENT** | `3275000000000003` | `patient123` | Health tracking, chat, appointments, view articles |

---

## Quick Reference Card

Keep this handy:

```
╔═══════════════════════════════════════════════════════╗
║  MEDIKU Dev Server Quick Start                        ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  1. Start PostgreSQL  (auto-starts with Windows)      ║
║  2. Start backend:    npm run dev                     ║
║  3. Start ngrok:      ngrok http 3000                 ║
║                                                       ║
║  Health check:  <your-url>/api/v1/health              ║
║                                                       ║
║  PATIENT login:  KK=3275000000000003  pw=patient123   ║
║  ADMIN login:    KK=3275000000000002  pw=admin123     ║
║                                                       ║
║  ⚠ Don't close the PowerShell windows!                ║
║  ⚠ Don't let the PC sleep!                            ║
╚═══════════════════════════════════════════════════════╝
```

---

**Questions?** See the other guides:
- [`LOCAL_TESTING.md`](./LOCAL_TESTING.md) — Running backend on your Linux dev machine
- [`DEPLOYMENT.md`](./DEPLOYMENT.md) — Production deployment to Hetzner + Coolify

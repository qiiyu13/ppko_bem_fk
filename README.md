# Mediku (Media Informasi dan Diagnostik Kesehatanku)

Mediku is a multi-role healthcare application built with Flutter + Express.js, designed to bridge patients and healthcare providers through health tracking, medical screenings, scheduling, and health education.

## Overview

Mediku supports three user roles:

- **Patients**: Track health metrics, manage family profiles, view schedules, and read health articles.
- **Admins**: Manage patient records, monitor metrics, conduct medical screenings, schedule appointments, and publish health articles.
- **Superadmins**: Oversee platform usage, manage users, configure regional structure (RW/RT), and administer system settings.

## Key Features

### For Patients
- **Health Tracking & Visualizations**: Monitor blood pressure, blood sugar, cholesterol, and uric acid with interactive charts and sparkline trends.
- **Multi-Profile Management**: Manage health records for multiple family members under one account.
- **Health Articles (Tanaman Toga)**: Educational content on traditional medicinal plants (Jahe, Kunyit, Sirih).
- **Appointments & Reports**: View upcoming medical appointments and screening reports with IRD risk scoring.

### For Admins
- **Patient Management**: Detailed views of patient profiles, screening histories, and health metrics.
- **Medical Screenings with IRD**: Automatic diabetes risk index calculation from screening data.
- **Article Editor**: Create and manage educational health articles.
- **QR Code Profiles**: Quick patient lookup via scannable family profile QR codes.

### For Superadmins
- **User Administration**: Full user management across all roles.
- **Regional Structure**: Manage RW/RT hierarchy and resident records.
- **System Oversight**: Dashboard with system-wide statistics and configuration.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (SDK ^3.10.7)
- **Backend**: Express.js 5 + Prisma ORM
- **Database**: PostgreSQL 16
- **Real-time**: WebSocket for live data sync
- **Charts**: `fl_chart` for health metric visualizations
- **Local Storage**: `sqflite` for offline support
- **Auth**: JWT with role-based access control
- **Push Notifications**: Firebase Cloud Messaging
- **Deployment**: Docker Compose with nginx reverse proxy

## Project Structure

- `lib/screens/` — UI for different roles:
  - `/patient/` — Patient-facing screens (dashboard, profiles, schedules, articles)
  - `/admin/` — Admin-facing screens (patient management, screenings, scheduling, article editor)
  - `/superadmin/` — System administration
- `lib/models/` — Data models (`family_profile`, `health_metric`, `tanaman_article`, etc.)
- `lib/services/` — Business logic and API services
- `lib/widgets/` — Reusable UI components (`metric_chart`, `profile_selector`, etc.)
- `backend/` — Express.js REST API + WebSocket server
  - `src/modules/` — Feature modules (auth, profiles, metrics, screenings, articles, appointments, regions, notifications)
  - `prisma/` — Database schema, migrations, and seed data
- `docs/` — Technical documentation and deployment guides
- `docker-compose.yml` / `docker-compose.prod.yml` — Dev and production container orchestration

## Getting Started

### Prerequisites
Ensure you have Flutter installed. Verify:
```bash
flutter doctor
```

### Clone & Install
```bash
git clone <repository_url>
cd ppko_bem_fk
flutter pub get
```

### Run
```bash
flutter run
```

### Backend (optional — for full-stack development)
```bash
cd backend
cp ../.env.example .env
npm install
npx prisma migrate deploy
npx prisma generate
npx prisma db seed
npm run dev
```

## Documentation

Additional documentation can be found in the `docs/` and `backend/docs/` directories, including deployment guides, LAN testing instructions, and server migration records.

# Mediku (Media Informasi dan Diagnostik Kesehatanku)

Mediku is a comprehensive, multi-role healthcare application built with Flutter. It is designed to bridge the gap between patients and healthcare providers by offering tools for health tracking, AI-assisted preliminary diagnostics, scheduling, and health education.

## Overview

Mediku supports three distinct user roles:
- **Patients**: Can track health metrics, manage family profiles, consult with an AI assistant, view schedules, and read health articles.
- **Admins**: (Healthcare providers/staff) Can manage patient records, monitor patient metrics, schedule appointments, and publish health articles.
- **Superadmins**: System administrators who oversee platform usage and manage system-wide settings.

## Key Features

### For Patients
- **Health Tracking & Visualizations**: Monitor critical health metrics (like Blood Pressure) with interactive charts.
- **Multi-Profile Management**: Manage health records for multiple family members under a single account.
- **Tanya Asisten (AI Assistant)**: A dedicated chat interface for AI-powered health consultations and information.
- **Health Articles (Tanaman Toga)**: Educational content focused on traditional and medicinal plants (e.g., Jahe, Kunyit, Sirih).
- **Personalized Reports & Schedules**: Access health screening reports and upcoming medical appointments.

### For Admins
- **Patient Management**: Detailed views of patient profiles, screening histories, and health metrics.
- **Article Editor**: Create and manage educational health articles for patients.
- **Scheduling**: Organize and manage patient schedules and appointments.

## Tech Stack & Libraries

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.7)
- **Local Database**: `sqflite` & `sqflite_common_ffi` for robust local data storage.
- **Charts & Visualizations**: `fl_chart` for dynamic health metric charts.
- **Assets & UI Elements**: `flutter_svg`, `phosphor_flutter`, and `cupertino_icons`.
- **Utilities**: `shared_preferences`, `intl`, `uuid`, and `image_picker`.
- **Text Editing**: `flutter_quill` for rich-text article creation.

## Project Structure

- `lib/screens/` - Contains the UI for the different user roles:
  - `/patient/` - Patient-facing screens (dashboards, assistant, profiles).
  - `/admin/` - Admin-facing screens (patient management, scheduling, article editor).
  - `/superadmin/` - System administration interfaces.
- `lib/models/` - Data models (e.g., `family_profile.dart`, `health_metric.dart`, `tanaman_article.dart`).
- `lib/services/` - Core business logic and services (e.g., `database_helper.dart`, `chat_storage_service.dart`, `profile_service.dart`).
- `lib/widgets/` - Reusable UI components (e.g., `bp_chart_widget.dart`, `profile_selector.dart`).
- `docs/plans/` - Technical documentation and implementation plans for major features.

## Getting Started

To get started with this project locally:

1. **Prerequisites**: Ensure you have Flutter installed. Verify your installation by running:
   ```bash
   flutter doctor
   ```
2. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd ppko_bem_fk
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the App**:
   ```bash
   flutter run
   ```

## Documentation

Additional planning and design documentation can be found in the `docs/plans/` directory, detailing features such as multi-profile support, admin expansions, and metric animations.

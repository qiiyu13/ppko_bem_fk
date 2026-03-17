# Mediku Journey Web

Patient Health Journey Visualization - A Flutter Web application that displays animated patient health journeys via QR code.

## Features

- **4 Animated Chapters**: Profile, Metrics Timeline, Medical Journey, Current Snapshot
- **QR Code Sharing**: Each journey can be shared via generated QR code
- **Responsive Design**: Works on mobile and desktop
- **Static Data**: Patient data served via JSON files

## Demo URLs (After Deployment)

- Patient 001: `https://your-app.vercel.app/journey?patient_id=patient-001`
- Patient 002: `https://your-app.vercel.app/journey?patient_id=patient-002`

## Development

```bash
# Install dependencies
flutter pub get

# Run locally
flutter run -d chrome

# Build for production
flutter build web --release

# Copy patient data to build
cp -r public/patients build/web/

# Test production build locally
cd build/web
python3 -m http.server 8080
```

Then open: `http://localhost:8080/journey?patient_id=patient-001`

## Deployment to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login (one time)
vercel login

# Deploy
vercel --prod
```

## Adding New Patients

1. Create JSON file in `public/patients/{patient-id}.json`
2. Follow schema in existing patient files (patient-001.json)
3. Redeploy: `vercel --prod`

## Data Schema

See design document at `.opencode/plans/2025-01-17-patient-journey-design.md`

## Project Structure

```
mediku_journey_web/
├── lib/
│   ├── main.dart                 # App entry with go_router
│   ├── routes/
│   │   └── app_router.dart       # URL routing
│   ├── models/
│   │   └── patient.dart          # Data models
│   ├── services/
│   │   └── data_service.dart     # HTTP fetching
│   ├── screens/
│   │   ├── journey_screen.dart   # Main PageView
│   │   └── not_found_screen.dart # Error handling
│   └── widgets/
│       ├── animations/           # Reusable animations
│       ├── chapters/             # 4 chapter widgets
│       └── progress_indicator.dart
├── public/
│   └── patients/                 # JSON data files
├── web/
│   └── patients/                 # Copy for dev server
└── vercel.json                   # Vercel config
```

## Tech Stack

- **Flutter Web** - UI framework
- **go_router** - URL routing
- **fl_chart** - Animated charts
- **qr_flutter** - QR code generation
- **url_strategy** - Remove hash from URLs

## QR Code Generation

To create QR codes for your documents:

1. Generate URL: `https://your-app.vercel.app/journey?patient_id=patient-001`
2. Use any QR generator (e.g., qr-code-generator.com)
3. Print in marketing materials

## License

MIT

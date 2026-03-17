# MEDIKU Web Demo

A web wrapper for the MEDIKU mobile app that deploys to Vercel with DevicePreview frame.

## What This Does

- Wraps the main Mediku mobile app for web deployment
- Shows the app in a phone/device frame using DevicePreview
- Auto-logs in to patient dashboard (skips authentication)
- Zero changes to the main mobile app code

## Architecture

```
mediku_web_demo/
├── lib/main.dart          # Wrapper entry point
├── pubspec.yaml           # Imports main app via path
└── vercel.json            # Vercel deployment config
```

## Key Features

1. **Device Frame**: App displays in phone frame via DevicePreview
2. **Auto-Login**: Goes directly to patient dashboard
3. **Web Database**: Uses sqflite_common_ffi_web for compatibility
4. **Safe**: Main app code remains untouched

## Development

```bash
cd mediku_web_demo

# Run locally
flutter run -d chrome

# Build for production
flutter build web --release
```

## Deployment

```bash
cd mediku_web_demo

# Deploy to Vercel
vercel --prod
```

The deployed URL will show the Mediku mobile app running inside a device frame.

## How It Works

1. Wrapper imports main app as dependency (`path: ../`)
2. Sets up web-compatible database
3. Initializes demo profile
4. Launches directly to PatientMainScreen
5. Wraps everything in DevicePreview for phone frame

## Main App Unchanged

Your mobile app at `/home/qiu/Work/ppko_bem_fk/lib/` is completely untouched:
- Still builds for Android/iOS normally
- Still has login flow intact
- No modifications needed

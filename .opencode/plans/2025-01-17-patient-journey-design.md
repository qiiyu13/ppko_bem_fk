# Patient Journey Visualization - Design Document

> QR-Triggered Web-Based Patient Health Journey Demo

**Date:** 2025-01-17  
**Status:** Approved  
**Approach:** Hybrid Cinematic Timeline Story

---

## 1. Overview

A standalone Flutter Web application that displays an animated patient health journey when accessed via QR code. The journey visualizes a patient's health metrics timeline and medical visit history in an engaging, cinematic format.

### User Experience Flow

1. **QR Code Scan** → Opens web URL
2. **Intro Screen** → Patient name fades in with tagline
3. **Chapter 1** (5s) → Profile cards assemble with basic info
4. **Chapter 2** (8s) → Health metrics animate with drawing charts
5. **Chapter 3** (7s) → Journey timeline with milestones
6. **Chapter 4** (5s) → Current snapshot dashboard
7. **CTA** → Share button to regenerate QR code

---

## 2. Architecture

### Tech Stack
- **Framework:** Flutter Web
- **Charts:** fl_chart
- **QR Generation:** qr_flutter
- **Animations:** Flutter AnimationController + Tween
- **Data:** Static JSON files served via CDN
- **Hosting:** Vercel

### Project Structure
```
mediku-journey-web/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── routes.dart               # URL routing (patient_id param)
│   ├── screens/
│   │   ├── journey_screen.dart   # Main PageView container
│   │   └── not_found_screen.dart # Invalid patient_id
│   ├── widgets/
│   │   ├── chapters/
│   │   │   ├── profile_chapter.dart
│   │   │   ├── metrics_chapter.dart
│   │   │   ├── timeline_chapter.dart
│   │   │   └── snapshot_chapter.dart
│   │   └── animations/           # Reusable animation widgets
│   ├── models/
│   │   ├── patient.dart          # Patient data model
│   │   ├── health_metric.dart    # Metric readings model
│   │   └── appointment.dart      # Visit/timeline event model
│   └── services/
│       └── data_service.dart     # Fetch JSON from CDN
├── web/
│   └── index.html               # Flutter web entry
├── public/                      # CDN-served JSON files
│   └── patients/
│       ├── patient-001.json
│       └── patient-002.json
└── vercel.json                  # Vercel deployment config
```

### Data Flow

```
URL: /journey?patient_id=abc123
         ↓
JourneyScreen fetches: https://cdn.example.com/patients/abc123.json
         ↓
    ┌────┴────┐
    ↓         ↓
Patient   Timeline
Profile    Events
    ↓         ↓
    └────┬────┘
         ↓
  PageView with 4
  animated chapters
```

---

## 3. Data Schema

### Patient JSON Format

```json
{
  "id": "patient-001",
  "name": "Budi Santoso",
  "age": 45,
  "gender": "Pria",
  "bloodType": "O+",
  "avatarUrl": "https://.../avatar.png",
  "summary": "Perjalanan kesehatan 6 bulan terakhir",
  "metrics": {
    "bloodPressure": {
      "current": "120/80",
      "history": [
        {"date": "2024-07-01", "value": 125, "secondaryValue": 82},
        {"date": "2024-08-01", "value": 122, "secondaryValue": 80},
        {"date": "2024-09-01", "value": 120, "secondaryValue": 78}
      ]
    },
    "cholesterol": {
      "current": "195",
      "unit": "mg/dL",
      "history": [...]
    },
    "bloodSugar": {...},
    "uricAcid": {...}
  },
  "timeline": [
    {
      "date": "2024-07-15",
      "type": "appointment",
      "title": "Pemeriksaan Rutin",
      "description": "Tekanan darah normal, kolesterol sedikit tinggi",
      "status": "completed"
    },
    {
      "date": "2024-08-20",
      "type": "lab",
      "title": "Cek Lab",
      "description": "Hasil lab menunjukkan perbaikan",
      "status": "completed"
    }
  ]
}
```

---

## 4. UI/UX Design

### Chapter 1: Profile Foundation
- Cards slide in from edges with stagger (200ms delay each)
- Name card first, then age, blood type, gender
- Subtle bounce on landing
- Background: Clean white with soft gradient

### Chapter 2: Metrics Timeline
- Full-width animated line charts
- Each metric chart draws itself (line animation)
- 4 metrics in vertical stack: BP, Cholesterol, Blood Sugar, Uric Acid
- Color-coded by status (green/orange/red)
- Y-axis labels fade in after lines complete

### Chapter 3: Journey Timeline
- Vertical timeline with alternating cards
- Events slide in from left/right alternately
- Icons pulse on landing
- Connecting line draws downward as events appear
- Dots on timeline pulse when reached

### Chapter 4: Current Snapshot
- All metrics appear as dashboard cards
- Cards fly in from different directions
- Status indicators animate (checkmark, warning icons)
- "Lihat Detail" CTA fades in last
- Share button with QR regeneration

### Transitions
- Smooth page transitions with shared element animations
- Swipe gesture support for manual navigation
- Progress indicator at top (4 dots)
- Auto-advance with manual override

---

## 5. Animation Specifications

### Timing
- Chapter 1: 5 seconds total
  - Stagger delay: 200ms between cards
  - Slide duration: 600ms
  - Bounce: 300ms
- Chapter 2: 8 seconds
  - Chart line draw: 2s per chart
  - Stagger: 500ms between charts
- Chapter 3: 7 seconds
  - Timeline line draw: 2s
  - Event cards: 400ms each, 300ms stagger
- Chapter 4: 5 seconds
  - Cards: 500ms fly-in
  - CTA: 800ms fade + scale

### Easing
- Entry: `Curves.easeOutCubic`
- Exit: `Curves.easeInCubic`
- Bounce: `Curves.elasticOut` (subtle)

---

## 6. Share Functionality

### QR Generation
- Generate same QR code as original
- URL includes patient_id param
- Display with "Scan to view this journey"
- Copy link button

### Share Options
- Copy URL to clipboard
- Native share (if supported on web)
- Download QR code as PNG

---

## 7. Error Handling

### Invalid Patient ID
- Show "Patient not found" screen
- Link to create demo data
- List available demo patients

### JSON Load Failure
- Retry button
- Fallback to cached data (if visited before)
- Error message with patient ID

### Network Issues
- Offline indicator
- Cached data fallback
- Retry on reconnect

---

## 8. Performance

### Optimizations
- Lazy load charts (only when chapter visible)
- Image caching for avatars
- JSON preloading for next chapter
- 60fps animations using Flutter's render loop

### Web-Specific
- PWA manifest for installability
- Service worker for offline viewing
- Lazy loading for heavy widgets

---

## 9. Deployment

### Vercel Configuration
- Build command: `flutter build web --release`
- Output directory: `build/web`
- Environment: Production
- Custom domain: Optional

### CDN for JSON
- Static JSON files in `public/patients/`
- Vercel serves from `public/` automatically
- Or separate S3/R2 bucket with custom domain

### URL Format
```
Production: https://mediku-journey.vercel.app/journey?patient_id=abc123
Local: http://localhost:8080/journey?patient_id=abc123
```

---

## 10. Future Enhancements

- Video export of animation
- More patient data types (medications, allergies)
- Custom color themes per patient
- Analytics tracking (page views, shares)
- Admin panel to generate patient JSON

---

## Approved By

User confirmed approval on 2025-01-17

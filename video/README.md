# Mediku promo loop (Remotion)

A ~39s 1920×1080 loop of the kader ↔ warga flow, built from real screenshots
of the app (`public/screens/`), with taps, typing, transitions and the data
hand-off animated on top.

```bash
npm install
npm run render   # -> out/mediku-loop.mp4
npm run studio   # live preview
```

`remotion.config.ts` points at the Playwright headless shell that cloud
sessions ship with; change or remove `setBrowserExecutable` to run locally.

## Story

1. Warga shows the family QR (`p03_qr`)
2. Kader scans it (`k02_scanner`; the camera feed is drawn over the desktop build's "no camera" state)
3. Kader fills the screening form (`k05_form` → `k07_form_filled`, revealed field by field)
4. IRD result (`k15_detail` crop) and push to warga (`p10_home_after`)
5. Kader schedules a re-check (`k17_jadwal_baru` → `k20_jadwal_filled` → `k21_jadwal_saved`)
6. Warga sees the notification and the new schedule (`p11_notif_after`, `p12_jadwal_after`)

Timings live in `src/timeline.ts`; tap/field coordinates in `src/MedikuLoop.tsx`
are in the app's logical pixels (412×915).

## Re-capturing screenshots

Screens were taken from a Linux desktop build (`flutter build linux`, Flutter 3.38)
at 412×915 with `GDK_SCALE=2`, against a local backend seeded with demo data
(kader `kader.rina`, family KK `3275010203040005`). The screening form is only
reachable after a camera scan, so it was opened directly with the same JSON the
patient QR encodes.

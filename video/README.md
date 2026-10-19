# Mediku promo loop (Remotion)

A ~41s 1920×1080 loop of the kader ↔ warga flow. The phones play real
screenshots of the app (`public/screens/`); taps, typing, transitions, stickers,
ink annotations and the data hand-off are animated on top.

```bash
npm install
npm run render   # -> out/mediku-loop.mp4
npm run studio   # live preview
```

`remotion.config.ts` points at the Playwright headless shell that cloud
sessions ship with; change or remove `setBrowserExecutable` to run locally.

## Look

Sticker-book style: flat colored stages (warga = heart-card pink, kader = app
green, results = cream paper), paper grain, hard offset shadows, die-cut
stickers of the app's own illustrations (`public/art/`, rendered from
`assets/svg`), hand-drawn ink marks, Fraunces + Caveat + Plus Jakarta Sans
(fonts in `public/fonts`, OFL licenses alongside).

## Story (`src/MedikuLoop.tsx`)

| Scene | File | What happens |
| --- | --- | --- |
| Title (out) | `scenes/Title.tsx` | Static title card breaks apart |
| 01 Warga | `scenes/Warga.tsx` `WargaQR` | Budi opens his family QR; it peels off as a sticker |
| 02–03 Kader | `scenes/Kader.tsx` `KaderScan` | QR lands in the scanner, "Bip!", form is typed while a mascot checklist ticks off |
| 04 Result | `scenes/Result.tsx` | Real IRD card, gauge sweeps to 0.92, paper plane leaves |
| 05 Warga | `WargaReceive` | Phone buzzes, push arrives, metric mascots pop out of the cards |
| 06 Kader | `KaderJadwal` | Re-check scheduled, calendar sticker drops |
| 07 Warga | `WargaFinal` | Notification opened, new appointment circled |
| Title (in) | `scenes/Title.tsx` | Title card rebuilds; last frame equals the first |

Each scene uses its own local frames; tap and field coordinates are in the
app's logical pixels (412×915).

## Re-capturing screenshots

Screens were taken from a Linux desktop build (`flutter build linux`, Flutter 3.38)
at 412×915 with `GDK_SCALE=2`, against a local backend seeded with demo data
(kader `kader.rina`, family KK `3275010203040005`). The screening form is only
reachable after a camera scan, so it was opened directly with the same JSON the
patient QR encodes.

# Plan: Export QR codes for SekolahLansia profiles (print cards)

## Goal
Generate one QR-code image per profile under the `SekolahLansia` account,
saved to a local folder, for printing onto physical ID cards.

## Context
- Prod API base: `https://mediku.appunnes.id/api/v1`
- Account: username `SekolahLansia` (role `PATIENT`, org account — registers
  elderly profiles on their behalf, no self-registration).
- The app's QR dialog (`lib/widgets/profile_qr_dialog.dart`) encodes each
  profile as JSON:
  ```json
  {"profileId": "<uuid>", "name": "<string>", "nik": "<string|null>"}
  ```
  Generated cards must use the **same payload shape** so the existing
  in-app scanner (if any) or any future scan flow reads them correctly.
- `nik` may be `null` (birthDate/nik are optional fields, per
  `backend/prisma/schema.prisma` — org accounts often don't have it yet).

## Steps

1. **Get an auth token for the SekolahLansia account.**
   ```bash
   curl -s -X POST https://mediku.appunnes.id/api/v1/auth/login \
     -H 'Content-Type: application/json' \
     -d '{"identifier":"SekolahLansia","password":"<password>"}' \
     | node -pe "JSON.parse(require('fs').readFileSync(0)).data.token"
   ```

2. **Fetch all profiles for that account.**
   ```bash
   curl -s https://mediku.appunnes.id/api/v1/profiles \
     -H "Authorization: Bearer $TOKEN"
   ```
   Response `data` is an array of profiles with `id`, `name`, `nik`, `gender`, etc.

3. **Install a QR-image generator** (neither is installed yet — pick one):
   - Node: `npm install qrcode` (in a scratch dir, not the repo)
   - Python: `pip install qrcode[pil]`

4. **For each profile, generate a PNG** encoding:
   ```json
   {"profileId": "<id>", "name": "<name>", "nik": "<nik or null>"}
   ```
   Save as `<folder>/<name>-<id-prefix>.png` (dedupe names, avoid spaces
   causing filesystem issues — slugify).

   Example Node snippet (after `npm install qrcode`):
   ```js
   const QRCode = require('qrcode');
   const fs = require('fs');
   const profiles = JSON.parse(fs.readFileSync('profiles.json')); // from step 2
   for (const p of profiles) {
     const payload = JSON.stringify({ profileId: p.id, name: p.name, nik: p.nik });
     const safeName = p.name.replace(/[^a-z0-9]+/gi, '_');
     QRCode.toFile(`out/${safeName}-${p.id.slice(0,8)}.png`, payload, {
       errorCorrectionLevel: 'H',
       width: 512,
     });
   }
   ```

5. **Output folder**: use the session scratchpad or a throwaway dir, then
   hand the folder path back — not committed to the repo (these are
   per-org exported assets, not source code).

6. **Card layout** (per earlier decision): QR image only, no printed
   name/label baked into the PNG — labeling/layout for the physical card
   handled separately (e.g. in whatever print/design tool is used).

## Open decisions for next run
- Output folder path (scratchpad vs. somewhere durable).
- Whether to bake a name label into the image after all, or keep QR-only.
- Card size / DPI if the print tool needs a specific image resolution
  (512x512 above is a reasonable default, adjust `width` in the snippet).

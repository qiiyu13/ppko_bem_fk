# Audio guide (ElevenLabs)

Music and sound effects for `out/mediku-loop.mp4` (67.3 s, 60 fps, loops).
Timings below come straight from the scene timeline, so the cues land on the
real on-screen moments.

## 1. Background music (Eleven Music)

**Target:** 67 s, instrumental, loopable, 114 BPM. 32 bars of 4/4 at 114 BPM is
67.37 s, almost exactly the video length, so the music can loop with it.

### Simple prompt (Text to music)

```
Playful, warm, upbeat instrumental for an animated health-app explainer about
community health workers (kader posyandu) and families in Indonesia.
114 BPM, 4/4, major key. Ukulele and marimba lead with a bouncy plucked melody,
light glockenspiel sparkles, soft hand claps, gentle shaker and a hint of
angklung, warm round bass, soft kick. Cheerful, friendly, curious, never
corporate. Leaves room for UI sound effects: no busy drums, no heavy synths,
no vocals. Clean loopable ending that resolves back into the opening motif.
Length 67 seconds.
```

Negative/avoid (if the UI offers it): `vocals, lyrics, EDM drops, heavy drums,
dubstep, distorted guitar, dark, cinematic trailer, epic orchestra`.

### Section plan (composition plan / sections editor)

Use this when you want the energy to follow the story. Durations add up to 67.3 s.

| # | Section | Video | Duration | Style for the section |
| --- | --- | --- | --- | --- |
| 1 | Intro + Warga QR | 0:00–0:10.6 | 10.6 s | Ukulele pluck motif alone, then marimba joins; light, curious |
| 2 | Kader scan + screening | 0:10.6–0:26.7 | 16.1 s | Add claps, shaker and bass; steady, busy-but-light groove |
| 3 | IRD result | 0:26.7–0:33.9 | 7.2 s | Short lift: drums drop out, glockenspiel and rising marimba |
| 4 | Warga receives | 0:33.9–0:41.3 | 7.4 s | Full groove returns, happy and bright |
| 5 | Kader schedules | 0:41.3–0:51.9 | 10.6 s | Same groove with a melody variation on whistle or recorder |
| 6 | Warga final | 0:51.9–1:01.6 | 9.7 s | Peak energy, everything playing, still light |
| 7 | Outro / title | 1:01.6–1:07.3 | 5.7 s | Strip back to the opening ukulele motif so it loops into section 1 |

If timing matters more than polish, keep "respect section durations" on. If the
result sounds stiff, turn it off; the total length is kept either way.

### Tips
- Generate 3–4 versions and pick the one with the cleanest start and end.
- Check the loop: play the last 5 s into the first 5 s. If there's a bump,
  ask for "seamless loop, ending flows back into the beginning" again, or let me
  crossfade it in Remotion.
- If a version comes out slightly long or short, send it anyway; I can trim it
  or fit it to the video.

## 2. Sound effects (Sound Effects)

**Settings:** set the duration yourself (shown below), prompt influence about
**50–70%** for UI sounds (literal) and **30–40%** for playful ones. Generate 3–4
variations each and keep the best. Leave **Loop** off; none of these loop.
Export as WAV or MP3 and keep the file names below.

| File | Duration | Prompt |
| --- | --- | --- |
| `sfx_tap.wav` | 0.3 s | Soft rubbery tap on a phone screen, short, cute, dry, no reverb |
| `sfx_pop.wav` | 0.4 s | Bubbly cartoon pop, playful sticker popping onto paper, short |
| `sfx_whoosh.wav` | 0.8 s | Quick light airy whoosh, like a paper card swishing past, soft |
| `sfx_pan.wav` | 1.0 s | Smooth soft swoosh for a camera pan, airy, gentle, not aggressive |
| `sfx_scan_beep.wav` | 0.5 s | Friendly bright double beep of a QR code scanner confirming a scan, clean |
| `sfx_typing.wav` | 2.0 s | Soft smartphone keyboard typing, gentle quick taps, about ten keystrokes |
| `sfx_check.wav` | 0.5 s | Bright single marimba ding, short and positive, like ticking a checklist |
| `sfx_success.wav` | 1.5 s | Cheerful success chime followed by a small party popper confetti burst |
| `sfx_gauge.wav` | 2.0 s | Playful rising tick-up meter sound, fast ticks climbing, ends with a soft ding |
| `sfx_marker_circle.wav` | 0.7 s | Felt-tip marker quickly circling on paper, one fast scribble loop |
| `sfx_pen_write.wav` | 1.2 s | Short handwriting with a marker on paper, light scribbling |
| `sfx_paper_plane.wav` | 1.4 s | Paper airplane gliding past, soft fluttering whoosh, playful |
| `sfx_vibrate.wav` | 0.8 s | Phone vibrating twice on a wooden table, short buzz buzz |
| `sfx_notify.wav` | 0.8 s | Friendly mobile app notification chime, two warm rising notes |
| `sfx_sticker_slap.wav` | 0.6 s | Cartoon sticker slapped onto paper, soft thud with a tiny bounce |
| `sfx_title_build.wav` | 2.2 s | Playful ascending xylophone run with small pops, ending in a sparkle |
| `sfx_title_scatter.wav` | 1.2 s | Quick cartoon scatter, little pops and swishes as things fly apart |

## 3. Cue sheet

Times are from the start of the video (mm:ss.s). Volumes are a starting point
relative to the music.

| Time | Moment | SFX | Vol |
| --- | --- | --- | --- |
| 00:00.4 | Title breaks apart | `sfx_title_scatter` | 70% |
| 00:01.6 | Burst into Warga scene, phone flies up | `sfx_whoosh` | 60% |
| 00:02.8 | Pak Budi sticker | `sfx_pop` | 60% |
| 00:05.2 | Tap QR button | `sfx_tap` | 70% |
| 00:05.4 | QR dialog opens | `sfx_pop` | 50% |
| 00:06.6 | "satu QR…" note writes | `sfx_pen_write` | 50% |
| 00:08.9 | QR peels off as sticker | `sfx_pop` | 60% |
| 00:09.7 | QR flies away | `sfx_whoosh` | 70% |
| 00:10.6 | Pan to Kader | `sfx_pan` | 60% |
| 00:12.6 | Tap "Pindai QR" | `sfx_tap` | 70% |
| 00:13.4 | QR flies into scanner | `sfx_whoosh` | 60% |
| 00:14.6 | Scanner locks, "Bip!" | `sfx_scan_beep` + `sfx_pop` | 90% |
| 00:15.3 | "tanpa cari nama…" note | `sfx_pen_write` | 50% |
| 00:17.6 | Form slides in | `sfx_whoosh` | 40% |
| 00:19.6–00:25.6 | Fields type in | `sfx_typing` (3×, back to back) | 50% |
| 00:21.2 | ✓ Tensi | `sfx_check` | 70% |
| 00:23.0 | ✓ Berat · Tinggi | `sfx_check` (pitch +1) | 70% |
| 00:24.0 | ✓ Gula darah | `sfx_check` (pitch +2) | 70% |
| 00:24.8 | ✓ Asam urat | `sfx_check` (pitch +3) | 70% |
| 00:25.8 | ✓ Kolesterol | `sfx_check` (pitch +4) | 70% |
| 00:26.6 | Tap Simpan + confetti | `sfx_tap` + `sfx_success` | 90% |
| 00:27.0 | IRD card pops in | `sfx_sticker_slap` | 60% |
| 00:28.0 | Gauge sweeps to 0.92 | `sfx_gauge` | 70% |
| 00:30.2 | 0.92 gets circled | `sfx_marker_circle` | 70% |
| 00:30.4 | "Waspada…" note | `sfx_pen_write` | 50% |
| 00:33.5 | Paper plane takes off | `sfx_paper_plane` | 70% |
| 00:33.9 | Pan to Warga | `sfx_pan` | 50% |
| 00:35.5 | Phone buzzes + push | `sfx_vibrate` + `sfx_notify` | 90% |
| 00:37.3 | Numbers update | `sfx_pop` | 50% |
| 00:37.6 / 37.9 / 38.1 / 38.4 | Mascots pop out | `sfx_pop` ×4 (rising pitch) | 60% |
| 00:39.3 | "angka terbaru…" note | `sfx_pen_write` | 50% |
| 00:41.3 | Pan to Kader | `sfx_pan` | 60% |
| 00:43.7 | Tap Jadwal tab | `sfx_tap` | 70% |
| 00:44.7 | Tap Jadwal Baru | `sfx_tap` | 70% |
| 00:45.7–00:49.5 | Fields type in | `sfx_typing` (2×) | 50% |
| 00:47.6 | Calendar "26" drops | `sfx_sticker_slap` | 80% |
| 00:49.3 | Location note | `sfx_pen_write` | 50% |
| 00:50.3 | Tap Tambah + confetti | `sfx_tap` + `sfx_success` | 90% |
| 00:50.7 | Paper plane takes off | `sfx_paper_plane` | 70% |
| 00:51.9 | Pan to Warga | `sfx_pan` | 50% |
| 00:53.4 | Phone buzzes + push | `sfx_vibrate` + `sfx_notify` | 90% |
| 00:55.4 | Tap the notification | `sfx_tap` | 70% |
| 00:56.1 | Notification circled | `sfx_marker_circle` | 70% |
| 00:57.7 | Tap back | `sfx_tap` | 60% |
| 00:58.4 | Tap Jadwal | `sfx_tap` | 70% |
| 00:59.0 | New appointment circled | `sfx_marker_circle` | 70% |
| 00:59.3 | "cek ulang 26 Okt…" note | `sfx_pen_write` | 50% |
| 01:01.6 | Burst into title | `sfx_whoosh` | 60% |
| 01:01.9 | Title builds | `sfx_title_build` | 80% |

## 4. Mixing

- Keep the music around **-18 to -14 LUFS** under the effects; effects should
  sit on top without being harsh.
- Dip the music about 30% for the scan beep, both success moments and both
  notification moments, then bring it back.
- To have it mixed into the video for you, put the files in
  `video/public/audio/` (`music.mp3` plus the `sfx_*` files above) and the
  composition can place every cue on the exact frame.

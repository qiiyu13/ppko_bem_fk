import React from 'react';
import {Html5Audio, Sequence, interpolate, staticFile} from 'remotion';
import {TIME_SCALE, out} from './time';
import {DURATION, START, SceneKey} from './timing';

// Music and sound effects (ElevenLabs, see AUDIO.md). Files in public/audio
// are trimmed and loudness-matched, so cue volumes are relative mix levels.
//
// Cues are written in each scene's local frames (the same numbers the scene
// code uses for its taps, pops and notes) and placed absolutely via START.

type Cue = [scene: SceneKey, at: number, sfx: string, vol: number, dur?: number];

// Typed form fields: [start, duration] in scene frames (see scenes/Kader.tsx).
const SCREENING_FIELDS: [number, number][] = [
  [270, 18],
  [298, 16],
  [324, 16],
  [350, 18],
  [378, 18],
  [406, 16],
  [432, 18],
];
const JADWAL_FIELDS: [number, number][] = [
  [130, 28],
  [168, 18],
  [196, 18],
  [224, 20],
];
const CHECKS = [318, 372, 400, 426, 454];

const CUES: Cue[] = [
  // Title breaks apart
  ['intro', 10, 'title_scatter', 0.75],

  // 01 Warga shows the QR
  ['warga', 0, 'whoosh', 0.5],
  ['warga', 36, 'pop', 0.55],
  ['warga', 52, 'pen_write', 0.3, 26],
  ['warga', 110, 'tap', 0.8],
  ['warga', 116, 'pop', 0.4],
  ['warga', 150, 'pen_write', 0.35, 34],
  ['warga', 220, 'pop_3', 0.6],
  ['warga', 245, 'whoosh', 0.7],

  // 02-03 Kader scans and screens
  ['kader', 0, 'pan', 0.55],
  ['kader', 40, 'pop', 0.5],
  ['kader', 56, 'pen_write', 0.3, 24],
  ['kader', 60, 'tap', 0.8],
  ['kader', 84, 'whoosh', 0.6],
  ['kader', 120, 'scan_beep', 0.85],
  ['kader', 122, 'pop_4', 0.5],
  ['kader', 140, 'pen_write', 0.35, 26],
  ['kader', 210, 'whoosh', 0.35],
  ...SCREENING_FIELDS.map(([at, d]): Cue => ['kader', at, 'typing', 0.45, d + 6]),
  ...CHECKS.map((at, i): Cue => ['kader', at, `check_${i + 1}`, 0.7]),
  ['kader', 480, 'tap', 0.85],
  ['kader', 482, 'success', 0.85],

  // 04 IRD result
  ['result', 10, 'sticker_slap', 0.6],
  ['result', 34, 'pop', 0.4],
  ['result', 40, 'gauge', 0.65],
  ['result', 44, 'pop_2', 0.4],
  ['result', 104, 'marker_circle', 0.7],
  ['result', 112, 'pen_write', 0.35, 30],
  ['result', 205, 'paper_plane', 0.7],

  // 05 Warga receives the result
  ['receive', 0, 'pan', 0.45],
  ['receive', 46, 'vibrate', 0.75],
  ['receive', 48, 'notify', 0.8],
  ['receive', 100, 'pop', 0.4],
  ['receive', 110, 'pop_1', 0.55],
  ['receive', 118, 'pop_2', 0.55],
  ['receive', 126, 'pop_3', 0.55],
  ['receive', 134, 'pop_4', 0.55],
  ['receive', 160, 'pen_write', 0.35, 32],

  // 06 Kader schedules a re-check
  ['jadwal', 0, 'pan', 0.55],
  ['jadwal', 70, 'tap', 0.8],
  ['jadwal', 100, 'tap', 0.8],
  ['jadwal', 106, 'whoosh', 0.3],
  ...JADWAL_FIELDS.map(([at, d]): Cue => ['jadwal', at, 'typing', 0.45, d + 6]),
  ['jadwal', 188, 'sticker_slap', 0.75],
  ['jadwal', 240, 'pen_write', 0.35, 30],
  ['jadwal', 270, 'tap', 0.85],
  ['jadwal', 272, 'success', 0.85],
  ['jadwal', 282, 'paper_plane', 0.7],

  // 07 Warga sees it
  ['final', 0, 'pan', 0.45],
  ['final', 46, 'vibrate', 0.75],
  ['final', 48, 'notify', 0.8],
  ['final', 104, 'tap', 0.8],
  ['final', 109, 'whoosh', 0.3],
  ['final', 125, 'marker_circle', 0.65],
  ['final', 175, 'tap', 0.7],
  ['final', 195, 'tap', 0.8],
  ['final', 207, 'pop', 0.35],
  ['final', 212, 'marker_circle', 0.65],
  ['final', 222, 'pen_write', 0.35, 30],

  // Title rebuilds
  ['outro', 0, 'whoosh', 0.5],
  ['outro', 8, 'title_build', 0.8],
];

// Moments the music steps back for.
const DUCKS: [SceneKey, number][] = [
  ['kader', 120],
  ['kader', 482],
  ['receive', 48],
  ['jadwal', 272],
  ['final', 48],
  ['outro', 8],
];

const MUSIC = 0.42;
const DUCK_DEPTH = 0.4;

const musicVolume = (f: number) => {
  let duck = 0;
  for (const [scene, at] of DUCKS) {
    const t = START[scene] + at;
    duck = Math.max(
      duck,
      interpolate(f, [t - 6, t, t + 22, t + 44], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
    );
  }
  return MUSIC * (1 - DUCK_DEPTH * duck);
};

const sfx = (name: string) => staticFile(`audio/sfx_${name}.wav`);

export const Soundtrack: React.FC = () => (
  <>
    <Html5Audio src={staticFile('audio/music.mp3')} volume={(f) => musicVolume(f / TIME_SCALE)} />
    {CUES.map(([scene, at, name, vol, dur], i) => {
      const from = START[scene] + at;
      const length = Math.min(dur ?? 150, DURATION - from);
      return (
        <Sequence key={i} from={out(from)} durationInFrames={out(length)} layout="none">
          <Html5Audio
            src={sfx(name)}
            // short fade on clipped cues (typing, writing) so they don't click off
            volume={(f) => (dur ? vol * interpolate(f / TIME_SCALE, [dur - 5, dur], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}) : vol)}
          />
        </Sequence>
      );
    })}
  </>
);

// Scene lengths and transition overlap, shared by the picture and the soundtrack.
// Each scene leaves ~2-3s for its headline and notes to be read before the next beat.
export const TR = 28;
export const SCENES = {intro: 75, warga: 300, kader: 510, result: 245, receive: 250, jadwal: 345, final: 320, outro: 170};
export type SceneKey = keyof typeof SCENES;

export const DURATION = Object.values(SCENES).reduce((a, b) => a + b, 0) - 7 * TR;

// Absolute first frame of each scene (scenes overlap by TR during transitions).
export const START = (() => {
  const out = {} as Record<SceneKey, number>;
  let at = 0;
  for (const k of Object.keys(SCENES) as SceneKey[]) {
    out[k] = at;
    at += SCENES[k] - TR;
  }
  return out;
})();

// All timings in frames @30fps. The loop is 1180 frames (~39s).
export const DURATION = 1180;

export const T = {
  introOut: 30, // green cover starts shrinking
  phonesIn: 40,
  // Warga shows QR
  wTapQr: 150,
  qrFly: 270,
  qrLock: 322,
  wCloseQr: 395,
  // Kader scans + screens
  kTapScan: 250,
  kForm: 370,
  kSave: 572,
  // Results arrive at warga
  sync1: 584,
  banner1: 628,
  wHomeUpdate: 680,
  // Kader schedules
  kTapJadwalTab: 700,
  kTapJadwalBaru: 728,
  kSaveJadwal: 852,
  sync2: 862,
  banner2: 900,
  wTapBanner: 935,
  wBackFromNotif: 1005,
  wTapJadwal: 1030,
  outro: 1090,
};

export type Focus = [frame: number, scale: number, dim: number];

export const FOCUS_W: Focus[] = [
  [0, 1, 0], [240, 1, 0], [262, 0.9, 0.5], [578, 0.9, 0.5], [598, 1, 0],
  [700, 1, 0], [720, 0.9, 0.5], [864, 0.9, 0.5], [884, 1, 0],
];
export const FOCUS_K: Focus[] = [
  [0, 0.9, 0.5], [240, 0.9, 0.5], [262, 1, 0], [864, 1, 0], [884, 0.9, 0.5],
  [1060, 0.9, 0.5], [1085, 1, 0],
];

import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  Background,
  BrandCover,
  Callout,
  Confetti,
  DataFlight,
  PhoneLabel,
  PulseRing,
  PushBanner,
  Snackbar,
  StepCaption,
} from './components/Bits';
import {Phone, Reveal, Screens, ScreenStep, Tap, Touch, focusAt, screenGeom, toGlobal} from './components/Phone';
import {C, SCREEN_H, SCREEN_W, shot} from './theme';
import {Patch} from './components/Patch';
import {DURATION, FOCUS_K, FOCUS_W, T} from './timeline';

const W_CX = 500;
const K_CX = 1420;
const CY = 590;
const W_ENTER = T.phonesIn;
const K_ENTER = T.phonesIn + 8;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Where the patient's QR sits in p03_qr, and the scanner window in k02_scanner.
const QR_RECT: [number, number, number, number] = [108, 328, 204, 204];
const SCAN_FRAME: [number, number, number, number] = [86, 362, 248, 246];

const wSteps: ScreenStep[] = [
  {at: 0, src: 'p02_home'},
  {at: T.wTapQr + 6, src: 'p03_qr', t: 'pop'},
  {at: T.wCloseQr + 5, src: 'p02_home', t: 'fade'},
  {at: T.wHomeUpdate, src: 'p10_home_after', t: 'fade'},
  {at: T.wTapBanner + 5, src: 'p11_notif_after', t: 'push'},
  {at: T.wBackFromNotif + 5, src: 'p10_home_after', t: 'back'},
  {at: T.wTapJadwal + 4, src: 'p12_jadwal_after', t: 'fade'},
];

const wTaps: Tap[] = [
  {f: T.wTapQr, x: 368, y: 800},
  {f: T.wCloseQr, x: 290, y: 621},
  {f: T.wTapBanner, x: 200, y: 70},
  {f: T.wBackFromNotif, x: 22, y: 22},
  {f: T.wTapJadwal, x: 154, y: 885},
];

const kSteps: ScreenStep[] = [
  {at: 0, src: 'k01_dashboard'},
  {at: T.kTapScan + 6, src: 'k02_scanner', t: 'push'},
  {at: T.kForm, src: 'k05_form', t: 'push'},
  {at: T.kSave - 2, src: 'k07_form_filled'},
  {at: T.kSave + 10, src: 'k13_dashboard_after', t: 'back'},
  {at: T.kTapJadwalTab + 4, src: 'k16_jadwal', t: 'fade'},
  {at: T.kTapJadwalBaru + 6, src: 'k17_jadwal_baru', t: 'push'},
  {at: T.kSaveJadwal - 2, src: 'k20_jadwal_filled'},
  {at: T.kSaveJadwal + 6, src: 'k21_jadwal_saved', t: 'back'},
];

const kTaps: Tap[] = [
  {f: T.kTapScan, x: 333, y: 800},
  {f: T.kSave, x: 206, y: 884},
  {f: T.kTapJadwalTab, x: 154, y: 885},
  {f: T.kTapJadwalBaru, x: 329, y: 800},
  {f: T.kSaveJadwal, x: 206, y: 661},
];

// Screening form fields (k05_form -> k07_form_filled), typed one after another.
const F0 = T.kForm + 22;
const formFields: {rect: [number, number, number, number]; dur: number}[] = [
  {rect: [16, 274, 174, 50], dur: 14},
  {rect: [227, 274, 170, 50], dur: 12},
  {rect: [16, 390, 186, 50], dur: 12},
  {rect: [213, 390, 184, 50], dur: 14},
  {rect: [16, 505, 380, 50], dur: 14},
  {rect: [16, 592, 380, 50], dur: 12},
  {rect: [16, 678, 380, 50], dur: 14},
];

// "Tambah Jadwal" form (k17 -> k20).
const J0 = T.kTapJadwalBaru + 22;
const jadwalFields: {rect: [number, number, number, number]; dur: number}[] = [
  {rect: [16, 101, 380, 50], dur: 24},
  {rect: [16, 198, 380, 50], dur: 14},
  {rect: [16, 294, 380, 50], dur: 16},
  {rect: [16, 390, 380, 50], dur: 20},
];

const typed = (start: number, fields: {rect: [number, number, number, number]; dur: number}[]) => {
  let at = start;
  return fields.map((fl) => {
    const r = {...fl, at};
    at += fl.dur + 6;
    return r;
  });
};

const ScannerOverlay: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const from = T.kTapScan + 6;
  if (f < from || f > T.kForm + 14) return null;
  const [x, y, w, h] = SCAN_FRAME;
  const arrived = f >= T.qrFly + 44;
  const lock = spring({frame: f - T.qrLock, fps, config: {damping: 9, stiffness: 180}});
  const locked = f >= T.qrLock;
  const scan = (Math.sin(f / 7) + 1) / 2;
  return (
    <>
      {/* Live camera feed (the desktop build has no camera, so the error state is covered). */}
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: 120,
          width: SCREEN_W,
          height: 640,
          background: 'radial-gradient(ellipse at 50% 55%, #3a4a40 0%, #1a221d 55%, #0b0f0c 100%)',
        }}
      />
      {arrived ? (
        <div
          style={{
            position: 'absolute',
            left: x + 22,
            top: y + 22,
            width: w - 44,
            height: h - 44,
            overflow: 'hidden',
            borderRadius: 8,
            transform: `scale(${1 + 0.06 * lock * (locked ? 1 : 0)})`,
          }}
        >
          <Img
            src={shot('p03_qr')}
            style={{
              position: 'absolute',
              width: (SCREEN_W * (w - 44)) / QR_RECT[2],
              left: (-QR_RECT[0] * (w - 44)) / QR_RECT[2],
              top: (-QR_RECT[1] * (w - 44)) / QR_RECT[3],
              filter: 'brightness(0.92)',
            }}
          />
        </div>
      ) : null}
      <div
        style={{
          position: 'absolute',
          left: x,
          top: y,
          width: w,
          height: h,
          borderRadius: 20,
          border: `3px solid ${locked ? '#4ADE80' : C.primaryLight}`,
          boxShadow: locked ? `0 0 ${30 * lock}px rgba(74,222,128,0.8)` : 'none',
        }}
      />
      {!locked ? (
        <div
          style={{
            position: 'absolute',
            left: x + 14,
            top: y + 14 + scan * (h - 28),
            width: w - 28,
            height: 3,
            borderRadius: 2,
            background: '#4ADE80',
            boxShadow: '0 0 12px #4ADE80',
          }}
        />
      ) : (
        <div
          style={{
            position: 'absolute',
            left: SCREEN_W / 2,
            top: y + h + 40,
            transform: `translateX(-50%) scale(${lock})`,
            background: '#4ADE80',
            color: C.primary,
            fontWeight: 700,
            fontSize: 20,
            padding: '8px 22px',
            borderRadius: 999,
            fontFamily: 'Plus Jakarta Sans',
          }}
        >
          Bip! Terdeteksi
        </div>
      )}
    </>
  );
};

export const MedikuLoop: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();

  const geom = (cx: number, keys: typeof FOCUS_W, enterAt: number) =>
    screenGeom(cx, CY, focusAt(keys, f).scale, spring({frame: f - enterAt, fps, config: {damping: 16, mass: 0.9}}));
  const wG = geom(W_CX, FOCUS_W, W_ENTER);
  const kG = geom(K_CX, FOCUS_K, K_ENTER);

  // QR card flying from the patient's phone into the kader's scanner.
  const qrP = interpolate(f, [T.qrFly, T.qrFly + 44], [0, 1], clamp);
  const qrFrom = toGlobal(wG, QR_RECT[0] + QR_RECT[2] / 2, QR_RECT[1] + QR_RECT[3] / 2);
  const qrTo = toGlobal(kG, SCAN_FRAME[0] + SCAN_FRAME[2] / 2, SCAN_FRAME[1] + SCAN_FRAME[3] / 2);
  const ease = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  const qe = ease(qrP);
  const qrX = qrFrom.x + (qrTo.x - qrFrom.x) * qe;
  const qrY = qrFrom.y + (qrTo.y - qrFrom.y) * qe + Math.sin(Math.PI * qe) * 300;
  const qrSize = QR_RECT[2] * (wG.s + ((kG.s * (SCAN_FRAME[2] - 44)) / QR_RECT[2] - wG.s) * qe);

  const kSide = toGlobal(kG, 30, 450);
  const wSide = toGlobal(wG, 390, 450);

  return (
    <AbsoluteFill style={{fontFamily: 'Plus Jakarta Sans'}}>
      <Background />

      <PhoneLabel x={W_CX} y={52} title="Warga" sub="Keluarga Budi Santoso" enterAt={W_ENTER + 10} />
      <PhoneLabel x={K_CX} y={52} title="Kader Posyandu" sub="Rina Marlina · RW 05" dark enterAt={K_ENTER + 10} />

      <Phone cx={W_CX} cy={CY} focus={FOCUS_W} enterAt={W_ENTER}>
        <Screens steps={wSteps} />
        <PulseRing from={T.wHomeUpdate + 6} rect={[16, 221, 182, 181]} />
        <PulseRing from={T.wHomeUpdate + 6} rect={[214, 221, 182, 181]} delay={5} />
        <PulseRing from={T.wHomeUpdate + 6} rect={[16, 419, 182, 181]} delay={10} />
        <PulseRing from={T.wHomeUpdate + 6} rect={[214, 419, 182, 181]} delay={15} />
        <PulseRing from={T.wTapJadwal + 14} rect={[17, 519, 378, 106]} radius={16} />
        <PushBanner
          from={T.banner1}
          to={T.banner1 + 46}
          title="Hasil Skrining Tersedia"
          body="Skrining kesehatan Budi Santoso selesai. Kategori IRD: Perhatian."
        />
        <PushBanner
          from={T.banner2}
          to={T.wTapBanner + 2}
          title="Jadwal Skrining Baru"
          body="Cek Ulang Gula Darah RW 05 pada 26 Oktober 2026 di Balai Warga RW 05"
        />
        <Touch taps={wTaps} />
      </Phone>

      <Phone cx={K_CX} cy={CY} focus={FOCUS_K} enterAt={K_ENTER}>
        <Screens steps={kSteps} />
        <ScannerOverlay />
        {typed(F0, formFields).map((fl, i) => (
          <Reveal key={i} at={fl.at} dur={fl.dur} src="k07_form_filled" rect={fl.rect} until={T.kSave - 2} />
        ))}
        {typed(J0, jadwalFields).map((fl, i) => (
          <Reveal key={i} at={fl.at} dur={fl.dur} src="k20_jadwal_filled" rect={fl.rect} until={T.kSaveJadwal - 2} />
        ))}
        <Snackbar from={T.kSave + 12} to={T.kSave + 90} text="Data screening berhasil disimpan!" />
        <Confetti at={T.kSave + 2} x={206} y={860} />
        <Confetti at={T.kSaveJadwal + 2} x={206} y={650} />
        <Patch from={T.kSaveJadwal + 80} src="k16_jadwal" rect={[0, 760, 412, 90]} />
        <Touch taps={kTaps} />
      </Phone>

      {/* QR card in flight */}
      {qrP > 0 && qrP < 1 ? (
        <div
          style={{
            position: 'absolute',
            left: qrX - qrSize / 2,
            top: qrY - qrSize / 2,
            width: qrSize,
            height: qrSize,
            overflow: 'hidden',
            borderRadius: 14,
            background: '#fff',
            boxShadow: '0 18px 40px rgba(13,31,20,0.3)',
            transform: `rotate(${Math.sin(Math.PI * qe) * -14}deg)`,
          }}
        >
          <Img
            src={shot('p03_qr')}
            style={{
              position: 'absolute',
              width: (SCREEN_W * qrSize) / QR_RECT[2],
              height: (SCREEN_H * qrSize) / QR_RECT[3],
              left: (-QR_RECT[0] * qrSize) / QR_RECT[2],
              top: (-QR_RECT[1] * qrSize) / QR_RECT[3],
            }}
          />
        </div>
      ) : null}

      <DataFlight at={T.sync1} dur={42} from={kSide} to={wSide} label="Hasil skrining" />
      <DataFlight at={T.sync2} dur={38} from={kSide} to={wSide} label="Jadwal baru" />

      <StepCaption from={95} to={245} n={1} title="Warga tunjukkan QR" sub="Setiap anggota keluarga punya QR unik di aplikasi Mediku." x={960} y={330} />
      <StepCaption from={255} to={372} n={2} title="Kader pindai QR" sub="Data pasien langsung terbuka, tanpa cari manual." x={960} y={330} />
      <StepCaption from={378} to={T.kSave + 6} n={3} title="Isi hasil skrining" sub="Tensi, berat & tinggi, gula darah, asam urat, kolesterol." x={960} y={330} />
      <StepCaption from={T.kSave + 14} to={T.kTapJadwalTab - 4} n={4} title="IRD dihitung otomatis" sub="Hasil langsung terkirim ke HP warga." x={960} y={200} />
      <Callout from={T.kSave + 26} to={T.kTapJadwalTab - 6} src="k15_detail" rect={[16, 316, 380, 138]} x={960} y={660} scale={1.3} />
      <StepCaption from={T.kTapJadwalTab + 4} to={T.sync2 - 2} n={5} title="Kader buat jadwal" sub="Cek ulang gula darah dijadwalkan untuk warga RW 05." x={960} y={330} />
      <StepCaption from={T.sync2 + 14} to={T.outro - 6} n={6} title="Warga langsung tahu" sub="Notifikasi, hasil skrining, dan jadwal, semua di genggaman." x={960} y={330} />

      <BrandCover openAt={T.introOut} closeAt={T.outro} end={DURATION} />
    </AbsoluteFill>
  );
};

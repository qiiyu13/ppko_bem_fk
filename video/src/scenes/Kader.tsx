import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, spring} from 'remotion';
import {useFrame, useClock} from '../time';
import {Check, InkLayer, Squiggle} from '../components/Ink';
import {Device, Field, PHONE_SCALE, Reveal, Screens, ScreenStep, Tap, Touch, devicePoint, typed} from '../components/Phone';
import {Burst, CalendarSticker, Confetti, PaperPlane, ScreenSticker, Stage, Sticker, stickerFilter} from '../components/Stickers';
import {Headline, Kicker, Note} from '../components/Type';
import {C, F, SCREEN_W, STAGE, art, shot} from '../theme';
import {QR_RECT} from './Warga';

const T = STAGE.kader;
export const K_PHONE = {cx: 1360, cy: 545, rotate: 4};
const TEXT_X = 130;
const HEAD = 110;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const Phone: React.FC<{steps: ScreenStep[]; taps: Tap[]; children?: React.ReactNode}> = ({steps, taps, children}) => (
  <Device {...K_PHONE} caseColor={C.cream} buttonColor={C.yellow} shadow={T.shadow}>
    <Screens steps={steps} />
    {children}
    <Touch taps={taps} />
  </Device>
);

// ---- Scan + screening -------------------------------------------------------

const SCAN_FRAME: [number, number, number, number] = [86, 362, 248, 246];
const SCAN_PUSH = 66;
const QR_IN = 84;
const QR_LAND = 118;
const LOCK = 120;
const FORM = 210;
const F0 = 270;
const SAVE = 480;

// Screening form fields (k05_form -> k07_form_filled).
const FORM_FIELDS: Field[] = [
  {rect: [16, 274, 174, 50], dur: 18},
  {rect: [227, 274, 170, 50], dur: 16},
  {rect: [16, 390, 186, 50], dur: 16},
  {rect: [213, 390, 184, 50], dur: 18},
  {rect: [16, 505, 380, 50], dur: 18},
  {rect: [16, 592, 380, 50], dur: 16},
  {rect: [16, 678, 380, 50], dur: 18},
];
const FORM_TIMES = typed(F0, FORM_FIELDS, 10);

const CHECKLIST: {icon: string; label: string; value: string; done: number; h: number}[] = [
  {icon: 'blood_pressure', label: 'Tensi', value: '142/90', done: FORM_TIMES[1].end, h: 70},
  {icon: 'running_modified', label: 'Berat · Tinggi', value: '74 · 168', done: FORM_TIMES[3].end, h: 52},
  {icon: 'blood_sugar', label: 'Gula darah', value: '152', done: FORM_TIMES[4].end, h: 34},
  {icon: 'uric_acid', label: 'Asam urat', value: '7.1', done: FORM_TIMES[5].end, h: 62},
  {icon: 'cholestrol', label: 'Kolesterol', value: '222', done: FORM_TIMES[6].end, h: 32},
];

const ScannerOverlay: React.FC = () => {
  const f = useFrame();
  const {fps} = useClock();
  if (f < SCAN_PUSH || f > FORM + 14) return null;
  const [x, y, w, h] = SCAN_FRAME;
  const lock = spring({frame: f - LOCK, fps, config: {damping: 8, stiffness: 200}});
  const locked = f >= LOCK;
  const scan = (Math.sin(f / 6) + 1) / 2;
  const inner = w - 44;
  return (
    <>
      {/* Live camera feed; the desktop build has no camera, so its error state is covered. */}
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
      {f >= QR_LAND ? (
        <div
          style={{
            position: 'absolute',
            left: x + 22,
            top: y + 22,
            width: inner,
            height: inner,
            overflow: 'hidden',
            borderRadius: 8,
            transform: `scale(${1 + 0.07 * lock})`,
          }}
        >
          <Img
            src={shot('p03_qr')}
            style={{
              position: 'absolute',
              width: (SCREEN_W * inner) / QR_RECT[2],
              left: (-QR_RECT[0] * inner) / QR_RECT[2],
              top: (-QR_RECT[1] * inner) / QR_RECT[3],
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
          border: `3px solid ${locked ? C.yellow : C.primaryLight}`,
          boxShadow: locked ? `0 0 ${34 * lock}px ${C.yellow}` : 'none',
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
            background: C.yellow,
            boxShadow: `0 0 12px ${C.yellow}`,
          }}
        />
      ) : null}
      {/* screen flash on lock */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: '#fff',
          opacity: interpolate(f, [LOCK, LOCK + 2, LOCK + 10], [0, 0.6, 0], clamp),
        }}
      />
    </>
  );
};

const ChecklistRow: React.FC<{i: number; y: number; item: (typeof CHECKLIST)[number]}> = ({i, y, item}) => {
  const f = useFrame();
  const {fps} = useClock();
  const at = FORM + 16 + i * 5;
  const s = spring({frame: f - at, fps, config: {damping: 12, stiffness: 150}});
  const done = f >= item.done;
  const bounce = spring({frame: f - item.done, fps, config: {damping: 7, stiffness: 220}});
  const value = interpolate(f, [item.done, item.done + 10], [0, 1], clamp);
  if (f < at) return null;
  return (
    <div style={{position: 'absolute', left: TEXT_X, top: y, width: 820, height: 84, opacity: s, transform: `translateX(${(1 - s) * -60}px)`}}>
      <div style={{position: 'absolute', left: 0, top: 0, width: 84, height: 84, display: 'grid', placeItems: 'center'}}>
        <Img
          src={art(item.icon)}
          style={{
            height: item.h,
            filter: stickerFilter(4, '#08230F', 4, 5),
            transform: `scale(${done ? 1 + 0.25 * Math.sin(Math.min(1, bounce) * Math.PI) : 0.85}) rotate(${done ? 0 : -8}deg)`,
            opacity: done ? 1 : 0.55,
          }}
        />
      </div>
      <div style={{position: 'absolute', left: 112, top: 18, fontFamily: F.ui, fontWeight: 700, fontSize: 32, color: C.cream}}>{item.label}</div>
      <div
        style={{
          position: 'absolute',
          left: 112,
          right: 140,
          top: 66,
          borderBottom: `3px dashed ${done ? 'transparent' : 'rgba(246,239,226,0.25)'}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 470,
          top: 4,
          fontFamily: F.hand,
          fontWeight: 700,
          fontSize: 58,
          color: C.yellow,
          clipPath: `inset(-60% ${(1 - value) * 130 - 30}% -60% -10%)`,
          transform: 'rotate(-3deg)',
        }}
      >
        {item.value}
      </div>
    </div>
  );
};

export const KaderScan: React.FC = () => {
  const f = useFrame();
  const target = devicePoint(K_PHONE, SCAN_FRAME[0] + SCAN_FRAME[2] / 2, SCAN_FRAME[1] + SCAN_FRAME[3] / 2, f);
  const p = interpolate(f, [QR_IN, QR_LAND], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const qx = -180 + (target.x + 180) * p;
  const qy = 60 + (target.y - 60) * p - Math.sin(p * Math.PI) * 120;
  const qScale = 1.35 + (((SCAN_FRAME[2] - 44) * PHONE_SCALE) / QR_RECT[2] - 1.35) * p;
  const qSize = QR_RECT[2] * qScale;
  const save = devicePoint(K_PHONE, 206, 884, f);
  const rows = CHECKLIST.map((item, i) => ({item, y: 520 + i * 98}));

  return (
    <AbsoluteFill>
      <Stage theme={T} numeral={f < FORM ? '02' : '03'} numeralX={-30} />

      {/* Part 1: scan */}
      <Kicker at={14} x={TEXT_X} y={170} n="02" label="KADER" theme={T} exitAt={FORM - 8} />
      <Headline
        at={20}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        exitAt={FORM - 10}
        lines={[['Pindai,'], [{t: 'bip!', em: true}], [{t: 'data', hl: true}, 'terbuka.']]}
      />
      <Note at={140} x={TEXT_X} y={630} text="tanpa cari nama satu-satu" color={C.yellow} size={52} rotate={-3} exitAt={FORM - 10} />
      <Sticker src={art('kader')} at={40} x={760} y={885} h={400} rotate={6} from={{x: 760, y: 1400}} exitAt={FORM - 10} shadow="#08230F" />
      <Note at={56} x={TEXT_X} y={800} text={'Bu Rina,\nkader RW 05'} color={C.cream} size={50} rotate={-5} exitAt={FORM - 10} />

      {/* Part 2: screening */}
      <Kicker at={FORM + 2} x={TEXT_X} y={170} n="03" label="SKRINING" theme={T} />
      <Headline
        at={FORM + 6}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        lines={[['Isi hasilnya,'], [{t: 'sekali', em: true}, {t: 'jalan.', em: true}]]}
      />
      {rows.map((r, i) => (
        <ChecklistRow key={i} i={i} y={r.y} item={r.item} />
      ))}
      <InkLayer>
        {rows.map((r, i) => (
          <Check key={i} x={TEXT_X + 700} y={r.y + 14} s={52} at={r.item.done + 4} color={C.yellow} width={9} />
        ))}
      </InkLayer>

      <Phone
        steps={[
          {at: 0, src: 'k01_dashboard'},
          {at: SCAN_PUSH, src: 'k02_scanner', t: 'push'},
          {at: FORM, src: 'k05_form', t: 'push'},
          {at: SAVE - 2, src: 'k07_form_filled'},
        ]}
        taps={[
          {f: 60, x: 333, y: 800},
          {f: SAVE, x: 206, y: 884},
        ]}
      >
        <ScannerOverlay />
        {FORM_TIMES.map((fl, i) => (
          <Reveal key={i} at={fl.at} dur={fl.dur} src="k07_form_filled" rect={fl.rect} until={SAVE - 2} />
        ))}
      </Phone>

      <Burst at={LOCK + 2} x={1080} y={230} r={115} text="Bip!" rotate={-12} exitAt={FORM - 6} />

      {f >= QR_IN && f < QR_LAND ? (
        <ScreenSticker
          src="p03_qr"
          rect={QR_RECT}
          scale={qScale}
          style={{left: qx - qSize / 2, top: qy - qSize / 2, transform: `rotate(${(1 - p) * 40 + p * K_PHONE.rotate}deg)`}}
        />
      ) : null}

      <Confetti at={SAVE + 2} x={save.x} y={save.y} />
    </AbsoluteFill>
  );
};

export const KADER_SAVE_POINT = devicePoint(K_PHONE, 206, 884, 0);
export const KADER_SCAN_DURATION = 510;

// ---- Jadwal -----------------------------------------------------------------

const J_TAB = 70;
const J_NEW = 100;
const J0 = 130;
const J_SAVE = 270;

// "Tambah Jadwal" form (k17 -> k20).
const JADWAL_FIELDS: Field[] = [
  {rect: [16, 101, 380, 50], dur: 28},
  {rect: [16, 198, 380, 50], dur: 18},
  {rect: [16, 294, 380, 50], dur: 18},
  {rect: [16, 390, 380, 50], dur: 20},
];
const J_TIMES = typed(J0, JADWAL_FIELDS, 10);

export const KaderJadwal: React.FC = () => {
  const f = useFrame();
  const add = devicePoint(K_PHONE, 206, 661, f);
  const start = devicePoint(K_PHONE, 30, 300, f);
  return (
    <AbsoluteFill>
      <Stage theme={T} numeral="06" numeralX={-30} />
      <Kicker at={14} x={TEXT_X} y={170} n="06" label="KADER" theme={T} />
      <Headline
        at={20}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        lines={[['Jadwal'], ['cek ulang?'], [{t: 'Beres.', em: true}]]}
      />
      <CalendarSticker at={J_TIMES[1].end + 2} x={300} y={800} month="OKT" day="26" rotate={-7} />
      <Note at={J_TIMES[3].end - 4} x={470} y={700} width={520} text={'Balai Warga RW 05\n08.00 – 10.00'} color={C.yellow} size={50} rotate={-3} />
      <InkLayer>
        <Squiggle x1={480} x2={800} y={826} at={J_TIMES[3].end + 10} color={C.cream} seed="j1" amp={5} width={5} />
      </InkLayer>

      <Phone
        steps={[
          {at: 0, src: 'k13_dashboard_after'},
          {at: J_TAB + 4, src: 'k16_jadwal', t: 'fade'},
          {at: J_NEW + 6, src: 'k17_jadwal_baru', t: 'push'},
          {at: J_SAVE - 2, src: 'k20_jadwal_filled'},
          {at: J_SAVE + 6, src: 'k21_jadwal_saved', t: 'back'},
        ]}
        taps={[
          {f: J_TAB, x: 154, y: 885},
          {f: J_NEW, x: 329, y: 800},
          {f: J_SAVE, x: 206, y: 661},
        ]}
      >
        {J_TIMES.map((fl, i) => (
          <Reveal key={i} at={fl.at} dur={fl.dur} src="k20_jadwal_filled" rect={fl.rect} until={J_SAVE - 2} />
        ))}
      </Phone>
      <Confetti at={J_SAVE + 2} x={add.x} y={add.y} />
      <PaperPlane
        at={J_SAVE + 12}
        dur={40}
        path={[
          {x: start.x, y: start.y},
          {x: 1000, y: -40},
          {x: 500, y: 40},
          {x: -260, y: 160},
        ]}
        label="jadwal baru"
        trail={C.cream}
      />
    </AbsoluteFill>
  );
};

import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, random, spring, staticFile} from 'remotion';
import {useFrame, useClock} from '../time';
import {C, DISPLAY_VARS, F, SCREEN_H, SCREEN_W, StageTheme, shot} from '../theme';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Die-cut white border + hard offset shadow, like a vinyl sticker.
export const stickerFilter = (border = 7, shadow = 'rgba(0,0,0,0.22)', sx = 9, sy = 11) =>
  [
    [border, 0],
    [-border, 0],
    [0, border],
    [0, -border],
    [border * 0.7, border * 0.7],
    [-border * 0.7, border * 0.7],
    [border * 0.7, -border * 0.7],
    [-border * 0.7, -border * 0.7],
  ]
    .map(([x, y]) => `drop-shadow(${x}px ${y}px 0 #fff)`)
    .concat(`drop-shadow(${sx}px ${sy}px 0 ${shadow})`)
    .join(' ');

export const usePop = (at: number, exitAt?: number) => {
  const f = useFrame();
  const {fps} = useClock();
  const s = spring({frame: f - at, fps, config: {damping: 9, stiffness: 170, mass: 0.7}});
  const out = exitAt === undefined ? 0 : interpolate(f, [exitAt, exitAt + 10], [0, 1], {...clamp, easing: Easing.in(Easing.back(2))});
  return {s, out, f};
};

export const Sticker: React.FC<{
  src: string;
  at: number;
  x: number;
  y: number;
  h: number;
  rotate?: number;
  exitAt?: number;
  shadow?: string;
  wobble?: number;
  from?: {x: number; y: number};
  flip?: boolean;
}> = ({src, at, x, y, h, rotate = 0, exitAt, shadow, wobble = 1, from, flip}) => {
  const {s, out, f} = usePop(at, exitAt);
  if (f < at) return null;
  const px = from ? from.x + (x - from.x) * Math.min(1, s) : x;
  const py = from ? from.y + (y - from.y) * Math.min(1, s) : y;
  const sway = Math.sin((f + random(src) * 100) / 18) * 3 * wobble;
  const sq = 1 + (1 - s) * 0.25;
  return (
    <Img
      src={src}
      style={{
        position: 'absolute',
        left: px,
        top: py,
        height: h,
        transform: `translate(-50%, -50%) rotate(${rotate + sway + (1 - s) * -25}deg) scale(${s * (1 - out) * (flip ? -1 : 1)}, ${(s * (1 - out)) / sq})`,
        filter: stickerFilter(Math.max(5, h * 0.025), shadow),
      }}
    />
  );
};

// A crop of a real screenshot turned into a sticker.
export const ScreenSticker: React.FC<{
  src: string;
  rect: [number, number, number, number];
  scale: number;
  style?: React.CSSProperties;
  children?: React.ReactNode;
}> = ({src, rect, scale, style, children}) => {
  const [rx, ry, rw, rh] = rect;
  return (
    <div
      style={{
        position: 'absolute',
        width: rw * scale,
        height: rh * scale,
        borderRadius: 16 * scale,
        overflow: 'hidden',
        background: '#fff',
        boxShadow: `0 0 0 ${8}px #fff, 14px 16px 0 8px rgba(0,0,0,0.2)`,
        ...style,
      }}
    >
      <div style={{position: 'absolute', width: SCREEN_W, height: SCREEN_H, transform: `scale(${scale})`, transformOrigin: '0 0', left: -rx * scale, top: -ry * scale}}>
        <Img src={shot(src)} style={{width: SCREEN_W, height: SCREEN_H}} />
        {children}
      </div>
    </div>
  );
};

// Comic starburst ("Bip!").
export const Burst: React.FC<{at: number; x: number; y: number; r: number; text: string; rotate?: number; exitAt?: number}> = ({
  at,
  x,
  y,
  r,
  text,
  rotate = -10,
  exitAt,
}) => {
  const {s, out, f} = usePop(at, exitAt);
  if (f < at) return null;
  const n = 14;
  const pts = new Array(n * 2)
    .fill(0)
    .map((_, i) => {
      const a = (i / (n * 2)) * Math.PI * 2;
      const rr = i % 2 ? r * 0.72 : r * (1 + (random(`b${i}`) - 0.5) * 0.12);
      return `${r * 1.2 + Math.cos(a) * rr},${r * 1.2 + Math.sin(a) * rr}`;
    })
    .join(' ');
  const pulse = 1 + Math.sin((f - at) / 3) * 0.03;
  return (
    <div
      style={{
        position: 'absolute',
        left: x - r * 1.2,
        top: y - r * 1.2,
        width: r * 2.4,
        height: r * 2.4,
        transform: `rotate(${rotate + (1 - s) * 60}deg) scale(${s * pulse * (1 - out)})`,
      }}
    >
      <svg width={r * 2.4} height={r * 2.4} style={{position: 'absolute', overflow: 'visible'}}>
        <polygon points={pts} fill={C.ink} transform={`translate(8 10)`} opacity={0.35} />
        <polygon points={pts} fill={C.yellow} stroke={C.ink} strokeWidth={6} strokeLinejoin="round" />
      </svg>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'grid',
          placeItems: 'center',
          fontFamily: F.display,
          fontVariationSettings: DISPLAY_VARS,
          fontStyle: 'italic',
          fontWeight: 800,
          fontSize: r * 0.62,
          color: C.ink,
        }}
      >
        {text}
      </div>
    </div>
  );
};

export const CalendarSticker: React.FC<{at: number; x: number; y: number; month: string; day: string; rotate?: number}> = ({
  at,
  x,
  y,
  month,
  day,
  rotate = 8,
}) => {
  const {s, f} = usePop(at);
  if (f < at) return null;
  const drop = (1 - s) * -380;
  return (
    <div
      style={{
        position: 'absolute',
        left: x - 115,
        top: y - 130 + drop,
        width: 230,
        height: 250,
        transform: `rotate(${rotate + Math.sin(f / 20) * 2}deg)`,
        filter: stickerFilter(8),
      }}
    >
      <div style={{position: 'absolute', inset: 0, borderRadius: 30, background: '#fff', overflow: 'hidden', border: `5px solid ${C.ink}`}}>
        <div
          style={{
            height: 74,
            background: C.coral,
            borderBottom: `5px solid ${C.ink}`,
            color: '#fff',
            fontFamily: F.ui,
            fontWeight: 800,
            fontSize: 34,
            letterSpacing: 8,
            display: 'grid',
            placeItems: 'center',
          }}
        >
          {month}
        </div>
        <div
          style={{
            fontFamily: F.display,
            fontVariationSettings: DISPLAY_VARS,
            fontWeight: 800,
            fontSize: 140,
            lineHeight: '160px',
            textAlign: 'center',
            color: C.ink,
          }}
        >
          {day}
        </div>
      </div>
      {[60, 170].map((rx) => (
        <div key={rx} style={{position: 'absolute', left: rx - 9, top: -16, width: 18, height: 40, borderRadius: 9, background: C.ink}} />
      ))}
    </div>
  );
};

type P = {x: number; y: number};

// Paper plane on a curved path, leaving a dashed trail and towing a label.
export const PaperPlane: React.FC<{at: number; dur: number; path: [P, P, P, P]; label?: string; color?: string; trail: string}> = ({
  at,
  dur,
  path,
  label,
  color = C.cream,
  trail,
}) => {
  const f = useFrame() - at;
  if (f < 0 || f > dur + 2) return null;
  const pt = (t: number) => {
    const [a, b, c, d] = path;
    const u = 1 - t;
    return {
      x: u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x,
      y: u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y,
    };
  };
  const p = Easing.inOut(Easing.quad)(Math.min(1, f / dur));
  const cur = pt(p);
  const ahead = pt(Math.min(1, p + 0.01));
  const ang = (Math.atan2(ahead.y - cur.y, ahead.x - cur.x) * 180) / Math.PI;
  const tail = new Array(24)
    .fill(0)
    .map((_, i) => pt(Math.max(0, p - 0.3 + (i / 23) * 0.3)))
    .map((q) => `${q.x.toFixed(1)},${q.y.toFixed(1)}`)
    .join(' ');
  return (
    <>
      <svg width={1920} height={1080} style={{position: 'absolute', left: 0, top: 0, overflow: 'visible'}}>
        <polyline points={tail} fill="none" stroke={trail} strokeWidth={5} strokeDasharray="4 14" strokeLinecap="round" />
      </svg>
      {label ? (
        <div
          style={{
            position: 'absolute',
            left: pt(Math.max(0, p - 0.07)).x,
            top: pt(Math.max(0, p - 0.07)).y + 46,
            transform: `translate(-50%, -50%) rotate(${Math.sin(f / 4) * 6}deg)`,
            background: C.yellow,
            border: `4px solid ${C.ink}`,
            borderRadius: 999,
            padding: '8px 22px',
            fontFamily: F.hand,
            fontWeight: 700,
            fontSize: 36,
            color: C.ink,
            whiteSpace: 'nowrap',
            boxShadow: `5px 6px 0 rgba(0,0,0,0.2)`,
          }}
        >
          {label}
        </div>
      ) : null}
      <svg
        width={120}
        height={80}
        viewBox="0 0 120 80"
        style={{position: 'absolute', left: cur.x - 60, top: cur.y - 40, transform: `rotate(${ang}deg)`, overflow: 'visible'}}
      >
        <polygon points="118,40 4,6 34,40 4,74" fill={color} stroke={C.ink} strokeWidth={5} strokeLinejoin="round" />
        <polygon points="118,40 34,40 22,58" fill="#d9cfbd" stroke={C.ink} strokeWidth={5} strokeLinejoin="round" />
      </svg>
    </>
  );
};

const Shape: React.FC<{kind: number; size: number; color: string}> = ({kind, size, color}) => {
  if (kind === 0)
    return (
      <svg width={size} height={size} viewBox="0 0 10 10">
        <path d="M4 0h2v4h4v2H6v4H4V6H0V4h4z" fill={color} />
      </svg>
    );
  if (kind === 1)
    return (
      <svg width={size} height={size} viewBox="0 0 10 10">
        <path d="M5 9 C1 6 0 4 1.5 2.2 C3 .8 4.4 1.6 5 2.8 C5.6 1.6 7 .8 8.5 2.2 C10 4 9 6 5 9z" fill={color} />
      </svg>
    );
  if (kind === 2)
    return (
      <svg width={size} height={size} viewBox="0 0 10 10">
        <path d="M1 9 C1 4 4 1 9 1 C9 6 6 9 1 9z" fill={color} />
      </svg>
    );
  return <div style={{width: size, height: size, borderRadius: '50%', background: color}} />;
};

// Confetti of crosses, hearts, leaves and dots.
export const Confetti: React.FC<{at: number; x: number; y: number; spread?: number}> = ({at, x, y, spread = 1}) => {
  const f = useFrame() - at;
  if (f < 0 || f > 70) return null;
  const colors = [C.yellow, C.coral, C.sky, C.statusGreen, C.kunyit, C.cream];
  return (
    <>
      {new Array(40).fill(0).map((_, i) => {
        const a = -Math.PI / 2 + (random(`ca${i}`) - 0.5) * 2.4 * spread;
        const v = 14 + random(`cv${i}`) * 16;
        const drag = 1 - Math.min(0.9, f / 70);
        const px = x + Math.cos(a) * v * f * drag;
        const py = y + Math.sin(a) * v * f * drag + 0.55 * f * f * 0.6;
        const size = 18 + random(`cs${i}`) * 18;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: px,
              top: py,
              opacity: interpolate(f, [50, 70], [1, 0], clamp),
              transform: `rotate(${f * 12 * (random(`ct${i}`) - 0.5) + i * 30}deg) scale(${interpolate(f, [0, 6], [0.2, 1], clamp)})`,
            }}
          >
            <Shape kind={i % 4} size={size} color={colors[i % colors.length]} />
          </div>
        );
      })}
    </>
  );
};

// Heads-up push notification, as FCM shows it on the phone.
export const PushBanner: React.FC<{from: number; to: number; title: string; body: string}> = ({from, to, title, body}) => {
  const f = useFrame();
  const {fps} = useClock();
  if (f < from || f > to + 12) return null;
  const sIn = spring({frame: f - from, fps, config: {damping: 11, stiffness: 140}});
  const out = interpolate(f, [to, to + 12], [0, 1], {...clamp, easing: Easing.in(Easing.cubic)});
  return (
    <div
      style={{
        position: 'absolute',
        left: 10,
        right: 10,
        top: 10 + (1 - sIn) * -140 - out * 140,
        borderRadius: 22,
        background: 'rgba(255,255,255,0.98)',
        boxShadow: '0 12px 30px rgba(13,31,20,0.28)',
        border: `1px solid rgba(0,0,0,0.06)`,
        padding: '12px 14px',
        fontFamily: F.ui,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: C.textSecondary}}>
        <Img src={staticFile('brand/logo_only.png')} style={{width: 18, height: 18}} />
        <span style={{fontWeight: 600, color: C.primary}}>Mediku</span>
        <span>· sekarang</span>
      </div>
      <div style={{fontSize: 15, fontWeight: 700, color: C.textPrimary, marginTop: 6}}>{title}</div>
      <div style={{fontSize: 13, color: C.textSecondary, marginTop: 2, lineHeight: 1.35}}>{body}</div>
    </div>
  );
};

export const PulseRing: React.FC<{from: number; rect: [number, number, number, number]; radius?: number; delay?: number; color?: string}> = ({
  from,
  rect,
  radius = 26,
  delay = 0,
  color = C.coral,
}) => {
  const f = useFrame() - from - delay;
  if (f < 0 || f > 60) return null;
  const [x, y, w, h] = rect;
  const p = interpolate(f, [0, 30], [0, 1], clamp);
  const flash = interpolate(f, [0, 4, 18], [0, 0.35, 0], clamp);
  return (
    <>
      <div style={{position: 'absolute', left: x, top: y, width: w, height: h, borderRadius: radius, background: '#fff', opacity: flash}} />
      <div
        style={{
          position: 'absolute',
          left: x - 12 * p,
          top: y - 12 * p,
          width: w + 24 * p,
          height: h + 24 * p,
          borderRadius: radius + 12 * p,
          border: `4px solid ${color}`,
          opacity: 1 - p,
        }}
      />
    </>
  );
};

// Flat colored stage with a giant outlined step numeral behind everything.
export const Stage: React.FC<{theme: StageTheme; numeral?: string; numeralX?: number; children?: React.ReactNode}> = ({
  theme,
  numeral,
  numeralX = 1000,
  children,
}) => {
  const f = useFrame();
  return (
    <AbsoluteFill style={{background: theme.bg, overflow: 'hidden'}}>
      {numeral ? (
        <div
          style={{
            position: 'absolute',
            left: numeralX + Math.sin(f / 50) * 10,
            top: 330,
            fontFamily: F.display,
            fontVariationSettings: DISPLAY_VARS,
            fontWeight: 900,
            fontSize: 980,
            lineHeight: 1,
            color: theme.numeral,
            letterSpacing: -40,
          }}
        >
          {numeral}
        </div>
      ) : null}
      {children}
    </AbsoluteFill>
  );
};

// Animated paper grain over the whole frame.
export const Grain: React.FC<{amount: number}> = ({amount}) => {
  const f = useFrame();
  const seed = Math.floor(f / 2) % 8;
  return (
    <AbsoluteFill style={{pointerEvents: 'none', mixBlendMode: 'multiply', opacity: amount}}>
      <svg width="100%" height="100%">
        <filter id={`g${seed}`}>
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed={seed} stitchTiles="stitch" />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width="100%" height="100%" filter={`url(#g${seed})`} />
      </svg>
    </AbsoluteFill>
  );
};

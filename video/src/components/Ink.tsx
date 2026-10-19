import React from 'react';
import {Easing, interpolate, random, spring, useCurrentFrame, useVideoConfig} from 'remotion';

// Hand-drawn marks: every path is slightly wobbly (seeded, so it is stable
// frame to frame) and draws itself on like a marker stroke.

type Pt = [number, number];

const smooth = (pts: Pt[]) => {
  // Catmull-Rom through the points, emitted as cubic beziers.
  let d = `M ${pts[0][0].toFixed(1)} ${pts[0][1].toFixed(1)}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] ?? p2;
    const c1: Pt = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2: Pt = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    d += ` C ${c1[0].toFixed(1)} ${c1[1].toFixed(1)} ${c2[0].toFixed(1)} ${c2[1].toFixed(1)} ${p2[0].toFixed(1)} ${p2[1].toFixed(1)}`;
  }
  return d;
};

export const arrowPath = (from: Pt, to: Pt, bend: number, seed: string) => {
  const mx = (from[0] + to[0]) / 2;
  const my = (from[1] + to[1]) / 2;
  const dx = to[0] - from[0];
  const dy = to[1] - from[1];
  const len = Math.hypot(dx, dy);
  const nx = -dy / len;
  const ny = dx / len;
  const pts: Pt[] = [];
  for (let i = 0; i <= 12; i++) {
    const t = i / 12;
    const b = Math.sin(Math.PI * t) * bend;
    const j = (random(`${seed}-${i}`) - 0.5) * 3;
    pts.push([from[0] + dx * t + nx * (b + j), from[1] + dy * t + ny * (b + j)]);
  }
  void mx;
  void my;
  const body = smooth(pts);
  const end = pts[pts.length - 1];
  const prev = pts[pts.length - 3];
  const ang = Math.atan2(end[1] - prev[1], end[0] - prev[0]);
  const head = 26;
  const h1: Pt = [end[0] - Math.cos(ang - 0.5) * head, end[1] - Math.sin(ang - 0.5) * head];
  const h2: Pt = [end[0] - Math.cos(ang + 0.45) * head, end[1] - Math.sin(ang + 0.45) * head];
  return {body, head: `M ${h1[0]} ${h1[1]} L ${end[0]} ${end[1]} L ${h2[0]} ${h2[1]}`};
};

export const squigglePath = (x1: number, x2: number, y: number, amp: number, seed: string) => {
  const n = 14;
  const pts: Pt[] = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    pts.push([x1 + (x2 - x1) * t, y + Math.sin(t * Math.PI * 5) * amp + (random(`${seed}-${i}`) - 0.5) * 2]);
  }
  return smooth(pts);
};

export const checkPath = (x: number, y: number, s: number) =>
  smooth([
    [x, y + s * 0.5],
    [x + s * 0.18, y + s * 0.66],
    [x + s * 0.36, y + s * 0.92],
    [x + s * 0.62, y + s * 0.45],
    [x + s, y],
  ]);

const useDraw = (at: number, dur: number) => {
  const f = useCurrentFrame();
  return interpolate(f, [at, at + dur], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
};

export const Stroke: React.FC<{d: string; at: number; dur?: number; color: string; width?: number; opacity?: number}> = ({
  d,
  at,
  dur = 16,
  color,
  width = 7,
  opacity = 1,
}) => {
  const p = useDraw(at, dur);
  if (p <= 0) return null;
  return (
    <path
      d={d}
      pathLength={1}
      strokeDasharray={1}
      strokeDashoffset={1 - p}
      fill="none"
      stroke={color}
      strokeWidth={width}
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  );
};

// Full-frame SVG layer for ink marks in scene coordinates.
export const InkLayer: React.FC<{children: React.ReactNode}> = ({children}) => (
  <svg width={1920} height={1080} style={{position: 'absolute', left: 0, top: 0, overflow: 'visible', pointerEvents: 'none'}}>
    {children}
  </svg>
);

export const Arrow: React.FC<{from: Pt; to: Pt; bend?: number; at: number; color: string; seed: string; width?: number}> = ({
  from,
  to,
  bend = 60,
  at,
  color,
  seed,
  width = 6,
}) => {
  const a = arrowPath(from, to, bend, seed);
  return (
    <>
      <Stroke d={a.body} at={at} dur={16} color={color} width={width} />
      <Stroke d={a.head} at={at + 14} dur={6} color={color} width={width} />
    </>
  );
};

export const Squiggle: React.FC<{x1: number; x2: number; y: number; at: number; color: string; seed: string; amp?: number; width?: number}> = ({
  x1,
  x2,
  y,
  at,
  color,
  seed,
  amp = 7,
  width = 6,
}) => <Stroke d={squigglePath(x1, x2, y, amp, seed)} at={at} dur={18} color={color} width={width} />;

export const Check: React.FC<{x: number; y: number; s: number; at: number; color: string; width?: number}> = ({x, y, s, at, color, width = 7}) => (
  <Stroke d={checkPath(x, y, s)} at={at} dur={10} color={color} width={width} />
);

// Little "brrr" strokes around a buzzing phone.
export const Buzz: React.FC<{cx: number; cy: number; w: number; h: number; at: number; color: string}> = ({cx, cy, w, h, at, color}) => {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > 22) return null;
  const o = interpolate(f, [0, 4, 16, 22], [0, 1, 1, 0]);
  const off = interpolate(f, [0, 22], [0, 18]);
  const lines: [number, number, number][] = [
    [-1, -0.32, -18],
    [-1, -0.18, 0],
    [-1, -0.04, 18],
    [1, -0.32, 18],
    [1, -0.18, 0],
    [1, -0.04, -18],
  ];
  return (
    <g opacity={o}>
      {lines.map(([side, ty, ang], i) => {
        const x = cx + side * (w / 2 + 30 + off);
        const y = cy + ty * h;
        const len = 38;
        const a = (ang * Math.PI) / 180;
        return (
          <line
            key={i}
            x1={x}
            y1={y}
            x2={x + side * Math.cos(a) * len}
            y2={y + Math.sin(a) * len}
            stroke={color}
            strokeWidth={7}
            strokeLinecap="round"
          />
        );
      })}
    </g>
  );
};

// A loop like a marker pen makes: starts at the upper left, sweeps a bit more
// than once around and finishes just outside where it began.
const loopPath = (rx: number, ry: number, seed: string, turns: number, drift: number) => {
  const n = 40;
  const pts: Pt[] = [];
  const start = -2.45 + (random(seed) - 0.5) * 0.25;
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    const a = start + t * Math.PI * 2 * turns;
    const k = 1 + Math.sin(t * 7 + random(`${seed}-k`) * 6) * 0.025 + (t - 0.5) * drift;
    pts.push([Math.cos(a) * rx * k, Math.sin(a) * ry * k]);
  }
  return smooth(pts);
};

// Circles something (given by its center and size) with a hand-drawn loop:
// a quick main stroke, a lighter second pass, a highlighter tint underneath,
// a little bounce and three emphasis ticks when the pen lifts.
export const MarkerCircle: React.FC<{
  cx: number;
  cy: number;
  w: number;
  h: number;
  at: number;
  color: string;
  seed: string;
  rotate?: number;
  pad?: number;
  width?: number;
  tint?: string;
}> = ({cx, cy, w, h, at, color, seed, rotate = 0, pad = 24, width = 7, tint}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  if (f < at) return null;
  const rx = w / 2 + pad;
  const ry = h / 2 + pad * 0.8;
  const DRAW = 17;
  const pen = Easing.bezier(0.45, 0, 0.2, 1);
  const p1 = interpolate(f, [at, at + DRAW], [0, 1], {extrapolateRight: 'clamp', easing: pen});
  const p2 = interpolate(f, [at + 5, at + 5 + DRAW], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: pen});
  const tintIn = spring({frame: f - at - 6, fps, config: {damping: 14}});
  const end = at + DRAW;
  const bounce = f < end ? 1 : 1 + 0.06 * Math.sin(Math.min(1, (f - end) / 9) * Math.PI);
  const main = loopPath(rx, ry, seed, 1.1, 0.09);
  const second = loopPath(rx * 1.04, ry * 1.06, `${seed}-b`, 1.02, 0.05);
  // ticks radiate from the upper right of the loop
  const ticks = [-0.95, -0.62, -0.3].map((a, i) => {
    const r0 = 1.12;
    const r1 = 1.38;
    const x0 = Math.cos(a) * rx * r0;
    const y0 = Math.sin(a) * ry * r0;
    const x1 = Math.cos(a) * (rx * r0 + (r1 - r0) * 90);
    const y1 = Math.sin(a) * (ry * r0 + (r1 - r0) * 90);
    const tp = interpolate(f, [end + i * 2, end + i * 2 + 6], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
    return tp > 0 ? (
      <line key={i} x1={x0} y1={y0} x2={x0 + (x1 - x0) * tp} y2={y0 + (y1 - y0) * tp} stroke={color} strokeWidth={width * 0.8} strokeLinecap="round" />
    ) : null;
  });
  const dash = (p: number) => ({pathLength: 1, strokeDasharray: 1, strokeDashoffset: 1 - p});
  return (
    <g transform={`translate(${cx} ${cy}) rotate(${rotate}) scale(${bounce})`}>
      {tint ? (
        <ellipse rx={rx * 0.92 * tintIn} ry={ry * 0.82 * tintIn} fill={tint} opacity={0.22} style={{mixBlendMode: 'multiply'}} />
      ) : null}
      <path d={second} {...dash(p2)} fill="none" stroke={color} strokeWidth={width * 0.45} strokeLinecap="round" opacity={0.55} />
      <path d={main} {...dash(p1)} fill="none" stroke={color} strokeWidth={width} strokeLinecap="round" strokeLinejoin="round" />
      {ticks}
    </g>
  );
};

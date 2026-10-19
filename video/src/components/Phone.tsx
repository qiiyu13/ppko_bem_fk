import React from 'react';
import {Easing, Img, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, SCREEN_H, SCREEN_W, shot} from '../theme';

const ease = Easing.bezier(0.33, 0, 0.2, 1);
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const PHONE_SCALE = 0.98;
const CASE = 18;

export type DeviceProps = {
  cx: number;
  cy: number;
  rotate: number;
  caseColor: string;
  buttonColor: string;
  shadow: string;
  enterAt?: number;
  shakeAt?: number[];
  children: React.ReactNode;
};

const bob = (f: number) => ({y: Math.sin(f / 28) * 7, r: Math.sin(f / 37) * 0.7});

const shake = (f: number, at: number[] = []) => {
  for (const a of at) {
    const t = f - a;
    if (t >= 0 && t < 16) return Math.sin(t * 2.4) * 3.2 * (1 - t / 16);
  }
  return 0;
};

// Where a point on the app screen (logical px) lands in the scene, so effects
// outside the phone can line up with UI inside it.
export const devicePoint = (
  d: {cx: number; cy: number; rotate: number},
  lx: number,
  ly: number,
  f = 0,
) => {
  const b = bob(f);
  const r = ((d.rotate + b.r) * Math.PI) / 180;
  const x = (lx - SCREEN_W / 2) * PHONE_SCALE;
  const y = (ly - SCREEN_H / 2) * PHONE_SCALE;
  return {
    x: d.cx + x * Math.cos(r) - y * Math.sin(r),
    y: d.cy + b.y + x * Math.sin(r) + y * Math.cos(r),
  };
};

// A chunky toy-like phone in a colored case, floating on the stage.
export const Device: React.FC<DeviceProps> = ({cx, cy, rotate, caseColor, buttonColor, shadow, enterAt, shakeAt, children}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = enterAt === undefined ? 1 : spring({frame: f - enterAt, fps, config: {damping: 13, mass: 0.9}});
  const b = bob(f);
  const w = SCREEN_W * PHONE_SCALE;
  const h = SCREEN_H * PHONE_SCALE;
  const r = rotate + b.r + shake(f, shakeAt) + (1 - enter) * -18;
  return (
    <div
      style={{
        position: 'absolute',
        left: cx - w / 2 - CASE,
        top: cy - h / 2 - CASE + b.y + (1 - enter) * 1100,
        width: w + CASE * 2,
        height: h + CASE * 2,
        transform: `rotate(${r}deg)`,
      }}
    >
      {/* hard offset shadow, printed-sticker style */}
      <div style={{position: 'absolute', inset: 0, borderRadius: 72, background: shadow, transform: 'translate(22px, 26px)'}} />
      {/* side buttons */}
      <div style={{position: 'absolute', right: -7, top: 210, width: 12, height: 90, borderRadius: 6, background: buttonColor}} />
      <div style={{position: 'absolute', right: -7, top: 320, width: 12, height: 56, borderRadius: 6, background: buttonColor}} />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: 72,
          background: caseColor,
          boxShadow: `inset 0 0 0 4px ${C.ink}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: CASE,
          top: CASE,
          width: w,
          height: h,
          borderRadius: 54,
          overflow: 'hidden',
          background: C.appBg,
          boxShadow: `0 0 0 4px ${C.ink}`,
        }}
      >
        <div style={{position: 'absolute', width: SCREEN_W, height: SCREEN_H, transform: `scale(${PHONE_SCALE})`, transformOrigin: '0 0'}}>
          {children}
        </div>
      </div>
    </div>
  );
};

export type ScreenStep = {at: number; src: string; t?: 'push' | 'back' | 'fade' | 'pop' | 'cut'};

const TRANS = 13;

// Plays real screenshots with the same kinds of transitions the app uses.
export const Screens: React.FC<{steps: ScreenStep[]}> = ({steps}) => {
  const f = useCurrentFrame();
  let i = 0;
  steps.forEach((s, k) => {
    if (s.at <= f) i = k;
  });
  const cur = steps[i];
  const prev = i > 0 ? steps[i - 1] : null;
  const p = prev ? interpolate(f, [cur.at, cur.at + TRANS], [0, 1], {extrapolateRight: 'clamp', easing: ease}) : 1;
  const img = (src: string, style: React.CSSProperties) => (
    <Img src={shot(src)} style={{position: 'absolute', width: SCREEN_W, height: SCREEN_H, ...style}} />
  );
  const t = cur.t ?? 'cut';
  if (!prev || p >= 1 || t === 'cut') return img(cur.src, {});
  if (t === 'push') {
    return (
      <>
        {img(prev.src, {transform: `translateX(${-0.3 * SCREEN_W * p}px)`, filter: `brightness(${1 - 0.15 * p})`})}
        {img(cur.src, {transform: `translateX(${SCREEN_W * (1 - p)}px)`, boxShadow: '-12px 0 30px rgba(0,0,0,0.15)'})}
      </>
    );
  }
  if (t === 'back') {
    return (
      <>
        {img(cur.src, {transform: `translateX(${-0.3 * SCREEN_W * (1 - p)}px)`})}
        {img(prev.src, {transform: `translateX(${SCREEN_W * p}px)`, boxShadow: '-12px 0 30px rgba(0,0,0,0.15)'})}
      </>
    );
  }
  if (t === 'pop') {
    return (
      <>
        {img(prev.src, {})}
        {img(cur.src, {opacity: p, transform: `scale(${0.96 + 0.04 * p})`})}
      </>
    );
  }
  return (
    <>
      {img(prev.src, {})}
      {img(cur.src, {opacity: p})}
    </>
  );
};

export type Field = {rect: [x: number, y: number, w: number, h: number]; dur: number};

// Lays out typed fields one after another from `start`.
export const typed = (start: number, fields: Field[], gap = 6) => {
  let at = start;
  return fields.map((fl) => {
    const r = {...fl, at, end: at + fl.dur};
    at += fl.dur + gap;
    return r;
  });
};

// "Types" a field by wiping in the same region of the filled-in screenshot.
export const Reveal: React.FC<{at: number; dur: number; src: string; rect: Field['rect']; until?: number}> = ({
  at,
  dur,
  src,
  rect,
  until,
}) => {
  const f = useCurrentFrame();
  if (f < at || (until !== undefined && f >= until)) return null;
  const [x, y, w, h] = rect;
  const p = interpolate(f, [at, at + dur], [0, 1], {extrapolateRight: 'clamp'});
  // Stepped so it reads as keystrokes rather than a smooth slide.
  const stepped = Math.min(1, Math.ceil(p * 8) / 8);
  const caretOn = p < 1 && Math.floor(f / 4) % 2 === 0;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w * stepped, height: h, overflow: 'hidden'}}>
      <Img src={shot(src)} style={{position: 'absolute', left: -x, top: -y, width: SCREEN_W, height: SCREEN_H}} />
      {caretOn ? <div style={{position: 'absolute', right: 0, top: h * 0.25, width: 2, height: h * 0.5, background: C.primary}} /> : null}
    </div>
  );
};

// Region of another real screenshot, faded in (e.g. to clear a baked-in snackbar).
export const Patch: React.FC<{from: number; src: string; rect: [number, number, number, number]}> = ({from, src, rect}) => {
  const f = useCurrentFrame();
  if (f < from) return null;
  const [x, y, w, h] = rect;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: h, overflow: 'hidden', opacity: interpolate(f, [from, from + 8], [0, 1], clamp)}}>
      <Img src={shot(src)} style={{position: 'absolute', left: -x, top: -y, width: SCREEN_W, height: SCREEN_H}} />
    </div>
  );
};

export type Tap = {f: number; x: number; y: number};

// A chunky fingertip that glides in, squishes on contact and leaves a splash.
export const Touch: React.FC<{taps: Tap[]}> = ({taps}) => {
  const f = useCurrentFrame();
  const LEAD = 16;
  const active = taps.find((t) => f >= t.f - LEAD && f <= t.f + 14);
  if (!active) return null;
  const idx = taps.indexOf(active);
  const prevTap = taps[idx - 1];
  const from = prevTap && active.f - prevTap.f < 50 ? prevTap : {x: active.x + 60, y: active.y + 110};
  const mv = interpolate(f, [active.f - LEAD, active.f - 3], [0, 1], {...clamp, easing: ease});
  const x = from.x + (active.x - from.x) * mv;
  const y = from.y + (active.y - from.y) * mv;
  const squish = interpolate(f, [active.f - 3, active.f, active.f + 5], [1, 0.7, 1], clamp);
  const opacity = interpolate(f, [active.f - LEAD, active.f - LEAD + 5, active.f + 8, active.f + 14], [0, 1, 1, 0], clamp);
  const splash = interpolate(f, [active.f, active.f + 12], [0, 1], clamp);
  return (
    <div style={{position: 'absolute', left: x, top: y, opacity, pointerEvents: 'none'}}>
      {f >= active.f
        ? new Array(6).fill(0).map((_, i) => {
            const a = (i / 6) * Math.PI * 2 + 0.3;
            const r0 = 22 + splash * 22;
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: Math.cos(a) * r0 - 3,
                  top: Math.sin(a) * r0 - 9,
                  width: 6,
                  height: 18 * (1 - splash),
                  borderRadius: 3,
                  background: C.ink,
                  transform: `rotate(${(a * 180) / Math.PI + 90}deg)`,
                }}
              />
            );
          })
        : null}
      <div
        style={{
          position: 'absolute',
          left: -20,
          top: -20,
          width: 40,
          height: 40,
          borderRadius: '50%',
          background: C.yellow,
          border: `4px solid ${C.ink}`,
          transform: `scale(${2 - squish}, ${squish})`,
          boxShadow: `4px 5px 0 ${C.ink}`,
        }}
      />
    </div>
  );
};

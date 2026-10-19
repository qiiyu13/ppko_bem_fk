import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, SCREEN_H, SCREEN_W, shot} from '../theme';
import {Focus} from '../timeline';

export const BASE_SCALE = 0.93;
const BEZEL = 13;

const ease = Easing.bezier(0.33, 0, 0.2, 1);

export const focusAt = (keys: Focus[], f: number) => {
  const frames = keys.map((k) => k[0]);
  const opts = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease} as const;
  return {
    scale: interpolate(f, frames, keys.map((k) => k[1]), opts),
    dim: interpolate(f, frames, keys.map((k) => k[2]), opts),
  };
};

// Global geometry of a phone's screen, shared by the phone itself and any
// effect that has to fly between phones (QR card, data particles).
export const screenGeom = (cx: number, cy: number, focusScale: number, enter: number) => {
  const s = BASE_SCALE * focusScale;
  const y = cy + (1 - enter) * 900;
  return {s, x: cx - (SCREEN_W / 2) * s, y: y - (SCREEN_H / 2) * s};
};

export const toGlobal = (g: {s: number; x: number; y: number}, lx: number, ly: number) => ({
  x: g.x + lx * g.s,
  y: g.y + ly * g.s,
});

export type ScreenStep = {at: number; src: string; t?: 'push' | 'back' | 'fade' | 'pop' | 'cut'};

const TRANS = 14;

// Plays a list of real screenshots with the app's own kind of transitions.
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

// "Types" a field by wiping in the same region from the filled-in screenshot.
export const Reveal: React.FC<{
  at: number;
  dur: number;
  src: string;
  rect: [x: number, y: number, w: number, h: number];
  until?: number;
}> = ({at, dur, src, rect, until}) => {
  const f = useCurrentFrame();
  if (f < at || (until !== undefined && f >= until)) return null;
  const [x, y, w, h] = rect;
  const p = interpolate(f, [at, at + dur], [0, 1], {extrapolateRight: 'clamp'});
  // Step the wipe so it reads as keystrokes rather than a smooth slide.
  const stepped = Math.min(1, Math.ceil(p * 8) / 8);
  const caretOn = p < 1 && Math.floor(f / 4) % 2 === 0;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w * stepped, height: h, overflow: 'hidden'}}>
      <Img src={shot(src)} style={{position: 'absolute', left: -x, top: -y, width: SCREEN_W, height: SCREEN_H}} />
      {caretOn ? (
        <div style={{position: 'absolute', right: 0, top: h * 0.25, width: 2, height: h * 0.5, background: C.primary}} />
      ) : null}
    </div>
  );
};

export type Tap = {f: number; x: number; y: number};

// A soft fingertip that glides between taps and ripples on contact.
export const Touch: React.FC<{taps: Tap[]}> = ({taps}) => {
  const f = useCurrentFrame();
  const LEAD = 16;
  const active = taps.find((t) => f >= t.f - LEAD && f <= t.f + 14);
  if (!active) return null;
  const idx = taps.indexOf(active);
  const from = taps[idx - 1] && active.f - taps[idx - 1].f < 60 ? taps[idx - 1] : {x: active.x + 40, y: active.y + 70};
  const mv = interpolate(f, [active.f - LEAD, active.f - 3], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: ease,
  });
  const x = from.x + (active.x - from.x) * mv;
  const y = from.y + (active.y - from.y) * mv;
  const press = interpolate(f, [active.f - 3, active.f, active.f + 4], [1, 0.75, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const opacity = interpolate(f, [active.f - LEAD, active.f - LEAD + 5, active.f + 8, active.f + 14], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ripple = interpolate(f, [active.f, active.f + 14], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <div style={{position: 'absolute', left: x, top: y, opacity, pointerEvents: 'none'}}>
      {f >= active.f ? (
        <div
          style={{
            position: 'absolute',
            left: -40 * ripple,
            top: -40 * ripple,
            width: 80 * ripple,
            height: 80 * ripple,
            borderRadius: '50%',
            border: `3px solid rgba(20,68,37,${0.6 * (1 - ripple)})`,
          }}
        />
      ) : null}
      <div
        style={{
          position: 'absolute',
          left: -17,
          top: -17,
          width: 34,
          height: 34,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.75)',
          border: '2.5px solid rgba(20,68,37,0.55)',
          boxShadow: '0 4px 14px rgba(0,0,0,0.25)',
          transform: `scale(${press})`,
        }}
      />
    </div>
  );
};

export const Phone: React.FC<{
  cx: number;
  cy: number;
  focus: Focus[];
  enterAt: number;
  children: React.ReactNode;
}> = ({cx, cy, focus, enterAt, children}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f - enterAt, fps, config: {damping: 16, mass: 0.9}});
  const {scale, dim} = focusAt(focus, f);
  const g = screenGeom(cx, cy, scale, enter);
  const w = SCREEN_W * g.s;
  const h = SCREEN_H * g.s;
  const tilt = (1 - enter) * 8;
  return (
    <div
      style={{
        position: 'absolute',
        left: g.x - BEZEL,
        top: g.y - BEZEL,
        width: w + BEZEL * 2,
        height: h + BEZEL * 2,
        borderRadius: 58,
        background: '#121a15',
        boxShadow: `0 ${30 + 20 * (1 - dim)}px 80px rgba(13,31,20,${0.18 + 0.12 * (1 - dim)}), inset 0 0 0 2px #2c3a31`,
        transform: `rotate(${tilt}deg)`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: BEZEL,
          top: BEZEL,
          width: w,
          height: h,
          borderRadius: 46,
          overflow: 'hidden',
          background: C.background,
        }}
      >
        <div style={{position: 'absolute', width: SCREEN_W, height: SCREEN_H, transform: `scale(${g.s})`, transformOrigin: '0 0'}}>
          {children}
        </div>
        <AbsoluteFill style={{background: C.background, opacity: dim * 0.55, pointerEvents: 'none'}} />
      </div>
    </div>
  );
};

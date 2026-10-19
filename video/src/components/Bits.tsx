import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, FONT, SCREEN_H, SCREEN_W, shot} from '../theme';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Background: React.FC = () => {
  const f = useCurrentFrame();
  const blob = (x: number, y: number, r: number, color: string, speed: number) => (
    <div
      style={{
        position: 'absolute',
        left: x + Math.sin(f / speed) * 30 - r,
        top: y + Math.cos(f / speed) * 24 - r,
        width: r * 2,
        height: r * 2,
        borderRadius: '50%',
        background: color,
        filter: 'blur(10px)',
      }}
    />
  );
  return (
    <AbsoluteFill style={{background: C.background, overflow: 'hidden'}}>
      {blob(180, 160, 260, C.primarySurface, 70)}
      {blob(1780, 920, 320, C.primarySurface, 90)}
      {blob(960, 1040, 220, 'rgba(111,169,187,0.16)', 60)}
      {blob(1650, 120, 140, 'rgba(111,169,187,0.14)', 50)}
      {new Array(9).fill(0).map((_, i) => {
        const x = random(`lx${i}`) * 1920;
        const y = ((random(`ly${i}`) * 1080 - f * (0.25 + random(`ls${i}`) * 0.35)) % 1180) + 1180;
        return (
          <Img
            key={i}
            src={staticFile('brand/leaf_icon@3x.png')}
            style={{
              position: 'absolute',
              left: x,
              top: (y % 1180) - 80,
              width: 26 + random(`lw${i}`) * 22,
              opacity: 0.22,
              transform: `rotate(${f * (random(`lr${i}`) - 0.5) * 1.2 + i * 40}deg)`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

export const PhoneLabel: React.FC<{x: number; y: number; title: string; sub: string; dark?: boolean; enterAt: number}> = ({
  x,
  y,
  title,
  sub,
  dark,
  enterAt,
}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - enterAt, fps, config: {damping: 14}});
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        transform: `translate(-50%, ${(1 - s) * -40}px)`,
        opacity: s,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '10px 22px 10px 10px',
        borderRadius: 999,
        background: dark ? C.primary : '#fff',
        boxShadow: '0 8px 24px rgba(13,31,20,0.10)',
        fontFamily: FONT,
        whiteSpace: 'nowrap',
      }}
    >
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: '50%',
          background: dark ? 'rgba(255,255,255,0.15)' : C.primarySurface,
          color: dark ? '#fff' : C.primary,
          display: 'grid',
          placeItems: 'center',
          fontWeight: 700,
          fontSize: 18,
        }}
      >
        {title[0]}
      </div>
      <div>
        <div style={{fontWeight: 700, fontSize: 22, color: dark ? '#fff' : C.textPrimary, lineHeight: 1.1}}>{title}</div>
        <div style={{fontSize: 15, color: dark ? 'rgba(255,255,255,0.75)' : C.textSecondary}}>{sub}</div>
      </div>
    </div>
  );
};

export const StepCaption: React.FC<{from: number; to: number; n: number; title: string; sub: string; x: number; y: number}> = ({
  from,
  to,
  n,
  title,
  sub,
  x,
  y,
}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  if (f < from - 2 || f > to + 12) return null;
  const sIn = spring({frame: f - from, fps, config: {damping: 13}});
  const out = interpolate(f, [to, to + 12], [0, 1], clamp);
  const badge = spring({frame: f - from - 4, fps, config: {damping: 8, stiffness: 160}});
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: 400,
        transform: `translate(-50%, ${(1 - sIn) * 40 - out * 30}px)`,
        opacity: sIn * (1 - out),
        fontFamily: FONT,
        textAlign: 'center',
      }}
    >
      <div
        style={{
          margin: '0 auto 18px',
          width: 64,
          height: 64,
          borderRadius: 22,
          background: C.primary,
          color: '#fff',
          fontSize: 32,
          fontWeight: 700,
          display: 'grid',
          placeItems: 'center',
          transform: `scale(${badge}) rotate(${(1 - badge) * -30}deg)`,
          boxShadow: '0 10px 24px rgba(20,68,37,0.3)',
        }}
      >
        {n}
      </div>
      <div style={{fontSize: 38, fontWeight: 700, color: C.textPrimary, lineHeight: 1.15, letterSpacing: -0.5}}>{title}</div>
      <div style={{fontSize: 21, color: C.textSecondary, marginTop: 12, lineHeight: 1.4}}>{sub}</div>
    </div>
  );
};

// Same look as the app's SnackBar (floating, rounded, statusGreen).
export const Snackbar: React.FC<{from: number; to: number; text: string}> = ({from, to, text}) => {
  const f = useCurrentFrame();
  if (f < from || f > to + 8) return null;
  const pIn = interpolate(f, [from, from + 8], [0, 1], clamp);
  const pOut = interpolate(f, [to, to + 8], [0, 1], clamp);
  return (
    <div
      style={{
        position: 'absolute',
        left: 16,
        right: 16,
        top: 786,
        height: 48,
        borderRadius: 10,
        background: C.statusGreen,
        color: '#fff',
        fontFamily: FONT,
        fontSize: 14.5,
        display: 'flex',
        alignItems: 'center',
        padding: '0 16px',
        boxShadow: '0 6px 16px rgba(0,0,0,0.2)',
        opacity: pIn * (1 - pOut),
        transform: `translateY(${(1 - pIn) * 20}px)`,
      }}
    >
      {text}
    </div>
  );
};

// Heads-up push notification, as FCM shows it on the phone.
export const PushBanner: React.FC<{from: number; to: number; title: string; body: string}> = ({from, to, title, body}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  if (f < from || f > to + 12) return null;
  const sIn = spring({frame: f - from, fps, config: {damping: 12, stiffness: 140}});
  const out = interpolate(f, [to, to + 12], [0, 1], {...clamp, easing: Easing.in(Easing.cubic)});
  const wiggle = Math.sin((f - from) / 2) * interpolate(f - from, [6, 22], [4, 0], clamp);
  return (
    <div
      style={{
        position: 'absolute',
        left: 10,
        right: 10,
        top: 8 + (1 - sIn) * -130 - out * 130,
        borderRadius: 20,
        background: 'rgba(255,255,255,0.97)',
        boxShadow: '0 12px 30px rgba(13,31,20,0.25)',
        padding: '12px 14px',
        fontFamily: FONT,
        transform: `rotate(${wiggle * 0.3}deg)`,
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

export const PulseRing: React.FC<{from: number; rect: [number, number, number, number]; radius?: number; delay?: number}> = ({
  from,
  rect,
  radius = 26,
  delay = 0,
}) => {
  const f = useCurrentFrame() - from - delay;
  if (f < 0 || f > 70) return null;
  const [x, y, w, h] = rect;
  const pulse = (k: number) => {
    const p = interpolate(f - k * 18, [0, 30], [0, 1], clamp);
    return (
      <div
        key={k}
        style={{
          position: 'absolute',
          left: x - 10 * p,
          top: y - 10 * p,
          width: w + 20 * p,
          height: h + 20 * p,
          borderRadius: radius + 10 * p,
          border: `3px solid ${C.statusGreen}`,
          opacity: p > 0 ? 1 - p : 0,
        }}
      />
    );
  };
  return <>{[0, 1].map(pulse)}</>;
};

export const Confetti: React.FC<{at: number; x: number; y: number}> = ({at, x, y}) => {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > 60) return null;
  const colors = [C.primary, C.statusGreen, C.yellow, C.secondary, C.statusAmber, '#9BCB6B'];
  return (
    <>
      {new Array(34).fill(0).map((_, i) => {
        const a = random(`ca${i}`) * Math.PI - Math.PI;
        const v = 9 + random(`cv${i}`) * 11;
        const px = x + Math.cos(a) * v * f;
        const py = y + Math.sin(a) * v * f + 0.45 * f * f;
        const size = 8 + random(`cs${i}`) * 9;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: px,
              top: py,
              width: size,
              height: size * (random(`cr${i}`) > 0.5 ? 0.45 : 1),
              borderRadius: random(`cc${i}`) > 0.6 ? '50%' : 3,
              background: colors[i % colors.length],
              opacity: interpolate(f, [40, 60], [1, 0], clamp),
              transform: `rotate(${f * 14 * (random(`ct${i}`) - 0.5)}deg)`,
            }}
          />
        );
      })}
    </>
  );
};

// Data hopping from one phone to the other along an arc.
export const DataFlight: React.FC<{
  at: number;
  dur: number;
  from: {x: number; y: number};
  to: {x: number; y: number};
  label: string;
}> = ({at, dur, from, to, label}) => {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > dur + 12) return null;
  const pos = (p: number) => {
    const e = Easing.inOut(Easing.cubic)(p);
    const x = from.x + (to.x - from.x) * e;
    const dip = Math.sin(Math.PI * e) * 210;
    const y = from.y + (to.y - from.y) * e + dip;
    return {x, y};
  };
  const chipP = interpolate(f, [0, dur], [0, 1], clamp);
  const chip = pos(chipP);
  const chipScale = interpolate(f, [0, 6, dur - 4, dur + 6], [0.3, 1, 1, 0.2], clamp);
  return (
    <>
      {new Array(7).fill(0).map((_, i) => {
        const p = interpolate(f - 3 - i * 2.5, [0, dur], [0, 1], clamp);
        if (p <= 0 || p >= 1) return null;
        const d = pos(p);
        const r = 13 - i * 1.4;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: d.x - r,
              top: d.y - r,
              width: r * 2,
              height: r * 2,
              borderRadius: '50%',
              background: i % 2 ? C.statusGreen : C.yellow,
              opacity: 0.85 - i * 0.09,
            }}
          />
        );
      })}
      <div
        style={{
          position: 'absolute',
          left: chip.x,
          top: chip.y,
          transform: `translate(-50%, -50%) scale(${chipScale}) rotate(${Math.sin(f / 4) * 6}deg)`,
          padding: '12px 20px 12px 14px',
          borderRadius: 999,
          background: '#fff',
          boxShadow: '0 10px 26px rgba(13,31,20,0.22)',
          fontFamily: FONT,
          fontWeight: 700,
          fontSize: 20,
          color: C.primary,
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          whiteSpace: 'nowrap',
        }}
      >
        <div style={{width: 14, height: 14, borderRadius: '50%', background: C.statusGreen}} />
        {label}
      </div>
    </>
  );
};

// A crop of a real screenshot popped out of the phone and enlarged.
export const Callout: React.FC<{
  from: number;
  to: number;
  src: string;
  rect: [number, number, number, number];
  x: number;
  y: number;
  scale: number;
}> = ({from, to, src, rect, x, y, scale}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  if (f < from || f > to + 12) return null;
  const s = spring({frame: f - from, fps, config: {damping: 10, stiffness: 120}});
  const out = interpolate(f, [to, to + 12], [0, 1], clamp);
  const [rx, ry, rw, rh] = rect;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: rw,
        height: rh,
        overflow: 'hidden',
        borderRadius: 18,
        boxShadow: '0 20px 50px rgba(13,31,20,0.25)',
        transform: `translate(-50%, -50%) scale(${scale * s * (1 - out * 0.3)}) rotate(${(1 - s) * -8 + Math.sin(f / 20) * 1}deg)`,
        opacity: 1 - out,
      }}
    >
      <Img src={shot(src)} style={{position: 'absolute', left: -rx, top: -ry, width: SCREEN_W, height: SCREEN_H}} />
    </div>
  );
};

// Green brand cover used for the intro and the outro, so the loop is seamless.
export const BrandCover: React.FC<{openAt: number; closeAt: number; end: number}> = ({openAt, closeAt, end}) => {
  const f = useCurrentFrame();
  const opening = interpolate(f, [openAt, openAt + 28], [1, 0], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const closing = interpolate(f, [closeAt, closeAt + 28], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const cover = f >= closeAt ? closing : opening;
  if (cover <= 0) return null;
  const content =
    f >= closeAt
      ? interpolate(f, [closeAt + 16, closeAt + 40], [0, 1], clamp)
      : interpolate(f, [openAt, openAt + 14], [1, 0], clamp);
  const bob = Math.sin((f / end) * Math.PI * 2 * 2) * 6;
  const R = 1150 * cover;
  return (
    <AbsoluteFill style={{clipPath: `circle(${R}px at 50% 52%)`, background: C.primary}}>
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', opacity: content, transform: `scale(${0.9 + 0.1 * content})`}}>
        <div style={{width: 210, height: 210, borderRadius: 60, background: '#fff', display: 'grid', placeItems: 'center', transform: `translateY(${bob}px)`, boxShadow: '0 20px 50px rgba(0,0,0,0.25)'}}>
          <Img src={staticFile('brand/logo_only.png')} style={{width: 160}} />
        </div>
        <div style={{fontFamily: FONT, fontWeight: 700, fontSize: 96, color: '#fff', letterSpacing: 6, marginTop: 34}}>MEDIKU</div>
        <div style={{fontFamily: FONT, fontSize: 30, color: 'rgba(255,255,255,0.85)', marginTop: 6}}>Kesehatan keluarga di satu tempat</div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 22,
            color: C.primary,
            background: C.primarySurface,
            padding: '10px 24px',
            borderRadius: 999,
            marginTop: 30,
            fontWeight: 600,
          }}
        >
          Kader posyandu &amp; warga, terhubung
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const SCREEN = {W: SCREEN_W, H: SCREEN_H};

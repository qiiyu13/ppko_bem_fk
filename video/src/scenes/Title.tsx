import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {InkLayer, Squiggle} from '../components/Ink';
import {Stage, stickerFilter} from '../components/Stickers';
import {C, DISPLAY_VARS, F, STAGE, art} from '../theme';

// The title card opens and closes the loop. It is fully static at the start
// of the intro and at the end of the outro, so the loop point is invisible.

type Mode = 'in' | 'out';

const ORDER = 12;
const START_IN = 8;
const STEP = 4;
const DUR = 20;
export const TITLE_SETTLED = START_IN + ORDER * STEP + DUR;

const useAmt = (mode: Mode, i: number) => {
  const f = useCurrentFrame();
  if (mode === 'in') {
    return interpolate(f, [START_IN + i * STEP, START_IN + i * STEP + DUR], [0, 1], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.out(Easing.back(1.8)),
    });
  }
  return interpolate(f, [12 + i * 2, 30 + i * 2], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.in(Easing.back(1.6)),
  });
};

const Mascot: React.FC<{mode: Mode; i: number; src: string; x: number; y: number; h: number; rotate: number}> = ({
  mode,
  i,
  src,
  x,
  y,
  h,
  rotate,
}) => {
  const a = useAmt(mode, i);
  // fly in from / out to beyond the nearest edge
  const dx = (x - 960) * (1 - a) * 1.4;
  const dy = (y - 540) * (1 - a) * 1.4;
  return (
    <Img
      src={src}
      style={{
        position: 'absolute',
        left: x + dx,
        top: y + dy,
        height: h,
        transform: `translate(-50%, -50%) rotate(${rotate + (1 - a) * 60}deg) scale(${Math.max(0, a)})`,
        filter: stickerFilter(Math.max(6, h * 0.03)),
      }}
    />
  );
};

const Letters: React.FC<{mode: Mode; text: string; base: number}> = ({mode, text, base}) => (
  <>
    {text.split('').map((ch, i) => (
      <Letter key={i} mode={mode} i={base + i * 0.5} ch={ch} k={i} />
    ))}
  </>
);

const Letter: React.FC<{mode: Mode; i: number; ch: string; k: number}> = ({mode, i, ch, k}) => {
  const a = useAmt(mode, i);
  return (
    <span
      style={{
        display: 'inline-block',
        transform: `translateY(${(1 - a) * (mode === 'in' ? -260 : 420)}px) rotate(${(1 - a) * (k % 2 ? 24 : -24)}deg)`,
        opacity: Math.min(1, a * 2),
      }}
    >
      {ch}
    </span>
  );
};

export const TitleCard: React.FC<{mode: Mode}> = ({mode}) => {
  const kicker = useAmt(mode, 0);
  const logo = useAmt(mode, 5);
  const tag = useAmt(mode, 6);
  return (
    <AbsoluteFill>
      <Stage theme={STAGE.paper} />
      <Mascot mode={mode} i={7} src={art('blood_pressure')} x={340} y={250} h={250} rotate={-12} />
      <Mascot mode={mode} i={8} src={art('uric_acid')} x={1590} y={250} h={200} rotate={10} />
      <Mascot mode={mode} i={9} src={art('blood_sugar')} x={215} y={560} h={105} rotate={-14} />
      <Mascot mode={mode} i={10} src={art('cholestrol')} x={1715} y={575} h={100} rotate={12} />
      <Mascot mode={mode} i={11} src={art('kader')} x={330} y={900} h={430} rotate={6} />
      <Mascot mode={mode} i={12} src={art('guy_only')} x={1600} y={910} h={400} rotate={-6} />

      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 268,
          textAlign: 'center',
          fontFamily: F.ui,
          fontWeight: 700,
          fontSize: 24,
          letterSpacing: 9,
          color: C.ink,
          opacity: kicker,
          transform: `translateY(${(1 - kicker) * -30}px)`,
        }}
      >
        KADER POSYANDU <span style={{color: C.coral}}>×</span> WARGA
      </div>

      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 300,
          textAlign: 'center',
          fontFamily: F.display,
          fontVariationSettings: DISPLAY_VARS,
          fontWeight: 800,
          fontSize: 300,
          lineHeight: 1,
          letterSpacing: -10,
          color: C.ink,
        }}
      >
        <Letters mode={mode} text="Mediku" base={1} />
      </div>

      <div
        style={{
          position: 'absolute',
          left: 1445,
          top: 280,
          width: 150,
          height: 150,
          borderRadius: '50%',
          background: '#fff',
          display: 'grid',
          placeItems: 'center',
          transform: `rotate(${14 + (1 - logo) * 120}deg) scale(${Math.max(0, logo)})`,
          boxShadow: `0 0 0 6px ${C.ink}, 9px 11px 0 6px rgba(60,45,20,0.25)`,
        }}
      >
        <Img src={staticFile('brand/logo_only.png')} style={{width: 112}} />
      </div>

      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 640,
          textAlign: 'center',
          fontFamily: F.hand,
          fontWeight: 700,
          fontSize: 72,
          color: C.coral,
          transform: `rotate(-2deg) translateY(${(1 - tag) * 40}px)`,
          opacity: Math.max(0, tag),
        }}
      >
        sehat bareng, mulai dari RW sendiri
      </div>
      {mode === 'in' ? (
        <InkLayer>
          <Squiggle x1={720} x2={1200} y={742} at={START_IN + 7 * STEP} color={C.yellow} seed="title" width={9} />
        </InkLayer>
      ) : (
        <InkLayer>
          <g opacity={tag}>
            <Squiggle x1={720} x2={1200} y={742} at={-100} color={C.yellow} seed="title" width={9} />
          </g>
        </InkLayer>
      )}
    </AbsoluteFill>
  );
};

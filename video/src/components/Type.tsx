import React from 'react';
import {interpolate, random, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, DISPLAY_VARS, F, StageTheme} from '../theme';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export type Seg = string | {t: string; em?: boolean; hl?: boolean};

const Word: React.FC<{
  word: string;
  em?: boolean;
  hl?: boolean;
  delay: number;
  exitAt?: number;
  theme: StageTheme;
  size: number;
  seed: string;
}> = ({word, em, hl, delay, exitAt, theme, size, seed}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - delay, fps, config: {damping: 11, stiffness: 150, mass: 0.8}});
  const out = exitAt === undefined ? 0 : interpolate(f, [exitAt, exitAt + 14], [0, 1], clamp);
  const drop = out * out * 420;
  const spin = out * (random(seed) - 0.5) * 70;
  const mark = spring({frame: f - delay - 8, fps, config: {damping: 18}});
  return (
    <span
      style={{
        display: 'inline-block',
        position: 'relative',
        marginRight: size * 0.24,
        transform: `translateY(${(1 - s) * size * 0.7 + drop}px) rotate(${(1 - s) * 9 + spin}deg)`,
        transformOrigin: '0% 100%',
        opacity: Math.min(1, s * 1.4) * (1 - out * out),
        fontFamily: F.display,
        fontStyle: em ? 'italic' : 'normal',
        color: em ? theme.em : theme.text,
        fontWeight: em ? 600 : 700,
      }}
    >
      {hl ? (
        <span
          style={{
            position: 'absolute',
            left: -size * 0.08,
            right: -size * 0.1,
            top: size * 0.24,
            height: size * 0.7,
            background: C.yellow,
            borderRadius: size * 0.12,
            transform: `skewX(-10deg) rotate(-2deg) scaleX(${mark})`,
            transformOrigin: '0 50%',
            zIndex: 0,
          }}
        />
      ) : null}
      <span style={{position: 'relative', zIndex: 1, color: hl && theme.text === C.cream ? C.ink : undefined}}>{word}</span>
    </span>
  );
};

export const Headline: React.FC<{
  at: number;
  x: number;
  y: number;
  width: number;
  theme: StageTheme;
  lines: Seg[][];
  size?: number;
  exitAt?: number;
  align?: 'left' | 'right';
}> = ({at, x, y, width, theme, lines, size = 112, exitAt, align = 'left'}) => {
  let k = 0;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width,
        fontSize: size,
        lineHeight: 0.98,
        letterSpacing: -size * 0.025,
        fontVariationSettings: DISPLAY_VARS,
        textAlign: align,
      }}
    >
      {lines.map((line, li) => (
        <div key={li} style={{whiteSpace: 'nowrap'}}>
          {line.flatMap((seg, si) => {
            const s = typeof seg === 'string' ? {t: seg} : seg;
            return s.t.split(' ').map((w, wi) => {
              const idx = k++;
              return (
                <Word
                  key={`${si}-${wi}`}
                  word={w}
                  em={s.em}
                  hl={s.hl}
                  delay={at + idx * 3}
                  exitAt={exitAt === undefined ? undefined : exitAt + idx * 1.5}
                  theme={theme}
                  size={size}
                  seed={`${li}-${si}-${wi}`}
                />
              );
            });
          })}
        </div>
      ))}
    </div>
  );
};

// "01 · WARGA" tag above a headline.
export const Kicker: React.FC<{at: number; x: number; y: number; n: string; label: string; theme: StageTheme; exitAt?: number}> = ({
  at,
  x,
  y,
  n,
  label,
  theme,
  exitAt,
}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - at, fps, config: {damping: 9, stiffness: 160}});
  const t = spring({frame: f - at - 5, fps, config: {damping: 16}});
  const out = exitAt === undefined ? 0 : interpolate(f, [exitAt, exitAt + 10], [0, 1], clamp);
  const dark = theme.text === C.cream;
  return (
    <div style={{position: 'absolute', left: x, top: y, display: 'flex', alignItems: 'center', gap: 16, opacity: 1 - out}}>
      <div
        style={{
          width: 62,
          height: 62,
          borderRadius: '50%',
          background: dark ? C.yellow : C.ink,
          color: dark ? C.ink : C.cream,
          display: 'grid',
          placeItems: 'center',
          fontFamily: F.display,
          fontVariationSettings: DISPLAY_VARS,
          fontWeight: 800,
          fontSize: 28,
          transform: `scale(${s}) rotate(${(1 - s) * -120}deg)`,
          boxShadow: `4px 5px 0 ${dark ? '#08230F' : 'rgba(0,0,0,0.18)'}`,
        }}
      >
        {n}
      </div>
      <div
        style={{
          fontFamily: F.ui,
          fontWeight: 700,
          fontSize: 22,
          letterSpacing: 6,
          color: theme.text,
          opacity: t,
          transform: `translateX(${(1 - t) * -20}px)`,
        }}
      >
        {label}
      </div>
    </div>
  );
};

// Handwritten note that "writes" itself left to right.
export const Note: React.FC<{
  at: number;
  x: number;
  y: number;
  text: string;
  color: string;
  size?: number;
  rotate?: number;
  exitAt?: number;
  width?: number;
}> = ({at, x, y, text, color, size = 50, rotate = -4, exitAt, width}) => {
  const f = useCurrentFrame();
  const dur = Math.max(12, text.length * 0.9);
  const p = interpolate(f, [at, at + dur], [0, 1], clamp);
  const out = exitAt === undefined ? 0 : interpolate(f, [exitAt, exitAt + 10], [0, 1], clamp);
  if (p <= 0) return null;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width,
        fontFamily: F.hand,
        fontWeight: 700,
        fontSize: size,
        lineHeight: 1.05,
        whiteSpace: 'pre-line',
        color,
        transform: `rotate(${rotate}deg)`,
        clipPath: `inset(-60% ${(1 - p) * 130 - 30}% -60% -10%)`,
        opacity: 1 - out,
      }}
    >
      {text}
    </div>
  );
};

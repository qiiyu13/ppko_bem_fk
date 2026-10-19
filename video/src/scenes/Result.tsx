import React from 'react';
import {AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Arrow, Circle, InkLayer} from '../components/Ink';
import {PaperPlane, ScreenSticker, Stage, Sticker} from '../components/Stickers';
import {Headline, Kicker, Note} from '../components/Type';
import {C, F, STAGE, art} from '../theme';

const T = STAGE.paper;
const TEXT_X = 130;

// IRD card in k15_detail (logical px) and the gauge inside it.
const CARD: [number, number, number, number] = [16, 316, 380, 138];
const SCALE = 2.1;
const BAR = {x0: 34, y: 413, unit: 229.3, max: 378};
const SCORE = 0.92;

// Redraws the gauge so the needle can sweep to the real score.
const Gauge: React.FC<{v: number}> = ({v}) => {
  const seg = (a: number, b: number, color: string, round: string) => (
    <div
      style={{
        position: 'absolute',
        left: BAR.x0 + a * BAR.unit,
        top: BAR.y - 4,
        width: (b - a) * BAR.unit,
        height: 8,
        background: color,
        borderRadius: round,
      }}
    />
  );
  const x = BAR.x0 + v * BAR.unit;
  return (
    <>
      <div style={{position: 'absolute', left: 28, top: 402, width: 356, height: 22, background: '#fff'}} />
      {seg(0, 0.75, C.statusGreen, '4px 0 0 4px')}
      {seg(0.75, 1, C.statusAmber, '0')}
      {seg(1, (BAR.max - BAR.x0) / BAR.unit, C.statusRed, '0 4px 4px 0')}
      <div
        style={{
          position: 'absolute',
          left: x - 9,
          top: BAR.y - 9,
          width: 18,
          height: 18,
          borderRadius: '50%',
          background: '#fff',
          boxShadow: '0 1px 4px rgba(0,0,0,0.3)',
          display: 'grid',
          placeItems: 'center',
        }}
      >
        <div style={{width: 9, height: 9, borderRadius: '50%', background: C.statusAmber}} />
      </div>
      {/* live score, same type as the app */}
      <div style={{position: 'absolute', left: 296, top: 336, width: 90, height: 38, background: '#fff'}} />
      <div
        style={{
          position: 'absolute',
          right: 412 - 381,
          top: 336,
          fontFamily: F.ui,
          fontWeight: 700,
          fontSize: 27,
          lineHeight: '38px',
          color: v < 0.75 ? C.statusGreen : C.statusAmber,
        }}
      >
        {v.toFixed(2)}
      </div>
    </>
  );
};

export const Result: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pop = spring({frame: f - 8, fps, config: {damping: 11, stiffness: 110}});
  const v = interpolate(f, [30, 62], [0, SCORE], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.back(1.4))});
  const w = CARD[2] * SCALE;
  const h = CARD[3] * SCALE;
  const cx = 1360;
  const cy = 500;
  const rot = -3 + (1 - pop) * -14;
  // number center in scene coords (card is small-angle rotated; close enough for ink)
  const numX = cx - w / 2 + (343 - CARD[0]) * SCALE;
  const numY = cy - h / 2 + (354 - CARD[1]) * SCALE;
  return (
    <AbsoluteFill>
      <Stage theme={T} numeral="04" numeralX={980} />
      <Kicker at={14} x={TEXT_X} y={170} n="04" label="OTOMATIS" theme={T} />
      <Headline
        at={18}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={110}
        lines={[['Risiko'], ['diabetes'], [{t: 'langsung', em: true}], [{t: 'dihitung.', hl: true}]]}
      />
      <Sticker src={art('blood_sugar')} at={34} x={cx - w / 2 + 20} y={cy + h / 2 + 70} h={96} rotate={-10} />
      <Sticker src={art('blood_pressure')} at={26} x={cx - w / 2 - 10} y={cy - h / 2 - 40} h={180} rotate={-14} />
      <ScreenSticker
        src="k15_detail"
        rect={CARD}
        scale={SCALE}
        style={{left: cx - w / 2, top: cy - h / 2, transform: `rotate(${rot}deg) scale(${pop})`}}
      >
        <Gauge v={v} />
      </ScreenSticker>
      <InkLayer>
        <Circle cx={numX} cy={numY} rx={92} ry={56} at={66} color={C.coral} seed="ird" width={8} />
        <Arrow from={[cx + 40, cy + h / 2 + 150]} to={[numX - 20, numY + 70]} bend={-60} at={80} color={C.coral} seed="ird-a" />
      </InkLayer>
      <Note at={72} x={cx - 330} y={cy + h / 2 + 110} text="Waspada, perlu dipantau ya!" color={C.coral} size={56} rotate={-4} />
      <PaperPlane
        at={92}
        dur={32}
        path={[
          {x: cx - w / 2 + 60, y: cy + h / 2 - 10},
          {x: 1000, y: 1000},
          {x: 400, y: 1020},
          {x: -260, y: 640},
        ]}
        label="hasil skrining"
        trail={C.ink}
      />
    </AbsoluteFill>
  );
};

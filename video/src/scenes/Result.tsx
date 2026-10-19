import React from 'react';
import {AbsoluteFill, Easing, interpolate, spring} from 'remotion';
import {useFrame, useClock} from '../time';
import {Arrow, InkLayer, MarkerCircle} from '../components/Ink';
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
  const f = useFrame();
  const {fps} = useClock();
  const pop = spring({frame: f - 10, fps, config: {damping: 11, stiffness: 110}});
  const v = interpolate(f, [40, 95], [0, SCORE], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.back(1.4))});
  const w = CARD[2] * SCALE;
  const h = CARD[3] * SCALE;
  const cx = 1360;
  const cy = 500;
  const rot = -3 + (1 - pop) * -14;
  // "0.92" on the card: logical bounds x 322..377, y 343..365. Map through the
  // card's own scale and rotation so the ink sits on the number.
  const r = (rot * Math.PI) / 180;
  const ox = (349.5 - CARD[0]) * SCALE - w / 2;
  const oy = (354 - CARD[1]) * SCALE - h / 2;
  const numX = cx + (ox * Math.cos(r) - oy * Math.sin(r)) * pop;
  const numY = cy + (ox * Math.sin(r) + oy * Math.cos(r)) * pop;
  const NOTE_X = 1060;
  const NOTE_Y = cy + h / 2 + 125;
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
      <Sticker src={art('blood_sugar')} at={44} x={cx - w / 2 + 20} y={cy + h / 2 + 70} h={96} rotate={-10} />
      <Sticker src={art('blood_pressure')} at={34} x={cx - w / 2 - 10} y={cy - h / 2 - 40} h={180} rotate={-14} />
      <ScreenSticker
        src="k15_detail"
        rect={CARD}
        scale={SCALE}
        style={{left: cx - w / 2, top: cy - h / 2, transform: `rotate(${rot}deg) scale(${pop})`}}
      >
        <Gauge v={v} />
      </ScreenSticker>
      <InkLayer>
        <MarkerCircle cx={numX} cy={numY} w={55 * SCALE} h={22 * SCALE} rotate={rot} pad={30} at={104} color={C.coral} tint={C.yellow} seed="ird" width={8} />
        {/* from the end of the note, around the outside of the card, up to the loop */}
        <Arrow from={[NOTE_X + 665, NOTE_Y + 10]} to={[numX + 110, numY + 40]} bend={75} at={128} color={C.coral} seed="ird-a" />
      </InkLayer>
      <Note at={112} x={NOTE_X} y={NOTE_Y} text="Waspada, perlu dipantau ya!" color={C.coral} size={56} rotate={-4} />
      <PaperPlane
        at={205}
        dur={40}
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

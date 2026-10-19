import React from 'react';
import {AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Arrow, Buzz, Circle, InkLayer} from '../components/Ink';
import {Device, PHONE_SCALE, Screens, ScreenStep, Tap, Touch, devicePoint} from '../components/Phone';
import {PaperPlane, PulseRing, PushBanner, ScreenSticker, Stage, Sticker} from '../components/Stickers';
import {Headline, Kicker, Note} from '../components/Type';
import {C, STAGE, art} from '../theme';

const T = STAGE.warga;
export const W_PHONE = {cx: 560, cy: 545, rotate: -4};
const TEXT_X = 1010;
const HEAD = 110;

const Phone: React.FC<{steps: ScreenStep[]; taps: Tap[]; shakeAt?: number[]; enterAt?: number; children?: React.ReactNode}> = ({
  steps,
  taps,
  shakeAt,
  enterAt,
  children,
}) => (
  <Device {...W_PHONE} caseColor={C.coral} buttonColor={C.ink} shadow={T.shadow} shakeAt={shakeAt} enterAt={enterAt}>
    <Screens steps={steps} />
    {children}
    <Touch taps={taps} />
  </Device>
);

// Where the patient's QR sits inside p03_qr (logical px).
export const QR_RECT: [number, number, number, number] = [108, 328, 204, 204];

export const WargaQR: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const qrAt = devicePoint(W_PHONE, QR_RECT[0] + QR_RECT[2] / 2, QR_RECT[1] + QR_RECT[3] / 2, f);

  // The QR peels off the screen, grows into a sticker, then flies right.
  const peel = spring({frame: f - 138, fps, config: {damping: 10, stiffness: 120}});
  const fly = interpolate(f, [160, 190], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.in(Easing.cubic)});
  const qrScale = PHONE_SCALE + (1.35 - PHONE_SCALE) * peel;
  const qx = qrAt.x + peel * 120 + fly * 1700;
  const qy = qrAt.y - peel * 170 - fly * 640;
  const size = QR_RECT[2] * qrScale;

  return (
    <AbsoluteFill>
      <Stage theme={T} numeral="01" numeralX={1080} />
      <Kicker at={14} x={TEXT_X} y={170} n="01" label="WARGA" theme={T} />
      <Headline
        at={20}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        lines={[['Cukup'], ['tunjukkan'], [{t: 'QR', hl: true}, {t: 'keluarga.', em: true}]]}
      />
      <Phone
        enterAt={2}
        steps={[
          {at: 0, src: 'p02_home'},
          {at: 76, src: 'p03_qr', t: 'pop'},
        ]}
        taps={[{f: 70, x: 368, y: 800}]}
      />
      <Sticker src={art('guy_only')} at={36} x={215} y={870} h={330} rotate={-6} from={{x: 215, y: 1300}} />
      <Note at={52} x={70} y={640} text="Pak Budi" color={T.text} size={52} rotate={-9} />
      <Note at={98} x={TEXT_X} y={650} width={760} text="satu QR untuk tiap anggota keluarga" color={T.text} size={50} rotate={-3} />
      <InkLayer>
        <Arrow from={[TEXT_X + 80, 740]} to={[qrAt.x + 150, qrAt.y + 40]} bend={-70} at={112} color={T.text} seed="w1" />
      </InkLayer>
      {f >= 138 && fly < 1 ? (
        <ScreenSticker
          src="p03_qr"
          rect={QR_RECT}
          scale={qrScale}
          style={{left: qx - size / 2, top: qy - size / 2, transform: `rotate(${peel * -8 + fly * 40 + Math.sin(f / 5) * 2}deg)`}}
        />
      ) : null}
    </AbsoluteFill>
  );
};

const METRIC_CARDS: [number, number, number, number][] = [
  [16, 221, 182, 181],
  [214, 221, 182, 181],
  [16, 419, 182, 181],
  [214, 419, 182, 181],
];

export const WargaReceive: React.FC = () => {
  const f = useCurrentFrame();
  const top = devicePoint(W_PHONE, 300, 70, f);
  const card = (i: number) => devicePoint(W_PHONE, METRIC_CARDS[i][0] + 91, METRIC_CARDS[i][1] + 90, f);
  return (
    <AbsoluteFill>
      <Stage theme={T} numeral="05" numeralX={1080} />
      <Kicker at={14} x={TEXT_X} y={170} n="05" label="WARGA" theme={T} />
      <Headline
        at={20}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        lines={[['Hasilnya'], [{t: 'langsung', em: true}], [{t: 'sampai', hl: true}, 'di HP.']]}
      />
      <Phone
        steps={[
          {at: 0, src: 'p02_home'},
          {at: 66, src: 'p10_home_after', t: 'fade'},
        ]}
        taps={[]}
        shakeAt={[36]}
      >
        {METRIC_CARDS.map((r, i) => (
          <PulseRing key={i} from={68} delay={i * 4} rect={r} />
        ))}
        <PushBanner
          from={38}
          to={86}
          title="Hasil Skrining Tersedia"
          body="Skrining kesehatan Budi Santoso selesai. Kategori IRD: Perhatian."
        />
      </Phone>
      <InkLayer>
        <Buzz cx={W_PHONE.cx} cy={W_PHONE.cy} w={440} h={930} at={36} color={T.text} />
      </InkLayer>
      <Sticker src={art('blood_pressure')} at={76} x={165} y={235} h={190} rotate={-12} from={card(0)} />
      <Sticker src={art('blood_sugar')} at={82} x={170} y={480} h={84} rotate={-16} from={card(1)} />
      <Sticker src={art('cholestrol')} at={88} x={175} y={660} h={80} rotate={10} from={card(2)} />
      <Sticker src={art('uric_acid')} at={94} x={175} y={880} h={170} rotate={8} from={card(3)} />
      <Note at={104} x={TEXT_X} y={650} width={780} text="angka terbaru langsung masuk!" color={T.text} size={52} rotate={-3} />
      <InkLayer>
        <Arrow from={[TEXT_X + 40, 735]} to={[card(3).x + 120, card(3).y + 20]} bend={60} at={116} color={T.text} seed="w4" />
      </InkLayer>
      <PaperPlane
        at={4}
        dur={32}
        path={[
          {x: 2050, y: 260},
          {x: 1650, y: 40},
          {x: 1050, y: 60},
          {x: top.x, y: top.y},
        ]}
        label="hasil skrining"
        trail={T.text}
      />
    </AbsoluteFill>
  );
};

export const WargaFinal: React.FC = () => {
  const f = useCurrentFrame();
  const top = devicePoint(W_PHONE, 300, 70, f);
  const notif = devicePoint(W_PHONE, 206, 98, f);
  const appt = devicePoint(W_PHONE, 206, 572, f);
  return (
    <AbsoluteFill>
      <Stage theme={T} numeral="07" numeralX={1080} />
      <Kicker at={14} x={TEXT_X} y={170} n="07" label="WARGA" theme={T} />
      <Headline
        at={20}
        x={TEXT_X}
        y={250}
        width={840}
        theme={T}
        size={HEAD}
        lines={[['Nggak ada'], ['yang'], [{t: 'ketinggalan.', em: true}]]}
      />
      <Phone
        steps={[
          {at: 0, src: 'p10_home_after'},
          {at: 67, src: 'p11_notif_after', t: 'push'},
          {at: 109, src: 'p10_home_after', t: 'back'},
          {at: 124, src: 'p12_jadwal_after', t: 'fade'},
        ]}
        taps={[
          {f: 62, x: 200, y: 66},
          {f: 104, x: 22, y: 22},
          {f: 120, x: 154, y: 885},
        ]}
        shakeAt={[34]}
      >
        <PulseRing from={132} rect={[17, 519, 378, 106]} radius={16} color={C.coral} />
        <PushBanner
          from={36}
          to={64}
          title="Jadwal Skrining Baru"
          body="Cek Ulang Gula Darah RW 05 pada 26 Oktober 2026 di Balai Warga RW 05"
        />
      </Phone>
      <InkLayer>
        <Buzz cx={W_PHONE.cx} cy={W_PHONE.cy} w={440} h={930} at={34} color={T.text} />
        {f < 108 ? <Circle cx={notif.x} cy={notif.y} rx={225} ry={62} at={80} color={C.coral} seed="n1" /> : null}
        <Circle cx={appt.x} cy={appt.y} rx={225} ry={72} at={136} color={C.coral} seed="n2" />
        <Arrow from={[TEXT_X + 30, 720]} to={[appt.x + 250, appt.y - 10]} bend={-50} at={150} color={T.text} seed="w6" />
      </InkLayer>
      <Note at={140} x={TEXT_X} y={640} width={800} text="cek ulang 26 Okt, udah tercatat!" color={T.text} size={52} rotate={-3} />
      <PaperPlane
        at={4}
        dur={30}
        path={[
          {x: 2050, y: 280},
          {x: 1650, y: 40},
          {x: 1050, y: 60},
          {x: top.x, y: top.y},
        ]}
        label="jadwal baru"
        trail={T.text}
      />
    </AbsoluteFill>
  );
};

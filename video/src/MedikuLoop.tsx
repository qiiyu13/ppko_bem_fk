import React from 'react';
import {AbsoluteFill} from 'remotion';
import {TransitionSeries, springTiming} from '@remotion/transitions';
import {slide} from '@remotion/transitions/slide';
import {Grain} from './components/Stickers';
import {KADER_SAVE_POINT, KaderJadwal, KaderScan} from './scenes/Kader';
import {Result} from './scenes/Result';
import {TitleCard} from './scenes/Title';
import {W_PHONE, WargaFinal, WargaQR, WargaReceive} from './scenes/Warga';
import {Soundtrack} from './Soundtrack';
import {out} from './time';
import {SCENES, TR} from './timing';
import {burst} from './transitions/burst';

export {DURATION} from './timing';

const pan = springTiming({config: {damping: 200}, durationInFrames: out(TR)});

// Spatially the warga lives on the left and the kader on the right, so the
// camera pans right to visit the kader and left to come back.

export const MedikuLoop: React.FC = () => (
  <AbsoluteFill style={{background: '#000'}}>
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={out(SCENES.intro)}>
        <TitleCard mode="out" />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: 960, y: 540})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.warga)}>
        <WargaQR />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-right'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.kader)}>
        <KaderScan />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: KADER_SAVE_POINT.x, y: KADER_SAVE_POINT.y})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.result)}>
        <Result />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-left'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.receive)}>
        <WargaReceive />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-right'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.jadwal)}>
        <KaderJadwal />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-left'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.final)}>
        <WargaFinal />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: W_PHONE.cx, y: W_PHONE.cy})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={out(SCENES.outro)}>
        <TitleCard mode="in" />
      </TransitionSeries.Sequence>
    </TransitionSeries>
    <Grain amount={0.12} />
    <Soundtrack />
  </AbsoluteFill>
);

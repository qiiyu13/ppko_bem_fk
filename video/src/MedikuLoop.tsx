import React from 'react';
import {AbsoluteFill} from 'remotion';
import {TransitionSeries, springTiming} from '@remotion/transitions';
import {slide} from '@remotion/transitions/slide';
import {Grain} from './components/Stickers';
import {KADER_SAVE_POINT, KaderJadwal, KaderScan} from './scenes/Kader';
import {Result} from './scenes/Result';
import {TitleCard} from './scenes/Title';
import {W_PHONE, WargaFinal, WargaQR, WargaReceive} from './scenes/Warga';
import {burst} from './transitions/burst';

const TR = 28;
const pan = springTiming({config: {damping: 200}, durationInFrames: TR});

// Spatially the warga lives on the left and the kader on the right, so the
// camera pans right to visit the kader and left to come back.
// Each scene leaves ~2-3s for its headline and notes to be read before the next beat.
const SCENES = {intro: 75, warga: 300, kader: 510, result: 245, receive: 250, jadwal: 345, final: 320, outro: 170};

export const DURATION = Object.values(SCENES).reduce((a, b) => a + b, 0) - 7 * TR;

export const MedikuLoop: React.FC = () => (
  <AbsoluteFill style={{background: '#000'}}>
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={SCENES.intro}>
        <TitleCard mode="out" />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: 960, y: 540})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.warga}>
        <WargaQR />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-right'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.kader}>
        <KaderScan />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: KADER_SAVE_POINT.x, y: KADER_SAVE_POINT.y})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.result}>
        <Result />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-left'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.receive}>
        <WargaReceive />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-right'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.jadwal}>
        <KaderJadwal />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({direction: 'from-left'})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.final}>
        <WargaFinal />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={burst({x: W_PHONE.cx, y: W_PHONE.cy})} timing={pan} />
      <TransitionSeries.Sequence durationInFrames={SCENES.outro}>
        <TitleCard mode="in" />
      </TransitionSeries.Sequence>
    </TransitionSeries>
    <Grain amount={0.12} />
  </AbsoluteFill>
);

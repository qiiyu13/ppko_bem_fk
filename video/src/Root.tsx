import {Composition, staticFile} from 'remotion';
import {loadFont} from '@remotion/fonts';
import {MedikuLoop} from './MedikuLoop';
import {FONT, FPS} from './theme';
import {DURATION} from './timeline';

// The app's own typeface (assets/fonts).
for (const [file, weight] of [
  ['Regular', '400'],
  ['Medium', '500'],
  ['SemiBold', '600'],
  ['Bold', '700'],
] as const) {
  loadFont({family: FONT, url: staticFile(`fonts/PlusJakartaSans-${file}.ttf`), weight});
}

export const Root: React.FC = () => (
  <Composition id="MedikuLoop" component={MedikuLoop} durationInFrames={DURATION} fps={FPS} width={1920} height={1080} />
);

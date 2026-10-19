import {Composition, staticFile} from 'remotion';
import {loadFont} from '@remotion/fonts';
import {DURATION, MedikuLoop} from './MedikuLoop';
import {F, FPS, H, W} from './theme';

// The app's own UI typeface (assets/fonts).
for (const [file, weight] of [
  ['Regular', '400'],
  ['Medium', '500'],
  ['SemiBold', '600'],
  ['Bold', '700'],
] as const) {
  loadFont({family: F.ui, url: staticFile(`fonts/PlusJakartaSans-${file}.ttf`), weight});
}
// Display + handwriting (OFL, see public/fonts/OFL-*.txt).
loadFont({family: F.display, url: staticFile('fonts/Fraunces.ttf'), weight: '100 900'});
loadFont({family: F.display, url: staticFile('fonts/Fraunces-Italic.ttf'), weight: '100 900', style: 'italic'});
loadFont({family: F.hand, url: staticFile('fonts/Caveat.ttf'), weight: '400 700'});

export const Root: React.FC = () => (
  <Composition id="MedikuLoop" component={MedikuLoop} durationInFrames={DURATION} fps={FPS} width={W} height={H} />
);

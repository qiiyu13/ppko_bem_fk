import React from 'react';
import {Img, interpolate, useCurrentFrame} from 'remotion';
import {SCREEN_H, SCREEN_W, shot} from '../theme';

// Fades in a region of another real screenshot, e.g. to clear a snackbar
// that was baked into the captured frame once it would have timed out.
export const Patch: React.FC<{from: number; src: string; rect: [number, number, number, number]}> = ({from, src, rect}) => {
  const f = useCurrentFrame();
  if (f < from) return null;
  const [x, y, w, h] = rect;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: h, overflow: 'hidden', opacity: interpolate(f, [from, from + 8], [0, 1], {extrapolateRight: 'clamp'})}}>
      <Img src={shot(src)} style={{position: 'absolute', left: -x, top: -y, width: SCREEN_W, height: SCREEN_H}} />
    </div>
  );
};

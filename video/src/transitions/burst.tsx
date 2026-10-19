import React from 'react';
import {AbsoluteFill, Easing} from 'remotion';
import type {TransitionPresentation, TransitionPresentationComponentProps} from '@remotion/transitions';
import {C} from '../theme';

type BurstProps = {x: number; y: number; ring?: string};

const R = 2400;

// The next scene bursts out of a point (usually the button just tapped),
// led by a yellow ring.
const BurstPresentation: React.FC<TransitionPresentationComponentProps<BurstProps>> = ({
  children,
  presentationDirection,
  presentationProgress,
  passedProps,
}) => {
  if (presentationDirection === 'exiting') return <AbsoluteFill>{children}</AbsoluteFill>;
  const p = presentationProgress;
  const ease = Easing.inOut(Easing.cubic);
  const ring = R * ease(Math.min(1, p / 0.85));
  const inner = R * ease(Math.max(0, (p - 0.12) / 0.88));
  const at = `${passedProps.x}px ${passedProps.y}px`;
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: passedProps.ring ?? C.yellow, clipPath: `circle(${ring}px at ${at})`}} />
      <AbsoluteFill style={{clipPath: `circle(${inner}px at ${at})`}}>{children}</AbsoluteFill>
    </AbsoluteFill>
  );
};

export const burst = (props: BurstProps): TransitionPresentation<BurstProps> => ({component: BurstPresentation, props});

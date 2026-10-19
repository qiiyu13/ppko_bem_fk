import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';

export const Hello: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 30], [0, 1], {extrapolateRight: 'clamp'});
  const y = interpolate(frame, [0, 30], [40, 0], {extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{background: '#0f172a', justifyContent: 'center', alignItems: 'center'}}>
      <h1 style={{color: 'white', fontSize: 96, fontFamily: 'sans-serif', opacity, transform: `translateY(${y}px)`}}>
        Hello Remotion
      </h1>
    </AbsoluteFill>
  );
};

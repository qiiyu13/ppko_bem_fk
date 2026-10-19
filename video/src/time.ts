import {useCurrentFrame, useVideoConfig} from 'remotion';

// The video renders at OUTPUT_FPS, but every animation is authored on a 30 fps
// clock ("story frames"). Scene code reads story frames, which are fractional
// at higher output rates, so in-between frames are real motion, not duplicates.
export const STORY_FPS = 30;
export const OUTPUT_FPS = 60;
export const TIME_SCALE = OUTPUT_FPS / STORY_FPS;

// Story frames -> output frames, for Sequence/TransitionSeries lengths.
export const out = (storyFrames: number) => Math.round(storyFrames * TIME_SCALE);

export const useFrame = () => useCurrentFrame() / TIME_SCALE;

export const useClock = () => ({...useVideoConfig(), fps: STORY_FPS});

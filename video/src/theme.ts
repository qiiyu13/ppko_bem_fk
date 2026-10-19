import {staticFile} from 'remotion';

// App colors (lib/constants/app_colors.dart) plus a warm print palette
// pulled from the app's own illustrations: heart pink, logo-cross yellow,
// kunyit orange, sky from the secondary color.
export const C = {
  primary: '#144425',
  primaryLight: '#1E6B38',
  primarySurface: '#E8F0EA',
  appBg: '#F7F9F7',
  textPrimary: '#0D1F14',
  textSecondary: '#6B7A70',
  statusRed: '#D94F4F',
  statusAmber: '#D97706',
  statusGreen: '#2D8653',

  ink: '#123B21',
  cream: '#F6EFE2',
  creamDeep: '#EADFC9',
  pink: '#F9D5D9',
  pinkDeep: '#F0B9C0',
  coral: '#E8475F',
  green: '#144425',
  greenDeep: '#0D3119',
  yellow: '#FFD23F',
  sky: '#9CCBDB',
  kunyit: '#F29F05',
  white: '#FFFFFF',
};

export type StageTheme = {
  bg: string;
  numeral: string;
  text: string;
  em: string;
  muted: string;
  shadow: string;
  grain: number;
};

export const STAGE: Record<'warga' | 'kader' | 'paper', StageTheme> = {
  warga: {bg: C.pink, numeral: C.pinkDeep, text: C.ink, em: C.coral, muted: '#7A4B52', shadow: 'rgba(120,30,45,0.22)', grain: 0.1},
  kader: {bg: C.green, numeral: '#1B5530', text: C.cream, em: C.yellow, muted: '#B9CDBF', shadow: '#08230F', grain: 0.14},
  paper: {bg: C.cream, numeral: C.creamDeep, text: C.ink, em: C.coral, muted: '#7C7363', shadow: 'rgba(60,45,20,0.22)', grain: 0.12},
};

export const F = {
  display: 'Fraunces',
  hand: 'Caveat',
  ui: 'Plus Jakarta Sans',
};

// Fraunces at its softest, wonkiest optical size.
export const DISPLAY_VARS = "'SOFT' 100, 'WONK' 1, 'opsz' 144";

export const FPS = 30;
export const W = 1920;
export const H = 1080;

// App screenshots are 412x915 logical px, captured at 2x.
export const SCREEN_W = 412;
export const SCREEN_H = 915;

export const shot = (name: string) => staticFile(`screens/${name}.png`);
export const art = (name: string) => staticFile(`art/${name}.png`);

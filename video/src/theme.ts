import {staticFile} from 'remotion';

// Mirrors lib/constants/app_colors.dart so overlays match the app.
export const C = {
  primary: '#144425',
  primaryLight: '#1E6B38',
  primarySurface: '#E8F0EA',
  background: '#F7F9F7',
  textPrimary: '#0D1F14',
  textSecondary: '#6B7A70',
  statusRed: '#D94F4F',
  statusAmber: '#D97706',
  statusGreen: '#2D8653',
  secondary: '#6FA9BB',
  yellow: '#F2D600',
};

export const FONT = 'Plus Jakarta Sans';
export const FPS = 30;

// App screenshots are 412x915 logical px, captured at 2x.
export const SCREEN_W = 412;
export const SCREEN_H = 915;

export const shot = (name: string) => staticFile(`screens/${name}.png`);

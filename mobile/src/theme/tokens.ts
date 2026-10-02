/**
 * RakshaNet (SignalRescue AI) — Design System Tokens
 * Source of truth: design.md
 * Hi-vis beacon design system for extreme emergency / offline resilience.
 */

export const brand = {
  signalYellow: '#FFC400',
  sosRed: '#D92D20',
  beaconTeal: '#0E8A94',
  nightNavy: '#0B1220',
};

export const light = {
  bg: '#FFFCEB',
  bgAlt: '#FFF5C2',
  surface: '#FFFFFF',
  surfaceSunken: '#F6F0D4',
  border: '#E6DCA8',
  borderStrong: '#C9BB6E',
  text: '#16202D',
  textMuted: '#566070',
  textDisabled: '#9AA1AB',
  primary: '#FFC400',
  primaryPressed: '#E0AA00',
  primarySoft: '#FFEFA6',
  primaryInk: '#8A5A00',
  onPrimary: '#1A1400',
  sos: '#D92D20',
  sosPressed: '#B42318',
  sosSoft: '#FDE2DF',
  info: '#0E8A94',
  infoSoft: '#D6F1F3',
  success: '#1E8E4E',
  successSoft: '#D9F2E3',
  warning: '#E07B00',
  warningSoft: '#FFE6C7',
  scrim: 'rgba(22,32,45,0.48)',
};

export const dark: typeof light = {
  bg: '#0B1220',
  bgAlt: '#111A2C',
  surface: '#162036',
  surfaceSunken: '#0E1627',
  border: '#26344F',
  borderStrong: '#3A4C70',
  text: '#EEF2F8',
  textMuted: '#9FADC2',
  textDisabled: '#5F6E86',
  primary: '#FFD21F',
  primaryPressed: '#E6B800',
  primarySoft: '#3A3010',
  primaryInk: '#FFD21F',
  onPrimary: '#1A1400',
  sos: '#FF5A4E',
  sosPressed: '#E0463B',
  sosSoft: '#3A1512',
  info: '#3CC6D0',
  infoSoft: '#0F3037',
  success: '#4CD08A',
  successSoft: '#0F3322',
  warning: '#FFA033',
  warningSoft: '#3A2508',
  scrim: 'rgba(0,0,0,0.64)',
};

export const lowPower: typeof dark = {
  ...dark,
  bg: '#000000',
  bgAlt: '#000000',
  surfaceSunken: '#000000',
};

export const severity = {
  light: {
    CRITICAL: '#D92D20',
    HIGH: '#E07B00',
    MEDIUM: '#C99A00',
    LOW: '#1E8E4E',
    UNKNOWN: '#566070',
  },
  dark: {
    CRITICAL: '#FF5A4E',
    HIGH: '#FFA033',
    MEDIUM: '#FFD21F',
    LOW: '#4CD08A',
    UNKNOWN: '#9FADC2',
  },
};

export const space = {
  1: 4,
  2: 8,
  3: 12,
  4: 16,
  5: 20,
  6: 24,
  8: 32,
  10: 40,
  12: 48,
  16: 64,
};

export const radius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 20,
  pill: 999,
};

export const size = {
  touchMin: 48,
  buttonPrimary: 56,
  input: 52,
  row: 64,
  tabBar: 64,
  appBar: 56,
  statusStrip: 40,
  sosHome: 176,
  sosScreenMax: 280,
  icon: {
    sm: 16,
    md: 24,
    lg: 32,
    xl: 48,
    hero: 64,
  },
};

export const type = {
  display: { fontSize: 40, lineHeight: 44, fontWeight: '700' as const },
  h1:      { fontSize: 28, lineHeight: 34, fontWeight: '700' as const },
  h2:      { fontSize: 22, lineHeight: 28, fontWeight: '600' as const },
  h3:      { fontSize: 18, lineHeight: 24, fontWeight: '700' as const },
  body:    { fontSize: 16, lineHeight: 24, fontWeight: '400' as const },
  caption: { fontSize: 14, lineHeight: 20, fontWeight: '400' as const },
  micro:   { fontSize: 12, lineHeight: 16, fontWeight: '700' as const },
  mono:    { fontSize: 14, lineHeight: 20, fontWeight: '500' as const },
};

export type ThemeMode = 'light' | 'dark' | 'lowPower';

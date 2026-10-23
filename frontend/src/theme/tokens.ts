/**
 * RakshaNet — Design System Tokens
 * Source of Truth: design.md
 * Hi-vis beacon design system for extreme emergency / offline resilience.
 */

export const brandTokens = {
  signalYellow: '#FFC400',
  sosRed: '#D92D20',
  beaconTeal: '#0E8A94',
  nightNavy: '#0B1220',
} as const;

export const lightTokens = {
  bg: '#F8FAFC',
  bgAlt: '#F1F5F9',
  surface: '#FFFFFF',
  surfaceSunken: '#F1F5F9',
  border: '#E2E8F0',
  borderStrong: '#CBD5E1',
  text: '#0F172A',
  textMuted: '#64748B',
  textDisabled: '#94A3B8',
  onPrimary: '#1A1400',
  primary: '#FFC400',
  primaryPressed: '#E0AA00',
  primarySoft: '#FEF08A',
  primaryInk: '#8A5A00',
  sos: '#DC2626',
  sosPressed: '#B91C1C',
  sosSoft: '#FEE2E2',
  info: '#0284C7',
  infoSoft: '#E0F2FE',
  success: '#16A34A',
  successSoft: '#DCFCE7',
  warning: '#D97706',
  warningSoft: '#FEF3C7',
  scrim: 'rgba(15, 23, 42, 0.48)',
} as const;

export const darkTokens = {
  bg: '#0B1220',
  bgAlt: '#111A2C',
  surface: '#162036',
  surfaceSunken: '#0E1627',
  border: '#26344F',
  borderStrong: '#3A4C70',
  text: '#EEF2F8',
  textMuted: '#9FADC2',
  textDisabled: '#5F6E86',
  onPrimary: '#1A1400',
  primary: '#FFD21F',
  primaryPressed: '#E6B800',
  primarySoft: '#3A3010',
  primaryInk: '#FFD21F',
  sos: '#FF5A4E',
  sosMain: '#D92D20',
  sosPressed: '#E0463B',
  sosSoft: '#3A1512',
  info: '#3CC6D0',
  infoSoft: '#0F3037',
  success: '#4CD08A',
  successSoft: '#0F3322',
  warning: '#FFA033',
  warningSoft: '#3A2508',
  scrim: 'rgba(0, 0, 0, 0.64)',
} as const;

export const oledTokens = {
  bg: '#000000',
  bgAlt: '#000000',
  surface: '#0E1627',
  surfaceSunken: '#000000',
  border: '#26344F',
  borderStrong: '#3A4C70',
  text: '#EEF2F8',
  textMuted: '#9FADC2',
  textDisabled: '#5F6E86',
  primary: '#FFD21F',
  primaryPressed: '#E6B800',
  primaryInk: '#FFD21F',
  primarySoft: '#3A3010',
  onPrimary: '#1A1400',
  sos: '#FF5A4E',
  sosMain: '#D92D20',
  sosPressed: '#E0463B',
  sosSoft: '#3A1512',
  info: '#3CC6D0',
  infoSoft: '#0F3037',
  success: '#4CD08A',
  successSoft: '#0F3322',
  warning: '#FFA033',
  warningSoft: '#3A2508',
  scrim: 'rgba(0, 0, 0, 0.64)',
} as const;

/**
 * Section 2.6: Map layer colours
 */
export const mapLayerTokens = {
  sosPin: {
    light: '#D92D20',
    dark: '#FF5A4E',
    main: '#D92D20',
    pulseRing: 'rgba(217, 45, 32, 0.4)',
    pulseRingOuter: 'rgba(217, 45, 32, 0.15)',
  },
  deviceCluster: {
    light: '#0E8A94',
    dark: '#3CC6D0',
    glow: 'rgba(14, 138, 148, 0.35)',
  },
  searchZone: {
    border: '#FFC400',
    borderDark: '#FFD21F',
    fill: 'rgba(255, 196, 0, 0.28)',
    fillDark: 'rgba(255, 210, 31, 0.28)',
    dashArray: '6, 6',
    borderWidth: 2,
  },
  communicationGap: {
    stroke: '#7A4DD8',
    strokeDark: '#A98BFF',
    fillColor: '#7A4DD8',
    fillColorDark: '#A98BFF',
    fillOpacity: 0.25,
    hatchColor: '#7A4DD8',
    hatchColorDark: '#A98BFF',
  },
  floodExtent: {
    stroke: '#2F6FDE',
    strokeDark: '#6C9DFF',
    borderLight: '#2F6FDE',
    borderDark: '#6C9DFF',
    fillLight: 'rgba(47, 111, 222, 0.30)',
    fillDark: 'rgba(108, 157, 255, 0.30)',
    fillOpacity: 0.30,
  },
  rescueTeam: {
    light: '#1E8E4E',
    dark: '#4CD08A',
    badgeBg: '#111A2C',
    badgeBorder: '#26344F',
    text: '#EEF2F8',
  },
  landslide: {
    light: '#E07B00',
    dark: '#FFA033',
    critical: '#D92D20',
    badgeBg: '#111A2C',
    badgeBorder: '#26344F',
    text: '#EEF2F8',
  },
  meshConnection: {
    activeLight: '#1E8E4E',
    activeDark: '#4CD08A',
    relayLight: '#0E8A94',
    relayDark: '#3CC6D0',
    weakLight: '#E07B00',
    weakDark: '#FFA033',
    broken: '#D92D20',
  },
  offlineGrid: {
    bg: '#0B1220',
    lineMajor: '#26344F',
    lineMinor: '#162036',
    coordsText: '#9FADC2',
    crosshair: '#3A4C70',
    watermark: 'rgba(255, 196, 0, 0.65)',
  },
} as const;

export const fontTokens = {
  display: 'Barlow Semi Condensed, sans-serif-condensed, sans-serif',
  body: 'Atkinson Hyperlegible, system-ui, -apple-system, sans-serif',
  mono: 'JetBrains Mono, monospace',
} as const;

export const radiusTokens = {
  xs: '4px',
  sm: '8px',
  md: '12px',
  lg: '20px',
  pill: '9999px',
  round: '50%',
} as const;

export type ThemeMode = 'dark' | 'light' | 'oled';

export const light = lightTokens;
export const dark = darkTokens;
export const oled = oledTokens;
export const brand = brandTokens;

export const severity = {
  light: {
    critical: lightTokens.sos,
    high: lightTokens.warning,
    medium: '#FFC400',
    low: lightTokens.info,
  },
  dark: {
    critical: darkTokens.sos,
    high: darkTokens.warning,
    medium: darkTokens.primary,
    low: darkTokens.info,
  },
  oled: {
    critical: oledTokens.sos,
    high: oledTokens.warning,
    medium: oledTokens.primary,
    low: oledTokens.info,
  },
} as const;

import React, { createContext, useContext } from 'react';
import { light, dark, oled, brand, severity } from './tokens';
import { useThemeStore } from '../store/themeStore';
import type { ThemeMode } from '../types';

export type { ThemeMode };

export interface ThemeTokens {
  bg: string;
  bgAlt: string;
  surface: string;
  surfaceSunken: string;
  border: string;
  borderStrong: string;
  text: string;
  textMuted: string;
  textDisabled: string;
  onPrimary: string;
  primary: string;
  primaryPressed: string;
  primarySoft: string;
  primaryInk: string;
  sos: string;
  sosPressed: string;
  sosSoft: string;
  info: string;
  infoSoft: string;
  success: string;
  successSoft: string;
  warning: string;
  warningSoft: string;
  scrim: string;
  [key: string]: string;
}

export interface ThemeContextType {
  theme: ThemeMode;
  setTheme: (theme: ThemeMode) => void;
  cycleTheme: () => void;
  tokens: ThemeTokens;
  brandTokens: typeof brand;
  severityTokens: Record<string, string>;
  isDark: boolean;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { theme, setTheme } = useThemeStore();

  const cycleTheme = () => {
    if (theme === 'dark') setTheme('oled');
    else if (theme === 'oled') setTheme('light');
    else setTheme('dark');
  };

  const currentTokens = (theme === 'light' ? light : theme === 'oled' ? oled : dark) as unknown as ThemeTokens;
  const currentSeverity = severity[theme] as unknown as Record<string, string>;

  return (
    <ThemeContext.Provider
      value={{
        theme,
        setTheme,
        cycleTheme,
        tokens: currentTokens,
        brandTokens: brand,
        severityTokens: currentSeverity,
        isDark: theme === 'dark' || theme === 'oled',
      }}
    >
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

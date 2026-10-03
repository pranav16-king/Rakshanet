import React, { createContext, useContext, useEffect, useState } from 'react';
import { light, dark, oled, brand, severity } from './tokens';

export type ThemeMode = 'light' | 'dark' | 'oled';

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

interface ThemeContextType {
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
  const [theme, setThemeState] = useState<ThemeMode>(() => {
    const saved = localStorage.getItem('signalrescue_theme') as ThemeMode;
    if (saved === 'light' || saved === 'dark' || saved === 'oled') {
      return saved;
    }
    // Command centers default to dark per design.md Section 8
    return 'dark';
  });

  useEffect(() => {
    const root = document.documentElement;
    root.classList.remove('light', 'dark', 'oled');
    if (theme === 'dark') {
      root.classList.add('dark');
    } else if (theme === 'oled') {
      root.classList.add('dark', 'oled');
    } else {
      root.classList.add('light');
    }
    root.setAttribute('data-theme', theme);
    localStorage.setItem('signalrescue_theme', theme);
  }, [theme]);

  const setTheme = (newTheme: ThemeMode) => {
    setThemeState(newTheme);
  };

  const cycleTheme = () => {
    setThemeState((prev) => {
      if (prev === 'dark') return 'oled';
      if (prev === 'oled') return 'light';
      return 'dark';
    });
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

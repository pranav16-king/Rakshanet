import { create } from 'zustand';
import type { ThemeMode } from '../types';

interface ThemeStoreState {
  theme: ThemeMode;
  setTheme: (theme: ThemeMode) => void;
  toggleTheme: () => void;
}

const STORAGE_KEY = 'signalrescue_theme';

const getInitialTheme = (): ThemeMode => {
  if (typeof window === 'undefined') return 'dark';
  const saved = localStorage.getItem(STORAGE_KEY) as ThemeMode | null;
  if (saved && (saved === 'dark' || saved === 'light' || saved === 'oled')) {
    return saved;
  }
  return 'dark';
};

const applyThemeToDOM = (theme: ThemeMode) => {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  root.classList.remove('light', 'dark', 'oled');
  root.classList.add(theme);
  root.setAttribute('data-theme', theme);
};

export const useThemeStore = create<ThemeStoreState>((set, get) => {
  const initial = getInitialTheme();
  applyThemeToDOM(initial);

  return {
    theme: initial,
    setTheme: (theme: ThemeMode) => {
      localStorage.setItem(STORAGE_KEY, theme);
      applyThemeToDOM(theme);
      set({ theme });
    },
    toggleTheme: () => {
      const current = get().theme;
      const next: ThemeMode = current === 'dark' ? 'light' : current === 'light' ? 'oled' : 'dark';
      get().setTheme(next);
    },
  };
});

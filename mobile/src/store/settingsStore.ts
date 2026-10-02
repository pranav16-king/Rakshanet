import { create } from 'zustand';
import { ThemeMode } from '@/theme/tokens';
import { RadioMode } from '@/types/network';

interface SettingsState {
  themeMode: ThemeMode;
  radioMode: RadioMode;
  setThemeMode: (mode: ThemeMode) => void;
  setRadioMode: (mode: RadioMode) => void;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  themeMode: 'dark', // Defaults to dark / night navy for disaster battery resilience
  radioMode: 'NORMAL',
  setThemeMode: (themeMode) => set({ themeMode }),
  setRadioMode: (radioMode) => set({ radioMode }),
}));

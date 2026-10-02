import { useSettingsStore } from '@/store/settingsStore';
import { brand, light, dark, lowPower, severity, space, radius, size, type, ThemeMode } from './tokens';

export * from './tokens';

export function useTheme() {
  const themeMode = useSettingsStore((state) => state.themeMode);

  let c = dark;
  if (themeMode === 'light') {
    c = light;
  } else if (themeMode === 'lowPower') {
    c = lowPower;
  }

  const currentSeverity = themeMode === 'light' ? severity.light : severity.dark;

  return {
    c,
    brand,
    severity: currentSeverity,
    space,
    radius,
    size,
    type,
    themeMode,
  };
}

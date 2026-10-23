// src/components/settings/ThemeSwitcher.tsx
import React from 'react';
import { Sun, Moon, BatteryCharging } from 'lucide-react';
import type { ThemeMode } from '../../types';

interface ThemeSwitcherProps {
  currentTheme: ThemeMode;
  onThemeChange: (theme: ThemeMode) => void;
}

export const ThemeSwitcher: React.FC<ThemeSwitcherProps> = ({
  currentTheme,
  onThemeChange,
}) => {
  return (
    <div className="space-y-3">
      <div>
        <h4 className="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
          Theme &amp; Power Optimization
        </h4>
        <p className="text-[11px] text-slate-500 dark:text-slate-400">
          Switch visual modes for high sunlight operations or night command center watches.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {/* Light Mode */}
        <button
          type="button"
          onClick={() => onThemeChange('light')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition cursor-pointer ${
            currentTheme === 'light'
              ? 'border-[#FFC400] dark:border-[#FFD21F] bg-[#FFC400]/10 text-slate-900 dark:text-white shadow-sm ring-1 ring-[#FFC400]'
              : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-[#0E1627] text-slate-600 dark:text-slate-300 hover:border-slate-400 dark:hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-amber-500/15 text-amber-600 dark:text-amber-400">
            <Sun className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs sm:text-sm font-bold">Light Hi-Vis</div>
            <div className="text-[11px] text-slate-500 dark:text-slate-400">High sunlight contrast</div>
          </div>
        </button>

        {/* Dark Mode */}
        <button
          type="button"
          onClick={() => onThemeChange('dark')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition cursor-pointer ${
            currentTheme === 'dark'
              ? 'border-[#FFC400] dark:border-[#FFD21F] bg-[#FFC400]/10 text-slate-900 dark:text-white shadow-sm ring-1 ring-[#FFD21F]'
              : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-[#0E1627] text-slate-600 dark:text-slate-300 hover:border-slate-400 dark:hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-cyan-500/15 text-cyan-600 dark:text-cyan-400">
            <Moon className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs sm:text-sm font-bold">Dark Night Navy</div>
            <div className="text-[11px] text-slate-500 dark:text-slate-400">Command center default</div>
          </div>
        </button>

        {/* Low Power OLED */}
        <button
          type="button"
          onClick={() => onThemeChange('oled')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition cursor-pointer ${
            currentTheme === 'oled'
              ? 'border-[#FFC400] dark:border-[#FFD21F] bg-[#FFC400]/10 text-slate-900 dark:text-white shadow-sm ring-1 ring-[#FFD21F]'
              : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-[#0E1627] text-slate-600 dark:text-slate-300 hover:border-slate-400 dark:hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
            <BatteryCharging className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs sm:text-sm font-bold">Low-Power OLED</div>
            <div className="text-[11px] text-slate-500 dark:text-slate-400">Pure #000000 battery save</div>
          </div>
        </button>
      </div>
    </div>
  );
};

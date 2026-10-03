// src/components/settings/ThemeSwitcher.tsx
import React from 'react';
import { Sun, Moon, BatteryCharging } from 'lucide-react';

interface ThemeSwitcherProps {
  currentTheme: 'dark' | 'light' | 'oled';
  onThemeChange: (theme: 'dark' | 'light' | 'oled') => void;
}

export const ThemeSwitcher: React.FC<ThemeSwitcherProps> = ({
  currentTheme,
  onThemeChange,
}) => {
  return (
    <div className="space-y-2">
      <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider">
        Theme &amp; Power Optimization
      </label>
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {/* Light Mode */}
        <button
          type="button"
          onClick={() => onThemeChange('light')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition ${
            currentTheme === 'light'
              ? 'border-amber-400 bg-amber-400/10 text-white'
              : 'border-slate-700 bg-[#162036] text-slate-300 hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-amber-500/20 text-amber-400">
            <Sun className="w-5 h-5" />
          </div>
          <div>
            <div className="text-sm font-bold">Light Hi-Vis</div>
            <div className="text-[11px] text-slate-400">High sunlight contrast</div>
          </div>
        </button>

        {/* Dark Mode */}
        <button
          type="button"
          onClick={() => onThemeChange('dark')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition ${
            currentTheme === 'dark'
              ? 'border-amber-400 bg-amber-400/10 text-white'
              : 'border-slate-700 bg-[#162036] text-slate-300 hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-indigo-500/20 text-indigo-400">
            <Moon className="w-5 h-5" />
          </div>
          <div>
            <div className="text-sm font-bold">Dark Night Navy</div>
            <div className="text-[11px] text-slate-400">Command center default</div>
          </div>
        </button>

        {/* Low Power OLED */}
        <button
          type="button"
          onClick={() => onThemeChange('oled')}
          className={`flex items-center gap-3 p-3.5 rounded-xl border text-left transition ${
            currentTheme === 'oled'
              ? 'border-amber-400 bg-amber-400/10 text-white'
              : 'border-slate-700 bg-[#162036] text-slate-300 hover:border-slate-600'
          }`}
        >
          <div className="p-2 rounded-lg bg-emerald-500/20 text-emerald-400">
            <BatteryCharging className="w-5 h-5" />
          </div>
          <div>
            <div className="text-sm font-bold">Low-Power OLED</div>
            <div className="text-[11px] text-slate-400">Pure #000000 battery save</div>
          </div>
        </button>
      </div>
    </div>
  );
};

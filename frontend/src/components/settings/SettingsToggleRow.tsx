// src/components/settings/SettingsToggleRow.tsx
import React from 'react';

interface SettingsToggleRowProps {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  icon?: React.ReactNode;
  badge?: string;
  disabled?: boolean;
}

export const SettingsToggleRow: React.FC<SettingsToggleRowProps> = ({
  label,
  description,
  checked,
  onChange,
  icon,
  badge,
  disabled = false,
}) => {
  return (
    <div
      onClick={() => {
        if (!disabled) onChange(!checked);
      }}
      className={`flex items-center justify-between py-3.5 px-3 rounded-lg transition-colors border-b border-slate-200/60 dark:border-slate-800/80 last:border-0 ${
        disabled
          ? 'opacity-50 cursor-not-allowed'
          : 'hover:bg-slate-50/80 dark:hover:bg-[#111A2C]/60 cursor-pointer'
      }`}
    >
      <div className="flex items-start sm:items-center gap-3 pr-4">
        {icon && (
          <div className="text-slate-500 dark:text-slate-400 flex-shrink-0 mt-0.5 sm:mt-0 p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800/80 border border-slate-200/80 dark:border-slate-700/60">
            {icon}
          </div>
        )}
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs sm:text-sm font-bold text-slate-900 dark:text-slate-100">
              {label}
            </span>
            {badge && (
              <span className="px-2 py-0.5 text-[10px] font-mono font-semibold rounded-md bg-amber-400/15 text-amber-600 dark:text-amber-400 border border-amber-400/30">
                {badge}
              </span>
            )}
          </div>
          {description && (
            <p className="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
              {description}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-2.5 flex-shrink-0">
        <span
          className={`text-[10px] font-mono font-bold uppercase tracking-wider hidden sm:inline-block px-1.5 py-0.5 rounded ${
            checked
              ? 'text-emerald-600 dark:text-emerald-400 bg-emerald-500/10'
              : 'text-slate-400 dark:text-slate-500 bg-slate-200/40 dark:bg-slate-800/40'
          }`}
        >
          {checked ? 'ACTIVE' : 'OFF'}
        </span>

        {/* Switch Toggle */}
        <button
          type="button"
          role="switch"
          aria-checked={checked}
          disabled={disabled}
          onClick={(e) => {
            e.stopPropagation();
            if (!disabled) onChange(!checked);
          }}
          className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] ${
            checked
              ? 'bg-emerald-500 dark:bg-emerald-500'
              : 'bg-slate-300 dark:bg-slate-700'
          }`}
        >
          <span
            className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-md ring-0 transition duration-200 ease-in-out ${
              checked ? 'translate-x-5' : 'translate-x-0'
            }`}
          />
        </button>
      </div>
    </div>
  );
};

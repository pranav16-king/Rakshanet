// src/components/settings/SettingsToggleRow.tsx
import React from 'react';

interface SettingsToggleRowProps {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  icon?: React.ReactNode;
}

export const SettingsToggleRow: React.FC<SettingsToggleRowProps> = ({
  label,
  description,
  checked,
  onChange,
  icon,
}) => {
  return (
    <div className="flex items-center justify-between py-3.5 border-b border-slate-700/60 last:border-0">
      <div className="flex items-center gap-3 pr-4">
        {icon && <div className="text-slate-400 flex-shrink-0">{icon}</div>}
        <div>
          <div className="text-sm font-medium text-slate-100">{label}</div>
          {description && (
            <div className="text-xs text-slate-400 mt-0.5">{description}</div>
          )}
        </div>
      </div>

      {/* Switch Toggle (green when checked, matching media_1791015140209.jpg) */}
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
          checked ? 'bg-emerald-500' : 'bg-slate-700'
        }`}
      >
        <span
          className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
            checked ? 'translate-x-5' : 'translate-x-0'
          }`}
        />
      </button>
    </div>
  );
};

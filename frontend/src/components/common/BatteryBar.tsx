import React from 'react';
import { Battery, BatteryCharging, BatteryWarning } from 'lucide-react';

interface BatteryBarProps {
  percent: number;
  className?: string;
  showIcon?: boolean;
}

export const BatteryBar: React.FC<BatteryBarProps> = ({
  percent,
  className = '',
  showIcon = true,
}) => {
  const clamped = Math.max(0, Math.min(100, percent));

  let barColor = 'bg-emerald-500';
  let textColor = 'text-emerald-700 dark:text-emerald-400';
  let Icon = Battery;

  if (clamped < 20) {
    barColor = 'bg-red-500';
    textColor = 'text-red-700 dark:text-red-400';
    Icon = BatteryWarning;
  } else if (clamped <= 50) {
    barColor = 'bg-amber-500';
    textColor = 'text-amber-700 dark:text-amber-400';
    Icon = Battery;
  }

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      {showIcon && <Icon className={`w-4 h-4 shrink-0 ${textColor}`} />}
      <div className="w-16 md:w-20 bg-slate-200 dark:bg-slate-700 rounded-full h-2 overflow-hidden flex-1 max-w-[80px]">
        <div
          className={`h-full rounded-full transition-all duration-300 ${barColor}`}
          style={{ width: `${clamped}%` }}
        />
      </div>
      <span className={`text-xs font-semibold tabular-nums min-w-[2.2rem] ${textColor}`}>
        {clamped}%
      </span>
    </div>
  );
};

export default BatteryBar;

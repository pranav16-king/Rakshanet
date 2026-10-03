// src/components/resources/AllocationProgress.tsx
import React from 'react';

interface AllocationProgressProps {
  allocated: number;
  total: number;
  unit: string;
}

export const AllocationProgress: React.FC<AllocationProgressProps> = ({
  allocated,
  total,
  unit,
}) => {
  const percentage = Math.min(100, Math.round((allocated / (total || 1)) * 100));

  const getBarColor = () => {
    if (percentage >= 90) return 'bg-red-500';
    if (percentage >= 70) return 'bg-amber-400';
    return 'bg-emerald-400';
  };

  return (
    <div className="space-y-1.5">
      <div className="flex justify-between items-center text-xs text-slate-300">
        <span>
          Allocated: <strong className="text-white">{allocated.toLocaleString()}</strong> {unit}
        </span>
        <span className="font-mono text-slate-400 font-medium">
          {percentage}% utilized
        </span>
      </div>

      <div className="w-full bg-[#0E1627] rounded-full h-2.5 overflow-hidden border border-slate-700/60">
        <div
          className={`h-full rounded-full transition-all duration-500 ${getBarColor()}`}
          style={{ width: `${percentage}%` }}
        />
      </div>

      <div className="flex justify-between items-center text-[11px] text-slate-400">
        <span>Available: {Math.max(0, total - allocated).toLocaleString()} {unit}</span>
        <span>Total: {total.toLocaleString()} {unit}</span>
      </div>
    </div>
  );
};

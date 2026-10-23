// src/components/analytics/ImpactCard.tsx
import React from 'react';
import { ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface ImpactCardProps {
  title: string;
  count: number | string;
  delta: string;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
}

export const ImpactCard: React.FC<ImpactCardProps> = ({
  title,
  count,
  delta,
  icon,
  trend = 'up',
}) => {
  const isPositive = trend === 'up';

  return (
    <div className="p-5 rounded-xl border border-slate-200 dark:border-slate-700/80 bg-white dark:bg-[#162036] shadow-xs flex flex-col justify-between hover:border-slate-300 dark:hover:border-slate-600 transition">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-slate-500 dark:text-slate-400">{title}</span>
        {icon && <div className="text-slate-400 dark:text-slate-400">{icon}</div>}
      </div>

      <div className="mt-2.5">
        <div className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white font-display">
          {typeof count === 'number' ? count.toLocaleString() : count}
        </div>

        <div className="mt-2 flex items-center gap-1.5">
          <span
            className={`inline-flex items-center gap-0.5 text-xs font-semibold px-2 py-0.5 rounded-full ${
              isPositive
                ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20'
                : 'bg-red-500/10 text-red-600 dark:text-red-400 border border-red-500/20'
            }`}
          >
            {isPositive ? (
              <ArrowUpRight className="w-3.5 h-3.5" />
            ) : (
              <ArrowDownRight className="w-3.5 h-3.5" />
            )}
            {delta}
          </span>
        </div>
      </div>
    </div>
  );
};

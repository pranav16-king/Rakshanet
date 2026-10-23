import React from 'react';
import { ArrowUpRight, ArrowDownRight, AlertOctagon } from 'lucide-react';
import { LoadingSkeleton } from './LoadingSkeleton';

export interface KpiCardProps {
  title: string;
  value: number | string;
  deltaYesterdayPct?: number;
  criticalCount?: number;
  criticalBadgeText?: string;
  highlightColor?: string;
  icon?: React.ElementType;
  accentColor?: 'teal' | 'red' | 'amber' | 'green' | 'default';
  isLoading?: boolean;
  className?: string;
}

export const KpiCard: React.FC<KpiCardProps> = ({
  title,
  value,
  deltaYesterdayPct,
  criticalCount,
  criticalBadgeText,
  highlightColor,
  icon: IconComponent,
  accentColor = 'default',
  isLoading = false,
  className = '',
}) => {
  if (isLoading) {
    return (
      <div className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-5 shadow-xs ${className}`}>
        <div className="flex justify-between items-center mb-3">
          <LoadingSkeleton variant="text" width="50%" />
          <LoadingSkeleton variant="circular" width="36px" height="36px" />
        </div>
        <LoadingSkeleton variant="text" height="36px" width="40%" className="mb-3" />
        <LoadingSkeleton variant="text" width="60%" />
      </div>
    );
  }

  const formattedValue =
    typeof value === 'number' ? value.toLocaleString('en-US') : value;

  const getIconWrapperClass = () => {
    switch (accentColor) {
      case 'red':
        return 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-900/40';
      case 'amber':
        return 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200/60 dark:border-amber-900/40';
      case 'teal':
        return 'bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 border border-teal-200/60 dark:border-teal-900/40';
      case 'green':
        return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-900/40';
      default:
        return 'bg-slate-100 dark:bg-[#0E1627] text-slate-600 dark:text-[#9FADC2] border border-slate-200/80 dark:border-[#26344F]';
    }
  };

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-5 shadow-xs hover:shadow-md hover:border-slate-300 dark:hover:border-[#3A4C70] transition-all duration-200 flex flex-col justify-between min-h-[136px] ${className}`}
    >
      {/* Top Header: Title & Icon */}
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-semibold text-slate-500 dark:text-[#9FADC2] uppercase tracking-wider">
          {title}
        </span>
        {IconComponent && (
          <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${getIconWrapperClass()}`}>
            <IconComponent size={18} />
          </div>
        )}
      </div>

      {/* Main Metric Value */}
      <div className="my-2">
        <span
          className={`text-3xl font-black tracking-tight ${
            highlightColor ? highlightColor : 'text-slate-900 dark:text-[#EEF2F8]'
          }`}
          style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
        >
          {formattedValue}
        </span>
      </div>

      {/* Status Trend Pill */}
      <div className="flex items-center gap-2 pt-1">
        {criticalCount !== undefined && criticalCount > 0 ? (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200/70 dark:border-rose-800/40">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping" />
            <AlertOctagon className="w-3.5 h-3.5" />
            {criticalBadgeText || `${criticalCount} critical`}
          </span>
        ) : deltaYesterdayPct !== undefined ? (
          <div className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-200/70 dark:border-emerald-800/40">
            {deltaYesterdayPct >= 0 ? (
              <ArrowUpRight className="w-3.5 h-3.5" />
            ) : (
              <ArrowDownRight className="w-3.5 h-3.5 text-rose-500" />
            )}
            <span>
              {deltaYesterdayPct >= 0 ? `+${deltaYesterdayPct}%` : `${deltaYesterdayPct}%`}
            </span>
            <span className="text-slate-500 dark:text-[#9FADC2] font-normal">vs yesterday</span>
          </div>
        ) : null}
      </div>
    </div>
  );
};

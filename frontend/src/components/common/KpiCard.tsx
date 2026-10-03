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
  isLoading = false,
  className = '',
}) => {
  if (isLoading) {
    return (
      <div className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm ${className}`}>
        <LoadingSkeleton variant="text" width="60%" className="mb-3" />
        <LoadingSkeleton variant="text" height="32px" width="40%" className="mb-3" />
        <LoadingSkeleton variant="text" width="50%" />
      </div>
    );
  }

  const formattedValue =
    typeof value === 'number' ? value.toLocaleString('en-US') : value;

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm transition-all duration-200 hover:shadow-md flex flex-col justify-between min-h-[128px] ${className}`}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2] uppercase tracking-wider">
          {title}
        </span>
      </div>

      <div className="my-2">
        <span
          className={`text-3xl font-extrabold tracking-tight font-display ${
            highlightColor ? highlightColor : 'text-[#16202D] dark:text-[#EEF2F8]'
          }`}
        >
          {formattedValue}
        </span>
      </div>

      <div className="flex items-center gap-2 pt-1">
        {criticalCount !== undefined && criticalCount > 0 ? (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#FDE2DF] dark:bg-[#3A1512] text-[#D92D20] dark:text-[#FF5A4E] border border-[#D92D20]/25">
            <AlertOctagon className="w-3.5 h-3.5" />
            {criticalBadgeText || `${criticalCount} critical`}
          </span>
        ) : deltaYesterdayPct !== undefined ? (
          <div className="inline-flex items-center gap-1 text-xs font-semibold text-[#1E8E4E] dark:text-[#4CD08A]">
            {deltaYesterdayPct >= 0 ? (
              <ArrowUpRight className="w-3.5 h-3.5" />
            ) : (
              <ArrowDownRight className="w-3.5 h-3.5 text-[#D92D20] dark:text-[#FF5A4E]" />
            )}
            <span>
              {deltaYesterdayPct >= 0 ? `+${deltaYesterdayPct}%` : `${deltaYesterdayPct}%`}
            </span>
            <span className="text-[#566070] dark:text-[#9FADC2] font-normal">from yesterday</span>
          </div>
        ) : null}
      </div>
    </div>
  );
};

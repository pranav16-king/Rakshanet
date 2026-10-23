import React, { useState } from 'react';
import { Calendar, ChevronDown, Check, RefreshCw } from 'lucide-react';

export interface DashboardTopBarProps {
  timeRange: string;
  onTimeRangeChange: (range: string) => void;
  onRefresh?: () => void;
  isFetching?: boolean;
  isEmptyMode: boolean;
  onToggleEmptyMode: () => void;
}

const TIME_RANGES = [
  { id: '24h', label: 'Last 24 hours' },
  { id: '7d', label: 'Last 7 days' },
  { id: '30d', label: 'Last 30 days' },
  { id: 'all', label: 'All time' },
];

export const DashboardTopBar: React.FC<DashboardTopBarProps> = ({
  timeRange,
  onTimeRangeChange,
  onRefresh,
  isFetching = false,
  isEmptyMode,
  onToggleEmptyMode,
}) => {
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const currentLabel =
    TIME_RANGES.find((r) => r.id === timeRange)?.label || 'Last 24 hours';

  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
      {/* Title & Subtitle */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-[#0F172A] dark:text-[#EEF2F8] font-display">
          Dashboard
        </h1>
        <p className="text-sm text-[#64748B] dark:text-[#9FADC2] mt-0.5">
          Real-time overview of disaster communication network
        </p>
      </div>

      {/* Controls & Dropdown */}
      <div className="flex items-center gap-3">
        {/* Toggle Empty State for testing / evaluation */}
        <button
          type="button"
          onClick={onToggleEmptyMode}
          className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
            isEmptyMode
              ? 'bg-[#FFC400] text-[#1A1400] border-[#FFC400] font-bold shadow-xs'
              : 'bg-white dark:bg-[#162036] text-[#64748B] dark:text-[#9FADC2] border-[#E2E8F0] dark:border-[#26344F] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844]'
          }`}
          title="Toggle zero-incident empty state"
        >
          {isEmptyMode ? 'Viewing Empty State' : 'Simulate Empty State'}
        </button>

        {/* Refresh Button */}
        {onRefresh && (
          <button
            type="button"
            onClick={onRefresh}
            disabled={isFetching}
            aria-label="Refresh overview data"
            className="p-2 rounded-xl bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#64748B] dark:text-[#9FADC2] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844] transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-4 h-4 ${isFetching ? 'animate-spin text-[#FFC400]' : ''}`} />
          </button>
        )}

        {/* Time Range Selector */}
        <div className="relative">
          <button
            type="button"
            onClick={() => setDropdownOpen(!dropdownOpen)}
            className="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] hover:border-[#FFC400] transition-colors shadow-2xs cursor-pointer"
          >
            <Calendar className="w-3.5 h-3.5 text-[#64748B] dark:text-[#9FADC2]" />
            <span>{currentLabel}</span>
            <ChevronDown className="w-3.5 h-3.5 text-[#64748B] dark:text-[#9FADC2]" />
          </button>

          {dropdownOpen && (
            <>
              <div
                className="fixed inset-0 z-40"
                onClick={() => setDropdownOpen(false)}
              />
              <div className="absolute right-0 mt-2 w-44 rounded-xl bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] shadow-lg py-1.5 z-50 animate-in fade-in zoom-in-95">
                {TIME_RANGES.map((r) => (
                  <button
                    key={r.id}
                    type="button"
                    onClick={() => {
                      onTimeRangeChange(r.id);
                      setDropdownOpen(false);
                    }}
                    className={`w-full text-left px-3.5 py-2 text-xs flex items-center justify-between transition-colors cursor-pointer ${
                      r.id === timeRange
                        ? 'bg-[#F8FAFC] dark:bg-[#0E1627] text-[#FFC400] font-bold'
                        : 'text-[#0F172A] dark:text-[#EEF2F8] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844]'
                    }`}
                  >
                    <span>{r.label}</span>
                    {r.id === timeRange && <Check className="w-3.5 h-3.5 text-[#FFC400]" />}
                  </button>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

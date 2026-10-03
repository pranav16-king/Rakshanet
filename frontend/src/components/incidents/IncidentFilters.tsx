import React from 'react';
import { Search, RotateCcw, Filter } from 'lucide-react';
import type { IncidentFilterOptions, SeverityLevel, DisasterType, IncidentStatus } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentFiltersProps {
  filters: IncidentFilterOptions;
  onChange: (updated: Partial<IncidentFilterOptions>) => void;
  onReset: () => void;
}

export const IncidentFilters: React.FC<IncidentFiltersProps> = ({ filters, onChange, onReset }) => {
  const { isDark } = useTheme();

  const severityOptions: { label: string; value: 'ALL' | SeverityLevel }[] = [
    { label: 'All Severities', value: 'ALL' },
    { label: 'Critical', value: 'CRITICAL' },
    { label: 'High', value: 'HIGH' },
    { label: 'Medium', value: 'MEDIUM' },
    { label: 'Low', value: 'LOW' },
  ];

  const typeOptions: { label: string; value: 'ALL' | DisasterType }[] = [
    { label: 'All Disaster Types', value: 'ALL' },
    { label: 'Flood', value: 'Flood' },
    { label: 'Landslide', value: 'Landslide' },
    { label: 'Building Collapse', value: 'Building Collapse' },
    { label: 'Cyclone', value: 'Cyclone' },
    { label: 'Flash Flood', value: 'Flash Flood' },
    { label: 'Earthquake', value: 'Earthquake' },
  ];

  const statusOptions: { label: string; value: 'ALL' | IncidentStatus }[] = [
    { label: 'All Statuses', value: 'ALL' },
    { label: 'Active', value: 'Active' },
    { label: 'Investigating', value: 'Investigating' },
    { label: 'Dispatched', value: 'Dispatched' },
    { label: 'Resolved', value: 'Resolved' },
  ];

  const selectClasses = `px-3 py-2 text-xs font-semibold rounded-lg border outline-none transition-colors cursor-pointer ${
    isDark
      ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] focus:border-[#FFD21F]'
      : 'bg-[#FFFFFF] border-[#E6DCA8] text-[#16202D] focus:border-[#FFC400]'
  }`;

  return (
    <div
      className={`p-4 rounded-xl border mb-6 flex flex-col lg:flex-row gap-3 items-stretch lg:items-center justify-between transition-colors shadow-sm ${
        isDark ? 'bg-[#111A2C] border-[#26344F]' : 'bg-[#FFFFFF] border-[#E6DCA8]'
      }`}
    >
      {/* Search Input */}
      <div className="relative flex-1 min-w-[260px]">
        <Search
          size={16}
          className={`absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none ${
            isDark ? 'text-[#9FADC2]' : 'text-[#566070]'
          }`}
        />
        <input
          type="text"
          value={filters.searchQuery}
          onChange={(e) => onChange({ searchQuery: e.target.value, page: 1 })}
          placeholder="Search incident title, location, or ticket ID..."
          className={`w-full pl-10 pr-4 py-2 text-xs rounded-lg border outline-none transition-colors ${
            isDark
              ? 'bg-[#0E1627] border-[#26344F] text-[#EEF2F8] placeholder-[#5F6E86] focus:border-[#FFD21F]'
              : 'bg-[#F6F0D4] border-[#E6DCA8] text-[#16202D] placeholder-[#9AA1AB] focus:border-[#FFC400]'
          }`}
        />
      </div>

      {/* Filter Selects */}
      <div className="flex flex-wrap items-center gap-2.5">
        <div className="flex items-center gap-1.5 text-xs text-muted font-bold mr-1">
          <Filter size={14} />
          <span>Filters:</span>
        </div>

        {/* Severity */}
        <select
          value={filters.severity}
          onChange={(e) => onChange({ severity: e.target.value as any, page: 1 })}
          className={selectClasses}
          aria-label="Filter by Severity"
        >
          {severityOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>

        {/* Type */}
        <select
          value={filters.type}
          onChange={(e) => onChange({ type: e.target.value as any, page: 1 })}
          className={selectClasses}
          aria-label="Filter by Disaster Type"
        >
          {typeOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>

        {/* Status */}
        <select
          value={filters.status}
          onChange={(e) => onChange({ status: e.target.value as any, page: 1 })}
          className={selectClasses}
          aria-label="Filter by Status"
        >
          {statusOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>

        {/* Reset Button */}
        <button
          type="button"
          onClick={onReset}
          title="Reset all filters"
          className={`p-2 rounded-lg border transition-colors flex items-center justify-center ${
            isDark
              ? 'bg-[#162036] border-[#26344F] text-[#9FADC2] hover:text-[#EEF2F8] hover:bg-[#1f2d4d]'
              : 'bg-[#F6F0D4] border-[#E6DCA8] text-[#566070] hover:text-[#16202D] hover:bg-[#ebdca8]'
          }`}
          aria-label="Reset filters"
        >
          <RotateCcw size={15} />
        </button>
      </div>
    </div>
  );
};

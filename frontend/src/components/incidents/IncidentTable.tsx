import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin,
  Clock,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ChevronRight,
  UserPlus,
  Users,
} from 'lucide-react';
import type { Incident, IncidentFilterOptions } from '../../types/incident.ts';
import { SeverityBadge } from '../common/SeverityBadge.tsx';
import { StatusBadge } from '../common/StatusBadge.tsx';
import { EmptyState } from '../common/EmptyState.tsx';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentTableProps {
  incidents: Incident[];
  filters: IncidentFilterOptions;
  onSortChange: (sortBy: IncidentFilterOptions['sortBy']) => void;
  onQuickAssign: (incident: Incident) => void;
  onResetFilters: () => void;
}

export const IncidentTable: React.FC<IncidentTableProps> = ({
  incidents,
  filters,
  onSortChange,
  onQuickAssign,
  onResetFilters,
}) => {
  const { isDark } = useTheme();
  const navigate = useNavigate();

  const renderSortIndicator = (field: IncidentFilterOptions['sortBy']) => {
    if (filters.sortBy !== field) {
      return <ArrowUpDown size={12} className="opacity-40" />;
    }
    return filters.sortOrder === 'asc' ? (
      <ArrowUp size={12} className="text-[#FFC400]" />
    ) : (
      <ArrowDown size={12} className="text-[#FFC400]" />
    );
  };

  if (incidents.length === 0) {
    return <EmptyState onAction={onResetFilters} />;
  }

  return (
    <div className="w-full overflow-x-auto">
      <table className="w-full text-left border-collapse text-sm">
        <thead>
          <tr
            className={`border-b text-xs font-mono font-bold tracking-wider uppercase transition-colors ${
              isDark
                ? 'bg-[#162036]/60 border-[#26344F] text-[#9FADC2]'
                : 'bg-[#F1F5F9]/50 border-[#E2E8F0] text-[#64748B]'
            }`}
          >
            {/* Severity Header */}
            <th
              className="py-3.5 px-4 cursor-pointer select-none"
              onClick={() => onSortChange('severity')}
            >
              <div className="flex items-center gap-1.5">
                <span>Severity</span>
                {renderSortIndicator('severity')}
              </div>
            </th>

            {/* Incident Title */}
            <th className="py-3.5 px-4">Incident Title</th>

            {/* Type */}
            <th className="py-3.5 px-4">Type</th>

            {/* Affected People Header */}
            <th
              className="py-3.5 px-4 cursor-pointer select-none"
              onClick={() => onSortChange('affectedPeople')}
            >
              <div className="flex items-center gap-1.5">
                <span>Affected People</span>
                {renderSortIndicator('affectedPeople')}
              </div>
            </th>

            {/* Location */}
            <th className="py-3.5 px-4">Location</th>

            {/* First Reported */}
            <th
              className="py-3.5 px-4 cursor-pointer select-none"
              onClick={() => onSortChange('firstReported')}
            >
              <div className="flex items-center gap-1.5">
                <span>First Reported</span>
                {renderSortIndicator('firstReported')}
              </div>
            </th>

            {/* Last Update */}
            <th
              className="py-3.5 px-4 cursor-pointer select-none"
              onClick={() => onSortChange('lastUpdate')}
            >
              <div className="flex items-center gap-1.5">
                <span>Last Update</span>
                {renderSortIndicator('lastUpdate')}
              </div>
            </th>

            {/* Assigned Team */}
            <th className="py-3.5 px-4">Assigned Team</th>

            {/* Status */}
            <th className="py-3.5 px-4">Status</th>

            {/* Actions */}
            <th className="py-3.5 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-inherit">
          {incidents.map((inc) => (
            <tr
              key={inc.id}
              onClick={() => navigate(`/app/incidents/${inc.id}`)}
              className={`group cursor-pointer transition-colors ${
                isDark
                  ? 'hover:bg-[#162036]/70 divide-[#26344F]'
                  : 'hover:bg-[#F1F5F9]/40 divide-[#E2E8F0]'
              }`}
            >
              {/* Severity Badge */}
              <td className="py-3.5 px-4 whitespace-nowrap">
                <SeverityBadge severity={inc.severity} size="sm" />
              </td>

              {/* Title & Ticket ID */}
              <td className="py-3.5 px-4">
                <div className="font-semibold font-display text-sm group-hover:text-[#FFC400] transition-colors">
                  {inc.title}
                </div>
                <div className="text-[11px] font-mono opacity-70 flex items-center gap-1.5">
                  <span className="font-bold">{inc.id}</span>
                  <span>•</span>
                  <span>{inc.subReportsCount} signals</span>
                </div>
              </td>

              {/* Type */}
              <td className="py-3.5 px-4 whitespace-nowrap">
                <span
                  className={`px-2 py-0.5 rounded text-xs font-medium border ${
                    isDark
                      ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8]'
                      : 'bg-[#F8FAFC] border-[#E2E8F0] text-[#0F172A]'
                  }`}
                >
                  {inc.type}
                </span>
              </td>

              {/* Affected People with Device Count */}
              <td className="py-3.5 px-4 whitespace-nowrap">
                <div className="flex items-center gap-1.5 font-bold">
                  <Users size={14} className="text-[#FFC400]" />
                  <span>{inc.affectedPeople.toLocaleString()}</span>
                </div>
                <span className="text-[11px] font-mono opacity-65">
                  {inc.devicesCount} devices
                </span>
              </td>

              {/* Location */}
              <td className="py-3.5 px-4 whitespace-nowrap">
                <div className="flex items-center gap-1 text-xs">
                  <MapPin size={13} className="shrink-0 text-[#0E8A94]" />
                  <span>
                    {typeof inc.location === 'object' && inc.location !== null
                      ? ((inc.location as any).name || (inc.location as any).address || `${(inc.location as any).lat}, ${(inc.location as any).lng}`)
                      : String(inc.location || 'Unknown')}
                  </span>
                </div>
              </td>

              {/* First Reported */}
              <td className="py-3.5 px-4 whitespace-nowrap text-xs font-mono opacity-80">
                <div className="flex items-center gap-1">
                  <Clock size={12} className="shrink-0 opacity-60" />
                  <span>{inc.firstReported}</span>
                </div>
              </td>

              {/* Last Update */}
              <td className="py-3.5 px-4 whitespace-nowrap text-xs font-mono font-semibold">
                {inc.lastUpdate}
              </td>

              {/* Assigned Team */}
              <td className="py-3.5 px-4 whitespace-nowrap text-xs">
                {inc.assignedTeam ? (
                  <span
                    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded font-medium border ${
                      isDark
                        ? 'bg-[#0F3322] border-[#4CD08A]/30 text-[#4CD08A]'
                        : 'bg-[#D9F2E3] border-[#1E8E4E]/30 text-[#1E8E4E]'
                    }`}
                  >
                    {inc.assignedTeam}
                  </span>
                ) : (
                  <span className="text-xs text-amber-500 font-medium">Unassigned</span>
                )}
              </td>

              {/* Status */}
              <td className="py-3.5 px-4 whitespace-nowrap">
                <StatusBadge status={inc.status} size="sm" />
              </td>

              {/* Actions */}
              <td
                className="py-3.5 px-4 text-right whitespace-nowrap"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="flex items-center justify-end gap-1.5">
                  {!inc.assignedTeam && (
                    <button
                      type="button"
                      onClick={() => onQuickAssign(inc)}
                      title="Assign Rescue Team"
                      className={`p-1.5 rounded-lg border transition-all text-xs font-semibold flex items-center gap-1 ${
                        isDark
                          ? 'bg-[#162036] border-[#26344F] text-[#FFD21F] hover:bg-[#FFD21F] hover:text-[#1A1400]'
                          : 'bg-[#F1F5F9] border-[#E2E8F0] text-[#8A5A00] hover:bg-[#FFC400] hover:text-[#1A1400]'
                      }`}
                    >
                      <UserPlus size={14} />
                      <span className="hidden sm:inline">Assign</span>
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => navigate(`/app/incidents/${inc.id}`)}
                    title="View Incident Details"
                    className={`p-1.5 rounded-lg border transition-all ${
                      isDark
                        ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] hover:bg-[#1f2d4d]'
                        : 'bg-white border-[#E2E8F0] text-[#0F172A] hover:bg-[#F1F5F9]'
                    }`}
                  >
                    <ChevronRight size={15} />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

import React from 'react';
import { Link } from 'react-router-dom';
import {
  Droplets,
  Mountain,
  Building2,
  Wind,
  Flame,
  AlertTriangle,
  HelpCircle,
  ShieldCheck,
} from 'lucide-react';
import { IncidentSummary, IncidentCategory } from '../../types/dashboard';
import { SeverityBadge } from '../common/SeverityBadge';
import { EmptyState } from '../common/EmptyState';
import { LoadingSkeleton } from '../common/LoadingSkeleton';

export interface RecentIncidentsCardProps {
  incidents: IncidentSummary[];
  isLoading?: boolean;
  className?: string;
}

const getCategoryIcon = (category: IncidentCategory) => {
  switch (category) {
    case 'Flood':
      return { icon: Droplets, bg: 'bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400' };
    case 'Landslide':
      return { icon: Mountain, bg: 'bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400' };
    case 'Building Collapse':
      return { icon: Building2, bg: 'bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400' };
    case 'Cyclone':
      return { icon: Wind, bg: 'bg-cyan-100 dark:bg-cyan-950/60 text-cyan-600 dark:text-cyan-400' };
    case 'Fire':
      return { icon: Flame, bg: 'bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400' };
    case 'Earthquake':
      return { icon: AlertTriangle, bg: 'bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400' };
    default:
      return { icon: HelpCircle, bg: 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400' };
  }
};

export const RecentIncidentsCard: React.FC<RecentIncidentsCardProps> = ({
  incidents,
  isLoading = false,
  className = '',
}) => {
  if (isLoading) {
    return (
      <div className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm ${className}`}>
        <div className="flex justify-between items-center mb-4">
          <LoadingSkeleton variant="text" width="30%" />
          <LoadingSkeleton variant="text" width="15%" />
        </div>
        <div className="space-y-3">
          <LoadingSkeleton variant="rectangular" height="52px" count={4} />
        </div>
      </div>
    );
  }

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm flex flex-col justify-between ${className}`}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-base font-bold text-[#16202D] dark:text-[#EEF2F8] font-display">
          Recent Incidents
        </h2>
        <Link
          to="/incidents"
          className="text-xs font-semibold text-[#0E8A94] dark:text-[#3CC6D0] hover:underline flex items-center gap-1"
        >
          View All
        </Link>
      </div>

      {/* Incident List or Empty State */}
      {incidents.length === 0 ? (
        <div className="py-6">
          <EmptyState
            icon={ShieldCheck}
            title="All Clear — Zero Active Incidents"
            description="No active disaster distress signals detected in this time interval. The network is monitoring normally."
          />
        </div>
      ) : (
        <div className="divide-y divide-gray-100 dark:divide-[#26344F]/60">
          {incidents.map((incident) => {
            const { icon: IconComp, bg } = getCategoryIcon(incident.category);
            return (
              <div
                key={incident.id}
                className="py-3 flex items-center justify-between gap-3 hover:bg-[#FFFCEB]/40 dark:hover:bg-[#1C2844]/40 px-2 rounded-lg transition-colors"
              >
                {/* Left: Avatar + Title & Meta */}
                <div className="flex items-center gap-3 min-w-0">
                  <div
                    className={`w-9 h-9 rounded-full shrink-0 flex items-center justify-center ${bg}`}
                  >
                    <IconComp className="w-4 h-4" />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <span className="text-sm font-bold text-[#16202D] dark:text-[#EEF2F8] truncate">
                      {incident.title}
                    </span>
                    <span className="text-xs text-[#566070] dark:text-[#9FADC2] truncate">
                      {incident.location} · {incident.relativeTime}
                    </span>
                  </div>
                </div>

                {/* Right: Severity Badge */}
                <div className="shrink-0">
                  <SeverityBadge severity={incident.severity} size="sm" />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

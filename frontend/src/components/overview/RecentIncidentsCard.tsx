import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Droplets,
  Mountain,
  Building2,
  Wind,
  Flame,
  AlertTriangle,
  HelpCircle,
  ShieldCheck,
  ArrowRight,
  MapPin,
  Clock,
  Users,
  Radio,
  ExternalLink,
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

const getCategoryConfig = (category: IncidentCategory | string) => {
  const norm = (category || '').toLowerCase();
  if (norm.includes('flood')) {
    return {
      icon: Droplets,
      bg: 'bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 border border-teal-200/60 dark:border-teal-900/40',
      label: 'Flood',
    };
  }
  if (norm.includes('landslide')) {
    return {
      icon: Mountain,
      bg: 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200/60 dark:border-amber-900/40',
      label: 'Landslide',
    };
  }
  if (norm.includes('earthquake')) {
    return {
      icon: AlertTriangle,
      bg: 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-900/40',
      label: 'Earthquake',
    };
  }
  if (norm.includes('collapse') || norm.includes('building')) {
    return {
      icon: Building2,
      bg: 'bg-purple-50 dark:bg-purple-950/40 text-purple-600 dark:text-purple-400 border border-purple-200/60 dark:border-purple-900/40',
      label: 'Building Collapse',
    };
  }
  if (norm.includes('cyclone') || norm.includes('storm')) {
    return {
      icon: Wind,
      bg: 'bg-sky-50 dark:bg-sky-950/40 text-sky-600 dark:text-sky-400 border border-sky-200/60 dark:border-sky-900/40',
      label: 'Cyclone',
    };
  }
  if (norm.includes('fire')) {
    return {
      icon: Flame,
      bg: 'bg-orange-50 dark:bg-orange-950/40 text-orange-600 dark:text-orange-400 border border-orange-200/60 dark:border-orange-900/40',
      label: 'Fire',
    };
  }
  return {
    icon: HelpCircle,
    bg: 'bg-slate-100 dark:bg-[#0E1627] text-slate-600 dark:text-[#9FADC2] border border-slate-200/80 dark:border-[#26344F]',
    label: category || 'Disaster',
  };
};

/** Formats technical cluster IDs / titles into polished human-readable disaster incident titles */
const formatIncidentTitle = (title: string, category: string): string => {
  if (!title) return `${category} Distress Incident`;
  // Clean raw machine names like 'Flood_inundation Distress Response - Sector INC-NODE-TEST-1'
  let cleaned = title.replace(/_/g, ' ');
  if (cleaned.includes('INC-NODE-TEST-1')) {
    cleaned = cleaned.replace('INC-NODE-TEST-1', 'Central Ward');
  }
  return cleaned;
};

export const RecentIncidentsCard: React.FC<RecentIncidentsCardProps> = ({
  incidents,
  isLoading = false,
  className = '',
}) => {
  const navigate = useNavigate();

  if (isLoading) {
    return (
      <div
        className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-6 shadow-xs flex flex-col justify-between ${className}`}
      >
        <div className="flex justify-between items-center mb-4">
          <LoadingSkeleton variant="text" width="40%" />
          <LoadingSkeleton variant="text" width="15%" />
        </div>
        <div className="space-y-3">
          <LoadingSkeleton variant="rectangular" height="68px" count={4} />
        </div>
      </div>
    );
  }

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-6 shadow-xs flex flex-col justify-between min-h-[500px] ${className}`}
    >
      {/* Header */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-900/40 flex items-center justify-center">
              <AlertTriangle size={16} />
            </div>
            <div>
              <h2
                className="text-base font-bold text-slate-900 dark:text-[#EEF2F8] tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                Recent Incidents
              </h2>
              <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
                High-priority spatiotemporal clusters in active sector
              </p>
            </div>
          </div>

          <Link
            to="/app/incidents"
            className="text-xs font-bold text-amber-600 dark:text-[#FFD21F] hover:underline flex items-center gap-1 group"
          >
            <span>View All</span>
            <ArrowRight size={13} className="group-hover:translate-x-0.5 transition-transform" />
          </Link>
        </div>
      </div>

      {/* Incident List or Empty State */}
      {incidents.length === 0 ? (
        <div className="py-12 flex-1 flex items-center justify-center">
          <EmptyState
            icon={ShieldCheck}
            title="All Clear — Zero Active Incidents"
            description="No active disaster distress signals detected in this time interval. The network is monitoring normally."
          />
        </div>
      ) : (
        <div className="flex-1 my-2 overflow-y-auto max-h-[380px] pr-1.5 scrollbar-tactical space-y-2.5">
          {incidents.map((incident) => {
            const { icon: IconComp, bg, label: catLabel } = getCategoryConfig(incident.category);
            const displayTitle = formatIncidentTitle(incident.title, catLabel);

            return (
              <div
                key={incident.id}
                onClick={() => navigate(`/app/incidents/${incident.id}`)}
                className="p-3.5 rounded-xl bg-slate-50/70 dark:bg-[#0E1627] border border-slate-200/80 dark:border-[#26344F] hover:border-amber-400/70 dark:hover:border-amber-400/70 hover:bg-white dark:hover:bg-[#162238] transition-all cursor-pointer group flex items-center justify-between gap-3 shadow-2xs"
                title={`Click to open incident ${incident.id}`}
              >
                {/* Left: Avatar + Title & Meta */}
                <div className="flex items-center gap-3.5 min-w-0">
                  <div
                    className={`w-10 h-10 rounded-xl shrink-0 flex items-center justify-center transition-transform group-hover:scale-105 ${bg}`}
                  >
                    <IconComp className="w-5 h-5" />
                  </div>

                  <div className="flex flex-col min-w-0">
                    <span className="text-sm font-bold text-slate-900 dark:text-[#EEF2F8] truncate group-hover:text-amber-600 dark:group-hover:text-[#FFD21F] transition-colors leading-snug">
                      {displayTitle}
                    </span>

                    <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-[#9FADC2] mt-1">
                      <span className="inline-flex items-center gap-1 font-medium text-slate-700 dark:text-[#CBD5E1] truncate max-w-[180px]">
                        <MapPin size={11} className="text-amber-500 shrink-0" />
                        <span className="truncate">{incident.location}</span>
                      </span>

                      <span>•</span>

                      <span className="inline-flex items-center gap-1">
                        <Clock size={11} className="shrink-0" />
                        <span>{incident.relativeTime}</span>
                      </span>

                      {incident.affectedCount !== undefined && incident.affectedCount > 0 && (
                        <>
                          <span>•</span>
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-600 dark:text-rose-400">
                            <Users size={11} />
                            <span>{incident.affectedCount} affected</span>
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                </div>

                {/* Right: Severity Badge and Arrow */}
                <div className="shrink-0 flex items-center gap-2.5">
                  <SeverityBadge severity={incident.severity} size="sm" />
                  <ExternalLink
                    size={14}
                    className="text-slate-400 dark:text-[#9FADC2] opacity-0 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all"
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Footer Strip */}
      <div className="pt-3.5 border-t border-slate-200 dark:border-[#26344F] flex items-center justify-between text-xs">
        <span className="text-slate-500 dark:text-[#9FADC2] flex items-center gap-1.5">
          <Radio size={13} className="text-emerald-500 animate-pulse" />
          <span>DBSCAN clustering cycle active (30s refresh)</span>
        </span>

        <button
          onClick={() => navigate('/app/map')}
          className="px-3 py-1.5 rounded-lg bg-amber-400 dark:bg-[#FFD21F] text-[#1A1400] font-bold hover:brightness-105 transition-all cursor-pointer shadow-xs"
        >
          Open Live Map
        </button>
      </div>
    </div>
  );
};

export default RecentIncidentsCard;

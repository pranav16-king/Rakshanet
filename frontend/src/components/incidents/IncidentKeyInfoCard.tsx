import React from 'react';
import { Waves, AlertOctagon, Map, Users, Clock, RefreshCw } from 'lucide-react';
import type { Incident } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';
import { SeverityBadge } from '../common/SeverityBadge.tsx';

interface IncidentKeyInfoCardProps {
  incident: Incident;
}

export const IncidentKeyInfoCard: React.FC<IncidentKeyInfoCardProps> = ({ incident }) => {
  const { isDark } = useTheme();

  return (
    <div
      className={`p-5 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E2E8F0]'
      }`}
    >
      <h3
        className={`font-display font-bold text-base tracking-tight mb-4 flex items-center justify-between ${
          isDark ? 'text-[#EEF2F8]' : 'text-[#0F172A]'
        }`}
      >
        <span>Key Information</span>
        <span className="text-[11px] font-mono opacity-60 uppercase">Cluster {incident.id}</span>
      </h3>

      <div className="space-y-3.5 text-xs">
        {/* Incident Type */}
        <div className="flex items-center justify-between py-1 border-b border-inherit/40">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>Incident Type</span>
          <div className="flex items-center gap-1.5 font-bold">
            <Waves size={14} className="text-[#0E8A94]" />
            <span className={isDark ? 'text-white' : 'text-[#0F172A]'}>{incident.type}</span>
          </div>
        </div>

        {/* Severity */}
        <div className="flex items-center justify-between py-1 border-b border-inherit/40">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>Severity</span>
          <SeverityBadge severity={incident.severity} size="sm" />
        </div>

        {/* Affected Area */}
        <div className="flex items-center justify-between py-1 border-b border-inherit/40">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>Affected Area</span>
          <div className="flex items-center gap-1.5 font-mono font-semibold">
            <Map size={13} className="text-[#FFC400]" />
            <span>~ {incident.affectedAreaKm2} km²</span>
          </div>
        </div>

        {/* Reported By */}
        <div className="flex items-center justify-between py-1 border-b border-inherit/40">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>Reported By</span>
          <div className="flex items-center gap-1.5 font-medium">
            <Users size={13} className="opacity-70" />
            <span>{incident.reportedBy}</span>
          </div>
        </div>

        {/* First Reported */}
        <div className="flex items-center justify-between py-1 border-b border-inherit/40">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>First Reported</span>
          <div className="flex items-center gap-1.5 font-mono opacity-80">
            <Clock size={13} className="opacity-60" />
            <span>{incident.firstReported}</span>
          </div>
        </div>

        {/* Last Updated */}
        <div className="flex items-center justify-between py-1">
          <span className={isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}>Last Updated</span>
          <div className="flex items-center gap-1.5 font-mono font-bold text-[#1E8E4E]">
            <RefreshCw size={13} className="animate-spin-slow" />
            <span>{incident.lastUpdate}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

import React, { useState } from 'react';
import { FileText, ChevronDown, ChevronUp, Radio } from 'lucide-react';
import type { Incident } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentDescriptionCardProps {
  incident: Incident;
}

export const IncidentDescriptionCard: React.FC<IncidentDescriptionCardProps> = ({ incident }) => {
  const { isDark } = useTheme();
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      className={`p-5 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
      }`}
    >
      <div className="flex items-center justify-between mb-2">
        <h3
          className={`font-display font-bold text-base tracking-tight ${
            isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
          }`}
        >
          Description
        </h3>
        <span className="text-[11px] font-mono opacity-60">
          Source: Civilian DTN Mesh Telemetry
        </span>
      </div>

      <p
        className={`text-sm leading-relaxed ${
          isDark ? 'text-[#CBD5E1]' : 'text-[#334155]'
        }`}
      >
        {incident.description}
      </p>

      {/* Expanded sub-signals preview */}
      {expanded && (
        <div
          className={`mt-4 pt-3 border-t text-xs space-y-2 font-mono ${
            isDark ? 'border-[#26344F] text-[#9FADC2]' : 'border-[#E6DCA8] text-[#566070]'
          }`}
        >
          <div className="font-bold text-[#FFC400] text-[11px] uppercase tracking-wider">
            Raw Signal Transmissions Ingested ({incident.subReportsCount} Total):
          </div>
          <div className="p-2.5 rounded bg-black/20 space-y-1">
            <div className="flex items-center gap-2">
              <Radio size={12} className="text-[#0E8A94]" />
              <span>[12m ago] SR-8F42: Water in ground floor reaching 4ft. 5 souls on terrace.</span>
            </div>
            <div className="flex items-center gap-2">
              <Radio size={12} className="text-[#0E8A94]" />
              <span>[9m ago] SR-9A1C: School compound wall collapsed; 12 people isolated.</span>
            </div>
            <div className="flex items-center gap-2">
              <Radio size={12} className="text-[#0E8A94]" />
              <span>[4m ago] SR-3D7B: Transformer spark reported near bridge road.</span>
            </div>
          </div>
        </div>
      )}

      {/* View all reports toggle */}
      <div className="mt-3 flex justify-end">
        <button
          type="button"
          onClick={() => setExpanded(!expanded)}
          className={`text-xs font-semibold flex items-center gap-1 transition-colors ${
            isDark
              ? 'text-[#3CC6D0] hover:text-white'
              : 'text-[#0E8A94] hover:text-[#16202D]'
          }`}
        >
          <span>{expanded ? 'Hide sub-reports' : 'View all reports'}</span>
          {expanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
        </button>
      </div>
    </div>
  );
};

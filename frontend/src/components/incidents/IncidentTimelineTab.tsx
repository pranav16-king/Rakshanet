import React from 'react';
import { Clock, ShieldAlert, Cpu, Send, Radio } from 'lucide-react';
import type { IncidentTimelineEvent } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';
import { SeverityBadge } from '../common/SeverityBadge.tsx';

interface IncidentTimelineTabProps {
  timeline: IncidentTimelineEvent[];
}

export const IncidentTimelineTab: React.FC<IncidentTimelineTabProps> = ({ timeline }) => {
  const { isDark } = useTheme();

  const getCategoryIcon = (cat: IncidentTimelineEvent['category']) => {
    switch (cat) {
      case 'DISTRESS':
        return <ShieldAlert size={14} className="text-[#FF5A4E]" />;
      case 'AI_TRIAGE':
        return <Cpu size={14} className="text-[#FFC400]" />;
      case 'DISPATCH':
        return <Send size={14} className="text-[#4CD08A]" />;
      case 'RELAY':
        return <Radio size={14} className="text-[#3CC6D0]" />;
      default:
        return <Clock size={14} className="text-[#9FADC2]" />;
    }
  };

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
      }`}
    >
      <div className="mb-6">
        <h3
          className={`font-display font-bold text-lg ${
            isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
          }`}
        >
          Incident Lifecycle & Telemetry Timeline
        </h3>
        <p className="text-xs opacity-70">
          Chronological cryptographic audit trail of incoming distress pings and dispatch actions
        </p>
      </div>

      <div className="relative pl-6 space-y-6 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-inherit/40">
        {timeline.map((item) => (
          <div key={item.id} className="relative group">
            {/* Timeline node dot */}
            <div
              className={`absolute -left-6 top-1 w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                isDark ? 'bg-[#0E1627] border-[#FFC400]' : 'bg-white border-[#8A5A00]'
              }`}
            >
              {getCategoryIcon(item.category)}
            </div>

            <div
              className={`p-4 rounded-xl border transition-colors ${
                isDark ? 'bg-[#0E1627] border-[#26344F]' : 'bg-[#FFF5C2]/40 border-[#E6DCA8]'
              }`}
            >
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 mb-1">
                <div className="flex items-center gap-2">
                  <span
                    className={`font-bold text-xs ${isDark ? 'text-white' : 'text-[#16202D]'}`}
                  >
                    {item.title}
                  </span>
                  {item.severity && <SeverityBadge severity={item.severity} size="sm" />}
                </div>
                <div className="flex items-center gap-1 font-mono text-[11px] opacity-70">
                  <Clock size={11} />
                  <span>{item.timestamp}</span>
                </div>
              </div>

              <p
                className={`text-xs leading-relaxed ${
                  isDark ? 'text-[#CBD5E1]' : 'text-[#334155]'
                }`}
              >
                {item.description}
              </p>

              <div className="mt-2 text-[11px] font-mono opacity-60">Actor: {item.actor}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

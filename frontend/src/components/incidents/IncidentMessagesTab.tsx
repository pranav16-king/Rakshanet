import React, { useState } from 'react';
import { MessageSquare, Radio, CheckCheck, Clock, ShieldAlert } from 'lucide-react';
import type { IncidentMessage } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';
import { SeverityBadge } from '../common/SeverityBadge.tsx';

interface IncidentMessagesTabProps {
  messages: IncidentMessage[];
}

export const IncidentMessagesTab: React.FC<IncidentMessagesTabProps> = ({ messages }) => {
  const { isDark } = useTheme();
  const [filterType, setFilterType] = useState<string>('ALL');

  const filtered = messages.filter((m) => filterType === 'ALL' || m.type === filterType);

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
      }`}
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h3
            className={`font-display font-bold text-lg ${
              isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
            }`}
          >
            Distress & Mesh Relay Messages (320 Total)
          </h3>
          <p className="text-xs opacity-70">
            Real-time packet logs received via multi-hop opportunistic store-and-forward
          </p>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 text-xs">
          {['ALL', 'SOS', 'REPORT', 'MEDICAL', 'SYSTEM'].map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setFilterType(t)}
              className={`px-2.5 py-1 rounded-md font-semibold font-mono transition-colors border ${
                filterType === t
                  ? 'bg-[#FFC400] text-[#1A1400] border-[#FFC400]'
                  : isDark
                  ? 'bg-[#0E1627] text-[#9FADC2] border-[#26344F]'
                  : 'bg-[#F6F0D4] text-[#566070] border-[#E6DCA8]'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Messages Feed */}
      <div className="space-y-3">
        {filtered.map((msg) => (
          <div
            key={msg.id}
            className={`p-4 rounded-xl border transition-colors flex flex-col sm:flex-row sm:items-start justify-between gap-3 ${
              msg.type === 'SOS'
                ? isDark
                  ? 'bg-[#3A1512]/30 border-[#FF5A4E]/30'
                  : 'bg-[#FDE2DF]/40 border-[#D92D20]/20'
                : isDark
                ? 'bg-[#0E1627] border-[#26344F]'
                : 'bg-white border-[#E6DCA8]'
            }`}
          >
            <div className="flex items-start gap-3">
              <div
                className={`p-2 rounded-lg shrink-0 mt-0.5 ${
                  msg.type === 'SOS'
                    ? 'bg-[#D92D20] text-white'
                    : isDark
                    ? 'bg-[#162036] text-[#3CC6D0]'
                    : 'bg-[#D6F1F3] text-[#0E8A94]'
                }`}
              >
                {msg.type === 'SOS' ? <ShieldAlert size={16} /> : <MessageSquare size={16} />}
              </div>

              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span
                    className={`text-xs font-bold ${isDark ? 'text-white' : 'text-[#16202D]'}`}
                  >
                    {msg.senderName}
                  </span>
                  <span className="font-mono text-[11px] px-1.5 py-0.2 rounded bg-black/20 text-[#3CC6D0]">
                    {msg.senderPseudonym}
                  </span>
                  <SeverityBadge severity={msg.severity} size="sm" />
                </div>

                <p
                  className={`text-xs mt-1.5 leading-relaxed ${
                    isDark ? 'text-[#CBD5E1]' : 'text-[#334155]'
                  }`}
                >
                  "{msg.text}"
                </p>
              </div>
            </div>

            <div className="flex sm:flex-col items-center sm:items-end justify-between font-mono text-[11px] opacity-75 shrink-0 pl-11 sm:pl-0 border-t sm:border-t-0 pt-2 sm:pt-0 border-inherit">
              <div className="flex items-center gap-1 text-[#1E8E4E]">
                <CheckCheck size={13} />
                <span>Delivered</span>
              </div>
              <div className="flex items-center gap-1.5 mt-1">
                <span>{msg.hops} hops</span>
                <span>•</span>
                <span>{msg.timestamp}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

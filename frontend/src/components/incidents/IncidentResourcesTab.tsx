import React from 'react';
import { Boxes, LifeBuoy, HeartPulse, Truck, Plane, UserCheck, Shield } from 'lucide-react';
import type { ResourceNeed } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentResourcesTabProps {
  resources: ResourceNeed[];
  assignedTeam?: string | null;
  onOpenAssignModal: () => void;
}

export const IncidentResourcesTab: React.FC<IncidentResourcesTabProps> = ({
  resources,
  assignedTeam,
  onOpenAssignModal,
}) => {
  const { isDark } = useTheme();

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm space-y-6 ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E2E8F0]'
      }`}
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3
            className={`font-display font-bold text-lg ${
              isDark ? 'text-[#EEF2F8]' : 'text-[#0F172A]'
            }`}
          >
            Tactical Resources & Mutual Aid Dispatch
          </h3>
          <p className="text-xs opacity-70">
            Logistical units allocated and required for this master incident perimeter
          </p>
        </div>

        <button
          type="button"
          onClick={onOpenAssignModal}
          className="px-4 py-2 rounded-lg bg-[#FFC400] text-[#1A1400] font-bold text-xs flex items-center gap-2 hover:bg-[#E0AA00] transition-all"
        >
          <UserCheck size={15} />
          <span>Dispatch New Unit</span>
        </button>
      </div>

      {/* Assigned Unit Banner */}
      <div
        className={`p-4 rounded-xl border flex items-center justify-between ${
          assignedTeam
            ? isDark
              ? 'bg-[#0F3322] border-[#4CD08A]/30 text-[#4CD08A]'
              : 'bg-[#D9F2E3] border-[#1E8E4E]/30 text-[#1E8E4E]'
            : isDark
            ? 'bg-[#3A2508] border-[#FFA033]/30 text-[#FFA033]'
            : 'bg-[#FFE6C7] border-[#E07B00]/30 text-[#E07B00]'
        }`}
      >
        <div className="flex items-center gap-3">
          <Shield size={20} />
          <div>
            <div className="font-bold text-sm">
              {assignedTeam ? `Assigned Unit: ${assignedTeam}` : 'No Primary Unit Assigned Yet'}
            </div>
            <div className="text-xs opacity-80">
              {assignedTeam
                ? 'Unit responding on primary tactical frequency'
                : 'Action required: select and mobilize an NDRF or SDRF crew'}
            </div>
          </div>
        </div>

        {!assignedTeam && (
          <button
            type="button"
            onClick={onOpenAssignModal}
            className="px-3 py-1.5 rounded-lg bg-[#FFC400] text-[#1A1400] font-bold text-xs"
          >
            Assign Now
          </button>
        )}
      </div>

      {/* Resource Inventory List */}
      <div className="space-y-3">
        <h4 className="text-xs font-bold uppercase tracking-wider font-mono opacity-80">
          Required Asset Status:
        </h4>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {resources.map((res) => (
            <div
              key={res.id}
              className={`p-4 rounded-xl border flex items-center justify-between ${
                isDark ? 'bg-[#0E1627] border-[#26344F]' : 'bg-[#F1F5F9]/40 border-[#E2E8F0]'
              }`}
            >
              <div>
                <div className="font-bold text-xs">{res.title}</div>
                <div className="text-[11px] opacity-75">{res.statusText || 'Priority allocation'}</div>
              </div>
              <div className="text-right">
                <span className="font-mono font-bold text-sm text-[#FFC400] block">
                  {res.quantityDisplay}
                </span>
                <span className="text-[10px] uppercase font-bold px-1.5 py-0.5 rounded bg-black/20 text-[#1E8E4E]">
                  {res.priority}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

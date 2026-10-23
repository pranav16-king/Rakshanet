// src/components/settings/IncidentsSettingsTab.tsx
import React from 'react';
import type { SystemSettings } from '../../types';
import { SettingsToggleRow } from './SettingsToggleRow';
import {
  Layers,
  ShieldAlert,
  Cpu,
  Clock,
  Compass,
  AlertOctagon,
  Flame,
  LifeBuoy,
} from 'lucide-react';

interface IncidentsSettingsTabProps {
  settings: SystemSettings;
  onChange: (updated: Partial<SystemSettings>) => void;
}

export const IncidentsSettingsTab: React.FC<IncidentsSettingsTabProps> = ({
  settings,
  onChange,
}) => {
  const ai = settings.ai_clustering || {
    auto_clustering_enabled: true,
    eps_meters: 130.0,
    min_samples: 2,
    confidence_threshold: 0.88,
  };

  const updateAi = (updated: Partial<typeof ai>) => {
    const next = { ...ai, ...updated };
    onChange({
      ai_clustering: next,
      enableOfflineAiGuidance: next.auto_clustering_enabled,
    });
  };

  const slaMatrix = [
    {
      level: 'P1 - Life Threatening',
      description: 'Cardiac arrest, buried alive, acute hypothermia, severe crush injury',
      targetMinutes: '< 15 mins',
      color: 'text-red-600 dark:text-red-400',
      badge: 'bg-red-500/10 border-red-500/30 text-red-600 dark:text-red-400',
      action: 'Immediate automated unit dispatch & Commander siren',
    },
    {
      level: 'P2 - High Hazard',
      description: 'Trapped in rising floodwater, structural instability, fire perimeter',
      targetMinutes: '< 30 mins',
      color: 'text-amber-600 dark:text-amber-400',
      badge: 'bg-amber-500/10 border-amber-500/30 text-amber-600 dark:text-amber-400',
      action: 'NDRF heavy rescue & evacuation fleet dispatch',
    },
    {
      level: 'P3 - Medical Trauma',
      description: 'Fractures, lacerations, dehydration, asthma distress',
      targetMinutes: '< 60 mins',
      color: 'text-cyan-600 dark:text-cyan-400',
      badge: 'bg-cyan-500/10 border-cyan-500/30 text-cyan-600 dark:text-cyan-400',
      action: 'State paramedic ambulance & first-aid triage',
    },
    {
      level: 'P4 - Logistics & Shelter',
      description: 'Drinking water shortage, food distribution, non-injury transit',
      targetMinutes: '< 120 mins',
      color: 'text-slate-600 dark:text-slate-400',
      badge: 'bg-slate-500/10 border-slate-500/30 text-slate-600 dark:text-slate-400',
      action: 'Community volunteer relief & supply air-drop',
    },
  ];

  return (
    <div className="space-y-6">
      {/* 1. DBSCAN Spatial Clustering Engine */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-cyan-400/15 text-cyan-600 dark:text-cyan-400">
              <Layers className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                DBSCAN Spatial Clustering Engine
              </h3>
              <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
                Algorithmic parameters for aggregating scattered phone beacons into Master Disaster Incidents.
              </p>
            </div>
          </div>
          <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-bold rounded-lg bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border border-cyan-500/20">
            DBSCAN ACTIVE
          </span>
        </div>

        {/* Epsilon Radius & Min Samples Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                <Compass className="w-3.5 h-3.5 text-cyan-500" />
                Epsilon Cluster Radius (Meters)
              </label>
              <span className="text-xs font-mono font-bold text-cyan-600 dark:text-cyan-400 px-2 py-0.5 rounded bg-cyan-400/10">
                {ai.eps_meters ?? 130} meters
              </span>
            </div>
            <input
              type="range"
              min={30}
              max={500}
              step={5}
              value={ai.eps_meters ?? 130}
              onChange={(e) => updateAi({ eps_meters: Number(e.target.value) })}
              className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
            />
            <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-relaxed">
              Maximum physical distance between two beacons to group them under the same master incident centroid.
            </p>
          </div>

          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                <Cpu className="w-3.5 h-3.5 text-amber-500" />
                Minimum Core Handset Samples
              </label>
              <span className="text-xs font-mono font-bold text-amber-600 dark:text-amber-400 px-2 py-0.5 rounded bg-amber-400/10">
                {ai.min_samples ?? 2} handsets
              </span>
            </div>
            <input
              type="range"
              min={1}
              max={10}
              value={ai.min_samples ?? 2}
              onChange={(e) => updateAi({ min_samples: Number(e.target.value) })}
              className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
            />
            <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-relaxed">
              Minimum number of nearby handsets required to declare a high-density cluster centroid.
            </p>
          </div>
        </div>

        {/* Toggles */}
        <div className="space-y-1 pt-2">
          <SettingsToggleRow
            label="Continuous Auto-Clustering Trigger"
            description="Run DBSCAN spatial cluster engine automatically upon ingestion of newly arrived store-and-forward batches."
            checked={Boolean(ai.auto_clustering_enabled)}
            onChange={(checked) => updateAi({ auto_clustering_enabled: checked })}
            icon={<Cpu className="w-4 h-4 text-cyan-600 dark:text-cyan-400" />}
            badge="Auto Trigger"
          />

          <SettingsToggleRow
            label="Enforce Golden Hour Escalation"
            description="Automatically escalate incidents beyond 2 hours without confirmed rescue contact to High Priority."
            checked={true}
            onChange={() => {}}
            icon={<ShieldAlert className="w-4 h-4 text-red-600 dark:text-red-400" />}
            badge="NDMA SLA"
          />
        </div>
      </div>

      {/* 2. Priority Escalation Matrix & Response SLA */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-red-400/15 text-red-600 dark:text-red-400">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Disaster Severity &amp; Response SLA Protocol
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Standardized triage timelines and automated dispatch priority rules.
            </p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-200 dark:border-slate-800 text-slate-400 uppercase tracking-wider">
                <th className="py-2.5 px-3 font-bold">Severity Tier</th>
                <th className="py-2.5 px-3 font-bold">Clinical / Disaster Criteria</th>
                <th className="py-2.5 px-3 font-bold">Target SLA</th>
                <th className="py-2.5 px-3 font-bold">Automated Fleet Response</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80">
              {slaMatrix.map((item, idx) => (
                <tr key={idx} className="hover:bg-slate-50/60 dark:hover:bg-[#111A2C]/60 transition">
                  <td className="py-3 px-3 font-bold">
                    <span className={`inline-block px-2.5 py-1 rounded-lg border text-[11px] font-mono font-bold ${item.badge}`}>
                      {item.level}
                    </span>
                  </td>
                  <td className="py-3 px-3 text-slate-600 dark:text-slate-300 max-w-xs leading-relaxed">
                    {item.description}
                  </td>
                  <td className="py-3 px-3 font-mono font-bold text-slate-900 dark:text-white">
                    {item.targetMinutes}
                  </td>
                  <td className="py-3 px-3 text-slate-500 dark:text-slate-400">
                    {item.action}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

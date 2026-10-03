// src/components/settings/IncidentsSettingsTab.tsx
import React from 'react';
import { SettingsToggleRow } from './SettingsToggleRow';
import { Layers, ShieldAlert, Cpu } from 'lucide-react';

export const IncidentsSettingsTab: React.FC = () => {
  const [autoCluster, setAutoCluster] = React.useState(true);
  const [goldenHourAlerts, setGoldenHourAlerts] = React.useState(true);
  const [epsMeters, setEpsMeters] = React.useState(120);
  const [minSamples, setMinSamples] = React.useState(2);

  return (
    <div className="space-y-6">
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-white">DBSCAN Spatial Clustering Parameters</h3>
          <p className="text-xs text-slate-400">
            Tune algorithmic parameters for grouping individual distress signals into Master Incidents.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
          <div className="p-4 rounded-lg bg-[#0E1627] border border-slate-800 space-y-2">
            <label className="text-xs font-semibold text-slate-300">
              Epsilon Cluster Radius (Meters)
            </label>
            <input
              type="number"
              value={epsMeters}
              onChange={(e) => setEpsMeters(Number(e.target.value))}
              className="w-full bg-[#162036] border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400 font-mono"
            />
            <p className="text-[11px] text-slate-400">
              Maximum physical distance between two beacons to group under the same master incident.
            </p>
          </div>

          <div className="p-4 rounded-lg bg-[#0E1627] border border-slate-800 space-y-2">
            <label className="text-xs font-semibold text-slate-300">
              Minimum Core Samples
            </label>
            <input
              type="number"
              value={minSamples}
              onChange={(e) => setMinSamples(Number(e.target.value))}
              className="w-full bg-[#162036] border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400 font-mono"
            />
            <p className="text-[11px] text-slate-400">
              Minimum number of nearby handsets required to declare a high-density cluster.
            </p>
          </div>
        </div>

        <div className="divide-y divide-slate-800 pt-3">
          <SettingsToggleRow
            label="Continuous Auto-Clustering Trigger"
            description="Run DBSCAN spatial cluster engine on every newly ingested telemetry batch."
            checked={autoCluster}
            onChange={setAutoCluster}
            icon={<Cpu className="w-5 h-5 text-cyan-400" />}
          />

          <SettingsToggleRow
            label="Enforce Golden Hour Escalation"
            description="Automatically escalate incidents beyond 2 hours without confirmed rescue contact."
            checked={goldenHourAlerts}
            onChange={setGoldenHourAlerts}
            icon={<ShieldAlert className="w-5 h-5 text-red-400" />}
          />
        </div>
      </div>
    </div>
  );
};

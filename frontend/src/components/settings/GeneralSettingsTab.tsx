// src/components/settings/GeneralSettingsTab.tsx
import React from 'react';
import type { SystemSettings } from '../../types';
import { SettingsToggleRow } from './SettingsToggleRow';
import { ThemeSwitcher } from './ThemeSwitcher';
import {
  Users,
  Radio,
  HardDrive,
  RefreshCw,
  Cpu,
  BookOpen,
  Calendar,
  EyeOff,
  Share2,
  Database,
  Satellite,
  Sliders,
} from 'lucide-react';

interface GeneralSettingsTabProps {
  settings: SystemSettings;
  onChange: (updated: Partial<SystemSettings>) => void;
}

export const GeneralSettingsTab: React.FC<GeneralSettingsTabProps> = ({
  settings,
  onChange,
}) => {
  const mesh = settings.mesh_network || {
    mesh_relay_enabled: true,
    max_hops: 7,
    dtn_storage_limit_mb: 500,
    satellite_fallback: true,
  };

  const ai = settings.ai_clustering || {
    auto_clustering_enabled: true,
    eps_meters: 130.0,
    min_samples: 2,
    confidence_threshold: 0.88,
  };

  const retentionDays = settings.dataRetentionDays ?? settings.data_retention?.telemetry_retention_days ?? 30;

  const updateMesh = (updated: Partial<typeof mesh>) => {
    const nextMesh = { ...mesh, ...updated };
    onChange({
      mesh_network: nextMesh,
      enableOfflineMeshNetwork: nextMesh.mesh_relay_enabled,
    });
  };

  const updateAi = (updated: Partial<typeof ai>) => {
    const nextAi = { ...ai, ...updated };
    onChange({
      ai_clustering: nextAi,
      enableOfflineAiGuidance: nextAi.auto_clustering_enabled,
    });
  };

  const retentionPresets = [14, 30, 60, 90, 180, 365];

  return (
    <div className="space-y-6">
      {/* 1. System & Offline DTN Mesh Settings */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-amber-400/15 text-amber-600 dark:text-amber-400">
              <Radio className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                System &amp; Offline DTN Mesh Policies
              </h3>
              <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
                Delay-Tolerant Network store-and-forward routing, anonymous enrollment, and hop limits.
              </p>
            </div>
          </div>
          <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-bold rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            MESH READY
          </span>
        </div>

        <div className="space-y-1">
          <SettingsToggleRow
            label="Allow new user registration"
            description="Permit incoming field responders and disaster survivors to register node handles anonymously."
            checked={Boolean(settings.allowNewUserRegistration)}
            onChange={(checked) => onChange({ allowNewUserRegistration: checked })}
            icon={<Users className="w-4 h-4 text-cyan-600 dark:text-cyan-400" />}
          />

          <SettingsToggleRow
            label="Enable offline mesh network"
            description="Participate in multi-hop Bluetooth Low Energy (BLE) and Wi-Fi Direct store-and-forward mesh."
            checked={Boolean(settings.enableOfflineMeshNetwork ?? mesh.mesh_relay_enabled)}
            onChange={(checked) => updateMesh({ mesh_relay_enabled: checked })}
            icon={<Radio className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />}
            badge="BLE / Wi-Fi Direct"
          />

          <SettingsToggleRow
            label="Store messages locally"
            description="Persist all raw DTN packets and breadcrumbs in phone's encrypted SQLite storage (AES-GCM-256)."
            checked={Boolean(settings.saveMessagesLocally ?? settings.storeMessagesLocally)}
            onChange={(checked) =>
              onChange({ saveMessagesLocally: checked, storeMessagesLocally: checked })
            }
            icon={<HardDrive className="w-4 h-4 text-amber-600 dark:text-amber-400" />}
          />

          <SettingsToggleRow
            label="Auto-sync when online"
            description="Flush opportunistically to satellite / gateway uplink when connection detected."
            checked={Boolean(settings.autoSyncWhenOnline ?? settings.data_retention?.sync_to_cloud)}
            onChange={(checked) => {
              onChange({
                autoSyncWhenOnline: checked,
                data_retention: {
                  ...(settings.data_retention || {}),
                  telemetry_retention_days: retentionDays,
                  anonymize_civilians: Boolean(settings.allowAnonymousUsage),
                  sync_to_cloud: checked,
                },
              });
            }}
            icon={<RefreshCw className="w-4 h-4 text-cyan-600 dark:text-cyan-400" />}
          />
        </div>

        {/* Tactical DTN Hardware Parameters */}
        <div className="pt-3 border-t border-slate-100 dark:border-slate-800 grid grid-cols-1 sm:grid-cols-3 gap-3.5">
          <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <Share2 className="w-3.5 h-3.5 text-cyan-500" />
                DTN Max Hops (TTL)
              </span>
              <span className="text-xs font-mono font-bold text-cyan-600 dark:text-cyan-400 px-2 py-0.5 rounded bg-cyan-400/10">
                {mesh.max_hops ?? 7} hops
              </span>
            </div>
            <input
              type="range"
              min={3}
              max={15}
              value={mesh.max_hops ?? 7}
              onChange={(e) => updateMesh({ max_hops: Number(e.target.value) })}
              className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
            />
            <p className="text-[10px] text-slate-500 dark:text-slate-400">
              Packets expire after traversing {mesh.max_hops ?? 7} intermediate relay nodes.
            </p>
          </div>

          <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <Database className="w-3.5 h-3.5 text-amber-500" />
                DTN Flash Limit
              </span>
              <span className="text-xs font-mono font-bold text-amber-600 dark:text-amber-400 px-2 py-0.5 rounded bg-amber-400/10">
                {mesh.dtn_storage_limit_mb ?? 500} MB
              </span>
            </div>
            <input
              type="range"
              min={100}
              max={2000}
              step={50}
              value={mesh.dtn_storage_limit_mb ?? 500}
              onChange={(e) => updateMesh({ dtn_storage_limit_mb: Number(e.target.value) })}
              className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
            />
            <p className="text-[10px] text-slate-500 dark:text-slate-400">
              FIFO purge buffer threshold for cached multi-hop telemetry.
            </p>
          </div>

          <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-2 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <Satellite className="w-3.5 h-3.5 text-emerald-500" />
                Satellite Uplink Failover
              </span>
              <span
                className={`text-[10px] font-mono font-bold px-1.5 py-0.5 rounded ${
                  mesh.satellite_fallback
                    ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                    : 'bg-slate-200 dark:bg-slate-800 text-slate-400'
                }`}
              >
                {mesh.satellite_fallback ? 'ENABLED' : 'DISABLED'}
              </span>
            </div>
            <button
              type="button"
              onClick={() => updateMesh({ satellite_fallback: !mesh.satellite_fallback })}
              className="w-full py-1.5 px-3 rounded-lg text-xs font-semibold border border-slate-300 dark:border-slate-700 hover:border-amber-400 transition text-slate-800 dark:text-slate-200 text-center"
            >
              Toggle Satellite Failover
            </button>
            <p className="text-[10px] text-slate-500 dark:text-slate-400">
              Auto-forward critical SOS via Iridium / GSAT transponder when ground nodes fail.
            </p>
          </div>
        </div>
      </div>

      {/* 2. AI Assistant & Edge Intelligence */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-5">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-cyan-400/15 text-cyan-600 dark:text-cyan-400">
            <Cpu className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              AI Assistant &amp; On-Device Intelligence
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              On-device distilled model for triage recommendations and NDMA disaster response manuals.
            </p>
          </div>
        </div>

        <div className="space-y-1">
          <SettingsToggleRow
            label="Enable offline AI guidance"
            description="On-device distilled model for first-aid triage, distress classification, and safety instructions."
            checked={Boolean(settings.enableOfflineAiGuidance ?? ai.auto_clustering_enabled)}
            onChange={(checked) => updateAi({ auto_clustering_enabled: checked })}
            icon={<Cpu className="w-4 h-4 text-cyan-600 dark:text-cyan-400" />}
          />

          <SettingsToggleRow
            label="Use local knowledge base"
            description="Embed NDMA disaster SOPs and offline first aid protocols into on-device retrieval."
            checked={Boolean(settings.useLocalKnowledgeBase)}
            onChange={(checked) => onChange({ useLocalKnowledgeBase: checked })}
            icon={<BookOpen className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />}
            badge="NDMA SOPs"
          />
        </div>

        <div className="pt-3 border-t border-slate-100 dark:border-slate-800 p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
              <Sliders className="w-3.5 h-3.5 text-amber-500" />
              AI Automated Triage Confidence Threshold
            </span>
            <span className="text-xs font-mono font-bold text-amber-600 dark:text-amber-400 px-2 py-0.5 rounded bg-amber-400/10">
              {Math.round((ai.confidence_threshold ?? 0.88) * 100)}%
            </span>
          </div>
          <input
            type="range"
            min={0.5}
            max={0.99}
            step={0.01}
            value={ai.confidence_threshold ?? 0.88}
            onChange={(e) => updateAi({ confidence_threshold: parseFloat(e.target.value) })}
            className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
          />
          <div className="flex justify-between text-[10px] text-slate-400 font-mono mt-1">
            <span>50% (Permissive)</span>
            <span>Recommended: 85-90%</span>
            <span>99% (Strict)</span>
          </div>
        </div>
      </div>

      {/* 3. Data & Privacy */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-5">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-red-400/15 text-red-600 dark:text-red-400">
            <Calendar className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Data Lifecycle &amp; Privacy Preservation
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Audit log retention duration and civilian pseudonym rotation policies.
            </p>
          </div>
        </div>

        <div className="space-y-4">
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-3">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <span className="text-xs sm:text-sm font-bold text-slate-900 dark:text-white block">
                  Data Retention Policy (Days)
                </span>
                <span className="text-[11px] text-slate-500 dark:text-[#9FADC2]">
                  Auto-purge resolved distress logs, deduplication bloom filters, and telemetry breadcrumbs.
                </span>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  min={7}
                  max={365}
                  value={retentionDays}
                  onChange={(e) => {
                    const days = Number(e.target.value);
                    onChange({
                      dataRetentionDays: days,
                      data_retention: {
                        ...(settings.data_retention || {}),
                        telemetry_retention_days: days,
                        sync_to_cloud: Boolean(settings.autoSyncWhenOnline),
                        anonymize_civilians: Boolean(settings.allowAnonymousUsage),
                      },
                    });
                  }}
                  className="w-24 h-9 px-2 text-center rounded-xl bg-white dark:bg-[#162036] border border-slate-300 dark:border-slate-700 text-xs font-mono font-bold text-slate-900 dark:text-white focus:outline-none focus:border-amber-400"
                />
                <span className="text-xs text-slate-500 font-mono">days</span>
              </div>
            </div>

            {/* Quick Presets */}
            <div className="flex flex-wrap items-center gap-1.5 pt-1">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mr-1">
                Presets:
              </span>
              {retentionPresets.map((days) => (
                <button
                  key={days}
                  type="button"
                  onClick={() =>
                    onChange({
                      dataRetentionDays: days,
                      data_retention: {
                        ...(settings.data_retention || {}),
                        telemetry_retention_days: days,
                        sync_to_cloud: Boolean(settings.autoSyncWhenOnline),
                        anonymize_civilians: Boolean(settings.allowAnonymousUsage),
                      },
                    })
                  }
                  className={`px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold transition cursor-pointer ${
                    retentionDays === days
                      ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                      : 'bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:border-amber-400'
                  }`}
                >
                  {days}d
                </button>
              ))}
            </div>
          </div>

          <SettingsToggleRow
            label="Allow anonymous usage"
            description="Strip Personally Identifiable Information (PII) and transmit distress signals under rotating pseudonyms (e.g. SR-8F42)."
            checked={Boolean(settings.allowAnonymousUsage ?? settings.data_retention?.anonymize_civilians)}
            onChange={(checked) => {
              onChange({
                allowAnonymousUsage: checked,
                data_retention: {
                  ...(settings.data_retention || {}),
                  telemetry_retention_days: retentionDays,
                  sync_to_cloud: Boolean(settings.autoSyncWhenOnline),
                  anonymize_civilians: checked,
                },
              });
            }}
            icon={<EyeOff className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />}
            badge="Privacy Guard"
          />
        </div>
      </div>

      {/* 4. Theme & Power Mode */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm">
        <ThemeSwitcher
          currentTheme={settings.theme || 'dark'}
          onThemeChange={(t) => onChange({ theme: t })}
        />
      </div>
    </div>
  );
};

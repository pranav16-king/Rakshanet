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
} from 'lucide-react';

interface GeneralSettingsTabProps {
  settings: SystemSettings;
  onChange: (updated: Partial<SystemSettings>) => void;
}

export const GeneralSettingsTab: React.FC<GeneralSettingsTabProps> = ({
  settings,
  onChange,
}) => {
  return (
    <div className="space-y-6">
      {/* 1. System Settings */}
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-white">System Settings</h3>
          <p className="text-xs text-slate-400">
            Control baseline operational behaviors for disaster communication nodes.
          </p>
        </div>

        <div className="divide-y divide-slate-800">
          <SettingsToggleRow
            label="Allow new user registration"
            description="Permit incoming field responders and disaster survivors to register node handles."
            checked={settings.allowNewUserRegistration}
            onChange={(checked) => onChange({ allowNewUserRegistration: checked })}
            icon={<Users className="w-5 h-5" />}
          />

          <SettingsToggleRow
            label="Enable offline mesh network"
            description="Participate in multi-hop Bluetooth Low Energy (BLE) and Wi-Fi Direct store-and-forward mesh."
            checked={settings.enableOfflineMeshNetwork}
            onChange={(checked) => onChange({ enableOfflineMeshNetwork: checked })}
            icon={<Radio className="w-5 h-5 text-cyan-400" />}
          />

          <SettingsToggleRow
            label="Save messages locally"
            description="Persist all raw DTN packets and breadcrumbs into phone's encrypted SQLite storage."
            checked={Boolean(settings.saveMessagesLocally ?? settings.storeMessagesLocally)}
            onChange={(checked) => onChange({ saveMessagesLocally: checked, storeMessagesLocally: checked })}
            icon={<HardDrive className="w-5 h-5 text-amber-400" />}
          />

          <SettingsToggleRow
            label="Auto-sync when online"
            description="Opportunistically ingest queued packets when moving data mules connect to satellite or field cellular fringe."
            checked={Boolean(settings.autoSyncWhenOnline)}
            onChange={(checked) => onChange({ autoSyncWhenOnline: checked })}
            icon={<RefreshCw className="w-5 h-5 text-emerald-400" />}
          />
        </div>
      </div>

      {/* 2. AI Assistant Settings */}
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-white">AI Assistant Settings</h3>
          <p className="text-xs text-slate-400">
            Configure on-device and edge intelligence models for automated disaster guidance.
          </p>
        </div>

        <div className="divide-y divide-slate-800">
          <SettingsToggleRow
            label="Enable offline AI guidance"
            description="Provide on-device first-aid triaging, water purification steps, and distress assessment."
            checked={Boolean(settings.enableOfflineAiGuidance)}
            onChange={(checked) => onChange({ enableOfflineAiGuidance: checked })}
            icon={<Cpu className="w-5 h-5 text-purple-400" />}
          />

          <SettingsToggleRow
            label="Use local knowledge base"
            description="Query bundled offline disaster relief manuals and emergency evacuation protocols."
            checked={Boolean(settings.useLocalKnowledgeBase)}
            onChange={(checked) => onChange({ useLocalKnowledgeBase: checked })}
            icon={<BookOpen className="w-5 h-5 text-cyan-400" />}
          />
        </div>
      </div>

      {/* 3. Data & Privacy */}
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-white">Data &amp; Privacy</h3>
          <p className="text-xs text-slate-400">
            Telemetry lifecycle policies and privacy preservation thresholds.
          </p>
        </div>

        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 py-2 border-b border-slate-800 pb-4">
            <div className="flex items-center gap-3">
              <Calendar className="w-5 h-5 text-slate-400 flex-shrink-0" />
              <div>
                <div className="text-sm font-medium text-slate-100">Data retention (days)</div>
                <div className="text-xs text-slate-400">
                  Number of days before historical distress logs and deduplication blooms are pruned.
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="number"
                min={7}
                max={365}
                value={settings.dataRetentionDays ?? 90}
                onChange={(e) => onChange({ dataRetentionDays: Number(e.target.value) })}
                className="w-24 bg-[#0E1627] border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-center font-mono text-white focus:outline-none focus:border-amber-400"
              />
              <span className="text-xs text-slate-400">days</span>
            </div>
          </div>

          <SettingsToggleRow
            label="Allow anonymous usage"
            description="Transmit rescue beacon distress signals using rotating pseudonyms (e.g. SR-8F42) without revealing citizen identity."
            checked={Boolean(settings.allowAnonymousUsage)}
            onChange={(checked) => onChange({ allowAnonymousUsage: checked })}
            icon={<EyeOff className="w-5 h-5 text-emerald-400" />}
          />
        </div>
      </div>

      {/* 4. Theme & Power Mode */}
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm">
        <ThemeSwitcher
          currentTheme={settings.theme || 'dark'}
          onThemeChange={(t) => onChange({ theme: t })}
        />
      </div>
    </div>
  );
};

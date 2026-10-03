// src/components/settings/NotificationsSettingsTab.tsx
import React, { useState } from 'react';
import { SettingsToggleRow } from './SettingsToggleRow';
import { Bell, Volume2, Flame, Smartphone } from 'lucide-react';

export const NotificationsSettingsTab: React.FC = () => {
  const [criticalAudio, setCriticalAudio] = useState(true);
  const [flashVisuals, setFlashVisuals] = useState(true);
  const [blackHoleAlerts, setBlackHoleAlerts] = useState(true);
  const [pushRelayNotifications, setPushRelayNotifications] = useState(false);

  return (
    <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
      <div>
        <h3 className="text-base font-bold text-white">Emergency Dispatch Notifications</h3>
        <p className="text-xs text-slate-400">
          Audio-visual triggers for urgent disaster scenarios and communication loss events.
        </p>
      </div>

      <div className="divide-y divide-slate-800">
        <SettingsToggleRow
          label="Critical SOS Audible Alarm"
          description="Plays loud acoustic emergency beacon in Command Center upon receiving Life-Threatening SOS."
          checked={criticalAudio}
          onChange={setCriticalAudio}
          icon={<Volume2 className="w-5 h-5 text-red-400" />}
        />

        <SettingsToggleRow
          label="Visual High-Visibility Beacon Pulse"
          description="Flashes screen border in Signal Red (#D92D20) when unhandled critical tickets appear."
          checked={flashVisuals}
          onChange={setFlashVisuals}
          icon={<Flame className="w-5 h-5 text-amber-400" />}
        />

        <SettingsToggleRow
          label="Black Hole Anomaly Alert Sound"
          description="Alerts dispatchers whenever a sector suffers catastrophic >75% telemetry loss."
          checked={blackHoleAlerts}
          onChange={setBlackHoleAlerts}
          icon={<Bell className="w-5 h-5 text-purple-400" />}
        />

        <SettingsToggleRow
          label="Relay Mules Push Notifications"
          description="Notify field devices whenever their handset successfully delivers buffered packets to base."
          checked={pushRelayNotifications}
          onChange={setPushRelayNotifications}
          icon={<Smartphone className="w-5 h-5 text-cyan-400" />}
        />
      </div>
    </div>
  );
};

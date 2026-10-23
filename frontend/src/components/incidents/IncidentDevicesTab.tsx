import React from 'react';
import { Smartphone, Battery, BatteryCharging, Radio, Wifi, Signal } from 'lucide-react';
import type { IncidentDevice } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentDevicesTabProps {
  devices: IncidentDevice[];
}

export const IncidentDevicesTab: React.FC<IncidentDevicesTabProps> = ({ devices }) => {
  const { isDark } = useTheme();

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E2E8F0]'
      }`}
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h3
            className={`font-display font-bold text-lg ${
              isDark ? 'text-[#EEF2F8]' : 'text-[#0F172A]'
            }`}
          >
            Connected Mesh Devices ({devices.length} Handsets / Repeaters)
          </h3>
          <p className="text-xs opacity-70">
            Physical mobile units forming the peer-to-peer opportunistic DTN topology
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {devices.map((dev) => (
          <div
            key={dev.deviceId}
            className={`p-4 rounded-xl border transition-all ${
              isDark ? 'bg-[#0E1627] border-[#26344F]' : 'bg-white border-[#E2E8F0]'
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div
                  className={`p-1.5 rounded-lg ${
                    dev.deviceType === 'Solar Repeater'
                      ? 'bg-[#FFC400]/20 text-[#FFC400]'
                      : 'bg-[#0E8A94]/20 text-[#0E8A94]'
                  }`}
                >
                  <Smartphone size={16} />
                </div>
                <div>
                  <div className="font-mono font-bold text-xs">{dev.deviceId}</div>
                  <div className="text-[11px] opacity-70">{dev.ownerName}</div>
                </div>
              </div>

              <span
                className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase font-mono ${
                  dev.status === 'Online'
                    ? 'bg-[#0F3322] text-[#4CD08A]'
                    : dev.status === 'Relay'
                    ? 'bg-[#0F3037] text-[#3CC6D0]'
                    : 'bg-[#3A2508] text-[#FFA033]'
                }`}
              >
                {dev.status}
              </span>
            </div>

            <div className="mt-3 pt-3 border-t border-inherit/40 grid grid-cols-3 gap-2 text-[11px] font-mono">
              <div>
                <span className="opacity-60 block">Battery</span>
                <span
                  className={`font-bold flex items-center gap-1 ${
                    dev.batteryPct > 40 ? 'text-[#1E8E4E]' : 'text-[#D92D20]'
                  }`}
                >
                  <Battery size={12} />
                  {dev.batteryPct}%
                </span>
              </div>
              <div>
                <span className="opacity-60 block">Mesh Hops</span>
                <span className="font-bold text-[#FFC400]">{dev.hops} hops</span>
              </div>
              <div>
                <span className="opacity-60 block">RSSI</span>
                <span className="font-bold opacity-80">{dev.rssi} dBm</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

import React from 'react';
import { Link } from 'react-router-dom';
import type { MapLayersState, LiveDevice } from '../../types/map';
import { LiveDeviceItem } from './LiveDeviceItem';

export interface LiveMapLayersDrawerProps {
  layers: MapLayersState;
  onToggleLayer: (layerKey: keyof MapLayersState) => void;
  devices: LiveDevice[];
  selectedDevice?: LiveDevice | null;
  onSelectDevice: (device: LiveDevice) => void;
  totalDevicesCount?: number;
  className?: string;
}

export const LiveMapLayersDrawer: React.FC<LiveMapLayersDrawerProps> = ({
  layers,
  onToggleLayer,
  devices,
  selectedDevice,
  onSelectDevice,
  totalDevicesCount = 326,
  className = '',
}) => {
  const layerItems: Array<{
    key: keyof MapLayersState;
    label: string;
    dotColor: string;
  }> = [
    { key: 'users', label: 'Users', dotColor: 'bg-emerald-500' },
    { key: 'nearbyDevices', label: 'Nearby Devices', dotColor: 'bg-blue-500' },
    { key: 'incidents', label: 'Incidents', dotColor: 'bg-red-500' },
    { key: 'rescueTeams', label: 'Rescue Teams', dotColor: 'bg-teal-500' },
    { key: 'meshConnections', label: 'Mesh Connections', dotColor: 'bg-cyan-400' },
    { key: 'hazardZones', label: 'Hazard Zones', dotColor: 'bg-amber-500' },
  ];

  return (
    <aside
      className={`w-80 bg-white dark:bg-[#0B1220] border-l border-[#E2E8F0] dark:border-[#26344F] flex flex-col shrink-0 h-full overflow-hidden select-none z-10 ${className}`}
    >
      {/* Top Section: Map Layers */}
      <div className="p-4 border-b border-[#E2E8F0] dark:border-[#26344F]">
        <h3 className="text-sm font-bold text-[#0F172A] dark:text-[#EEF2F8] font-display mb-3">
          Map Layers
        </h3>

        <div className="space-y-2.5">
          {layerItems.map((item) => {
            const isChecked = layers[item.key];
            return (
              <div
                key={item.key}
                className="flex items-center justify-between py-0.5 text-xs font-medium text-[#0F172A] dark:text-[#EEF2F8]"
              >
                <div className="flex items-center gap-2.5">
                  <span className={`w-2.5 h-2.5 rounded-full ${item.dotColor} shadow-2xs`} />
                  <span>{item.label}</span>
                </div>

                {/* Accessible switch toggle button */}
                <button
                  type="button"
                  role="switch"
                  aria-checked={isChecked}
                  onClick={() => onToggleLayer(item.key)}
                  className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-[#FFC400] ${
                    isChecked ? 'bg-[#1E8E4E] dark:bg-[#4CD08A]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                      isChecked ? 'translate-x-4' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Section: Live Devices List */}
      <div className="flex-1 flex flex-col min-h-0 p-4">
        <div className="flex items-center justify-between mb-3 shrink-0">
          <h3 className="text-sm font-bold text-[#0F172A] dark:text-[#EEF2F8] font-display">
            Live Devices ({totalDevicesCount})
          </h3>
          <Link
            to="/app/devices"
            className="text-xs font-semibold text-[#0E8A94] dark:text-[#3CC6D0] hover:underline"
          >
            View All
          </Link>
        </div>

        <div className="flex-1 overflow-y-auto space-y-2 pr-1">
          {devices.map((device) => (
            <LiveDeviceItem
              key={device.id}
              device={device}
              isSelected={selectedDevice?.id === device.id}
              onSelect={onSelectDevice}
            />
          ))}
        </div>
      </div>
    </aside>
  );
};

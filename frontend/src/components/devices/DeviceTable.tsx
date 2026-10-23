import React, { useState } from 'react';
import { Radio, Search, Filter, RefreshCw, Zap, Tablet, Smartphone } from 'lucide-react';
import type { Device, DeviceType, DeviceStatus } from '../../types/devices';
import { StatusBadge } from '../common/StatusBadge';
import { BatteryBar } from '../common/BatteryBar';
import { devicesApi } from '../../api/devices';

interface DeviceTableProps {
  devices: Device[];
  typeFilter: string;
  onTypeFilterChange: (type: string) => void;
  statusFilter: string;
  onStatusFilterChange: (status: string) => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onRefresh?: () => void;
}

export const DeviceTable: React.FC<DeviceTableProps> = ({
  devices,
  typeFilter,
  onTypeFilterChange,
  statusFilter,
  onStatusFilterChange,
  searchQuery,
  onSearchChange,
  onRefresh,
}) => {
  const [pingingId, setPingingId] = useState<string | null>(null);
  const [pingResults, setPingResults] = useState<Record<string, number | null>>({});

  const handlePing = async (deviceId: string) => {
    setPingingId(deviceId);
    try {
      const res = await devicesApi.pingDevice(deviceId);
      setPingResults((prev) => ({ ...prev, [deviceId]: res.latencyMs }));
    } finally {
      setPingingId(null);
    }
  };

  const getStatusType = (status: DeviceStatus): 'online' | 'relay' | 'offline' => {
    switch (status) {
      case 'Online':
        return 'online';
      case 'Relay':
        return 'relay';
      case 'Offline':
      default:
        return 'offline';
    }
  };

  return (
    <div className="space-y-4">
      {/* Filter Bar matching media_1791015140209.jpg (bottom-center-left) */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 bg-white dark:bg-slate-900 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800">
        <div className="relative flex-1 max-w-sm">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Search by Device ID or User Name..."
            className="w-full pl-9 pr-4 py-1.5 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          {/* Type Dropdown */}
          <div className="flex items-center gap-1.5">
            <label className="text-xs text-slate-500 font-medium">Type:</label>
            <select
              value={typeFilter}
              onChange={(e) => onTypeFilterChange(e.target.value)}
              className="px-3 py-1.5 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            >
              <option value="All">All Types</option>
              <option value="Phone">Phone</option>
              <option value="Tablet">Tablet</option>
            </select>
          </div>

          {/* Status Dropdown */}
          <div className="flex items-center gap-1.5">
            <label className="text-xs text-slate-500 font-medium">Status:</label>
            <select
              value={statusFilter}
              onChange={(e) => onStatusFilterChange(e.target.value)}
              className="px-3 py-1.5 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            >
              <option value="All">All Status</option>
              <option value="Online">Online</option>
              <option value="Relay">Relay</option>
              <option value="Offline">Offline</option>
            </select>
          </div>

          {onRefresh && (
            <button
              type="button"
              onClick={onRefresh}
              className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
              title="Refresh Devices"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-xs">
        <table className="w-full text-left text-sm text-slate-700 dark:text-slate-200">
          <thead className="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
            <tr>
              <th scope="col" className="px-5 py-3.5">Device ID</th>
              <th scope="col" className="px-5 py-3.5">User Name</th>
              <th scope="col" className="px-5 py-3.5">Type</th>
              <th scope="col" className="px-5 py-3.5">Location</th>
              <th scope="col" className="px-5 py-3.5">Battery</th>
              <th scope="col" className="px-5 py-3.5">Status</th>
              <th scope="col" className="px-5 py-3.5 text-right">Mesh Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 font-normal">
            {devices.map((device) => {
              const pingTime = pingResults[device.id];
              const isPinging = pingingId === device.id;

              return (
                <tr
                  key={device.id}
                  className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors"
                >
                  {/* Device ID (monospace font) */}
                  <td className="px-5 py-3.5 whitespace-nowrap">
                    <div className="font-mono text-xs font-bold text-slate-900 dark:text-slate-100 flex items-center gap-1.5">
                      <Radio className="w-3.5 h-3.5 text-[#FFC400]" />
                      <span>{device.id}</span>
                    </div>
                  </td>

                  {/* User Name */}
                  <td className="px-5 py-3.5 whitespace-nowrap font-medium text-slate-900 dark:text-slate-100">
                    {device.userName}
                  </td>

                  {/* Type */}
                  <td className="px-5 py-3.5 whitespace-nowrap">
                    <span className="inline-flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                      {device.type === 'Tablet' ? (
                        <Tablet className="w-3.5 h-3.5 text-slate-400" />
                      ) : (
                        <Smartphone className="w-3.5 h-3.5 text-slate-400" />
                      )}
                      <span>{device.type}</span>
                    </span>
                  </td>

                  {/* Location */}
                  <td className="px-5 py-3.5 whitespace-nowrap text-slate-600 dark:text-slate-300 text-xs">
                    {device.location}
                  </td>

                  {/* Battery % bar */}
                  <td className="px-5 py-3.5 whitespace-nowrap">
                    {device.battery === undefined ? <span className="text-xs text-slate-500">Not reported</span> : <BatteryBar percent={device.battery} />}
                  </td>

                  {/* Status */}
                  <td className="px-5 py-3.5 whitespace-nowrap">
                    <StatusBadge
                      label={device.status}
                      type={getStatusType(device.status)}
                      dot
                    />
                  </td>

                  {/* Actions / Ping */}
                  <td className="px-5 py-3.5 whitespace-nowrap text-right">
                    <div className="inline-flex items-center gap-2">
                      {pingTime !== undefined && (
                        <span className="font-mono text-[11px] text-emerald-600 dark:text-emerald-400">
                          {pingTime}ms
                        </span>
                      )}
                      <button
                        type="button"
                        onClick={() => handlePing(device.id)}
                        disabled={isPinging || device.status === 'Offline'}
                        className={`inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-lg border transition-colors ${
                          device.status === 'Offline'
                            ? 'opacity-40 cursor-not-allowed border-slate-200 dark:border-slate-800'
                            : 'border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200'
                        }`}
                        title="Ping device over mesh network"
                      >
                        <Zap className={`w-3 h-3 ${isPinging ? 'animate-bounce text-[#FFC400]' : ''}`} />
                        <span>{isPinging ? 'Ping...' : 'Ping'}</span>
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DeviceTable;

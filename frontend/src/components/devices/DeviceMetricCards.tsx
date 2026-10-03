import React from 'react';
import { Smartphone, Wifi, Repeat, AlertCircle } from 'lucide-react';
import type { DeviceSummaryMetrics } from '../../types/devices';

interface DeviceMetricCardsProps {
  metrics: DeviceSummaryMetrics;
}

export const DeviceMetricCards: React.FC<DeviceMetricCardsProps> = ({ metrics }) => {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* 1. Total Devices */}
      <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider block mb-1">
            Total Devices
          </span>
          <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">
            {metrics.totalDevices}
          </div>
          <span className="text-[11px] text-slate-400 block mt-0.5">
            Registered on mesh
          </span>
        </div>
        <div className="w-11 h-11 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-700 dark:text-slate-300">
          <Smartphone className="w-5 h-5" />
        </div>
      </div>

      {/* 2. Online */}
      <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider block mb-1 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            Online
          </span>
          <div className="flex items-baseline gap-1.5">
            <span className="text-2xl font-bold text-slate-900 dark:text-slate-100">
              {metrics.onlineCount}
            </span>
            <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/50 px-1.5 py-0.5 rounded">
              {metrics.onlinePercent}%
            </span>
          </div>
          <span className="text-[11px] text-slate-400 block mt-0.5">
            Active heartbeats
          </span>
        </div>
        <div className="w-11 h-11 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200/60 dark:border-emerald-900/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
          <Wifi className="w-5 h-5" />
        </div>
      </div>

      {/* 3. Relay Devices */}
      <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-wider block mb-1 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
            Relay Devices
          </span>
          <div className="flex items-baseline gap-1.5">
            <span className="text-2xl font-bold text-slate-900 dark:text-slate-100">
              {metrics.relayCount}
            </span>
            <span className="text-xs font-semibold text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/50 px-1.5 py-0.5 rounded">
              {metrics.relayPercent}%
            </span>
          </div>
          <span className="text-[11px] text-slate-400 block mt-0.5">
            Forwarding packets
          </span>
        </div>
        <div className="w-11 h-11 rounded-xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200/60 dark:border-amber-900/40 flex items-center justify-center text-amber-600 dark:text-amber-400">
          <Repeat className="w-5 h-5" />
        </div>
      </div>

      {/* 4. Offline */}
      <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-red-600 dark:text-red-400 uppercase tracking-wider block mb-1 flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
            Offline
          </span>
          <div className="flex items-baseline gap-1.5">
            <span className="text-2xl font-bold text-slate-900 dark:text-slate-100">
              {metrics.offlineCount}
            </span>
            <span className="text-xs font-semibold text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-950/50 px-1.5 py-0.5 rounded">
              {metrics.offlinePercent}%
            </span>
          </div>
          <span className="text-[11px] text-slate-400 block mt-0.5">
            Signal lost / asleep
          </span>
        </div>
        <div className="w-11 h-11 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200/60 dark:border-red-900/40 flex items-center justify-center text-red-600 dark:text-red-400">
          <AlertCircle className="w-5 h-5" />
        </div>
      </div>
    </div>
  );
};

export default DeviceMetricCards;

// src/components/settings/HealthCheckStatus.tsx
import React, { useState, useEffect } from 'react';
import { settingsApi } from '../../api/settings';
import type { TelemetryStatsResponse } from '../../types';
import {
  Activity,
  RefreshCw,
  Radio,
  HardDrive,
  Database,
  Users,
  Server,
  CloudCheck,
} from 'lucide-react';

export const HealthCheckStatus: React.FC = () => {
  const [checking, setChecking] = useState<boolean>(false);
  const [apiOnline, setApiOnline] = useState<boolean>(true);
  const [latency, setLatency] = useState<number>(12);
  const [wsOnline, setWsOnline] = useState<boolean>(true);
  const [lastCheckTime, setLastCheckTime] = useState<string>('Just now');
  const [mongoStatus, setMongoStatus] = useState<string>('CONNECTED');
  const [stats, setStats] = useState<TelemetryStatsResponse | null>(null);

  const runHealthCheck = async () => {
    setChecking(true);
    try {
      const [res, telemetry] = await Promise.all([
        settingsApi.checkBackendHealth(),
        settingsApi.getTelemetryStats(),
      ]);
      setApiOnline(res.apiHealthy);
      setLatency(res.apiLatencyMs > 0 ? res.apiLatencyMs : 12);
      setWsOnline(res.wsHealthy);
      setMongoStatus(res.details?.mongo_atlas || (res.apiHealthy ? 'CONNECTED' : 'DISCONNECTED'));
      setLastCheckTime(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
      if (telemetry) {
        setStats(telemetry);
      }
    } finally {
      setChecking(false);
    }
  };

  useEffect(() => {
    runHealthCheck();
  }, []);

  return (
    <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-cyan-400/15 text-cyan-600 dark:text-cyan-400">
            <Activity className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Connection &amp; Infrastructure Health
            </h4>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Live diagnostic status for local SQLite ingestion gateway and cloud synchronization.
            </p>
          </div>
        </div>

        <button
          onClick={runHealthCheck}
          disabled={checking}
          className="self-start sm:self-auto flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:border-amber-400 transition cursor-pointer"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${checking ? 'animate-spin' : ''}`} />
          Ping Check
        </button>
      </div>

      {/* Primary Gateway & WebSocket Stream */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
        {/* Backend REST API */}
        <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 flex items-center justify-between">
          <div className="space-y-0.5">
            <div className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              FastAPI Opportunistic Gateway
            </div>
            <div className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${apiOnline ? 'bg-emerald-500' : 'bg-red-500'}`} />
              {apiOnline ? 'Online & Healthy' : 'Degraded / Unreachable'}
            </div>
            <div className="text-[10px] text-slate-400">Checked: {lastCheckTime}</div>
          </div>
          <div className="text-right">
            <span className="text-sm font-mono text-cyan-600 dark:text-cyan-400 font-bold block">
              {latency} ms
            </span>
            <span className="text-[10px] font-mono text-slate-400">Response Latency</span>
          </div>
        </div>

        {/* WebSocket Mesh Stream */}
        <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 flex items-center justify-between">
          <div className="space-y-0.5">
            <div className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Real-Time Mesh WebSocket (/ws/mesh)
            </div>
            <div className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${wsOnline ? 'bg-emerald-500 animate-pulse' : 'bg-red-500'}`} />
              {wsOnline ? 'Connected (Duplex)' : 'Disconnected'}
            </div>
            <div className="text-[10px] text-slate-400">Live Ingest Stream</div>
          </div>
          <div className="text-right">
            <span className="inline-flex items-center gap-1 text-xs font-mono font-bold text-emerald-600 dark:text-emerald-400 px-2 py-0.5 rounded bg-emerald-500/10">
              <Radio className="w-3.5 h-3.5 animate-pulse" /> LIVE STREAM
            </span>
          </div>
        </div>
      </div>

      {/* Real Live Database Storage Metrics */}
      {stats && (
        <div className="pt-2">
          <div className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
            Local SQLite Telemetry Vault Metrics
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
              <div className="text-[10px] font-bold text-slate-400 uppercase">Packets Ingested</div>
              <div className="text-lg font-mono font-black text-slate-900 dark:text-white mt-0.5">
                {stats.unique_packets_stored}
              </div>
              <div className="text-[10px] text-slate-500">Encrypted in SQLite</div>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
              <div className="text-[10px] font-bold text-slate-400 uppercase">Active SOS Beacons</div>
              <div className="text-lg font-mono font-black text-red-600 dark:text-red-400 mt-0.5">
                {stats.sos_beacons_count}
              </div>
              <div className="text-[10px] text-slate-500">Distress Pings</div>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
              <div className="text-[10px] font-bold text-slate-400 uppercase">Data Relay Mules</div>
              <div className="text-lg font-mono font-black text-cyan-600 dark:text-cyan-400 mt-0.5">
                {stats.active_mules}
              </div>
              <div className="text-[10px] text-slate-500">Mule Nodes Carrying</div>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
              <div className="text-[10px] font-bold text-slate-400 uppercase">Dashboard Sockets</div>
              <div className="text-lg font-mono font-black text-amber-600 dark:text-amber-400 mt-0.5">
                {stats.connected_dashboard_clients}
              </div>
              <div className="text-[10px] text-slate-500">Active Consoles</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

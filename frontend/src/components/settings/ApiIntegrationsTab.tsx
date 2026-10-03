// src/components/settings/ApiIntegrationsTab.tsx
import React, { useState } from 'react';
import { HealthCheckStatus } from './HealthCheckStatus';
import { Database, Radio, Globe, Shield } from 'lucide-react';

export const ApiIntegrationsTab: React.FC = () => {
  const [gatewayUrl, setGatewayUrl] = useState(
    import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'
  );
  const [wsUrl, setWsUrl] = useState('ws://localhost:8000/ws/mesh');

  return (
    <div className="space-y-6">
      <HealthCheckStatus />

      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-white">API &amp; Network Gateways</h3>
          <p className="text-xs text-slate-400">
            Configure ingress endpoints, MongoDB Atlas dual-persistence status, and CAD 112 forwarders.
          </p>
        </div>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-300 flex items-center gap-2">
              <Globe className="w-4 h-4 text-cyan-400" />
              FastAPI Gateway Base URL
            </label>
            <input
              type="text"
              value={gatewayUrl}
              onChange={(e) => setGatewayUrl(e.target.value)}
              className="w-full bg-[#0E1627] border border-slate-700 rounded-lg px-3.5 py-2 text-sm text-white font-mono focus:outline-none focus:border-amber-400"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-300 flex items-center gap-2">
              <Radio className="w-4 h-4 text-emerald-400" />
              WebSocket Mesh Real-Time Endpoint
            </label>
            <input
              type="text"
              value={wsUrl}
              onChange={(e) => setWsUrl(e.target.value)}
              className="w-full bg-[#0E1627] border border-slate-700 rounded-lg px-3.5 py-2 text-sm text-white font-mono focus:outline-none focus:border-amber-400"
            />
          </div>

          <div className="p-4 rounded-lg bg-[#0E1627] border border-slate-800 space-y-2">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-200">
              <Database className="w-4 h-4 text-amber-400" />
              Dual-Persistence Architecture Status
            </div>
            <div className="text-xs text-slate-400 leading-relaxed">
              • <strong>Primary Transactional Store:</strong> Local SQLite (`gateway_telemetry.db`) — 100% offline availability.<br />
              • <strong>Cloud Archive Store:</strong> MongoDB Atlas Cluster (`rakshanet_command_center`) — automatic dual-write with fallback buffer.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

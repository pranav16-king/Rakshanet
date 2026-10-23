// src/components/settings/ApiIntegrationsTab.tsx
import React, { useState } from 'react';
import { HealthCheckStatus } from './HealthCheckStatus';
import {
  Database,
  Radio,
  Globe,
  FileCode,
  Copy,
  Check,
  ExternalLink,
  Layers,
  Cpu,
  Share2,
} from 'lucide-react';

export const ApiIntegrationsTab: React.FC = () => {
  const [copiedKey, setCopiedKey] = useState<string | null>(null);
  const [gatewayUrl, setGatewayUrl] = useState<string>(
    import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'
  );
  const [wsUrl, setWsUrl] = useState<string>('ws://localhost:8000/ws/mesh');

  const copyToClipboard = (key: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => {
      setCopiedKey(null);
    }, 2000);
  };

  const interopFeeds = [
    {
      id: 'cap_xml',
      title: 'OASIS CAP v1.2 XML Alert Feed',
      description: 'Standard XML feed ingested by national disaster management bodies (NDMA, SACHET, SDMA, CAP-AU). Auto-clusters active distress beacons.',
      endpoint: `${gatewayUrl}/api/v1/interop/cap/feed.xml`,
      badge: 'NDMA / SACHET 1.2',
      badgeColor: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
      method: 'GET',
      format: 'XML (application/xml)',
    },
    {
      id: 'cad_json',
      title: 'CAD 112 / ERSS Incident Dispatch Feed',
      description: 'REST JSON feed compatible with legacy Computer-Aided Dispatch (CAD 112 / ERSS) dispatch engines. Includes geofence radii & casualty triage.',
      endpoint: `${gatewayUrl}/api/v1/interop/cad/incidents`,
      badge: 'POLICE & FIRE 112',
      badgeColor: 'bg-cyan-500/15 text-cyan-400 border-cyan-500/30',
      method: 'GET',
      format: 'JSON (application/json)',
    },
    {
      id: 'telemetry_sync',
      title: 'Opportunistic Telemetry Ingress',
      description: 'Batch sync endpoint used by field rescue mules and DTN relay nodes to upload store-and-forward BLE/Wi-Fi Direct packets upon link recovery.',
      endpoint: `${gatewayUrl}/api/v1/telemetry/sync`,
      badge: 'DTN STORE-AND-FORWARD',
      badgeColor: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
      method: 'POST',
      format: 'SyncBatchRequest (JSON)',
    },
    {
      id: 'qdrant_faces',
      title: 'AI Facial Embedding Search (Qdrant & SFace)',
      description: 'Vector similarity search endpoint matching field-captured victim photos against NDMA missing person facial biometric embeddings.',
      endpoint: `${gatewayUrl}/api/v1/missing-persons/search-by-photo`,
      badge: 'BIOMETRIC AI COSSIM',
      badgeColor: 'bg-sky-500/15 text-sky-400 border-sky-500/30',
      method: 'POST',
      format: 'Multipart/form-data (JPEG/PNG)',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Infrastructure & Connection Health Check */}
      <HealthCheckStatus />

      {/* Gateway Configuration & Endpoints */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider flex items-center gap-2">
              <Globe className="w-5 h-5 text-cyan-600 dark:text-cyan-400" />
              API &amp; Real-Time Ingress Configuration
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Configured REST endpoints, WebSocket streaming channels, and interactive OpenAPI documentation.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <a
              href={`${gatewayUrl}/docs`}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:border-amber-400 transition"
            >
              <FileCode className="w-3.5 h-3.5 text-amber-500" />
              OpenAPI (Swagger)
              <ExternalLink className="w-3 h-3 text-slate-400" />
            </a>
            <a
              href={`${gatewayUrl}/redoc`}
              target="_blank"
              rel="noreferrer"
              className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:border-cyan-400 transition"
            >
              <Layers className="w-3.5 h-3.5 text-cyan-500" />
              ReDoc Spec
              <ExternalLink className="w-3 h-3 text-slate-400" />
            </a>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300 flex items-center justify-between">
              <span className="flex items-center gap-2">
                <Globe className="w-4 h-4 text-cyan-500" />
                FastAPI Gateway Base URL
              </span>
              <button
                type="button"
                onClick={() => copyToClipboard('gateway', gatewayUrl)}
                className="text-[11px] text-cyan-600 dark:text-cyan-400 hover:underline flex items-center gap-1"
              >
                {copiedKey === 'gateway' ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
                {copiedKey === 'gateway' ? 'Copied' : 'Copy'}
              </button>
            </label>
            <input
              type="text"
              value={gatewayUrl}
              onChange={(e) => setGatewayUrl(e.target.value)}
              className="w-full bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs text-slate-900 dark:text-white font-mono focus:outline-none focus:border-amber-400"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300 flex items-center justify-between">
              <span className="flex items-center gap-2">
                <Radio className="w-4 h-4 text-emerald-500" />
                Mesh WebSocket Real-Time Channel
              </span>
              <button
                type="button"
                onClick={() => copyToClipboard('ws', wsUrl)}
                className="text-[11px] text-cyan-600 dark:text-cyan-400 hover:underline flex items-center gap-1"
              >
                {copiedKey === 'ws' ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
                {copiedKey === 'ws' ? 'Copied' : 'Copy'}
              </button>
            </label>
            <input
              type="text"
              value={wsUrl}
              onChange={(e) => setWsUrl(e.target.value)}
              className="w-full bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 text-xs text-slate-900 dark:text-white font-mono focus:outline-none focus:border-amber-400"
            />
          </div>
        </div>

        {/* Dual Persistence Architecture Card */}
        <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-800 space-y-2.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-900 dark:text-slate-200">
              <Database className="w-4 h-4 text-amber-500" />
              Dual-Persistence Architecture &amp; Vector Index
            </div>
            <span className="inline-flex items-center gap-1 text-[10px] font-mono font-bold text-emerald-600 dark:text-emerald-400 px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20">
              SQLITE + MONGODB DUAL-WRITE
            </span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-1 text-xs text-slate-600 dark:text-slate-400">
            <div className="p-3 rounded-lg bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
              <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Primary Storage (SQLite)</span>
              <code className="text-[11px] font-mono text-cyan-600 dark:text-cyan-400">gateway_telemetry.db</code>
              <p className="text-[11px] text-slate-500 mt-1">Zero-latency zero-dependency offline local store on physical gateway.</p>
            </div>
            <div className="p-3 rounded-lg bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
              <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Cloud Mirror (Mongo Atlas)</span>
              <code className="text-[11px] font-mono text-emerald-600 dark:text-emerald-400">rakshanet_command_center</code>
              <p className="text-[11px] text-slate-500 mt-1">Auto-syncs via background worker whenever upstream WAN/satellite recovers.</p>
            </div>
            <div className="p-3 rounded-lg bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
              <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Biometrics (Qdrant &amp; SFace)</span>
              <code className="text-[11px] font-mono text-amber-600 dark:text-amber-400">128-dim Cosine Index</code>
              <p className="text-[11px] text-slate-500 mt-1">High-speed cosine vector matching for missing persons face recognition.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Interoperability Feeds & Emergency Standards */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div>
          <h3 className="text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider flex items-center gap-2">
            <Share2 className="w-5 h-5 text-amber-500" />
            Disaster Authority Interoperability Feeds (Live)
          </h3>
          <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
            Standardized machine-to-machine endpoints providing live feeds to NDMA SACHET, NDRF, SDMA, and police dispatch desks.
          </p>
        </div>

        <div className="space-y-3.5">
          {interopFeeds.map((feed) => (
            <div
              key={feed.id}
              className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700 transition"
            >
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                    {feed.method}
                  </span>
                  <span className="text-sm font-bold text-slate-900 dark:text-white">
                    {feed.title}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded-full border ${feed.badgeColor}`}
                  >
                    {feed.badge}
                  </span>
                  <span className="text-[11px] font-mono text-slate-400">
                    {feed.format}
                  </span>
                </div>
              </div>

              <p className="text-xs text-slate-500 dark:text-slate-400 mb-3">
                {feed.description}
              </p>

              <div className="flex items-center justify-between gap-3 p-2 rounded-lg bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
                <code className="text-xs font-mono text-cyan-600 dark:text-cyan-400 truncate select-all">
                  {feed.endpoint}
                </code>
                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    type="button"
                    onClick={() => copyToClipboard(feed.id, feed.endpoint)}
                    className="flex items-center gap-1 px-2.5 py-1 rounded-md bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-xs font-semibold text-slate-700 dark:text-slate-200 transition cursor-pointer"
                  >
                    {copiedKey === feed.id ? (
                      <>
                        <Check className="w-3 h-3 text-emerald-500" />
                        <span className="text-emerald-500">Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3 h-3 text-slate-400" />
                        <span>Copy URL</span>
                      </>
                    )}
                  </button>
                  {feed.method === 'GET' && (
                    <a
                      href={feed.endpoint}
                      target="_blank"
                      rel="noreferrer"
                      className="flex items-center gap-1 px-2.5 py-1 rounded-md bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-400 hover:bg-cyan-100 dark:hover:bg-cyan-900/40 text-xs font-semibold transition"
                    >
                      <ExternalLink className="w-3 h-3" />
                      Open
                    </a>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

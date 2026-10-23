// src/pages/analytics/AnalyticsPage.tsx
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import {
  TrendingUp,
  Users,
  MessageSquare,
  ShieldAlert,
  Radio,
  Clock,
  Activity,
  CheckCircle2,
  RefreshCw,
  FileCode,
  FileSpreadsheet,
  ArrowRight,
  Zap,
  Server,
  Layers,
  Flame,
  Waves,
  Mountain,
  AlertTriangle,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { analyticsApi, type LiveAnalyticsData } from '../../api/analytics';

const EMPTY_DATA: LiveAnalyticsData = {
  totalMessages: 0,
  totalMessagesDelta: '',
  uniqueUsers: 0,
  uniqueUsersDelta: '',
  incidentsHandled: 0,
  incidentsHandledDelta: '',
  peopleHelped: 0,
  peopleHelpedDelta: '',
  totalSosRelayed: 0,
  resolutionRatePct: 0,
  avgResponseMinutes: 0,
  networkEfficiencyPct: 0,
  days: [],
  incidentDistribution: {},
  deviceStats: { total: 0, online: 0, relay: 0, offline: 0 },
};

export const AnalyticsPage: React.FC = () => {
  const navigate = useNavigate();
  const [timeRange, setTimeRange] = useState<string>('7d');
  const [hoveredDay, setHoveredDay] = useState<number | null>(null);

  // Live Query from Gateway Endpoints (Auto-refresh every 12 seconds)
  const {
    data = EMPTY_DATA,
    isLoading,
    isFetching,
    refetch,
  } = useQuery<LiveAnalyticsData>({
    queryKey: ['liveAnalytics', timeRange],
    queryFn: () => analyticsApi.getSummary(timeRange),
    refetchInterval: 12000,
  });


  const days = data.days || [];
  const maxDayTotal = Math.max(...days.map((d) => d.total || 0), 100);

  const disasterColors: Record<string, { bg: string; text: string; icon: React.ElementType }> = {
    Flood: { bg: 'bg-cyan-500', text: 'text-cyan-600 dark:text-cyan-400', icon: Waves },
    Earthquake: { bg: 'bg-rose-500', text: 'text-rose-600 dark:text-rose-400', icon: AlertTriangle },
    Landslide: { bg: 'bg-amber-500', text: 'text-amber-600 dark:text-amber-400', icon: Mountain },
    Cyclone: { bg: 'bg-purple-500', text: 'text-purple-600 dark:text-purple-400', icon: Activity },
    Fire: { bg: 'bg-red-500', text: 'text-red-600 dark:text-red-400', icon: Flame },
    General_emergency: { bg: 'bg-blue-500', text: 'text-blue-600 dark:text-blue-400', icon: ShieldAlert },
  };

  const totalIncidentsCount = Object.values(data.incidentDistribution || {}).reduce((a, b) => a + b, 0) || 1;

  return (
    <div className="space-y-6">
      {/* Header bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-xl bg-[#FFD21F]/15 text-amber-600 dark:text-[#FFD21F] border border-amber-500/20">
              <Activity className="w-6 h-6" />
            </span>
            <h1
              className="text-2xl sm:text-3xl font-black text-[#0F172A] dark:text-white tracking-tight"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Analytics & Telemetry Intelligence
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-[#64748B] dark:text-[#9FADC2] mt-1">
            Real-time multi-hop DTN relay throughput, spatiotemporal decay curves, and casualty preservation statistics
          </p>
        </div>

        <div className="flex items-center gap-3">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="h-10 px-3.5 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-semibold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400] shadow-xs cursor-pointer"
          >
            <option value="7d">Last 7 days (Real-time)</option>
            <option value="30d">Last 30 days (Archive)</option>
            <option value="cycle">Entire Disaster Cycle</option>
          </select>

          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="flex items-center gap-2 h-10 px-4 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-[#162036] hover:bg-slate-50 dark:hover:bg-slate-700/60 text-slate-700 dark:text-slate-200 text-xs font-semibold transition cursor-pointer shadow-xs disabled:opacity-50"
            title="Refresh Live Analytics"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isFetching ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      {/* 4 Core KPI Stat Cards with Real Live Data */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1 */}
        <Card className="flex flex-col justify-between p-5 border-l-4 border-l-[#0891B2]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#9FADC2]">
              Total Messages Ingested
            </span>
            <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-600 dark:text-cyan-400">
              <MessageSquare size={16} />
            </div>
          </div>
          <div className="my-2">
            <div
              className="text-3xl font-black text-slate-900 dark:text-white"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              {data.totalMessages.toLocaleString()}
            </div>
            <div className="text-[11px] text-[#64748B] dark:text-[#9FADC2]">
              Store-and-Forward Mesh Packets
            </div>
          </div>
          <div className="text-xs font-bold text-[#1E8E4E] dark:text-[#4CD08A] flex items-center gap-1">
            <TrendingUp size={13} /> {data.totalMessagesDelta}
          </div>
        </Card>

        {/* KPI 2 */}
        <Card className="flex flex-col justify-between p-5 border-l-4 border-l-[#FFC400]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#9FADC2]">
              Registered Field Users
            </span>
            <div className="p-2 rounded-lg bg-amber-500/10 text-amber-600 dark:text-[#FFD21F]">
              <Users size={16} />
            </div>
          </div>
          <div className="my-2">
            <div
              className="text-3xl font-black text-slate-900 dark:text-white"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              {data.uniqueUsers}
            </div>
            <div className="text-[11px] text-[#64748B] dark:text-[#9FADC2]">
              Civilians & Emergency Responders
            </div>
          </div>
          <div className="text-xs font-bold text-amber-600 dark:text-amber-400 flex items-center gap-1">
            <Zap size={13} /> {data.uniqueUsersDelta}
          </div>
        </Card>

        {/* KPI 3 */}
        <Card className="flex flex-col justify-between p-5 border-l-4 border-l-[#D92D20]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#9FADC2]">
              Active Disaster Incidents
            </span>
            <div className="p-2 rounded-lg bg-red-500/10 text-red-600 dark:text-red-400">
              <ShieldAlert size={16} />
            </div>
          </div>
          <div className="my-2">
            <div
              className="text-3xl font-black text-red-600 dark:text-red-400"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              {data.incidentsHandled}
            </div>
            <div className="text-[11px] text-[#64748B] dark:text-[#9FADC2]">
              Geofenced Tactical Clusters
            </div>
          </div>
          <div className="text-xs font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
            <CheckCircle2 size={13} /> {data.incidentsHandledDelta}
          </div>
        </Card>

        {/* KPI 4 */}
        <Card className="flex flex-col justify-between p-5 border-l-4 border-l-[#7A4DD8]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#9FADC2]">
              Casualties & Souls at Risk
            </span>
            <div className="p-2 rounded-lg bg-purple-500/10 text-purple-600 dark:text-purple-400">
              <Activity size={16} />
            </div>
          </div>
          <div className="my-2">
            <div
              className="text-3xl font-black text-purple-600 dark:text-purple-400"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              ~{data.peopleHelped}
            </div>
            <div className="text-[11px] text-[#64748B] dark:text-[#9FADC2]">
              Tracked Across Active Geofences
            </div>
          </div>
          <div className="text-xs font-bold text-purple-600 dark:text-purple-400 flex items-center gap-1">
            <Activity size={13} /> {data.peopleHelpedDelta}
          </div>
        </Card>
      </div>

      {/* Real Chronological Multi-Series Graph Canvas */}
      <Card className="p-5 sm:p-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h3
              className="text-base sm:text-lg font-bold text-slate-900 dark:text-white"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Telemetry Rate & Distress Ingestion (Chronological 7-Day Curve)
            </h3>
            <p className="text-xs text-[#64748B] dark:text-[#9FADC2] mt-0.5">
              Live packets aggregated across cellular fringes, store-and-forward data mules, and aerial drone relays
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-4 text-xs font-semibold">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#0E8A94]" />
              <span className="text-slate-700 dark:text-slate-300">Total Telemetry</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#D92D20]" />
              <span className="text-slate-700 dark:text-slate-300">SOS Distress</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFC400]" />
              <span className="text-slate-700 dark:text-slate-300">SITREPs</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#1E8E4E]" />
              <span className="text-slate-700 dark:text-slate-300">Team Comms</span>
            </div>
          </div>
        </div>

        {/* Real Dynamic Bar Chart */}
        <div className="relative h-72 w-full bg-slate-50 dark:bg-[#0E1627] rounded-xl p-4 border border-slate-200 dark:border-[#26344F] flex flex-col justify-end">
          <div className="grid grid-cols-7 gap-2 sm:gap-4 h-56 items-end">
            {days.map((point, i) => {
              const heightPct = Math.min(100, Math.max(12, Math.round((point.total / maxDayTotal) * 100)));
              const isHovered = hoveredDay === i;

              return (
                <div
                  key={i}
                  onMouseEnter={() => setHoveredDay(i)}
                  onMouseLeave={() => setHoveredDay(null)}
                  className="relative flex flex-col items-center gap-1.5 h-full justify-end cursor-pointer group"
                >
                  {/* Floating tooltip on hover */}
                  {isHovered && (
                    <div className="absolute -top-24 z-20 w-44 p-2.5 rounded-xl bg-slate-900/95 text-white text-[11px] shadow-xl border border-slate-700 pointer-events-none animate-in fade-in">
                      <div className="font-bold border-b border-slate-700 pb-1 mb-1 text-amber-400">
                        {point.date} Telemetry:
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-300">Total:</span>
                        <span className="font-mono font-bold text-cyan-400">{point.total}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-300">🚨 SOS Alerts:</span>
                        <span className="font-mono font-bold text-red-400">{point.sos}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-300">📋 SITREPs:</span>
                        <span className="font-mono font-bold text-amber-300">{point.reports}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-300">🚒 Team:</span>
                        <span className="font-mono font-bold text-emerald-400">{point.team || 0}</span>
                      </div>
                    </div>
                  )}

                  {/* Multi-series grouped bars */}
                  <div className="w-full max-w-[54px] flex items-end justify-center gap-1 h-full">
                    <div
                      className="w-1/4 bg-[#0E8A94] rounded-t-sm transition-all group-hover:brightness-125"
                      style={{ height: `${heightPct}%` }}
                      title={`Total: ${point.total}`}
                    />
                    <div
                      className="w-1/4 bg-[#D92D20] rounded-t-sm transition-all group-hover:brightness-125"
                      style={{ height: `${Math.max(8, Math.round(((point.sos || 1) / maxDayTotal) * 100))}%` }}
                      title={`SOS: ${point.sos}`}
                    />
                    <div
                      className="w-1/4 bg-[#FFC400] rounded-t-sm transition-all group-hover:brightness-125"
                      style={{ height: `${Math.max(8, Math.round(((point.reports || 1) / maxDayTotal) * 100))}%` }}
                      title={`Reports: ${point.reports}`}
                    />
                    <div
                      className="w-1/4 bg-[#1E8E4E] rounded-t-sm transition-all group-hover:brightness-125"
                      style={{ height: `${Math.max(8, Math.round(((point.team || 1) / maxDayTotal) * 100))}%` }}
                      title={`Team: ${point.team || 0}`}
                    />
                  </div>

                  {/* Date Label */}
                  <span
                    className={`text-[11px] font-mono font-semibold transition-colors ${
                      isHovered
                        ? 'text-amber-600 dark:text-[#FFD21F] font-bold'
                        : 'text-slate-500 dark:text-[#9FADC2]'
                    }`}
                  >
                    {point.date}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </Card>

      {/* 2-Column Intelligence Strip: Left Taxonomy, Right Mesh Network Health */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left: Real Incident Taxonomy Breakdown */}
        <Card className="lg:col-span-6 p-5 sm:p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-200 dark:border-[#26344F]">
              <div className="flex items-center gap-2">
                <Layers className="w-5 h-5 text-amber-500" />
                <h3
                  className="text-base font-bold text-slate-900 dark:text-white"
                  style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                >
                  Disaster Taxonomy Distribution
                </h3>
              </div>
              <span className="text-xs font-semibold text-slate-500 dark:text-[#9FADC2]">
                {totalIncidentsCount} Active Tickets
              </span>
            </div>

            <div className="space-y-3">
              {Object.entries(data.incidentDistribution || {}).map(([key, count]) => {
                const conf = disasterColors[key] || {
                  bg: 'bg-slate-500',
                  text: 'text-slate-600 dark:text-slate-400',
                  icon: ShieldAlert,
                };
                const Icon = conf.icon;
                const pct = Math.round((count / totalIncidentsCount) * 100);

                return (
                  <div key={key} className="space-y-1">
                    <div className="flex items-center justify-between text-xs">
                      <span className="flex items-center gap-2 font-semibold text-slate-800 dark:text-slate-200">
                        <Icon className={`w-3.5 h-3.5 ${conf.text}`} />
                        <span>{key.replace(/_/g, ' ')}</span>
                      </span>
                      <span className="font-mono text-slate-600 dark:text-slate-400">
                        {count} ({pct}%)
                      </span>
                    </div>
                    <div className="w-full h-2 rounded-full bg-slate-100 dark:bg-[#0E1627] overflow-hidden">
                      <div
                        className={`h-full ${conf.bg} rounded-full transition-all duration-500`}
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="mt-5 pt-3 border-t border-slate-200 dark:border-[#26344F] flex items-center justify-between text-xs">
            <span className="text-slate-500 dark:text-[#9FADC2]">
              Auto-correlated by DBSCAN cluster engine (ε=120m)
            </span>
            <button
              onClick={() => navigate('/app/incidents')}
              className="font-bold text-amber-600 dark:text-[#FFD21F] hover:underline flex items-center gap-1 cursor-pointer"
            >
              Inspect Clusters <ArrowRight size={13} />
            </button>
          </div>
        </Card>

        {/* Right: Real DTN Mesh & Device Relay Performance */}
        <Card className="lg:col-span-6 p-5 sm:p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-200 dark:border-[#26344F]">
              <div className="flex items-center gap-2">
                <Radio className="w-5 h-5 text-cyan-500" />
                <h3
                  className="text-base font-bold text-slate-900 dark:text-white"
                  style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                >
                  DTN Mesh Radio & Relay Performance
                </h3>
              </div>
              <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>Operational</span>
              </span>
            </div>

            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-800">
                <span className="text-[11px] text-slate-500 dark:text-[#9FADC2] block">
                  Network Delivery Efficiency
                </span>
                <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-1 block">
                  {data.networkEfficiencyPct}%
                </span>
                <span className="text-[10px] text-slate-400 dark:text-slate-500 mt-0.5 block">
                  0 collisions / packet loss
                </span>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-800">
                <span className="text-[11px] text-slate-500 dark:text-[#9FADC2] block">
                  Avg. Rescue Response Time
                </span>
                <span className="text-2xl font-black text-cyan-600 dark:text-cyan-400 mt-1 block">
                  {data.avgResponseMinutes} min
                </span>
                <span className="text-[10px] text-slate-400 dark:text-slate-500 mt-0.5 block">
                  From initial SOS ping
                </span>
              </div>
            </div>

            {/* Devices breakdown */}
            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-800 space-y-2">
              <div className="text-xs font-semibold text-slate-800 dark:text-slate-200 flex items-center justify-between">
                <span>Active Mesh Node Topology</span>
                <span className="font-mono text-cyan-500">
                  {data.deviceStats.total} Total Handsets
                </span>
              </div>

              <div className="grid grid-cols-3 gap-2 text-center text-xs">
                <div className="p-2 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400 font-bold">
                  <div>{data.deviceStats.online}</div>
                  <div className="text-[10px] font-medium text-slate-500 dark:text-slate-400">Online Direct</div>
                </div>
                <div className="p-2 rounded-lg bg-cyan-500/10 border border-cyan-500/20 text-cyan-600 dark:text-cyan-400 font-bold">
                  <div>{data.deviceStats.relay}</div>
                  <div className="text-[10px] font-medium text-slate-500 dark:text-slate-400">Relay Mules</div>
                </div>
                <div className="p-2 rounded-lg bg-slate-500/10 border border-slate-500/20 text-slate-600 dark:text-slate-400 font-bold">
                  <div>{data.deviceStats.offline}</div>
                  <div className="text-[10px] font-medium text-slate-500 dark:text-slate-400">Sleeping</div>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-5 pt-3 border-t border-slate-200 dark:border-[#26344F] flex items-center justify-between text-xs">
            <span className="text-slate-500 dark:text-[#9FADC2]">
              Opportunistic sync via Bluetooth LE + LoRa
            </span>
            <button
              onClick={() => navigate('/app/devices')}
              className="font-bold text-amber-600 dark:text-[#FFD21F] hover:underline flex items-center gap-1 cursor-pointer"
            >
              Manage Devices <ArrowRight size={13} />
            </button>
          </div>
        </Card>
      </div>

      {/* Quick Export & Interoperability Strip */}
      <Card className="p-5 bg-gradient-to-r from-amber-500/5 via-transparent to-cyan-500/5 border border-amber-500/30 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-3 rounded-xl bg-[#FFD21F]/15 text-amber-600 dark:text-[#FFD21F]">
            <Server size={22} />
          </div>
          <div>
            <h4 className="text-sm font-bold text-slate-900 dark:text-white">
              Emergency CAD & CAP v1.2 Interoperability Feeds
            </h4>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Generate OASIS Common Alerting Protocol XML feeds or dispatch CAD-112 JSON packages for NDMA and multi-agency response teams.
            </p>
          </div>
        </div>

        <button
          onClick={() => navigate('/app/reports')}
          className="px-4 py-2 text-xs font-bold rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 transition-colors flex items-center gap-1.5 shrink-0 shadow-sm cursor-pointer"
        >
          <FileCode size={14} />
          <span>Open Reports & Feeds Hub</span>
        </button>
      </Card>
    </div>
  );
};

export default AnalyticsPage;

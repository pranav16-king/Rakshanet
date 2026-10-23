import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Users,
  AlertOctagon,
  Radio,
  Share2,
  RefreshCw,
  Calendar,
  Activity,
} from 'lucide-react';
import { fetchDashboardOverview } from '../../api/dashboard';
import { KpiCard } from '../../components/common/KpiCard';
import { IncidentDistributionChart } from '../../components/overview/IncidentDistributionChart';
import { RecentIncidentsCard } from '../../components/overview/RecentIncidentsCard';

export const DashboardPage: React.FC = () => {
  const [timeRange, setTimeRange] = useState<string>('24h');

  // TanStack Query: Real-time 15s polling from /api/v1/dashboard/overview
  const {
    data,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: ['dashboardOverview', timeRange],
    queryFn: () => fetchDashboardOverview(timeRange),
    refetchInterval: 15000,
  });

  const kpis = data?.kpis;
  const distribution = data?.incidentDistribution;
  const recentIncidents = data?.recentIncidents || [];

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1
              className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white tracking-tight"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Command Center Dashboard
            </h1>
            <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-500/30 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Live Mesh Active</span>
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-[#9FADC2] mt-0.5">
            Real-time disaster telemetry, DBSCAN spatiotemporal incident clusters & mesh throughput
          </p>
        </div>

        {/* Header Controls */}
        <div className="flex items-center gap-2.5">
          {/* Manual Refresh */}
          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="p-2 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-600 dark:text-[#9FADC2] hover:text-slate-900 dark:hover:text-white hover:border-slate-300 dark:hover:border-[#3A4C70] transition-colors cursor-pointer shadow-2xs disabled:opacity-60"
            title="Refresh dashboard telemetry"
          >
            <RefreshCw size={15} className={isFetching ? 'animate-spin text-amber-500' : ''} />
          </button>

          {/* Time Range Select */}
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400 dark:text-[#9FADC2]">
              <Calendar size={14} />
            </div>
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              className="h-9 pl-8 pr-4 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-bold text-slate-900 dark:text-[#EEF2F8] hover:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400 cursor-pointer shadow-2xs transition-colors"
            >
              <option value="24h">Last 24 hours</option>
              <option value="7d">Last 7 days</option>
              <option value="all">All-Time Event</option>
            </select>
          </div>
        </div>
      </div>

      {/* 4 KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Total Active Users */}
        <KpiCard
          title="Total Active Users"
          value={kpis ? kpis.totalActiveUsers.count : 0}
          deltaYesterdayPct={kpis?.totalActiveUsers.deltaYesterdayPct}
          icon={Users}
          accentColor="teal"
          isLoading={isLoading}
        />

        {/* KPI 2: Active Incidents */}
        <KpiCard
          title="Active Incidents"
          value={kpis ? kpis.activeIncidents.count : 0}
          criticalCount={kpis?.activeIncidents.criticalCount}
          highlightColor="text-rose-600 dark:text-rose-400"
          icon={AlertOctagon}
          accentColor="red"
          isLoading={isLoading}
        />

        {/* KPI 3: Connected Devices */}
        <KpiCard
          title="Connected Devices"
          value={kpis ? kpis.connectedDevices.count : 0}
          deltaYesterdayPct={kpis?.connectedDevices.deltaYesterdayPct}
          icon={Radio}
          accentColor="amber"
          isLoading={isLoading}
        />

        {/* KPI 4: Messages Relayed */}
        <KpiCard
          title="Messages Relayed"
          value={kpis ? kpis.messagesRelayed.count : 0}
          deltaYesterdayPct={kpis?.messagesRelayed.deltaYesterdayPct}
          icon={Share2}
          accentColor="green"
          isLoading={isLoading}
        />
      </div>

      {/* Main Analytics Grid: Balanced Equal Height */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        {/* Left Column (5/12): Incident Distribution Donut Chart */}
        <div className="lg:col-span-5 flex flex-col">
          <IncidentDistributionChart
            categories={distribution?.categories || []}
            total={distribution?.total || 0}
            isLoading={isLoading}
            className="h-full"
          />
        </div>

        {/* Right Column (7/12): Recent Incidents Scrollable List */}
        <div className="lg:col-span-7 flex flex-col">
          <RecentIncidentsCard
            incidents={recentIncidents}
            isLoading={isLoading}
            className="h-full"
          />
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;

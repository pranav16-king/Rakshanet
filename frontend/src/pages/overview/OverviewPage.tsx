import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchDashboardOverview } from '../../api/dashboard';
import { DashboardTopBar } from '../../components/overview/DashboardTopBar';
import { KpiCard } from '../../components/common/KpiCard';
import { IncidentDistributionChart } from '../../components/overview/IncidentDistributionChart';
import { RecentIncidentsCard } from '../../components/overview/RecentIncidentsCard';

export const OverviewPage: React.FC = () => {
  const [timeRange, setTimeRange] = useState<string>('24h');
  const [isEmptyMode, setIsEmptyMode] = useState<boolean>(false);

  // TanStack Query: fetches from /api/v1/dashboard/overview
  const {
    data: overviewData,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: ['dashboardOverview', timeRange, isEmptyMode],
    queryFn: () => fetchDashboardOverview(timeRange, isEmptyMode),
    refetchInterval: 15000, // Real-time background sync
  });

  const kpis = overviewData?.kpis;
  const distribution = overviewData?.incidentDistribution;
  const incidents = overviewData?.recentIncidents || [];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* TopBar with Title, Subtitle, Time Range & Simulated Empty State toggle */}
      <DashboardTopBar
        timeRange={timeRange}
        onTimeRangeChange={setTimeRange}
        onRefresh={() => refetch()}
        isFetching={isFetching}
        isEmptyMode={isEmptyMode}
        onToggleEmptyMode={() => setIsEmptyMode((prev) => !prev)}
      />

      {/* 4 KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Total Active Users */}
        <KpiCard
          title="Total Active Users"
          value={kpis ? kpis.totalActiveUsers.count : 0}
          deltaYesterdayPct={kpis?.totalActiveUsers.deltaYesterdayPct}
          isLoading={isLoading}
        />

        {/* KPI 2: Active Incidents */}
        <KpiCard
          title="Active Incidents"
          value={kpis ? kpis.activeIncidents.count : 0}
          criticalCount={kpis?.activeIncidents.criticalCount}
          highlightColor="text-[#D92D20] dark:text-[#FF5A4E]"
          isLoading={isLoading}
        />

        {/* KPI 3: Connected Devices */}
        <KpiCard
          title="Connected Devices"
          value={kpis ? kpis.connectedDevices.count : 0}
          deltaYesterdayPct={kpis?.connectedDevices.deltaYesterdayPct}
          isLoading={isLoading}
        />

        {/* KPI 4: Messages Relayed */}
        <KpiCard
          title="Messages Relayed"
          value={kpis ? kpis.messagesRelayed.count : 0}
          deltaYesterdayPct={kpis?.messagesRelayed.deltaYesterdayPct}
          isLoading={isLoading}
        />
      </div>

      {/* Analytics & Incidents Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Incident Distribution Donut Chart */}
        <div className="lg:col-span-5">
          <IncidentDistributionChart
            categories={distribution?.categories || []}
            total={distribution?.total || 0}
            isLoading={isLoading}
          />
        </div>

        {/* Right Column: Recent Incidents List Card */}
        <div className="lg:col-span-7">
          <RecentIncidentsCard
            incidents={incidents}
            isLoading={isLoading}
          />
        </div>
      </div>
    </div>
  );
};

export default OverviewPage;

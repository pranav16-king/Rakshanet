import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  AlertTriangle,
  Users,
  Activity,
  Radio,
  Plus,
  RefreshCw,
} from 'lucide-react';
import type {
  Incident,
  IncidentFilterOptions,
  PaginatedIncidentsResponse,
} from '../../types/incident.ts';
import { fetchIncidents } from '../../api/incidents.ts';
import { IncidentTable } from '../../components/incidents/IncidentTable.tsx';
import { IncidentFilters } from '../../components/incidents/IncidentFilters.tsx';
import { IncidentPagination } from '../../components/incidents/IncidentPagination.tsx';
import { AssignTeamModal } from '../../components/incidents/AssignTeamModal.tsx';
import { useTheme } from '../../theme/ThemeContext.tsx';

export const IncidentsListPage: React.FC = () => {
  const { isDark } = useTheme();
  const [searchParams, setSearchParams] = useSearchParams();

  // Query-based filter state synced with URL search params
  const [filters, setFilters] = useState<IncidentFilterOptions>(() => ({
    searchQuery: searchParams.get('q') || '',
    severity: (searchParams.get('severity') as any) || 'ALL',
    type: (searchParams.get('type') as any) || 'ALL',
    status: (searchParams.get('status') as any) || 'ALL',
    sortBy: (searchParams.get('sortBy') as any) || 'lastUpdate',
    sortOrder: (searchParams.get('sortOrder') as any) || 'desc',
    page: parseInt(searchParams.get('page') || '1', 10),
    pageSize: parseInt(searchParams.get('pageSize') || '10', 10),
  }));

  const [response, setResponse] = useState<PaginatedIncidentsResponse>({
    data: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 10,
    totalPages: 1,
  });

  const [loading, setLoading] = useState(true);
  const [assignModalIncident, setAssignModalIncident] = useState<Incident | null>(null);

  // Sync state to URL params
  useEffect(() => {
    const params: Record<string, string> = {};
    if (filters.searchQuery) params.q = filters.searchQuery;
    if (filters.severity !== 'ALL') params.severity = filters.severity;
    if (filters.type !== 'ALL') params.type = filters.type;
    if (filters.status !== 'ALL') params.status = filters.status;
    if (filters.sortBy !== 'lastUpdate') params.sortBy = filters.sortBy;
    if (filters.sortOrder !== 'desc') params.sortOrder = filters.sortOrder;
    if (filters.page > 1) params.page = String(filters.page);
    if (filters.pageSize !== 10) params.pageSize = String(filters.pageSize);
    setSearchParams(params, { replace: true });
  }, [filters, setSearchParams]);

  // Load incidents data
  const loadData = async () => {
    setLoading(true);
    try {
      const res = await fetchIncidents(filters);
      setResponse(res);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [
    filters.searchQuery,
    filters.severity,
    filters.type,
    filters.status,
    filters.sortBy,
    filters.sortOrder,
    filters.page,
    filters.pageSize,
  ]);

  const handleFilterChange = (updated: Partial<IncidentFilterOptions>) => {
    setFilters((prev) => ({ ...prev, ...updated }));
  };

  const handleResetFilters = () => {
    setFilters({
      searchQuery: '',
      severity: 'ALL',
      type: 'ALL',
      status: 'ALL',
      sortBy: 'lastUpdate',
      sortOrder: 'desc',
      page: 1,
      pageSize: 10,
    });
  };

  const handleSortChange = (sortBy: IncidentFilterOptions['sortBy']) => {
    setFilters((prev) => ({
      ...prev,
      sortBy,
      sortOrder: prev.sortBy === sortBy && prev.sortOrder === 'asc' ? 'desc' : 'asc',
      page: 1,
    }));
  };

  // KPI Metrics calculations
  const totalIncidents = response.totalCount;
  const criticalCount = response.data.filter((i) => i.severity === 'CRITICAL').length;
  const totalPeople = response.data.reduce((sum, i) => sum + i.affectedPeople, 0);

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Top Banner and KPI Cards */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1
            className={`font-display font-bold text-2xl tracking-tight ${
              isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
            }`}
          >
            Incident Command & Triage
          </h1>
          <p className="text-xs opacity-75 mt-0.5">
            Real-time master incidents clustered from civilian mesh telemetry and cellular pings
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={loadData}
            title="Refresh Incidents"
            className={`p-2.5 rounded-lg border transition-all flex items-center gap-2 text-xs font-semibold ${
              isDark
                ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] hover:bg-[#1f2d4d]'
                : 'bg-white border-[#E6DCA8] text-[#16202D] hover:bg-[#FFF5C2]'
            }`}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            <span>Refresh Feed</span>
          </button>
        </div>
      </div>

      {/* KPI Stats Row (Section 8 Command Center spec) */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          className={`p-4 rounded-xl border transition-colors ${
            isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
          }`}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold opacity-70">Total Master Incidents</span>
            <Activity size={16} className="text-[#FFC400]" />
          </div>
          <div className="font-display font-bold text-2xl">{totalIncidents}</div>
          <span className="text-[11px] opacity-65 font-mono">DBSCAN aggregated</span>
        </div>

        <div
          className={`p-4 rounded-xl border transition-colors ${
            isDark ? 'bg-[#3A1512]/40 border-[#FF5A4E]/30' : 'bg-[#FDE2DF]/50 border-[#D92D20]/20'
          }`}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold text-[#FF5A4E]">Critical Severity</span>
            <AlertTriangle size={16} className="text-[#D92D20]" />
          </div>
          <div className="font-display font-bold text-2xl text-[#FF5A4E]">
            {criticalCount}
          </div>
          <span className="text-[11px] opacity-80 font-mono">Immediate threat to life</span>
        </div>

        <div
          className={`p-4 rounded-xl border transition-colors ${
            isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
          }`}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold opacity-70">Estimated Survivors</span>
            <Users size={16} className="text-[#0E8A94]" />
          </div>
          <div className="font-display font-bold text-2xl">{totalPeople.toLocaleString()}</div>
          <span className="text-[11px] opacity-65 font-mono">Poisson casualty model</span>
        </div>

        <div
          className={`p-4 rounded-xl border transition-colors ${
            isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
          }`}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold opacity-70">Mesh Gateways Active</span>
            <Radio size={16} className="text-[#1E8E4E]" />
          </div>
          <div className="font-display font-bold text-2xl text-[#1E8E4E]">4 Nodes</div>
          <span className="text-[11px] opacity-65 font-mono">Zero backhaul loss</span>
        </div>
      </div>

      {/* Filter Controls Component */}
      <IncidentFilters
        filters={filters}
        onChange={handleFilterChange}
        onReset={handleResetFilters}
      />

      {/* Main Table Card */}
      <div
        className={`rounded-xl border shadow-sm transition-colors overflow-hidden ${
          isDark ? 'bg-[#111A2C] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
        }`}
      >
        <IncidentTable
          incidents={response.data}
          filters={filters}
          onSortChange={handleSortChange}
          onQuickAssign={(inc) => setAssignModalIncident(inc)}
          onResetFilters={handleResetFilters}
        />

        {/* Server-side / Query-based Pagination */}
        <IncidentPagination
          currentPage={response.currentPage}
          totalPages={response.totalPages}
          totalCount={response.totalCount}
          pageSize={response.pageSize}
          onPageChange={(page) => handleFilterChange({ page })}
          onPageSizeChange={(pageSize) => handleFilterChange({ pageSize, page: 1 })}
        />
      </div>

      {/* Assign Team Modal */}
      {assignModalIncident && (
        <AssignTeamModal
          isOpen={true}
          incident={assignModalIncident}
          onClose={() => setAssignModalIncident(null)}
          onSuccess={() => {
            loadData();
          }}
        />
      )}
    </div>
  );
};

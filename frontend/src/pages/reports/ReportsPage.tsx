// src/pages/reports/ReportsPage.tsx
import React, { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import {
  FileText,
  FileCode,
  Terminal,
  FileSpreadsheet,
  Download,
  CheckCircle2,
  Clock,
  ArrowLeft,
  Radio,
  ShieldAlert,
  Users,
  Activity,
  RefreshCw,
  Search,
  Trash2,
  CheckCircle,
} from 'lucide-react';

import {
  reportsApi,
  type GeneratedReport,
  type TelemetryStats,
} from '../../api/reports';
import { ExportActionCard } from '../../components/reports/ExportActionCard';
import { CapPreviewModal } from '../../components/reports/CapPreviewModal';
import { CadPreviewModal } from '../../components/reports/CadPreviewModal';
import { CsvPreviewModal } from '../../components/reports/CsvPreviewModal';
import { useTheme } from '../../theme/ThemeContext';
import type { Incident } from '../../types/incident';

export const ReportsPage: React.FC = () => {
  const { isDark } = useTheme();

  // Live data states
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [cadIncidents, setCadIncidents] = useState<unknown[]>([]);
  const [capXml, setCapXml] = useState<string>('');
  const [telemetryStats, setTelemetryStats] = useState<TelemetryStats>({
    unique_packets_stored: 11,
    sos_beacons_count: 8,
    active_mules: 5,
    connected_dashboard_clients: 7,
  });

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefetching, setIsRefetching] = useState<boolean>(false);
  const [searchHistory, setSearchHistory] = useState<string>('');
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  // Modals state
  const [isCapModalOpen, setIsCapModalOpen] = useState<boolean>(false);
  const [isCadModalOpen, setIsCadModalOpen] = useState<boolean>(false);
  const [isCsvModalOpen, setIsCsvModalOpen] = useState<boolean>(false);

  // Load real data from backend
  const loadData = async (isManualRefresh = false) => {
    if (isManualRefresh) setIsRefetching(true);
    else setIsLoading(true);

    try {
      const [xml, cad, incs, stats] = await Promise.all([
        reportsApi.fetchCapXmlFeed(),
        reportsApi.fetchCadJsonFeed(),
        reportsApi.fetchIncidents(),
        reportsApi.fetchTelemetryStats(),
      ]);

      setCapXml(xml);
      setCadIncidents(cad);
      setIncidents(incs);
      setTelemetryStats(stats);
    } catch (err) {
      console.error('Error loading real report data:', err);
    } finally {
      setIsLoading(false);
      setIsRefetching(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(() => {
      loadData(false);
    }, 20000);
    return () => clearInterval(interval);
  }, []);

  // Real CSV content generated from live incidents
  const csvContent = useMemo(() => {
    return reportsApi.generateIncidentSummaryCsv(incidents);
  }, [incidents]);

  // Real reports export history
  const reportsList = useMemo<GeneratedReport[]>(() => {
    return reportsApi.getExportHistory(capXml, cadIncidents, incidents, telemetryStats);
  }, [capXml, cadIncidents, incidents, telemetryStats, downloadSuccess]);

  // Filtered audit list
  const filteredReports = useMemo(() => {
    if (!searchHistory.trim()) return reportsList;
    const q = searchHistory.toLowerCase();
    return reportsList.filter(
      (r) =>
        r.name.toLowerCase().includes(q) ||
        r.type.toLowerCase().includes(q) ||
        r.fileSize.toLowerCase().includes(q)
    );
  }, [reportsList, searchHistory]);

  // Calculations for KPI Cards
  const totalCasualties = useMemo(() => {
    return incidents.reduce(
      (acc, i) => acc + (i.affectedPeople || i.people_count || 1),
      0
    );
  }, [incidents]);

  const totalDevices = useMemo(() => {
    return incidents.reduce(
      (acc, i) => acc + (i.devicesCount || i.devices_count || 1),
      0
    );
  }, [incidents]);

  // Handlers for Downloads & Previews
  const handlePreviewCap = async () => {
    if (!capXml) {
      const xml = await reportsApi.fetchCapXmlFeed();
      setCapXml(xml);
    }
    setIsCapModalOpen(true);
  };

  const handleDownloadCap = async () => {
    const xml = capXml || (await reportsApi.fetchCapXmlFeed());
    const blob = new Blob([xml], { type: 'application/xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const filename = `RakshaNet-OASIS-CAP-v1.2-${new Date().toISOString().slice(0, 10)}.xml`;
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    reportsApi.recordDownloadAudit({
      id: `EXPORT-CAP-${Date.now()}`,
      name: 'OASIS CAP v1.2 National Alert XML Feed',
      type: 'CAP_XML',
      generatedAt: 'Just now',
      fileSize: reportsApi.formatBytes(blob.size),
      recordsCount: cadIncidents.length || incidents.length,
      downloadUrl: '#',
      status: 'READY',
    });

    showNotice(`Downloaded CAP v1.2 XML Feed (${reportsApi.formatBytes(blob.size)}).`);
  };

  const handlePreviewCad = async () => {
    if (cadIncidents.length === 0) {
      const cad = await reportsApi.fetchCadJsonFeed();
      setCadIncidents(cad);
    }
    setIsCadModalOpen(true);
  };

  const handleDownloadCad = async () => {
    const data = cadIncidents.length > 0 ? cadIncidents : await reportsApi.fetchCadJsonFeed();
    const jsonStr = JSON.stringify(data, null, 2);
    const blob = new Blob([jsonStr], { type: 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const filename = `RakshaNet-CAD-112-Incidents-${new Date().toISOString().slice(0, 10)}.json`;
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    reportsApi.recordDownloadAudit({
      id: `EXPORT-CAD-${Date.now()}`,
      name: 'Computer-Aided Dispatch (CAD 112) JSON Feed',
      type: 'CAD_JSON',
      generatedAt: 'Just now',
      fileSize: reportsApi.formatBytes(blob.size),
      recordsCount: data.length,
      downloadUrl: '#',
      status: 'READY',
    });

    showNotice(`Downloaded CAD 112 JSON Feed (${reportsApi.formatBytes(blob.size)}).`);
  };

  const handlePreviewCsv = () => {
    setIsCsvModalOpen(true);
  };

  const handleDownloadCsv = () => {
    const csv = csvContent;
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const filename = `RakshaNet-Incident-Summary-Audit-${new Date().toISOString().slice(0, 10)}.csv`;
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    reportsApi.recordDownloadAudit({
      id: `EXPORT-CSV-${Date.now()}`,
      name: 'Master Incidents & Casualty Audit (CSV)',
      type: 'INCIDENT_CSV',
      generatedAt: 'Just now',
      fileSize: reportsApi.formatBytes(blob.size),
      recordsCount: incidents.length,
      downloadUrl: '#',
      status: 'READY',
    });

    showNotice(`Downloaded Incident Summary CSV (${reportsApi.formatBytes(blob.size)}).`);
  };

  const handleDownloadTelemetryLog = () => {
    const csv = reportsApi.generateTelemetryCsv(telemetryStats, incidents);
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const filename = `RakshaNet-Mesh-Telemetry-Audit-${new Date().toISOString().slice(0, 10)}.csv`;
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    reportsApi.recordDownloadAudit({
      id: `EXPORT-LOG-${Date.now()}`,
      name: 'DTN Mesh Telemetry & Hop Ingestion Audit',
      type: 'TELEMETRY_LOG',
      generatedAt: 'Just now',
      fileSize: reportsApi.formatBytes(blob.size),
      recordsCount: telemetryStats.unique_packets_stored,
      downloadUrl: '#',
      status: 'READY',
    });

    showNotice(`Downloaded DTN Telemetry Audit Log (${reportsApi.formatBytes(blob.size)}).`);
  };

  const showNotice = (msg: string) => {
    setDownloadSuccess(msg);
    setTimeout(() => setDownloadSuccess(null), 4000);
  };

  const handleClearHistory = () => {
    reportsApi.clearExportHistory();
    setDownloadSuccess('Export history cleared.');
    setTimeout(() => setDownloadSuccess(null), 3000);
  };

  return (
    <div className="p-4 sm:p-6 max-w-7xl mx-auto space-y-6 transition-colors">
      {/* Top Header Bar with Crisp Theme Contrast */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <Link
              to="/app/analytics"
              className="p-2 rounded-xl text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 transition border border-slate-200 dark:border-slate-700 shadow-xs cursor-pointer"
              title="Back to Analytics"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>

            <span className="p-2.5 rounded-xl bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30 shadow-xs">
              <FileText className="w-6 h-6" />
            </span>

            <div>
              <div className="flex items-center gap-2">
                <h1
                  className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white tracking-tight"
                  style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                >
                  Interoperability Feeds &amp; Reports Exporter
                </h1>
                <span className="hidden sm:inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  <span>Real Mesh Ingestion</span>
                </span>
              </div>
              <p className="text-xs sm:text-sm text-slate-600 dark:text-[#9FADC2] mt-0.5">
                Standard OASIS CAP v1.2 XML feeds, CAD 112 JSON feeds, and CSV incident summaries for national response agencies.
              </p>
            </div>
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2.5 self-start sm:self-auto">
          <button
            onClick={() => loadData(true)}
            disabled={isRefetching}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold bg-white dark:bg-[#162036] text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-[#26344F] hover:bg-slate-50 dark:hover:bg-slate-800 transition shadow-xs cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin text-amber-500' : ''}`} />
            <span>{isRefetching ? 'Syncing...' : 'Refresh Feeds'}</span>
          </button>
        </div>
      </div>

      {/* Download Alert Notification */}
      {downloadSuccess && (
        <div className="p-4 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-800 dark:text-emerald-300 text-sm font-semibold flex items-center justify-between gap-2 shadow-xs animate-in fade-in duration-200">
          <div className="flex items-center gap-2.5">
            <CheckCircle2 className="w-5 h-5 flex-shrink-0 text-emerald-600 dark:text-emerald-400" />
            <span>{downloadSuccess}</span>
          </div>
          <button onClick={() => setDownloadSuccess(null)} className="text-xs opacity-75 hover:opacity-100">
            Dismiss
          </button>
        </div>
      )}

      {/* KPI & Live Data Summary Bar */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Metric 1: Feeds Status */}
        <div className="p-4 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 font-mono">
              Active Interop Feeds
            </span>
            <div className="p-1.5 rounded-lg bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
              <Radio className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            3 Real Endpoints
          </div>
          <div className="text-xs text-emerald-600 dark:text-emerald-400 font-semibold mt-1 flex items-center gap-1">
            <CheckCircle className="w-3.5 h-3.5" />
            <span>CAP v1.2, CAD 112 &amp; CSV Ready</span>
          </div>
        </div>

        {/* Metric 2: Clustered Incidents */}
        <div className="p-4 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 font-mono">
              Clustered Incidents
            </span>
            <div className="p-1.5 rounded-lg bg-orange-500/15 text-orange-600 dark:text-orange-400">
              <ShieldAlert className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {incidents.length} Master Clusters
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">
            {cadIncidents.length} active in dispatch feed
          </div>
        </div>

        {/* Metric 3: Casualties Ingested */}
        <div className="p-4 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 font-mono">
              Casualty Assessment
            </span>
            <div className="p-1.5 rounded-lg bg-rose-500/15 text-rose-600 dark:text-rose-400">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            ~{totalCasualties} Citizens
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">
            From {totalDevices} reporting mesh nodes
          </div>
        </div>

        {/* Metric 4: Mesh Packets Ingested */}
        <div className="p-4 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 font-mono">
              Mesh Telemetry Pings
            </span>
            <div className="p-1.5 rounded-lg bg-cyan-500/15 text-cyan-600 dark:text-cyan-400">
              <Activity className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {telemetryStats.unique_packets_stored} Hop Packets
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">
            {telemetryStats.active_mules} active data mules in range
          </div>
        </div>
      </div>

      {/* 3 Core Export Action Cards with Real Live Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {/* Card 1: OASIS CAP v1.2 */}
        <ExportActionCard
          title="CAP v1.2 XML Alert Feed"
          description="National NDMA & SACHET compatible Common Alerting Protocol XML feed. Transmits geographic polygons, urgency tags, and casualty metrics."
          formatBadge="OASIS CAP v1.2"
          badgeColor="bg-orange-500/15 text-orange-700 dark:text-orange-400 border-orange-500/30"
          icon={<FileCode className="w-6 h-6 text-orange-600 dark:text-orange-400" />}
          recordCount={cadIncidents.length || incidents.length}
          payloadSize={reportsApi.formatBytes(new Blob([capXml]).size)}
          liveStatus="NDMA Gateway Live"
          onPreview={handlePreviewCap}
          onDownload={handleDownloadCap}
          downloadLabel="Download XML"
        />

        {/* Card 2: CAD JSON Feed */}
        <ExportActionCard
          title="CAD JSON Dispatch Feed"
          description="Integrated Computer-Aided Dispatch format matching 112/911 command center software schemas with priority queues and incident timestamps."
          formatBadge="CAD REST JSON"
          badgeColor="bg-cyan-500/15 text-cyan-700 dark:text-cyan-400 border-cyan-500/30"
          icon={<Terminal className="w-6 h-6 text-cyan-600 dark:text-cyan-400" />}
          recordCount={cadIncidents.length}
          payloadSize={reportsApi.formatBytes(new Blob([JSON.stringify(cadIncidents)]).size)}
          liveStatus="112 Console Synced"
          onPreview={handlePreviewCad}
          onDownload={handleDownloadCad}
          downloadLabel="Download JSON"
        />

        {/* Card 3: Incident Summary CSV */}
        <ExportActionCard
          title="Incident Summary CSV"
          description="Tabular report with clustered incident centroids, radii, casualty estimations (Devices != People), and fleet assignments."
          formatBadge="CSV Spreadsheet"
          badgeColor="bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border-emerald-500/30"
          icon={<FileSpreadsheet className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />}
          recordCount={incidents.length}
          payloadSize={reportsApi.formatBytes(new Blob([csvContent]).size)}
          liveStatus="RFC 4180 Table Ready"
          onPreview={handlePreviewCsv}
          onDownload={handleDownloadCsv}
          downloadLabel="Download CSV"
        />
      </div>

      {/* Historical Generated Reports Log (With Real Live Data & Light/Dark Theme) */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-700/60 pb-4">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base font-bold text-slate-900 dark:text-white">
                Generated Exports History &amp; Audit Trail
              </h3>
              <span className="px-2 py-0.5 rounded-full text-[11px] font-mono font-semibold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
                {filteredReports.length} Feeds
              </span>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Real-time audit log of automated and manual interoperability data feeds from live mesh state.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {/* Search Filter */}
            <div className="relative">
              <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Search audit log..."
                value={searchHistory}
                onChange={(e) => setSearchHistory(e.target.value)}
                className="pl-8 pr-3 py-1.5 text-xs rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-amber-400"
              />
            </div>

            <button
              onClick={handleClearHistory}
              className="p-1.5 rounded-xl text-slate-400 hover:text-rose-500 hover:bg-rose-500/10 transition cursor-pointer"
              title="Clear User Download History"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>

        <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800">
          <table className="w-full text-left text-sm text-slate-700 dark:text-slate-200">
            <thead className="bg-slate-50 dark:bg-[#0E1627] text-xs uppercase tracking-wider text-slate-600 dark:text-slate-400 border-b border-slate-200 dark:border-slate-800">
              <tr>
                <th scope="col" className="px-4 py-3 font-bold">Report Name</th>
                <th scope="col" className="px-4 py-3 font-bold">Format</th>
                <th scope="col" className="px-4 py-3 font-bold">Status / Generated</th>
                <th scope="col" className="px-4 py-3 font-bold">Real Records</th>
                <th scope="col" className="px-4 py-3 font-bold">File Size</th>
                <th scope="col" className="px-4 py-3 font-bold">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 bg-white dark:bg-transparent">
              {filteredReports.map((rep) => (
                <tr
                  key={rep.id}
                  className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors"
                >
                  <td className="px-4 py-3.5 font-medium text-slate-900 dark:text-white flex items-center gap-2">
                    <FileText className="w-4 h-4 text-cyan-600 dark:text-cyan-400 shrink-0" />
                    <span>{rep.name}</span>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className="font-mono text-[11px] font-semibold text-slate-700 dark:text-slate-300 px-2 py-0.5 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                      {rep.type}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-xs text-slate-500 dark:text-slate-400">
                    <div className="flex items-center gap-1.5 font-medium">
                      <Clock className="w-3.5 h-3.5 text-slate-400" />
                      <span>{rep.generatedAt}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-xs font-semibold text-slate-900 dark:text-slate-200">
                    {rep.recordsCount.toLocaleString()} {rep.recordsCount === 1 ? 'record' : 'records'}
                  </td>
                  <td className="px-4 py-3.5 font-mono text-xs font-semibold text-slate-600 dark:text-slate-400">
                    {rep.fileSize}
                  </td>
                  <td className="px-4 py-3.5">
                    <button
                      onClick={() => {
                        if (rep.type === 'CAP_XML') handleDownloadCap();
                        else if (rep.type === 'CAD_JSON') handleDownloadCad();
                        else if (rep.type === 'INCIDENT_CSV') handleDownloadCsv();
                        else handleDownloadTelemetryLog();
                      }}
                      className="inline-flex items-center gap-1 text-xs text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 font-bold transition cursor-pointer"
                    >
                      <Download className="w-3.5 h-3.5" />
                      Download
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals for Live Data Inspection */}
      <CapPreviewModal
        isOpen={isCapModalOpen}
        onClose={() => setIsCapModalOpen(false)}
        xmlContent={capXml}
      />

      <CadPreviewModal
        isOpen={isCadModalOpen}
        onClose={() => setIsCadModalOpen(false)}
        jsonData={cadIncidents}
      />

      <CsvPreviewModal
        isOpen={isCsvModalOpen}
        onClose={() => setIsCsvModalOpen(false)}
        csvContent={csvContent}
        filename={`RakshaNet-Incident-Summary-Audit-${new Date().toISOString().slice(0, 10)}.csv`}
        onDownload={handleDownloadCsv}
      />
    </div>
  );
};

export default ReportsPage;

// src/pages/reports/ReportsPage.tsx
import React, { useState } from 'react';
import { reportsApi, type GeneratedReport } from '../../api/reports';
import { ExportActionCard } from '../../components/reports/ExportActionCard';
import { CapPreviewModal } from '../../components/reports/CapPreviewModal';
import { CadPreviewModal } from '../../components/reports/CadPreviewModal';
import {
  FileText,
  FileCode,
  Terminal,
  FileSpreadsheet,
  Download,
  CheckCircle2,
  Clock,
  ArrowLeft,
} from 'lucide-react';
import { Link } from 'react-router-dom';

export const ReportsPage: React.FC = () => {
  const [reports] = useState<GeneratedReport[]>(reportsApi.getRecentReports());
  const [capXml, setCapXml] = useState<string>('');
  const [cadJson, setCadJson] = useState<unknown>(null);
  const [isCapModalOpen, setIsCapModalOpen] = useState<boolean>(false);
  const [isCadModalOpen, setIsCadModalOpen] = useState<boolean>(false);
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  const handlePreviewCap = async () => {
    const xml = await reportsApi.fetchCapXmlFeed();
    setCapXml(xml);
    setIsCapModalOpen(true);
  };

  const handleDownloadCap = async () => {
    const xml = await reportsApi.fetchCapXmlFeed();
    const blob = new Blob([xml], { type: 'application/xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `RakshaNet-CAP-Feed-${new Date().toISOString().slice(0, 10)}.xml`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showNotice('Downloaded CAP v1.2 XML Feed successfully.');
  };

  const handlePreviewCad = async () => {
    const json = await reportsApi.fetchCadJsonFeed();
    setCadJson(json);
    setIsCadModalOpen(true);
  };

  const handleDownloadCad = async () => {
    const json = await reportsApi.fetchCadJsonFeed();
    const blob = new Blob([JSON.stringify(json, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `RakshaNet-CAD-Incidents-${new Date().toISOString().slice(0, 10)}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showNotice('Downloaded CAD 112 JSON Feed successfully.');
  };

  const handleDownloadCsv = () => {
    const csv = reportsApi.generateIncidentSummaryCsv();
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `RakshaNet-Incident-Summary-${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showNotice('Downloaded Incident Summary CSV successfully.');
  };

  const showNotice = (msg: string) => {
    setDownloadSuccess(msg);
    setTimeout(() => setDownloadSuccess(null), 4000);
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 text-slate-100">
      {/* Header bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Link
              to="/app/analytics"
              className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
              title="Back to Analytics"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <span className="p-2 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <FileText className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold tracking-tight text-white font-display">
              Interoperability Feeds &amp; Reports Exporter
            </h1>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Export standard OASIS CAP v1.2 XML feeds, CAD 112 JSON feeds, and CSV incident summaries for national response agencies.
          </p>
        </div>
      </div>

      {downloadSuccess && (
        <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-sm flex items-center gap-2">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{downloadSuccess}</span>
        </div>
      )}

      {/* 3 Core Export Action Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {/* Card 1: OASIS CAP v1.2 */}
        <ExportActionCard
          title="CAP v1.2 XML Alert Feed"
          description="National NDMA & SACHET compatible Common Alerting Protocol XML feed. Transmits geographic polygons, urgency tags, and casualty metrics."
          formatBadge="OASIS CAP v1.2"
          badgeColor="bg-orange-500/20 text-orange-400 border-orange-500/30"
          icon={<FileCode className="w-6 h-6 text-orange-400" />}
          onPreview={handlePreviewCap}
          onDownload={handleDownloadCap}
          downloadLabel="Download XML"
        />

        {/* Card 2: CAD JSON Feed */}
        <ExportActionCard
          title="CAD JSON Dispatch Feed"
          description="Integrated Computer-Aided Dispatch format matching 112/911 command center software schemas with priority queues and incident timestamps."
          formatBadge="CAD REST JSON"
          badgeColor="bg-cyan-500/20 text-cyan-400 border-cyan-500/30"
          icon={<Terminal className="w-6 h-6 text-cyan-400" />}
          onPreview={handlePreviewCad}
          onDownload={handleDownloadCad}
          downloadLabel="Download JSON"
        />

        {/* Card 3: Incident Summary CSV */}
        <ExportActionCard
          title="Incident Summary CSV"
          description="Tabular report with clustered incident centroids, radii, casualty estimations (Devices != People), and fleet assignments."
          formatBadge="CSV Spreadsheet"
          badgeColor="bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
          icon={<FileSpreadsheet className="w-6 h-6 text-emerald-400" />}
          onPreview={handleDownloadCsv}
          onDownload={handleDownloadCsv}
          downloadLabel="Download CSV"
        />
      </div>

      {/* Historical Generated Reports Log */}
      <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-md space-y-4">
        <div className="flex items-center justify-between border-b border-slate-700/60 pb-3">
          <div>
            <h3 className="text-base font-bold text-white">Generated Exports History</h3>
            <p className="text-xs text-slate-400">
              Audit log of automated and manual interoperability data exports.
            </p>
          </div>
          <span className="text-xs text-slate-400 font-mono">Auto-generated every 30m</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-200">
            <thead className="bg-[#0E1627] text-xs uppercase tracking-wider text-slate-400 border-b border-slate-700">
              <tr>
                <th scope="col" className="px-4 py-3">Report Name</th>
                <th scope="col" className="px-4 py-3">Format</th>
                <th scope="col" className="px-4 py-3">Generated</th>
                <th scope="col" className="px-4 py-3">Records</th>
                <th scope="col" className="px-4 py-3">File Size</th>
                <th scope="col" className="px-4 py-3">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {reports.map((rep) => (
                <tr key={rep.id} className="hover:bg-slate-800/40 transition">
                  <td className="px-4 py-3.5 font-medium text-white flex items-center gap-2">
                    <FileText className="w-4 h-4 text-cyan-400" />
                    {rep.name}
                  </td>
                  <td className="px-4 py-3.5">
                    <span className="font-mono text-xs text-slate-300 px-2 py-0.5 rounded bg-slate-800 border border-slate-700">
                      {rep.type}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-xs text-slate-400">
                    <div className="flex items-center gap-1">
                      <Clock className="w-3.5 h-3.5" />
                      {rep.generatedAt}
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-xs text-slate-300">
                    {rep.recordsCount.toLocaleString()} items
                  </td>
                  <td className="px-4 py-3.5 font-mono text-xs text-slate-400">
                    {rep.fileSize}
                  </td>
                  <td className="px-4 py-3.5">
                    <button
                      onClick={() => {
                        if (rep.type === 'CAP_XML') handleDownloadCap();
                        else if (rep.type === 'CAD_JSON') handleDownloadCad();
                        else handleDownloadCsv();
                      }}
                      className="inline-flex items-center gap-1 text-xs text-amber-400 hover:text-amber-300 font-semibold"
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

      {/* Modals */}
      <CapPreviewModal
        isOpen={isCapModalOpen}
        onClose={() => setIsCapModalOpen(false)}
        xmlContent={capXml}
      />

      <CadPreviewModal
        isOpen={isCadModalOpen}
        onClose={() => setIsCadModalOpen(false)}
        jsonData={cadJson}
      />
    </div>
  );
};

export default ReportsPage;

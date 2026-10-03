// src/pages/communication-gaps/CommunicationGapsPage.tsx
import React, { useState, useEffect } from 'react';
import type { BlackHoleAnomaly } from '../../types';
import { communicationGapsApi } from '../../api/communicationGaps';
import { BlackHoleAlertCard } from '../../components/communication-gaps/BlackHoleAlertCard';
import { CommunicationGapsMap } from '../../components/communication-gaps/CommunicationGapsMap';
import {
  Radio,
  RefreshCw,
  Search,
  Users,
  Clock,
  CheckCircle2,
  AlertTriangle,
  Zap,
} from 'lucide-react';

export const CommunicationGapsPage: React.FC = () => {
  const [anomalies, setAnomalies] = useState<BlackHoleAnomaly[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [scanning, setScanning] = useState<boolean>(false);
  const [selectedAnomalyId, setSelectedAnomalyId] = useState<string | undefined>(undefined);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [filterSeverity, setFilterSeverity] = useState<string>('ALL');
  const [scanNotice, setScanNotice] = useState<string | null>(null);

  const fetchAnomalies = async () => {
    setLoading(true);
    try {
      const data = await communicationGapsApi.getAnomalies();
      setAnomalies(data);
      if (data.length > 0 && !selectedAnomalyId) {
        setSelectedAnomalyId(data[0].anomaly_id);
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnomalies();
  }, []);

  const handleTriggerScan = async () => {
    setScanning(true);
    setScanNotice(null);
    try {
      const res = await communicationGapsApi.triggerScan();
      setAnomalies(res.anomalies);
      setScanNotice(
        `Multi-sector decay scan complete: Found ${res.anomaly_count} silence zones (${res.critical_count} critical, ${res.warning_count} warning).`
      );
    } finally {
      setScanning(false);
    }
  };

  const filteredAnomalies = anomalies.filter((a) => {
    const matchesSearch =
      a.sector_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.recommended_action.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesSeverity = filterSeverity === 'ALL' || a.severity === filterSeverity;
    return matchesSearch && matchesSeverity;
  });

  const criticalCount = anomalies.filter((a) => a.severity === 'CRITICAL' || a.drop_percentage >= 75).length;
  const warningCount = anomalies.filter((a) => a.severity === 'WARNING' || (a.drop_percentage >= 45 && a.drop_percentage < 75)).length;
  const totalSilencedPopulation = anomalies.reduce((sum, a) => sum + a.estimated_silenced_people, 0);

  const selectedAnomaly = anomalies.find((a) => a.anomaly_id === selectedAnomalyId);

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 text-slate-100">
      {/* Header bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-xl bg-purple-500/10 text-purple-400 border border-purple-500/20">
              <Radio className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold tracking-tight text-white font-display">
              Communication Gaps & Black Hole Detector
            </h1>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Feature 16: Autonomous detection of sudden telemetry decay curves, cut-off villages, and complete silence zones.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={fetchAnomalies}
            disabled={loading}
            className="flex items-center gap-2 px-3.5 py-2.5 rounded-lg border border-slate-700 bg-[#162036] hover:bg-slate-700/60 text-slate-200 text-sm font-medium transition"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>

          <button
            onClick={handleTriggerScan}
            disabled={scanning}
            className="flex items-center gap-2 px-5 py-2.5 rounded-lg bg-purple-600 hover:bg-purple-500 text-white font-bold text-sm shadow-lg shadow-purple-600/20 transition disabled:opacity-50"
          >
            <Zap className={`w-4 h-4 ${scanning ? 'animate-spin' : ''}`} />
            {scanning ? 'Scanning Spatiotemporal Grid...' : 'Trigger Black Hole Scan'}
          </button>
        </div>
      </div>

      {scanNotice && (
        <div className="p-4 rounded-xl bg-purple-900/30 border border-purple-500/40 text-purple-300 text-sm flex items-center justify-between">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-purple-400 flex-shrink-0" />
            <span>{scanNotice}</span>
          </div>
          <button
            onClick={() => setScanNotice(null)}
            className="text-xs text-purple-300 hover:text-white"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Silenced Sectors Tracked</div>
          <div className="text-2xl font-bold text-white mt-1">{anomalies.length}</div>
          <div className="text-xs text-slate-500 mt-0.5">Spatiotemporal grid cells</div>
        </div>

        <div className="p-4 rounded-xl bg-[#161327] border border-purple-500/30 shadow-sm">
          <div className="text-xs text-purple-300 font-semibold">Critical Blackouts (&gt;75% Loss)</div>
          <div className="text-2xl font-bold text-purple-400 mt-1 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            {criticalCount}
          </div>
          <div className="text-xs text-purple-300/70 mt-0.5">Immediate aerial relay needed</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Decaying Sectors (&gt;45% Loss)</div>
          <div className="text-2xl font-bold text-amber-400 mt-1 flex items-center gap-2">
            <Clock className="w-5 h-5" />
            {warningCount}
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Early warning decay trajectory</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Est. Cut-off Population</div>
          <div className="text-2xl font-bold text-purple-300 mt-1 flex items-center gap-2">
            <Users className="w-5 h-5" />
            ~{totalSilencedPopulation.toLocaleString()}
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Statistical (Devices != People 2.5x)</div>
        </div>
      </div>

      {/* Search & Filter Bar */}
      <div className="flex flex-col sm:flex-row gap-3 items-center justify-between bg-[#162036] p-3.5 rounded-xl border border-slate-700/70">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by sector code, action..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-[#0E1627] border border-slate-700 rounded-lg pl-9 pr-3.5 py-2 text-sm text-slate-200 placeholder-slate-500 focus:outline-none focus:border-purple-400"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-slate-400">Severity:</span>
          <select
            value={filterSeverity}
            onChange={(e) => setFilterSeverity(e.target.value)}
            className="bg-[#0E1627] border border-slate-700 text-slate-200 rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-purple-400"
          >
            <option value="ALL">All Severities</option>
            <option value="CRITICAL">Critical Only (&gt;75%)</option>
            <option value="WARNING">Warning Only (&gt;45%)</option>
          </select>
        </div>
      </div>

      {/* Main 2-column layout: Left Cards List, Right Hatched GIS Map */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Sector Anomaly Cards */}
        <div className="lg:col-span-5 space-y-3.5">
          <div className="flex items-center justify-between text-xs text-slate-400 px-1">
            <span>Detected Silence Sectors ({filteredAnomalies.length})</span>
            <span>Click sector to focus on map</span>
          </div>

          {loading ? (
            <div className="p-12 text-center text-slate-400">
              <RefreshCw className="w-6 h-6 animate-spin mx-auto text-purple-400 mb-2" />
              Scanning for communication black holes...
            </div>
          ) : (
            filteredAnomalies.map((anomaly) => (
              <BlackHoleAlertCard
                key={anomaly.anomaly_id}
                anomaly={anomaly}
                isSelected={selectedAnomalyId === anomaly.anomaly_id}
                onSelect={() => setSelectedAnomalyId(anomaly.anomaly_id)}
              />
            ))
          )}
        </div>

        {/* Right Column: Leaflet Map showing Hatched Purple Polygon Areas */}
        <div className="lg:col-span-7 space-y-4">
          <CommunicationGapsMap
            anomalies={filteredAnomalies}
            selectedAnomalyId={selectedAnomalyId}
            onSelectAnomaly={(a) => setSelectedAnomalyId(a.anomaly_id)}
          />

          {/* Selected Anomaly Tactical Action Dispatch Box */}
          {selectedAnomaly && (
            <div className="p-5 rounded-xl border border-purple-500/30 bg-[#161327] space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-xs text-purple-300 font-mono">SELECTED FOCUS ZONE</span>
                  <div className="text-base font-bold text-white mt-0.5">
                    {selectedAnomaly.sector_id}
                  </div>
                </div>
                <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-500/20 text-purple-300 border border-purple-500/40">
                  {selectedAnomaly.severity}
                </span>
              </div>

              <div className="text-xs text-slate-300 bg-[#0B101E] p-3 rounded-lg border border-slate-800">
                <div className="font-semibold text-slate-200 mb-1">Autonomous Drone & Relay Dispatch Recommendation:</div>
                <div className="text-purple-300 font-mono text-[11px]">
                  {selectedAnomaly.recommended_action}
                </div>
                <p className="text-slate-400 mt-2">
                  This sector experienced a <strong>{selectedAnomaly.drop_percentage.toFixed(1)}% collapse</strong> in active mesh heartbeats over the last 120 minutes. Approximately <strong>{selectedAnomaly.estimated_silenced_people} residents</strong> are cut off from rescue dispatch without cellular or road ingress.
                </p>
              </div>

              <div className="flex items-center justify-end gap-3 pt-1">
                <button
                  onClick={() => alert(`Aerial Drone Dispatch Order queued for sector ${selectedAnomaly.sector_id}`)}
                  className="px-4 py-2 text-xs rounded-lg bg-purple-500 hover:bg-purple-400 font-bold text-white shadow-md transition"
                >
                  Dispatch Tactical DTN Relay Drone
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default CommunicationGapsPage;

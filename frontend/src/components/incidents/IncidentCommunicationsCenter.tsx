import React, { useState, useMemo } from 'react';
import {
  ShieldAlert,
  Radio,
  FileText,
  Send,
  MessageSquare,
  Mic,
  CheckCheck,
  Clock,
  Battery,
  AlertTriangle,
  ArrowRight,
  RefreshCw,
  Search,
  Filter,
  CheckCircle2,
  MapPin,
  ExternalLink,
  Volume2,
  Activity,
  Layers,
  Users,
  Info,
  Copy,
  Check,
  User,
} from 'lucide-react';
import { Button } from '../common/Button';
import { Card } from '../common/Card';
import { broadcastIncidentMessage } from '../../api/incidents';
import { HumanReadablePayload } from './HumanReadablePayload';
import type {
  IncidentCommunicationsResponse,
  IncidentSosAlert,
  RelayTopologyRoute,
  IncidentFieldSitrep,
  IncidentTeamComm,
  IncidentVoiceTranscription,
  IncidentCategorizedCommunication,
} from '../../types/incident';

interface IncidentCommunicationsCenterProps {
  incidentId: string;
  communications?: IncidentCommunicationsResponse | null;
  isLoading?: boolean;
  onRefresh?: () => void;
}

const reportedNumber = (value: unknown, suffix = ''): string =>
  typeof value === 'number' && Number.isFinite(value)
    ? `${value}${suffix}`
    : 'Not reported';

const reportedCoordinates = (lat: unknown, lng: unknown): string =>
  typeof lat === 'number' && Number.isFinite(lat) && typeof lng === 'number' && Number.isFinite(lng)
    ? `[${lat.toFixed(4)}, ${lng.toFixed(4)}]`
    : 'Location not reported';

const reportedTimestamp = (value: unknown, rawTimestamp?: unknown): string => {
  if (typeof value === 'string' && value.trim() && value !== 'Time not reported') {
    return value;
  }
  if (rawTimestamp) {
    try {
      const num = typeof rawTimestamp === 'number' ? rawTimestamp : parseFloat(String(rawTimestamp));
      if (!isNaN(num) && num > 0) {
        const sec = num > 1e11 ? num : num * 1000;
        const d = new Date(sec);
        if (!isNaN(d.getTime())) {
          return d.toLocaleString('en-IN', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true,
          });
        }
      }
    } catch {
      // fallback
    }
  }
  return 'Just now';
};

export const IncidentCommunicationsCenter: React.FC<IncidentCommunicationsCenterProps> = ({
  incidentId,
  communications,
  isLoading = false,
  onRefresh,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<
    'ALL' | 'SOS' | 'RELAY' | 'SITREP' | 'TEAM' | 'VOICE'
  >('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [broadcastText, setBroadcastText] = useState('');
  const [isBroadcasting, setIsBroadcasting] = useState(false);
  const [broadcastSuccess, setBroadcastSuccess] = useState<string | null>(null);
  const [revealedImeis, setRevealedImeis] = useState<Record<string, boolean>>({});
  const [showAllImeis, setShowAllImeis] = useState<boolean>(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const toggleImei = (id: string) => {
    setRevealedImeis((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const copyImei = (imei: string, id: string) => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(imei);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2500);
    }
  };

  const summary = communications?.summary || {
    total: 0,
    sos_count: 0,
    sitreps_count: 0,
    team_comms_count: 0,
    voice_count: 0,
    active_devices: 0,
  };

  const handleSendBroadcast = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!broadcastText.trim()) return;

    setIsBroadcasting(true);
    try {
      await broadcastIncidentMessage(
        incidentId,
        broadcastText.trim(),
        'HIGH',
        'ALL_CHANNELS'
      );
      setBroadcastSuccess('Command queued for a field gateway; delivery is not yet confirmed.');
      setBroadcastText('');
      setTimeout(() => setBroadcastSuccess(null), 4000);
      if (onRefresh) onRefresh();
    } catch (err) {
      console.error('Failed to broadcast message:', err);
    } finally {
      setIsBroadcasting(false);
    }
  };

  // Filtered Unified Stream
  const filteredAll = useMemo(() => {
    const list = communications?.all_communications || [];
    if (!searchQuery.trim()) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(
      (c) =>
        (c.title || '').toLowerCase().includes(q) ||
        (c.content || '').toLowerCase().includes(q) ||
        (c.sender || '').toLowerCase().includes(q) ||
        (c.category || '').toLowerCase().includes(q)
    );
  }, [communications?.all_communications, searchQuery]);

  return (
    <div className="space-y-6">
      {/* Top Header Strip with Summary Counts */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <Radio className="w-5 h-5 text-[#0891B2] animate-pulse" />
            <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">
              Incident Mesh Communications Center
            </h2>
            <span className="px-2 py-0.5 text-[11px] font-bold rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
              Gateway data
            </span>
          </div>
          <p className="text-xs text-[#64748B] dark:text-[#94A3B8] mt-0.5">
            Observed field packets and queued command-center messages for this incident
          </p>
        </div>

        <div className="flex items-center gap-2">
          {onRefresh && (
            <Button
              variant="outline"
              size="sm"
              onClick={onRefresh}
              disabled={isLoading}
              className="text-xs border-[#CBD5E1] dark:border-[#334155]"
            >
              <RefreshCw
                className={`w-3.5 h-3.5 mr-1.5 ${isLoading ? 'animate-spin text-[#0891B2]' : ''}`}
              />
              <span>Refresh Comms</span>
            </Button>
          )}
        </div>
      </div>

      {/* Communications Navigation Tabs (Separately Arranged Categories!) */}
      <div className="flex items-center gap-2 border-b border-[#E2E8F0] dark:border-[#1E293B] pb-1 overflow-x-auto">
        <button
          onClick={() => setActiveSubTab('ALL')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'ALL'
              ? 'bg-[#FFD21F] text-[#0B1220] shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-gray-100 dark:hover:bg-gray-800'
          }`}
        >
          <Layers className="w-3.5 h-3.5" />
          <span>Unified Feed ({summary.total})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('SOS')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'SOS'
              ? 'bg-red-500 text-white shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-red-500/10 hover:text-red-500'
          }`}
        >
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>🚨 SOS Distress ({summary.sos_count})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('RELAY')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'RELAY'
              ? 'bg-cyan-600 text-white shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-cyan-500/10 hover:text-cyan-500'
          }`}
        >
          <Radio className="w-3.5 h-3.5" />
          <span>📡 Mesh Hop Topology</span>
        </button>

        <button
          onClick={() => setActiveSubTab('SITREP')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'SITREP'
              ? 'bg-amber-500 text-white shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-amber-500/10 hover:text-amber-500'
          }`}
        >
          <FileText className="w-3.5 h-3.5" />
          <span>📋 Civilian SITREPs ({summary.sitreps_count})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('TEAM')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'TEAM'
              ? 'bg-emerald-600 text-white shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-emerald-500/10 hover:text-emerald-500'
          }`}
        >
          <MessageSquare className="w-3.5 h-3.5" />
          <span>🚒 Team Comms ({summary.team_comms_count})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('VOICE')}
          className={`flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl transition-all whitespace-nowrap cursor-pointer ${
            activeSubTab === 'VOICE'
              ? 'bg-purple-600 text-white shadow-sm'
              : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-purple-500/10 hover:text-purple-500'
          }`}
        >
          <Mic className="w-3.5 h-3.5" />
          <span>🎙️ Voice Transcriptions ({summary.voice_count})</span>
        </button>
      </div>

      {/* ===================================================================== */}
      {/* 1. UNIFIED FEED WITH SEARCH & IMEI TOGGLE */}
      {/* ===================================================================== */}
      {activeSubTab === 'ALL' && (
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row items-center gap-3">
            <div className="relative flex-1 w-full">
              <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-[#94A3B8]" />
              <input
                type="text"
                placeholder="Search messages, senders, IMEIs, or reports..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-sm rounded-xl bg-white dark:bg-[#111A2E] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] outline-none"
              />
            </div>
            <button
              type="button"
              onClick={() => setShowAllImeis((prev) => !prev)}
              className={`px-3 py-2 text-xs font-bold rounded-xl border transition-all flex items-center gap-1.5 shrink-0 cursor-pointer ${
                showAllImeis
                  ? 'bg-cyan-500/20 text-cyan-700 dark:text-cyan-300 border-cyan-500/40 ring-1 ring-cyan-500/30'
                  : 'bg-white dark:bg-[#111A2E] text-slate-700 dark:text-slate-300 border-slate-300 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
              title="Toggle visibility of IMEI numbers for all communication cards"
            >
              <Info className="w-3.5 h-3.5 text-cyan-500" />
              <span>{showAllImeis ? 'Hide All IMEIs' : 'Show All IMEIs (i)'}</span>
            </button>
          </div>

          {filteredAll.length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <Radio className="w-10 h-10 mx-auto text-[#64748B] dark:text-[#94A3B8] opacity-60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Communications Ingested Yet</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                No mesh distress packets, field SITREPs, or team radio transmissions have been recorded for this incident cluster yet. Live mesh packets will appear here in real-time.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredAll.map((item: IncidentCategorizedCommunication) => {
                const isSOS = item.category === 'SOS';
                const isSITREP = item.category === 'SITREP';
                const isTeam = item.category === 'RESCUE_COMMS';
                const imei = item.imei || (item.sender_id && item.sender_id.length >= 14 ? item.sender_id : null);
                const isImeiRevealed = showAllImeis || !!revealedImeis[item.id];
                const displayName = item.sender_name || item.sender || (item.sender_id ? `Node ${item.sender_id.slice(-4)}` : 'Mesh Handset');

                return (
                  <div
                    key={item.id}
                    className={`p-4 rounded-xl border transition-all ${
                      isSOS
                        ? 'bg-red-500/5 dark:bg-red-950/20 border-red-500/30'
                        : isSITREP
                        ? 'bg-amber-500/5 dark:bg-amber-950/20 border-amber-500/30'
                        : isTeam
                        ? 'bg-emerald-500/5 dark:bg-emerald-950/20 border-emerald-500/30'
                        : 'bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-start gap-3 flex-1 min-w-0">
                        <div
                          className={`p-2 rounded-lg shrink-0 mt-0.5 ${
                            isSOS
                              ? 'bg-red-500 text-white'
                              : isSITREP
                              ? 'bg-amber-500 text-white'
                              : isTeam
                              ? 'bg-emerald-600 text-white'
                              : 'bg-purple-600 text-white'
                          }`}
                        >
                          {isSOS ? (
                            <ShieldAlert className="w-4 h-4" />
                          ) : isSITREP ? (
                            <FileText className="w-4 h-4" />
                          ) : isTeam ? (
                            <MessageSquare className="w-4 h-4" />
                          ) : (
                            <Mic className="w-4 h-4" />
                          )}
                        </div>

                        <div className="flex-1 min-w-0">
                          {/* Card Header with Badges, Sender Name & IMEI (i) button */}
                          <div className="flex items-center gap-2 flex-wrap">
                            <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                              {item.title}
                            </h4>

                            {/* Sender Name with User Icon */}
                            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-lg text-xs font-semibold bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-slate-700">
                              <User className="w-3.5 h-3.5 text-cyan-600 dark:text-cyan-400" />
                              <span>{displayName}</span>
                            </span>

                            {/* [i] Info Button to Reveal / Hide IMEI */}
                            {imei && (
                              <div className="inline-flex items-center">
                                {isImeiRevealed ? (
                                  <div className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md font-mono text-[11px] font-bold bg-cyan-50 dark:bg-cyan-950/70 border border-cyan-400 text-cyan-800 dark:text-cyan-200 shadow-xs animate-fadeIn">
                                    <Info className="w-3.5 h-3.5 text-cyan-500" />
                                    <span>IMEI: {imei}</span>
                                    <button
                                      type="button"
                                      onClick={() => copyImei(imei, item.id)}
                                      className="p-0.5 hover:text-cyan-950 dark:hover:text-white transition cursor-pointer"
                                      title="Copy IMEI number"
                                    >
                                      {copiedId === item.id ? (
                                        <Check className="w-3 h-3 text-emerald-500" />
                                      ) : (
                                        <Copy className="w-3 h-3" />
                                      )}
                                    </button>
                                    <button
                                      type="button"
                                      onClick={() => toggleImei(item.id)}
                                      className="text-[10px] text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 ml-0.5 cursor-pointer"
                                      title="Hide IMEI"
                                    >
                                      ✕
                                    </button>
                                  </div>
                                ) : (
                                  <button
                                    type="button"
                                    onClick={() => toggleImei(item.id)}
                                    className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-mono font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-300 dark:border-slate-700 hover:bg-cyan-500/15 hover:text-cyan-600 hover:border-cyan-400 transition cursor-pointer"
                                    title="Click (i) to view device IMEI number"
                                  >
                                    <Info className="w-3.5 h-3.5 text-cyan-500" />
                                    <span>IMEI (i)</span>
                                  </button>
                                )}
                              </div>
                            )}

                            <span
                              className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                                item.priority === 'CRITICAL'
                                  ? 'bg-red-500/15 text-red-600 border-red-500/30'
                                  : 'bg-amber-500/15 text-amber-600 border-amber-500/30'
                              }`}
                            >
                              {item.priority}
                            </span>
                          </div>

                          {/* Human-Readable Message Content (Clean Cards, No Raw JSON) */}
                          <HumanReadablePayload
                            content={item.content}
                            title={item.title}
                            category={item.category}
                            meta={item.meta}
                          />
                        </div>
                      </div>

                      <div className="flex flex-col items-end gap-1 text-[11px] text-[#64748B] dark:text-[#94A3B8] shrink-0 font-mono">
                        <span className="font-semibold text-slate-700 dark:text-slate-300">
                          {reportedTimestamp(item.timestamp_display, item.timestamp)}
                        </span>
                        <span className="text-[10px] bg-[#E2E8F0] dark:bg-[#1E293B] px-1.5 py-0.5 rounded">
                          {item.hops ?? 0} mesh hops
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* 2. SOS DISTRESS TRANSMISSIONS */}
      {/* ===================================================================== */}
      {activeSubTab === 'SOS' && (
        <div className="space-y-4">
          <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 flex items-center justify-between text-xs text-red-700 dark:text-red-400">
            <div className="flex items-center gap-2">
              <ShieldAlert className="w-4 h-4 text-red-500 shrink-0" />
              <span>
                <strong>{communications?.sos_alerts?.length ?? 0} observed SOS packet(s):</strong> values below are reported by the sender or its relay packet.
              </span>
            </div>
            <span className="font-bold">Prioritize Rooftop Extractions</span>
          </div>

          {(communications?.sos_alerts || []).length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <ShieldAlert className="w-10 h-10 mx-auto text-red-500/60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Active SOS Transmissions</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                No direct survivor SOS beacons have been emitted or relayed for this incident cluster.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {(communications?.sos_alerts || []).map((sos: IncidentSosAlert) => {
                const sosImei = sos.imei || (sos.sender_id && sos.sender_id.length >= 14 ? sos.sender_id : null);
                const isRevealed = showAllImeis || !!revealedImeis[sos.id];
                return (
                  <Card
                    key={sos.id}
                    className="p-5 bg-white dark:bg-[#111A2E] border-red-500/40 ring-1 ring-red-500/20 shadow-md"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase bg-red-500 text-white animate-pulse">
                            CRITICAL SOS
                          </span>
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 border border-slate-200 dark:border-slate-700">
                            <User className="w-3.5 h-3.5 text-red-500" />
                            <span>{sos.sender_name || 'Survivor Handset'}</span>
                          </span>

                          {/* [i] Info Button for IMEI */}
                          {sosImei && (
                            <div className="inline-flex items-center">
                              {isRevealed ? (
                                <div className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md font-mono text-[11px] font-bold bg-cyan-50 dark:bg-cyan-950/70 border border-cyan-400 text-cyan-800 dark:text-cyan-200 shadow-xs animate-fadeIn">
                                  <Info className="w-3.5 h-3.5 text-cyan-500" />
                                  <span>IMEI: {sosImei}</span>
                                  <button
                                    type="button"
                                    onClick={() => copyImei(sosImei, sos.id)}
                                    className="p-0.5 hover:text-cyan-950 dark:hover:text-white transition cursor-pointer"
                                    title="Copy IMEI number"
                                  >
                                    {copiedId === sos.id ? (
                                      <Check className="w-3 h-3 text-emerald-500" />
                                    ) : (
                                      <Copy className="w-3 h-3" />
                                    )}
                                  </button>
                                  <button
                                    type="button"
                                    onClick={() => toggleImei(sos.id)}
                                    className="text-[10px] text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 ml-0.5 cursor-pointer"
                                    title="Hide IMEI"
                                  >
                                    ✕
                                  </button>
                                </div>
                              ) : (
                                <button
                                  type="button"
                                  onClick={() => toggleImei(sos.id)}
                                  className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-mono font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-300 dark:border-slate-700 hover:bg-cyan-500/15 hover:text-cyan-600 hover:border-cyan-400 transition cursor-pointer"
                                  title="Click (i) to view device IMEI number"
                                >
                                  <Info className="w-3.5 h-3.5 text-cyan-500" />
                                  <span>IMEI (i)</span>
                                </button>
                              )}
                            </div>
                          )}
                        </div>

                        {/* Human-Readable SOS Payload */}
                        <HumanReadablePayload
                          content={sos.payload}
                          title="SOS"
                          category="SOS"
                        />

                        <div className="flex flex-wrap items-center gap-4 text-xs text-[#64748B] dark:text-[#94A3B8] pt-1">
                          <span className="flex items-center gap-1">
                            <Users className="w-3.5 h-3.5 text-red-500" />
                            <strong>{reportedNumber(sos.casualties)} people reported</strong>
                          </span>
                          <span>•</span>
                          <span className="flex items-center gap-1 font-mono">
                            <Battery className="w-3.5 h-3.5 text-amber-500" />
                            {reportedNumber(sos.battery_pct, '%')} battery
                          </span>
                          <span>•</span>
                          <span className="flex items-center gap-1 font-mono">
                            <MapPin className="w-3.5 h-3.5 text-cyan-500" />
                            {reportedCoordinates(sos.lat, sos.lng)}
                          </span>
                          <span>•</span>
                          <span className="font-semibold text-slate-700 dark:text-slate-300">
                            {reportedTimestamp(sos.timestamp_display, sos.timestamp)}
                          </span>
                        </div>
                      </div>

                    {/* Relay Route Snippet */}
                    <div className="sm:w-64 p-3 rounded-xl bg-gray-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] shrink-0 text-xs">
                      <div className="font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center justify-between mb-2">
                        <span>DTN Relay Chain</span>
                        <span className="text-[10px] text-cyan-600 font-mono">
                          {sos.hops} Hops
                        </span>
                      </div>
                      <div className="space-y-1.5">
                        {(sos.relay_path || []).map((step, idx) => (
                          <div
                            key={idx}
                            className="flex items-center justify-between text-[11px] text-[#475569] dark:text-[#CBD5E1]"
                          >
                            <span className="truncate max-w-[130px] font-mono">{step.node}</span>
                            <span className="font-mono text-[10px] text-cyan-500">{step.rssi}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* 3. MESH RELAY & DTN HOP TOPOLOGY */}
      {/* ===================================================================== */}
      {activeSubTab === 'RELAY' && (
        <div className="space-y-4">
          <div className="p-3 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-between text-xs text-cyan-800 dark:text-cyan-300">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-cyan-500 shrink-0" />
              <span>
                <strong>Multi-Hop Store-and-Forward Telemetry:</strong> Physical hop progression through volunteer handsets & airborne drones.
              </span>
            </div>
            <span className="font-mono text-[11px]">Lossless Mesh Transport</span>
          </div>

          {(communications?.relay_topology || []).length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <Radio className="w-10 h-10 mx-auto text-cyan-500/60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Multi-Hop Routes Recorded</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                Packets for this incident were received via direct single-hop or gateway uplink without intermediate store-and-forward relay hops.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {(communications?.relay_topology || []).map((route: RelayTopologyRoute) => (
                <Card
                  key={route.route_id}
                  className="p-5 bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B]"
                >
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <h3 className="font-bold text-sm text-[#0F172A] dark:text-[#F8FAFC]">
                        Relay Route: {route.route_id}
                      </h3>
                      <span className="text-xs px-2 py-0.5 rounded font-mono bg-cyan-500/20 text-cyan-600 dark:text-cyan-400">
                        Origin: {route.origin_device}
                      </span>
                    </div>
                    <div className="flex items-center gap-3 text-xs font-mono">
                      <span className="text-[#64748B] dark:text-[#94A3B8]">
                        Latency: ~{route.estimated_latency_ms}ms
                      </span>
                      <span className="px-2 py-0.5 rounded font-bold bg-emerald-500/20 text-emerald-600">
                        {route.status}
                      </span>
                    </div>
                  </div>

                  {/* Node-by-node Chain Visual */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    {route.hops.map((hop, hidx) => (
                      <div
                        key={hidx}
                        className="p-3.5 rounded-xl bg-gray-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] relative"
                      >
                        <div className="flex items-center justify-between text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                          <span>Hop #{hop.hop_number}</span>
                          <span className="text-[10px] text-cyan-600 font-mono">
                            {hop.signal_dbm} dBm
                          </span>
                        </div>
                        <div className="text-xs font-mono text-[#0891B2] mt-1 font-semibold">
                          {hop.device_id}
                        </div>
                        <div className="text-[11px] text-[#64748B] dark:text-[#94A3B8] mt-0.5">
                          {hop.role}
                        </div>
                        <div className="mt-2 pt-2 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-between text-[10px] text-[#64748B]">
                          <span>Delay: +{hop.delay_ms}ms</span>
                          <span>Battery: {hop.battery}%</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* 4. CIVILIAN FIELD SITREPS */}
      {/* ===================================================================== */}
      {activeSubTab === 'SITREP' && (
        <div className="space-y-4">
          {(communications?.field_sitreps || []).length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <FileText className="w-10 h-10 mx-auto text-amber-500/60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Field SITREPs Submitted</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                No citizen or volunteer hazard reports have been submitted for this incident sector yet.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {(communications?.field_sitreps || []).map((sit: IncidentFieldSitrep) => (
                <Card
                  key={sit.id}
                  className="p-5 bg-white dark:bg-[#111A2E] border border-amber-500/30"
                >
                  <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-0.5 text-xs font-bold rounded-full bg-amber-500/20 text-amber-700 dark:text-amber-300">
                          {sit.category.replace('_', ' ')}
                        </span>
                        <h4 className="font-bold text-sm text-[#0F172A] dark:text-[#F8FAFC]">
                          {sit.location}
                        </h4>
                      </div>
                      <HumanReadablePayload
                        content={sit.notes}
                        title="SITREP"
                        category={sit.category}
                      />
                      <div className="mt-2.5 p-2 rounded-lg bg-amber-500/10 border border-amber-500/20 text-xs text-amber-800 dark:text-amber-200">
                        <strong>Reported operational action:</strong> {sit.actionable || 'Not reported'}
                      </div>
                    </div>

                    <div className="flex sm:flex-col items-end gap-1 text-[11px] text-[#64748B] dark:text-[#94A3B8] shrink-0 font-mono">
                      <span className="font-semibold text-slate-700 dark:text-slate-300">
                        {reportedTimestamp(sit.timestamp_display, sit.timestamp)}
                      </span>
                      <span>Reported by: {sit.reporter}</span>
                      <span>{reportedCoordinates(sit.lat, sit.lng)}</span>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* 5. RESCUE TEAM COMMUNICATIONS */}
      {/* ===================================================================== */}
      {activeSubTab === 'TEAM' && (
        <div className="space-y-4">
          {(communications?.team_comms || []).length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <MessageSquare className="w-10 h-10 mx-auto text-emerald-500/60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Rescue Team Dispatches</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                No command orders or tactical progress messages have been sent to field rescue units for this incident yet.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {(communications?.team_comms || []).map((tc: IncidentTeamComm) => (
                <Card
                  key={tc.id}
                  className="p-4 bg-white dark:bg-[#111A2E] border-emerald-500/30"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-600">
                          {tc.type}
                        </span>
                        <span className="text-xs font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                          {tc.sender} → {tc.recipient}
                        </span>
                      </div>
                      <p className="text-xs text-[#334155] dark:text-[#CBD5E1] mt-2 leading-relaxed">
                        "{tc.message}"
                      </p>
                    </div>
                    <div className="flex flex-col items-end text-[11px] font-mono text-[#64748B]">
                      <span>{reportedTimestamp(tc.timestamp_display, tc.timestamp)}</span>
                      <span className="text-emerald-500 font-bold">{tc.status}</span>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* 6. VOICE & AUDIO MEMOS */}
      {/* ===================================================================== */}
      {activeSubTab === 'VOICE' && (
        <div className="space-y-4">
          {(communications?.voice_transcriptions || []).length === 0 ? (
            <div className="p-8 text-center rounded-2xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B] space-y-2">
              <Mic className="w-10 h-10 mx-auto text-purple-500/60" />
              <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">No Audio Transcriptions</h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mx-auto">
                No voice memos or audio recordings have been captured from mesh handsets for this incident.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {(communications?.voice_transcriptions || []).map((vt: IncidentVoiceTranscription) => (
                <Card
                  key={vt.id}
                  className="p-4 bg-white dark:bg-[#111A2E] border-purple-500/30"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <Mic className="w-4 h-4 text-purple-500" />
                        <h4 className="font-bold text-sm text-[#0F172A] dark:text-[#F8FAFC]">
                          {vt.speaker} ({vt.duration_seconds}s audio)
                        </h4>
                        <span className="text-[10px] px-2 py-0.5 rounded-full bg-purple-500/20 text-purple-600 font-mono">
                          AI NLP Conf: {Math.round(vt.urgency_score * 100)}%
                        </span>
                      </div>

                      <p className="text-xs text-[#334155] dark:text-[#CBD5E1] mt-2 italic bg-purple-500/5 p-3 rounded-lg border border-purple-500/20">
                        "{vt.transcription}"
                      </p>

                      <div className="mt-2 flex flex-wrap items-center gap-1.5">
                        <span className="text-[11px] font-semibold text-[#64748B]">Extracted NLP Entities:</span>
                        {vt.nlp_extracted_entities.map((ent, eidx) => (
                          <span
                            key={eidx}
                            className="px-2 py-0.5 text-[10px] rounded bg-purple-500/10 text-purple-700 dark:text-purple-300 font-semibold"
                          >
                            {ent}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* TACTICAL MESH BROADCAST BAR */}
      {/* ===================================================================== */}
      <Card className="p-4 bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B]">
        <div className="flex items-center gap-2 mb-2">
          <Radio className="w-4 h-4 text-[#0891B2]" />
          <h4 className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC] uppercase tracking-wider">
            Broadcast Tactical Guidance to Incident Mesh Handsets
          </h4>
        </div>

        {broadcastSuccess && (
          <div className="mb-3 p-2.5 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{broadcastSuccess}</span>
          </div>
        )}

        <form onSubmit={handleSendBroadcast} className="flex gap-2">
          <input
            type="text"
            placeholder="Type evacuation advisory or responder instructions (e.g. Boat reaching House 42 in 5m)..."
            value={broadcastText}
            onChange={(e) => setBroadcastText(e.target.value)}
            className="flex-1 px-3 py-2 text-xs rounded-xl bg-white dark:bg-[#111A2E] border border-[#CBD5E1] dark:border-[#334155] text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:ring-2 focus:ring-[#FFD21F]"
          />
          <Button
            type="submit"
            disabled={isBroadcasting || !broadcastText.trim()}
            className="bg-[#0891B2] hover:bg-[#0e7490] text-white text-xs font-semibold flex items-center gap-1.5 shrink-0"
          >
            {isBroadcasting ? (
              <>
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                <span>Transmitting...</span>
              </>
            ) : (
              <>
                <Send className="w-3.5 h-3.5" />
                <span>Transmit over Mesh</span>
              </>
            )}
          </Button>
        </form>
      </Card>
    </div>
  );
};

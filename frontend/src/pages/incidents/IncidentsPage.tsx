import React, { useState, useMemo, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import L from 'leaflet';
import {
  AlertTriangle,
  Search,
  Filter,
  Users,
  MapPin,
  Clock,
  ArrowRight,
  RefreshCw,
  Radio,
  ShieldAlert,
  Layers,
  Map as MapIcon,
  LayoutGrid,
  CheckCircle2,
  Activity,
  Flame,
  Waves,
  Mountain,
  Building,
  Wind,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { incidentsApi } from '../../api/incidents.ts';
import { useWebSocket } from '../../hooks/useWebSocket';
import { useTheme } from '../../theme/ThemeContext.tsx';
import type { Incident } from '../../types/incident.ts';

export const IncidentsPage: React.FC = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { isDark } = useTheme();

  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [search, setSearch] = useState('');
  const [viewMode, setViewMode] = useState<'GRID' | 'MAP'>('GRID');
  const [isClustering, setIsClustering] = useState(false);
  const [clusterToast, setClusterToast] = useState<string | null>(null);

  // Map container reference
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);

  // 1. Live Incidents Query
  const {
    data: incidents = [],
    isLoading,
    isRefetching,
    refetch,
  } = useQuery<Incident[]>({
    queryKey: ['incidents'],
    queryFn: () => incidentsApi.getIncidents(),
    refetchInterval: 12000,
  });

  // 2. Real-time Gateway WebSocket Uplink Reaction
  const { status: wsStatus, lastMessage } = useWebSocket();
  useEffect(() => {
    if (!lastMessage) return;
    const ev = String((lastMessage as any).event);
    if (
      ev === 'NEW_PACKET_INGESTED' ||
      ev === 'INCIDENTS_UPDATED' ||
      ev === 'INCIDENT_ASSIGNED'
    ) {
      refetch();
    }
  }, [lastMessage, refetch]);

  // Recalculate DBSCAN clusters across edge mesh nodes
  const handleRecalculateClusters = async () => {
    setIsClustering(true);
    try {
      const res = await incidentsApi.triggerClustering(120.0, 2);
      queryClient.invalidateQueries({ queryKey: ['incidents'] });
      refetch();
      setClusterToast(
        `DBSCAN recalculation complete: ${res.incident_count || incidents.length} incident clusters synchronized.`
      );
      setTimeout(() => setClusterToast(null), 4000);
    } catch (err) {
      console.error('Failed to trigger DBSCAN clustering:', err);
    } finally {
      setIsClustering(false);
    }
  };

  // Filtered incidents
  const filtered = useMemo(() => {
    return incidents.filter((inc) => {
      const sev = (inc.severity || '').toUpperCase();
      const matchesSev = filterSeverity === 'ALL' || sev === filterSeverity;

      const st = (inc.status || '').toUpperCase();
      const matchesStatus =
        filterStatus === 'ALL' ||
        (filterStatus === 'ACTIVE' && (st === 'ACTIVE' || st === 'OPEN' || st === 'INVESTIGATING')) ||
        (filterStatus === 'DISPATCHED' && (st === 'DISPATCHED' || st === 'ASSIGNED' || st === 'IN_PROGRESS')) ||
        (filterStatus === 'RESOLVED' && (st === 'RESOLVED' || st === 'CONTAINED'));

      const q = search.toLowerCase().trim();
      const locStr =
        typeof inc.location === 'string'
          ? inc.location
          : inc.location?.address || '';
      const matchesSearch =
        !q ||
        inc.title?.toLowerCase().includes(q) ||
        locStr.toLowerCase().includes(q) ||
        inc.id?.toLowerCase().includes(q) ||
        String(inc.type || '').toLowerCase().includes(q);

      return matchesSev && matchesStatus && matchesSearch;
    });
  }, [incidents, filterSeverity, filterStatus, search]);

  // Metrics calculation
  const totalIncidents = incidents.length;
  const criticalCount = incidents.filter(
    (i) => (i.severity || '').toUpperCase() === 'CRITICAL'
  ).length;
  const totalCasualties = incidents.reduce(
    (acc, i) => acc + (i.affectedPeople || i.people_count || 0),
    0
  );
  const totalHandsets = incidents.reduce(
    (acc, i) => acc + (i.devicesCount || i.devices_count || 0),
    0
  );

  // Initialize and update tactical Leaflet overview map
  useEffect(() => {
    if (viewMode !== 'MAP' || !mapContainerRef.current) return;

    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
    }

    // Centroid of incidents or center of India
    const defaultLat = filtered[0]?.coordinates?.lat || 22.5937;
    const defaultLng = filtered[0]?.coordinates?.lng || 78.9629;
    const initialZoom = filtered.length === 1 ? 14 : filtered.length > 1 ? 6 : 5;

    const map = L.map(mapContainerRef.current, {
      center: [defaultLat, defaultLng],
      zoom: initialZoom,
      zoomControl: true,
    });
    mapInstanceRef.current = map;

    const tileUrl = isDark
      ? 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
      : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    L.tileLayer(tileUrl, {
      attribution: '&copy; OpenStreetMap contributors, RakshaNet Tactical',
      maxZoom: 19,
    }).addTo(map);

    filtered.forEach((inc) => {
      const lat = inc.coordinates?.lat || (inc as any).lat || 30.1458;
      const lng = inc.coordinates?.lng || (inc as any).lng || 78.2982;
      const sev = (inc.severity || 'HIGH').toUpperCase();
      const color =
        sev === 'CRITICAL'
          ? '#EF4444'
          : sev === 'HIGH'
          ? '#F59E0B'
          : '#06B6D4';
      const radiusM = inc.clusterRadiusMeters || 600;

      // Geofence circle
      L.circle([lat, lng], {
        radius: radiusM,
        color: color,
        weight: 2,
        dashArray: '4, 4',
        fillColor: color,
        fillOpacity: 0.2,
      }).addTo(map);

      // Custom Pulsating Pin
      const icon = L.divIcon({
        className: 'incident-cluster-pin',
        html: `
          <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
            <div style="position: absolute; width: 32px; height: 32px; border-radius: 50%; background: ${color}; opacity: 0.35; animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
            <div style="width: 22px; height: 22px; border-radius: 50%; background: ${color}; border: 2.5px solid white; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.5);">
              !
            </div>
          </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      });

      const marker = L.marker([lat, lng], { icon }).addTo(map);
      marker.bindPopup(`
        <div style="min-width: 220px; font-family: sans-serif; padding: 2px;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px;">
            <span style="font-weight: 800; font-size: 11px; color: ${color};">${sev}</span>
            <span style="font-size: 10px; background: #e2e8f0; padding: 1px 6px; border-radius: 4px; font-family: monospace;">${inc.id}</span>
          </div>
          <h4 style="margin: 0 0 6px 0; font-size: 13px; font-weight: 700; color: #0f172a;">${inc.title}</h4>
          <div style="font-size: 11px; color: #475569; margin-bottom: 8px;">
            <div>👥 <strong>~${inc.affectedPeople || inc.people_count || 0}</strong> casualties estimated</div>
            <div>📡 <strong>${inc.devicesCount || inc.devices_count || 0}</strong> active mesh handsets</div>
          </div>
          <a href="/app/incidents/${inc.id}" style="display: inline-block; width: 100%; text-align: center; background: #0891b2; color: white; text-decoration: none; font-size: 11px; font-weight: 700; padding: 6px 0; border-radius: 6px;">
            Open Mesh Communications & Map →
          </a>
        </div>
      `);
    });

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [viewMode, filtered, isDark]);

  const getDisasterIcon = (type: string) => {
    const t = (type || '').toLowerCase();
    if (t.includes('flood') || t.includes('water')) {
      return <Waves className="w-4 h-4 text-cyan-500" />;
    }
    if (t.includes('fire')) {
      return <Flame className="w-4 h-4 text-orange-500" />;
    }
    if (t.includes('landslide') || t.includes('mountain')) {
      return <Mountain className="w-4 h-4 text-amber-500" />;
    }
    if (t.includes('collapse') || t.includes('building')) {
      return <Building className="w-4 h-4 text-stone-500" />;
    }
    if (t.includes('cyclone') || t.includes('wind')) {
      return <Wind className="w-4 h-4 text-blue-500" />;
    }
    return <AlertTriangle className="w-4 h-4 text-rose-500" />;
  };

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {clusterToast && (
        <div className="fixed top-5 right-5 z-50 animate-in fade-in slide-in-from-top-4 duration-300">
          <div className="flex items-center gap-2 px-4 py-3 rounded-xl bg-emerald-600 text-white shadow-xl border border-emerald-500 font-medium text-sm">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <span>{clusterToast}</span>
            <button
              onClick={() => setClusterToast(null)}
              className="ml-2 hover:opacity-80"
              aria-label="Dismiss alert"
            >
              ×
            </button>
          </div>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Radio className="w-5 h-5 text-[#0891B2] animate-pulse" />
            <span className="text-xs font-mono font-bold text-[#8A5A00] dark:text-[#FFD21F] uppercase tracking-wider">
              Disaster Response Command
            </span>
            <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30 flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span>{wsStatus === 'connected' ? 'Live Mesh Synchronized' : 'Gateway Polling'}</span>
            </span>
          </div>

          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight mt-1"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Incident Command & Mesh Clusters
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            DBSCAN-correlated distress tickets, hop-by-hop mesh telemetry, and multi-channel rescue extractions
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* View Switcher: Grid vs Map */}
          <div className="flex items-center p-1 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-sm">
            <button
              onClick={() => setViewMode('GRID')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'GRID'
                  ? 'bg-[#FFD21F] text-[#0B1220] shadow-sm'
                  : 'text-[#64748B] dark:text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-white'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              <span>Grid View</span>
            </button>
            <button
              onClick={() => setViewMode('MAP')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'MAP'
                  ? 'bg-[#FFD21F] text-[#0B1220] shadow-sm'
                  : 'text-[#64748B] dark:text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-white'
              }`}
            >
              <MapIcon className="w-3.5 h-3.5" />
              <span>Tactical Map</span>
            </button>
          </div>

          {/* Trigger DBSCAN Reclustering */}
          <Button
            variant="secondary"
            size="md"
            disabled={isClustering || isRefetching}
            leftIcon={<RefreshCw size={16} className={isClustering || isRefetching ? 'animate-spin text-[#0891B2]' : ''} />}
            onClick={handleRecalculateClusters}
          >
            {isClustering ? 'Recalculating...' : 'Re-cluster Signals'}
          </Button>
        </div>
      </div>

      {/* KPI Summary Strip */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-sm">
          <div className="flex items-center justify-between text-xs text-[#64748B] dark:text-[#94A3B8]">
            <span>Active Incidents</span>
            <Activity className="w-4 h-4 text-cyan-500" />
          </div>
          <div className="text-2xl font-black text-[#16202D] dark:text-white mt-1">
            {totalIncidents}
          </div>
          <div className="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold mt-0.5">
            Geofenced Sector Tickets
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-red-500/30 bg-red-500/5 shadow-sm">
          <div className="flex items-center justify-between text-xs text-red-600 dark:text-red-400">
            <span>Critical Triage Priority</span>
            <ShieldAlert className="w-4 h-4 text-red-500 animate-pulse" />
          </div>
          <div className="text-2xl font-black text-red-600 dark:text-red-400 mt-1">
            {criticalCount}
          </div>
          <div className="text-[11px] text-red-700/80 dark:text-red-300 font-semibold mt-0.5">
            Immediate Extraction Required
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-sm">
          <div className="flex items-center justify-between text-xs text-[#64748B] dark:text-[#94A3B8]">
            <span>Souls at Risk (Casualties)</span>
            <Users className="w-4 h-4 text-amber-500" />
          </div>
          <div className="text-2xl font-black text-[#16202D] dark:text-white mt-1">
            ~{totalCasualties}
          </div>
          <div className="text-[11px] text-[#64748B] dark:text-[#94A3B8] font-semibold mt-0.5">
            Statistical Poisson Estimate
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-sm">
          <div className="flex items-center justify-between text-xs text-[#64748B] dark:text-[#94A3B8]">
            <span>Active Mesh Handsets</span>
            <Radio className="w-4 h-4 text-[#0891B2]" />
          </div>
          <div className="text-2xl font-black text-[#16202D] dark:text-white mt-1">
            {totalHandsets}
          </div>
          <div className="text-[11px] text-cyan-600 dark:text-cyan-400 font-semibold mt-0.5">
            DTN Store-and-Forward Mules
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3 p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-sm">
        <div className="relative flex-1">
          <Search
            size={16}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search incident ticket ID, title, location, disaster type..."
            className="w-full h-10 pl-10 pr-4 text-xs rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Status Filter */}
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="h-10 px-3 text-xs font-semibold rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          >
            <option value="ALL">All Statuses</option>
            <option value="ACTIVE">🔴 Active / Open</option>
            <option value="DISPATCHED">🟡 Dispatched / Assigned</option>
            <option value="RESOLVED">🟢 Resolved / Contained</option>
          </select>

          {/* Severity Pills */}
          <div className="flex items-center gap-1.5 overflow-x-auto">
            {['ALL', 'CRITICAL', 'HIGH', 'MEDIUM'].map((sev) => (
              <button
                key={sev}
                onClick={() => setFilterSeverity(sev)}
                className={`px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                  filterSeverity === sev
                    ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                    : 'text-[#566070] dark:text-[#9FADC2] hover:bg-black/5 dark:hover:bg-white/5 border border-transparent'
                }`}
              >
                {sev === 'ALL' ? 'All Severities' : sev}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content: Map or Grid */}
      {viewMode === 'MAP' ? (
        <Card className="p-4 bg-white dark:bg-[#162036] border-[#E6DCA8] dark:border-[#26344F] shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-[#16202D] dark:text-white">
                Territory Disaster Map & Clustered Zones ({filtered.length})
              </h3>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                Interactive geographic overview showing active DBSCAN clusters, casualty zones, and mesh geofences
              </p>
            </div>
            <span className="text-xs font-mono font-bold text-cyan-600 dark:text-cyan-400">
              Click pins to inspect incident details
            </span>
          </div>

          <div
            ref={mapContainerRef}
            className="w-full rounded-xl overflow-hidden border border-[#CBD5E1] dark:border-[#1E293B]"
            style={{ height: '560px' }}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((inc) => {
            const isCritical = (inc.severity || '').toUpperCase() === 'CRITICAL';
            const locationStr =
              typeof inc.location === 'string'
                ? inc.location
                : inc.location?.address ||
                  (inc.coordinates
                    ? `${inc.coordinates.lat.toFixed(3)}° N, ${inc.coordinates.lng.toFixed(3)}° E`
                    : 'Tactical Area');

            const statusStr = (inc.status || 'ACTIVE').toUpperCase();
            const casualtyCount = inc.affectedPeople || inc.people_count || 0;
            const deviceCount = inc.devicesCount || inc.devices_count || 0;

            return (
              <Card
                key={inc.id}
                variant="alert"
                alertColor={isCritical ? 'red' : inc.severity === 'HIGH' ? 'yellow' : 'teal'}
                className="cursor-pointer hover:shadow-lg transition-all flex flex-col justify-between group border hover:border-[#FFD21F] dark:hover:border-[#FFD21F]"
                onClick={() => navigate(`/app/incidents/${inc.id}`)}
              >
                <div>
                  {/* Top Bar with ID, Disaster Icon, and Status */}
                  <div className="flex items-center justify-between mb-2.5">
                    <div className="flex items-center gap-2">
                      {getDisasterIcon(inc.type || inc.disaster_type || '')}
                      <span className="font-mono text-xs font-bold text-[#8A5A00] dark:text-[#FFD21F]">
                        {inc.id}
                      </span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                          statusStr === 'ACTIVE' || statusStr === 'OPEN'
                            ? 'bg-red-500/15 text-red-600 dark:text-red-400 border-red-500/30'
                            : statusStr === 'DISPATCHED' || statusStr === 'ASSIGNED'
                            ? 'bg-cyan-500/15 text-cyan-600 dark:text-cyan-400 border-cyan-500/30'
                            : 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                        }`}
                      >
                        {statusStr}
                      </span>
                      <Badge severity={inc.severity} label={inc.severity} />
                    </div>
                  </div>

                  {/* Title & Description */}
                  <h3
                    className="text-base sm:text-lg font-bold text-[#16202D] dark:text-white leading-tight mb-2 group-hover:text-[#0891B2] transition-colors"
                    style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                  >
                    {inc.title}
                  </h3>

                  <p className="text-xs text-[#566070] dark:text-[#9FADC2] line-clamp-2 mb-4 leading-relaxed">
                    {inc.description}
                  </p>
                </div>

                {/* Footer Metrics & Detail Link */}
                <div className="pt-3 border-t border-[#E6DCA8]/60 dark:border-[#26344F]/60 space-y-2">
                  <div className="flex items-center justify-between text-xs text-[#566070] dark:text-[#9FADC2]">
                    <span className="flex items-center gap-1 font-semibold text-[#16202D] dark:text-white">
                      <Users size={14} className="text-[#0E8A94]" /> ~{casualtyCount} souls
                    </span>
                    <span className="flex items-center gap-1 font-mono text-[#0891B2]">
                      <Radio size={14} /> {deviceCount} mesh nodes
                    </span>
                  </div>

                  <div className="flex items-center justify-between text-xs text-[#566070] dark:text-[#9FADC2]">
                    <span className="flex items-center gap-1 truncate max-w-[180px]">
                      <MapPin size={13} className="shrink-0 text-amber-500" />
                      <span className="truncate">{locationStr}</span>
                    </span>

                    <span className="font-bold text-[#8A5A00] dark:text-[#FFD21F] group-hover:translate-x-1 transition-transform flex items-center gap-1 shrink-0">
                      View Comms & Map <ArrowRight size={13} />
                    </span>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default IncidentsPage;

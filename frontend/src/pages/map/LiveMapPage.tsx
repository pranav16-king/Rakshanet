import React, { useState, useMemo, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate, Link, useSearchParams } from 'react-router-dom';
import {
  Search,
  Layers,
  Radio,
  Eye,
  EyeOff,
  RefreshCw,
  ShieldAlert,
  Users,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { MapCanvas } from '../../components/map/MapCanvas';
import { NodeDetailDrawer } from '../../components/map/NodeDetailDrawer';
import { LiveDeviceItem } from '../../components/map/LiveDeviceItem';
import {
  fetchMapIncidents,
  fetchLiveDevices,
  fetchDeviceStats,
  fetchRescueTeams,
} from '../../api/map';
import type {
  MapIncidentNode,
  LiveDevice,
  RescueTeam,
  MapLayersState,
} from '../../types/map';
import { isValidCoordinate } from '../../utils/geoNavigation';

export const LiveMapPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  // URL query parameter coordinates for direct map panning from toast/external links
  const queryLat = searchParams.get('lat') ? parseFloat(searchParams.get('lat')!) : null;
  const queryLng = searchParams.get('lng') ? parseFloat(searchParams.get('lng')!) : null;
  const queryFocus = searchParams.get('focus');

  const mapCenter = useMemo((): [number, number] | undefined => {
    if (
      queryLat !== null &&
      queryLng !== null &&
      isValidCoordinate(queryLat, queryLng)
    ) {
      return [queryLat, queryLng];
    }
    return undefined;
  }, [queryLat, queryLng]);

  // Active Layers State
  const [activeLayers, setActiveLayers] = useState<MapLayersState>({
    users: true,
    nearbyDevices: true,
    incidents: true,
    rescueTeams: true,
    meshConnections: true,
    hazardZones: true,
  });

  // Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [severityFilter, setSeverityFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Selected Entities
  const [selectedIncident, setSelectedIncident] = useState<MapIncidentNode | null>(null);
  const [selectedDevice, setSelectedDevice] = useState<LiveDevice | null>(null);
  const [selectedRescueTeam, setSelectedRescueTeam] = useState<RescueTeam | null>(null);

  // Queries for real backend data (Polling every 6-12s for live mesh refresh)
  const {
    data: incidents = [],
    isLoading: isIncidentsLoading,
    isFetching: isIncidentsFetching,
    refetch: refetchIncidents,
  } = useQuery({
    queryKey: ['map-incidents'],
    queryFn: fetchMapIncidents,
    refetchInterval: 6000,
  });

  const {
    data: devices = [],
    isLoading: isDevicesLoading,
    refetch: refetchDevices,
  } = useQuery({
    queryKey: ['live-devices'],
    queryFn: fetchLiveDevices,
    refetchInterval: 6000,
  });

  const {
    data: deviceStats = { total: 0, online: 0, relay: 0, offline: 0 },
    refetch: refetchStats,
  } = useQuery({
    queryKey: ['device-stats'],
    queryFn: fetchDeviceStats,
    refetchInterval: 10000,
  });

  const {
    data: rescueTeams = [],
    refetch: refetchTeams,
  } = useQuery({
    queryKey: ['rescue-teams'],
    queryFn: fetchRescueTeams,
    refetchInterval: 15000,
  });

  // Focus node synchronization if specified in URL query
  useEffect(() => {
    if (queryFocus && incidents.length > 0) {
      const match = incidents.find((i) => i.id === queryFocus);
      if (match) {
        setSelectedIncident(match);
        setSelectedDevice(null);
        setSelectedRescueTeam(null);
      }
    }
  }, [queryFocus, incidents]);

  const handleRefreshAll = () => {
    refetchIncidents();
    refetchDevices();
    refetchStats();
    refetchTeams();
  };

  const toggleLayer = (layer: keyof MapLayersState) => {
    setActiveLayers((prev) => ({ ...prev, [layer]: !prev[layer] }));
  };

  // Filtered Devices
  const filteredDevices = useMemo(() => {
    return devices.filter((d) => {
      const query = searchQuery.trim().toLowerCase();
      const matchesSearch =
        !query ||
        d.id.toLowerCase().includes(query) ||
        d.name.toLowerCase().includes(query) ||
        d.location.toLowerCase().includes(query) ||
        d.type.toLowerCase().includes(query);

      const matchesStatus =
        statusFilter === 'ALL' || d.status.toLowerCase() === statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    });
  }, [devices, searchQuery, statusFilter]);

  // Filtered Incidents
  const filteredIncidents = useMemo(() => {
    return incidents.filter((inc) => {
      const query = searchQuery.trim().toLowerCase();
      const matchesSearch =
        !query ||
        inc.id.toLowerCase().includes(query) ||
        inc.title.toLowerCase().includes(query) ||
        (inc.description && inc.description.toLowerCase().includes(query)) ||
        inc.badgeLabel.toLowerCase().includes(query);

      const matchesSeverity =
        severityFilter === 'ALL' || inc.severity === severityFilter;

      return matchesSearch && matchesSeverity;
    });
  }, [incidents, searchQuery, severityFilter]);

  // Active SOS Beacon count
  const activeSosCount = useMemo(() => {
    return incidents.filter(
      (inc) =>
        inc.type === 'sos' ||
        inc.severity === 'CRITICAL' ||
        inc.badgeLabel.toLowerCase().includes('sos') ||
        inc.title.toLowerCase().includes('sos')
    ).length;
  }, [incidents]);

  // Dynamic Sector Centroid Readout
  const sectorCoordinates = useMemo(() => {
    const validCoords: [number, number][] = [];
    incidents.forEach((i) => {
      if (isValidCoordinate(i.lat, i.lng)) validCoords.push([i.lat, i.lng]);
    });
    devices.forEach((d) => {
      if (isValidCoordinate(d.lat, d.lng)) validCoords.push([d.lat, d.lng]);
    });
    if (validCoords.length === 0) return 'Coordinates unavailable';

    const avgLat = validCoords.reduce((a, b) => a + b[0], 0) / validCoords.length;
    const avgLng = validCoords.reduce((a, b) => a + b[1], 0) / validCoords.length;
    return `${avgLat.toFixed(4)}° N, ${avgLng.toFixed(4)}° E · WGS84`;
  }, [incidents, devices]);

  const layerDefinitions: Array<{
    key: keyof MapLayersState;
    label: string;
    dotColor: string;
    count?: number;
  }> = [
    { key: 'users', label: 'Users & Civilians', dotColor: 'bg-emerald-500', count: deviceStats.total },
    { key: 'nearbyDevices', label: 'Mesh Devices', dotColor: 'bg-blue-500', count: devices.length },
    { key: 'incidents', label: 'Distress Incidents', dotColor: 'bg-red-500', count: incidents.length },
    { key: 'rescueTeams', label: 'Rescue Teams', dotColor: 'bg-teal-500', count: rescueTeams.length },
    { key: 'meshConnections', label: 'Mesh Radio Links', dotColor: 'bg-cyan-400' },
    { key: 'hazardZones', label: 'Hazard & Inundation Zones', dotColor: 'bg-amber-500' },
  ];

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1
              className="text-2xl sm:text-3xl font-black text-[#0F172A] dark:text-white tracking-tight"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Live Map & Devices
            </h1>
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-300 dark:border-emerald-800">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              Live Telemetry
            </span>
            {activeSosCount > 0 && (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-black bg-red-600 text-white animate-pulse shadow-md">
                <ShieldAlert size={12} />
                {activeSosCount} ACTIVE SOS
              </span>
            )}
          </div>
          <p className="text-xs sm:text-sm text-[#64748B] dark:text-[#9FADC2]">
            Real-time geospatial locations of mesh nodes, rescue units, rapid response direction vectors & disaster incidents
          </p>
        </div>

        {/* Filter bar */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Search box */}
          <div className="relative">
            <Search
              size={15}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 dark:text-[#9FADC2]"
            />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search node, ID, incident..."
              className="h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            />
          </div>

          {/* Severity filter */}
          <select
            value={severityFilter}
            onChange={(e) => setSeverityFilter(e.target.value)}
            className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-semibold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
          >
            <option value="ALL">All Severities</option>
            <option value="CRITICAL">Critical Only</option>
            <option value="HIGH">High Severity</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
          </select>

          {/* Device status filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-semibold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
          >
            <option value="ALL">All Devices</option>
            <option value="Online">Online</option>
            <option value="Relay">Relay Nodes</option>
            <option value="Offline">Offline</option>
          </select>

          {/* Refresh button */}
          <button
            type="button"
            onClick={handleRefreshAll}
            aria-label="Refresh live data"
            className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-bold text-slate-900 dark:text-white hover:bg-slate-100 dark:hover:bg-[#1C2844] transition-colors flex items-center gap-1.5 cursor-pointer shadow-xs"
            title="Force refresh live map telemetry"
          >
            <RefreshCw
              size={14}
              className={`${isIncidentsFetching ? 'animate-spin text-[#FFC400]' : ''}`}
            />
            <span className="hidden sm:inline">Refresh</span>
          </button>
        </div>
      </div>

      {/* Main Map + Right Side Panel Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 relative">
        {/* Map View Canvas Container */}
        <div className="lg:col-span-8 xl:col-span-9 relative">
          <div className="relative h-[650px] w-full rounded-2xl bg-[#0B1220] border-2 border-slate-200 dark:border-[#26344F] overflow-hidden shadow-xl">
            {/* Interactive Real MapCanvas */}
            <MapCanvas
              center={mapCenter}
              zoom={mapCenter ? 15 : 13}
              incidents={filteredIncidents}
              devices={filteredDevices}
              rescueTeams={rescueTeams}
              layers={activeLayers}
              selectedIncident={selectedIncident}
              selectedDevice={selectedDevice}
              selectedRescueTeam={selectedRescueTeam}
              onSelectIncident={(inc) => {
                setSelectedIncident(inc);
                setSelectedDevice(null);
                setSelectedRescueTeam(null);
              }}
              onSelectDevice={(dev) => {
                setSelectedDevice(dev);
                setSelectedIncident(null);
                setSelectedRescueTeam(null);
              }}
              onSelectRescueTeam={(team) => {
                setSelectedRescueTeam(team);
                setSelectedIncident(null);
                setSelectedDevice(null);
              }}
            />

            {/* Empty State Banner if 0 active incidents */}
            {incidents.length === 0 && !isIncidentsLoading && (
              <div className="absolute top-4 left-1/2 -translate-x-1/2 z-[400] px-4 py-2 rounded-xl bg-[#0B1220]/90 backdrop-blur-md border border-[#26344F] text-white shadow-lg flex items-center gap-2.5 text-xs">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>No active distress beacons in sector · Mesh radio scanning active (DBSCAN ε=120m)</span>
              </div>
            )}

            {/* Bottom Status Ribbon */}
            <div className="absolute bottom-4 left-4 right-4 z-[400] px-4 py-2.5 rounded-xl bg-[#0B1220]/90 backdrop-blur-md border border-[#26344F] flex flex-wrap items-center justify-between gap-3 text-xs text-white shadow-lg">
              <div className="flex items-center gap-3">
                <span className="w-2.5 h-2.5 rounded-full bg-[#4CD08A] animate-ping" />
                <span className="font-medium">
                  Mesh Radio Telemetry:{' '}
                  <strong className="text-emerald-400 font-bold">
                    {deviceStats.online + deviceStats.relay} Active Nodes
                  </strong>{' '}
                  ({deviceStats.online} Online, {deviceStats.relay} Relaying)
                </span>
                {activeSosCount > 0 && (
                  <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-red-600/30 text-red-300 border border-red-500/50 font-bold text-[11px] animate-pulse">
                    <span className="w-2 h-2 rounded-full bg-red-500" />
                    {activeSosCount} Active SOS Vector{activeSosCount > 1 ? 's' : ''} Synced
                  </span>
                )}
              </div>
              <div className="text-[11px] text-[#9FADC2] font-mono flex items-center gap-2">
                <span>Sector Centroid: {sectorCoordinates}</span>
                <span className="hidden md:inline px-2 py-0.5 rounded bg-[#162036] text-[10px] text-amber-300">
                  {filteredIncidents.length} Clustered Incident(s)
                </span>
              </div>
            </div>
          </div>

          {/* Node Detail Drawer Floating Overlay */}
          <NodeDetailDrawer
            selectedNode={
              selectedIncident ||
              (selectedRescueTeam
                ? {
                    id: selectedRescueTeam.id,
                    title: selectedRescueTeam.name,
                    type: 'rescue_team',
                    badgeLabel: 'Rescue Unit',
                    countLabel: `${selectedRescueTeam.membersCount} Responders`,
                    lat: selectedRescueTeam.lat,
                    lng: selectedRescueTeam.lng,
                    severity: 'LOW',
                    description: `Status: ${selectedRescueTeam.status} · Leader: ${selectedRescueTeam.leader || 'Field Lead'} · Contact: ${selectedRescueTeam.contact || 'VHF 156.8 MHz'} · Capabilities: ${selectedRescueTeam.capabilities?.join(', ') || 'Tactical Search & Rescue'}`,
                    reportedAgo: 'Active team',
                  }
                : null)
            }
            selectedDevice={selectedDevice}
            onClose={() => {
              setSelectedIncident(null);
              setSelectedDevice(null);
              setSelectedRescueTeam(null);
            }}
            onViewDetails={(id) => {
              navigate(`/app/incidents/${encodeURIComponent(id)}`);
            }}
            onAssignTeam={(id) => {
              navigate(`/app/incidents/${encodeURIComponent(id)}`);
            }}
          />
        </div>

        {/* Right Side Panel: Layers & Live Devices */}
        <div className="lg:col-span-4 xl:col-span-3 space-y-6">
          {/* Map Layers Card */}
          <Card>
            <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-200 dark:border-[#26344F]">
              <div className="flex items-center gap-2">
                <Layers size={18} className="text-amber-600 dark:text-[#FFD21F]" />
                <h3 className="text-sm font-bold text-slate-900 dark:text-white">
                  Map Layers
                </h3>
              </div>
              <span className="text-[11px] font-semibold text-slate-500 dark:text-[#9FADC2]">
                {Object.values(activeLayers).filter(Boolean).length}/6 Active
              </span>
            </div>

            <div className="space-y-2">
              {layerDefinitions.map((item) => {
                const isChecked = activeLayers[item.key];
                return (
                  <div
                    key={item.key}
                    onClick={() => toggleLayer(item.key)}
                    className="flex items-center justify-between p-2 rounded-lg hover:bg-black/5 dark:hover:bg-[#0E1627] cursor-pointer transition-colors"
                  >
                    <div className="flex items-center gap-2.5">
                      <span className={`w-2.5 h-2.5 rounded-full ${item.dotColor} shadow-2xs`} />
                      <span className="text-xs font-semibold text-slate-900 dark:text-[#EEF2F8]">
                        {item.label}
                      </span>
                      {item.count !== undefined && (
                        <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-gray-100 dark:bg-[#1E293B] text-gray-600 dark:text-gray-300">
                          {item.count}
                        </span>
                      )}
                    </div>
                    <button
                      type="button"
                      aria-label={`Toggle layer ${item.label}`}
                      className="text-amber-600 dark:text-[#FFD21F] cursor-pointer"
                    >
                      {isChecked ? (
                        <Eye size={16} />
                      ) : (
                        <EyeOff size={16} className="text-slate-400 dark:text-gray-500" />
                      )}
                    </button>
                  </div>
                );
              })}
            </div>
          </Card>

          {/* Live Devices Card with Real Data */}
          <Card>
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-slate-200 dark:border-[#26344F]">
              <div className="flex items-center gap-2">
                <Radio size={18} className="text-[#0E8A94] dark:text-[#3CC6D0]" />
                <h3 className="text-sm font-bold text-slate-900 dark:text-white">
                  Live Devices ({deviceStats.total || devices.length})
                </h3>
              </div>
              <Link
                to="/app/devices"
                className="text-[11px] font-bold text-amber-600 dark:text-[#FFD21F] hover:underline"
              >
                View All
              </Link>
            </div>

            {/* Quick Status Breakdown */}
            <div className="grid grid-cols-3 gap-2 mb-3">
              <div className="p-2 rounded-lg bg-emerald-50 dark:bg-[#0F3322]/50 border border-emerald-200 dark:border-emerald-900/50 text-center">
                <span className="block text-xs font-black text-[#1E8E4E] dark:text-[#4CD08A]">
                  {deviceStats.online}
                </span>
                <span className="text-[10px] text-emerald-800 dark:text-emerald-300 font-medium">
                  Online
                </span>
              </div>
              <div className="p-2 rounded-lg bg-cyan-50 dark:bg-[#0F3037]/50 border border-cyan-200 dark:border-cyan-900/50 text-center">
                <span className="block text-xs font-black text-[#0E8A94] dark:text-[#3CC6D0]">
                  {deviceStats.relay}
                </span>
                <span className="text-[10px] text-cyan-800 dark:text-cyan-300 font-medium">
                  Relay
                </span>
              </div>
              <div className="p-2 rounded-lg bg-gray-50 dark:bg-[#162036] border border-gray-200 dark:border-gray-800 text-center">
                <span className="block text-xs font-black text-gray-600 dark:text-gray-400">
                  {deviceStats.offline}
                </span>
                <span className="text-[10px] text-gray-500 font-medium">
                  Offline
                </span>
              </div>
            </div>

            {/* Real Scrollable Device List */}
            <div className="space-y-2 max-h-[380px] overflow-y-auto pr-1">
              {filteredDevices.length > 0 ? (
                filteredDevices.map((d) => (
                  <LiveDeviceItem
                    key={d.id}
                    device={d}
                    isSelected={selectedDevice?.id === d.id}
                    onSelect={(device) => {
                      setSelectedDevice(device);
                      setSelectedIncident(null);
                      setSelectedRescueTeam(null);
                    }}
                  />
                ))
              ) : isDevicesLoading ? (
                <div className="py-8 text-center text-xs text-slate-400 dark:text-[#9FADC2]">
                  Scanning mesh spectrum for active nodes...
                </div>
              ) : (
                <div className="py-8 text-center px-3 rounded-xl bg-gray-50 dark:bg-[#0E1627] border border-dashed border-slate-200 dark:border-[#26344F]">
                  <AlertTriangle className="w-6 h-6 text-amber-500 mx-auto mb-2 opacity-80" />
                  <p className="text-xs font-semibold text-slate-900 dark:text-white">
                    No active distress beacons in sector
                  </p>
                  <p className="text-[11px] text-slate-500 dark:text-[#9FADC2] mt-1">
                    Mesh radio scanning active · Waiting for BLE/LoRa peer handshake
                  </p>
                </div>
              )}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default LiveMapPage;

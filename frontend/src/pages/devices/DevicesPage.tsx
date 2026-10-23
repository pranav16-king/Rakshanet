import React, { useState, useEffect, useCallback } from 'react';
import {
  Search,
  Smartphone,
  Tablet,
  Radio,
  Share2,
  RefreshCw,
  Eye,
  Activity,
  Layers,
  FileText,
  MapPin,
  Wifi,
  CheckCircle2,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { KpiCard } from '../../components/common/KpiCard';
import { devicesApi } from '../../api/devices';
import type {
  Device,
  DeviceSummaryMetrics,
  NetworkTopologyNode,
  ConnectionLog,
  DeviceType,
  DeviceStatus,
} from '../../types/devices';
import { DeviceDetailDrawer } from '../../components/devices/DeviceDetailDrawer';
import { NetworkTopology } from '../../components/devices/NetworkTopology';
import { ConnectionLogsTable } from '../../components/devices/ConnectionLogsTable';

export const DevicesPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'Device List' | 'Network Topology' | 'Connection Logs'>(
    'Device List'
  );
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [typeFilter, setTypeFilter] = useState<string>('All');
  const [search, setSearch] = useState<string>('');

  const [devices, setDevices] = useState<Device[]>([]);
  const [topologyNodes, setTopologyNodes] = useState<NetworkTopologyNode[]>([]);
  const [connectionLogs, setConnectionLogs] = useState<ConnectionLog[]>([]);
  const [selectedDevice, setSelectedDevice] = useState<Device | null>(null);

  const [metrics, setMetrics] = useState<DeviceSummaryMetrics>({
    totalDevices: 0,
    onlineCount: 0,
    onlinePercent: 0,
    relayCount: 0,
    relayPercent: 0,
    offlineCount: 0,
    offlinePercent: 0,
  });
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Fetch real data from backend
  const loadData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [devList, summary, topo, logs] = await Promise.all([
        devicesApi.getDevices(typeFilter, statusFilter, search),
        devicesApi.getSummaryMetrics(),
        devicesApi.getTopology(),
        devicesApi.getConnectionLogs(),
      ]);
      setDevices(devList);
      setMetrics(summary);
      setTopologyNodes(topo);
      setConnectionLogs(logs);
    } catch {
      // Handled in api
    } finally {
      setIsLoading(false);
    }
  }, [typeFilter, statusFilter, search]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleDeviceClick = (dev: Device) => {
    setSelectedDevice(dev);
  };

  const getHardwareIcon = (type: DeviceType) => {
    switch (type) {
      case 'Tablet':
        return <Tablet size={15} className="text-purple-500 shrink-0" />;
      case 'Satellite Uplink':
        return <Radio size={15} className="text-amber-500 shrink-0" />;
      case 'Relay Beacon':
        return <Share2 size={15} className="text-cyan-500 shrink-0" />;
      default:
        return <Smartphone size={15} className="text-blue-500 shrink-0" />;
    }
  };

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
              Devices & Network Telemetry
            </h1>
            <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-500/30 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>{metrics.onlineCount} Mesh Nodes Active</span>
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-[#9FADC2] mt-0.5">
            Real-time tracking of handsets, solar relay beacons, tactical satellite hubs, and opportunistic data mules
          </p>
        </div>

        <button
          onClick={() => loadData()}
          disabled={isLoading}
          className="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs font-bold text-slate-700 dark:text-[#EEF2F8] hover:border-amber-400 hover:text-slate-900 dark:hover:text-white transition-all cursor-pointer shadow-2xs disabled:opacity-60"
        >
          <RefreshCw size={14} className={isLoading ? 'animate-spin text-amber-500' : ''} />
          <span>Refresh Telemetry</span>
        </button>
      </div>

      {/* Top 4 Real Metrics Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <KpiCard
          title="Total Registered Nodes"
          value={metrics.totalDevices}
          icon={Layers}
          accentColor="teal"
          isLoading={isLoading}
        />
        <KpiCard
          title="Online Reachable"
          value={metrics.onlineCount}
          deltaYesterdayPct={metrics.onlinePercent}
          icon={CheckCircle2}
          accentColor="green"
          isLoading={isLoading}
        />
        <KpiCard
          title="Active Relay Mules"
          value={metrics.relayCount}
          deltaYesterdayPct={metrics.relayPercent}
          icon={Share2}
          accentColor="amber"
          isLoading={isLoading}
        />
        <KpiCard
          title="Offline Unreachable"
          value={metrics.offlineCount}
          criticalCount={metrics.offlineCount}
          criticalBadgeText={`${metrics.offlineCount} unreachable`}
          icon={Radio}
          accentColor="red"
          isLoading={isLoading}
        />
      </div>

      {/* Navigation Tabs */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 dark:border-[#26344F] pb-3">
        {/* Tab Buttons */}
        <div className="flex items-center gap-2">
          {[
            { id: 'Device List', label: `Device List (${devices.length})`, icon: Smartphone },
            { id: 'Network Topology', label: 'Network Topology', icon: Activity },
            { id: 'Connection Logs', label: `Live Ingestion Logs (${connectionLogs.length})`, icon: FileText },
          ].map((tab) => {
            const Icon = tab.icon;
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  active
                    ? 'bg-amber-400 dark:bg-[#FFD21F] text-[#1A1400] shadow-xs'
                    : 'bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-600 dark:text-[#9FADC2] hover:bg-slate-50 dark:hover:bg-[#1C2844]'
                }`}
              >
                <Icon size={14} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Global Search inside tabs */}
        <div className="relative w-full sm:w-72">
          <Search
            size={14}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search device ID, operator, sector..."
            className="w-full h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs text-slate-900 dark:text-[#EEF2F8] placeholder-slate-400 dark:placeholder-[#9FADC2]/70 focus:outline-none focus:ring-2 focus:ring-amber-400 shadow-2xs transition-all"
          />
        </div>
      </div>

      {/* TAB 1: DEVICE LIST TABLE */}
      {activeTab === 'Device List' && (
        <div className="space-y-4 animate-in fade-in duration-150">
          {/* Filter Bar: Status & Hardware Type */}
          <div className="flex flex-wrap items-center justify-between gap-3 p-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F]">
            {/* Status Filter Pills */}
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-semibold text-slate-500 dark:text-[#9FADC2] mr-1">
                Status:
              </span>
              {['All', 'Online', 'Relay', 'Offline'].map((st) => (
                <button
                  key={st}
                  onClick={() => setStatusFilter(st)}
                  className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                    statusFilter === st
                      ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                      : 'bg-slate-100 dark:bg-[#0E1627] text-slate-600 dark:text-[#9FADC2] hover:bg-slate-200 dark:hover:bg-[#1C2844]'
                  }`}
                >
                  {st}
                </button>
              ))}
            </div>

            {/* Hardware Type Select */}
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-slate-500 dark:text-[#9FADC2]">
                Hardware:
              </span>
              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="h-8 px-2.5 rounded-lg bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-[#26344F] text-xs font-semibold text-slate-900 dark:text-[#EEF2F8] focus:outline-none focus:ring-2 focus:ring-amber-400 cursor-pointer"
              >
                <option value="All">All Hardware Types</option>
                <option value="Phone">Phones</option>
                <option value="Tablet">Field Tablets</option>
                <option value="Relay Beacon">Relay Beacons</option>
                <option value="Satellite Uplink">Satellite Uplinks</option>
              </select>
            </div>
          </div>

          {/* Table Container */}
          <Card className="p-0 overflow-hidden border border-slate-200 dark:border-[#26344F] shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-[#0E1627] text-slate-500 dark:text-[#9FADC2] uppercase tracking-wider font-semibold border-b border-slate-200 dark:border-[#26344F]">
                  <tr>
                    <th className="py-3.5 px-4">Device ID</th>
                    <th className="py-3.5 px-4">Operator / Node</th>
                    <th className="py-3.5 px-4">Hardware Type</th>
                    <th className="py-3.5 px-4">Location Sector</th>
                    <th className="py-3.5 px-4">Signal & Hops</th>
                    <th className="py-3.5 px-4">Battery</th>
                    <th className="py-3.5 px-4 text-center">Packets Muled</th>
                    <th className="py-3.5 px-4 text-center">Status</th>
                    <th className="py-3.5 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200/80 dark:divide-[#26344F]/50">
                  {isLoading && devices.length === 0 ? (
                    <tr>
                      <td colSpan={9} className="py-12 text-center text-slate-400">
                        <RefreshCw className="w-6 h-6 mx-auto mb-2 animate-spin text-amber-500" />
                        Scanning disaster sector mesh radios...
                      </td>
                    </tr>
                  ) : devices.length === 0 ? (
                    <tr>
                      <td colSpan={9} className="py-12 text-center text-slate-400">
                        No active mesh devices match the selected filters.
                      </td>
                    </tr>
                  ) : (
                    devices.map((d) => (
                      <tr
                        key={d.id}
                        onClick={() => handleDeviceClick(d)}
                        className="hover:bg-slate-50/80 dark:hover:bg-[#162238]/60 transition-colors cursor-pointer group"
                      >
                        {/* Device ID */}
                        <td className="py-3.5 px-4">
                          <span className="font-mono font-bold text-amber-700 dark:text-[#FFD21F] bg-amber-50 dark:bg-amber-950/40 px-2 py-0.5 rounded border border-amber-200/60 dark:border-amber-900/40">
                            {d.id}
                          </span>
                        </td>

                        {/* Operator / Node Name */}
                        <td className="py-3.5 px-4">
                          <div className="flex flex-col">
                            <span className="font-bold text-slate-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-[#FFD21F] transition-colors">
                              {d.userName}
                            </span>
                            {d.ownerName && d.ownerName !== d.userName && (
                              <span className="text-[11px] text-slate-400 dark:text-[#9FADC2]">
                                Operator: {d.ownerName}
                              </span>
                            )}
                          </div>
                        </td>

                        {/* Hardware Type */}
                        <td className="py-3.5 px-4">
                          <span className="inline-flex items-center gap-1.5 font-medium text-slate-700 dark:text-[#CBD5E1]">
                            {getHardwareIcon(d.type)}
                            <span>{d.type}</span>
                          </span>
                        </td>

                        {/* Location Sector */}
                        <td className="py-3.5 px-4 font-medium text-slate-700 dark:text-[#CBD5E1]">
                          <div className="flex items-center gap-1.5">
                            <MapPin size={12} className="text-amber-500 shrink-0" />
                            <span className="truncate max-w-[200px]">{d.location}</span>
                          </div>
                        </td>

                        {/* Signal & Hops */}
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs font-bold text-slate-900 dark:text-white">
                              {d.signalStrengthDbm === undefined ? 'Not reported' : `${d.signalStrengthDbm} dBm`}
                            </span>
                            <span className="text-[10px] px-1.5 py-0.2 rounded bg-slate-100 dark:bg-[#0E1627] text-slate-500 dark:text-[#9FADC2] border border-slate-200/60 dark:border-[#26344F]">
                              {d.meshHops === undefined ? 'Hops unavailable' : d.meshHops === 0 ? '0 hops' : `${d.meshHops} hops`}
                            </span>
                          </div>
                        </td>

                        {/* Battery Level */}
                        <td className="py-3.5 px-4">
                          {d.battery === undefined ? (
                            <span className="text-xs text-slate-500 dark:text-[#9FADC2]">Not reported</span>
                          ) : <div className="flex items-center gap-2">
                            <div className="w-14 h-2 rounded-full bg-slate-200 dark:bg-slate-700/60 overflow-hidden">
                              <div
                                className={`h-full ${
                                  d.battery > 50
                                    ? 'bg-emerald-500'
                                    : d.battery > 20
                                    ? 'bg-amber-500'
                                    : 'bg-rose-500'
                                }`}
                                style={{ width: `${d.battery}%` }}
                              />
                            </div>
                            <span className="font-mono text-[11px] font-bold text-slate-900 dark:text-white">
                              {d.battery}%
                            </span>
                          </div>}
                        </td>

                        {/* Packets Muled */}
                        <td className="py-3.5 px-4 text-center font-mono font-bold text-slate-700 dark:text-[#CBD5E1]">
                          {d.packetsForwarded ?? 'Not reported'}
                        </td>

                        {/* Status Badge */}
                        <td className="py-3.5 px-4 text-center">
                          <span
                            className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full font-bold text-[11px] ${
                              d.status === 'Online'
                                ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30'
                                : d.status === 'Relay'
                                ? 'bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-400 border border-cyan-500/30'
                                : 'bg-slate-100 dark:bg-slate-800 text-slate-500 border border-slate-400/30'
                            }`}
                          >
                            <span
                              className={`w-1.5 h-1.5 rounded-full ${
                                d.status === 'Online'
                                  ? 'bg-emerald-500 animate-pulse'
                                  : d.status === 'Relay'
                                  ? 'bg-cyan-500 animate-pulse'
                                  : 'bg-slate-400'
                              }`}
                            />
                            {d.status}
                          </span>
                        </td>

                        {/* Actions */}
                        <td className="py-3.5 px-4 text-right">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeviceClick(d);
                            }}
                            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#162036] hover:bg-amber-400 hover:text-slate-950 dark:hover:bg-[#FFD21F] dark:hover:text-black border border-slate-200 dark:border-[#26344F] font-semibold text-[11px] text-slate-700 dark:text-[#EEF2F8] transition-colors cursor-pointer"
                          >
                            <Eye size={12} />
                            <span>Inspect</span>
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Table Footer */}
            <div className="p-3 bg-slate-50 dark:bg-[#0E1627] border-t border-slate-200 dark:border-[#26344F] flex items-center justify-between text-xs text-slate-500 dark:text-[#9FADC2]">
              <span>
                Showing {devices.length} real mesh nodes ingested from SQLite & mesh radio gateways
              </span>
              <span className="font-mono">Heartbeat interval: 15s</span>
            </div>
          </Card>
        </div>
      )}

      {/* TAB 2: NETWORK TOPOLOGY GRAPH */}
      {activeTab === 'Network Topology' && (
        <div className="space-y-4 animate-in fade-in duration-150">
          <NetworkTopology nodes={topologyNodes} />
        </div>
      )}

      {/* TAB 3: CONNECTION LOGS */}
      {activeTab === 'Connection Logs' && (
        <div className="space-y-4 animate-in fade-in duration-150">
          <ConnectionLogsTable logs={connectionLogs} />
        </div>
      )}

      {/* Detailed Slide-Over Drawer for Selected Device */}
      <DeviceDetailDrawer
        device={selectedDevice}
        onClose={() => setSelectedDevice(null)}
        onViewLogs={(deviceId) => {
          setActiveTab('Connection Logs');
          setSearch(deviceId);
        }}
      />
    </div>
  );
};

export default DevicesPage;

import React, { useState } from 'react';
import {
  Search,
  Layers,
  Radio,
  Eye,
  EyeOff,
  Crosshair,
  Maximize2,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';

export const LiveMapPage: React.FC = () => {
  const [activeLayers, setActiveLayers] = useState({
    users: true,
    nearbyDevices: true,
    incidents: true,
    rescueTeams: true,
    meshConnections: true,
    hazardZones: false,
  });

  const [searchQuery, setSearchQuery] = useState('');

  const toggleLayer = (layer: keyof typeof activeLayers) => {
    setActiveLayers((prev) => ({ ...prev, [layer]: !prev[layer] }));
  };

  const devices = [
    { id: 'SR-8F42', location: 'Uttarakhand', status: 'Online', role: 'Edge Node' },
    { id: 'SR-9A1C', location: 'Uttarakhand', status: 'Relay', role: 'Data Mule' },
    { id: 'SR-3D7B', location: 'Himachal Pradesh', status: 'Online', role: 'Edge Node' },
    { id: 'SR-4E2F', location: 'Delhi', status: 'Offline', role: 'Edge Node' },
  ];

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Live Map & Devices
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            Real-time geospatial location of users, mesh nodes, and clustered distress zones
          </p>
        </div>

        {/* Filter bar */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="relative">
            <Search
              size={15}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
            />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search location, device..."
              className="h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            />
          </div>

          <select className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-semibold text-[#16202D] dark:text-white">
            <option>All Incidents</option>
            <option>Critical Only</option>
          </select>

          <select className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-semibold text-[#16202D] dark:text-white">
            <option>All Devices</option>
            <option>Online Mules</option>
          </select>
        </div>
      </div>

      {/* Main Map + Right Side Panel Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Map View Canvas */}
        <div className="lg:col-span-8 xl:col-span-9">
          <div className="relative h-[600px] w-full rounded-2xl bg-[#0E1627] border-2 border-[#E6DCA8] dark:border-[#26344F] overflow-hidden shadow-lg flex items-center justify-center">
            {/* Topographic Background Simulation */}
            <div
              className="absolute inset-0 opacity-40 bg-cover bg-center"
              style={{
                backgroundImage:
                  'radial-gradient(circle at 50% 50%, #162036 0%, #0B1220 100%)',
              }}
            />

            {/* Simulated Geospatial Grid */}
            <div
              className="absolute inset-0 opacity-20 pointer-events-none"
              style={{
                backgroundImage:
                  'linear-gradient(#26344F 1px, transparent 1px), linear-gradient(90deg, #26344F 1px, transparent 1px)',
                backgroundSize: '40px 40px',
              }}
            />

            {/* Map Controls Overlay */}
            <div className="absolute top-4 left-4 z-10 flex flex-col gap-2">
              <button
                className="w-9 h-9 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#16202D] dark:text-white flex items-center justify-center shadow-md hover:bg-[#FFEFA6] dark:hover:bg-[#1E2B48] transition-colors"
                title="Center on incident centroid"
              >
                <Crosshair size={18} />
              </button>
              <button
                className="w-9 h-9 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#16202D] dark:text-white flex items-center justify-center shadow-md hover:bg-[#FFEFA6] dark:hover:bg-[#1E2B48] transition-colors"
                title="Toggle fullscreen"
              >
                <Maximize2 size={18} />
              </button>
            </div>

            {/* Active Clustered Incident Zones overlay */}
            <div className="relative z-10 w-full h-full p-8 flex flex-col justify-around">
              {/* Incident 1: SOS Cluster */}
              <div className="absolute top-1/4 left-1/4 transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center cursor-pointer group">
                <div className="relative flex items-center justify-center">
                  <div className="w-24 h-24 rounded-full bg-[#D92D20]/20 animate-ping absolute" />
                  <div className="w-16 h-16 rounded-full bg-[#D92D20] text-white flex flex-col items-center justify-center shadow-lg shadow-red-500/50 border-2 border-white">
                    <span className="text-xs font-black">SOS</span>
                    <span className="text-[10px] font-semibold">12 users</span>
                  </div>
                </div>
                <div className="mt-2 bg-[#0B1220]/90 backdrop-blur-md px-2.5 py-1 rounded-lg border border-[#D92D20]/40 text-[11px] font-bold text-white shadow">
                  Alaknanda Gorge
                </div>
              </div>

              {/* Incident 2: Landslide */}
              <div className="absolute top-1/3 right-1/3 transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center cursor-pointer group">
                <div className="w-14 h-14 rounded-full bg-[#E07B00] text-white flex flex-col items-center justify-center shadow-lg shadow-amber-500/50 border-2 border-white">
                  <span className="text-[11px] font-bold">Landslide</span>
                  <span className="text-[9px]">6 devices</span>
                </div>
                <div className="mt-2 bg-[#0B1220]/90 px-2.5 py-1 rounded-lg border border-[#E07B00]/40 text-[11px] font-bold text-white">
                  NH-7 Sector 4
                </div>
              </div>

              {/* Incident 3: Flood Area */}
              <div className="absolute bottom-1/4 left-1/3 transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center cursor-pointer group">
                <div className="w-16 h-16 rounded-full bg-[#0E8A94] text-white flex flex-col items-center justify-center shadow-lg shadow-teal-500/50 border-2 border-white">
                  <span className="text-[11px] font-bold">Flood Area</span>
                  <span className="text-[9px]">15 devices</span>
                </div>
                <div className="mt-2 bg-[#0B1220]/90 px-2.5 py-1 rounded-lg border border-[#0E8A94]/40 text-[11px] font-bold text-white">
                  Koshi Embankment
                </div>
              </div>

              {/* Rescue Team Unit */}
              <div className="absolute bottom-1/5 right-1/4 transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center cursor-pointer group">
                <div className="w-14 h-14 rounded-xl bg-[#1E8E4E] text-white flex flex-col items-center justify-center shadow-lg shadow-green-500/50 border-2 border-white">
                  <span className="text-[10px] font-bold">Rescue Team</span>
                  <span className="text-[9px]">4 units</span>
                </div>
                <div className="mt-2 bg-[#0B1220]/90 px-2 py-0.5 rounded-lg border border-green-500/40 text-[10px] font-bold text-white">
                  NDRF Zodiac 01
                </div>
              </div>
            </div>

            {/* Bottom Status Ribbon */}
            <div className="absolute bottom-4 left-4 right-4 z-10 px-4 py-2.5 rounded-xl bg-[#0B1220]/90 backdrop-blur-md border border-[#26344F] flex items-center justify-between text-xs text-white">
              <div className="flex items-center gap-3">
                <span className="w-2.5 h-2.5 rounded-full bg-[#4CD08A] animate-ping" />
                <span>Geospatial Mesh Coverage: <strong>89.4% Active</strong></span>
              </div>
              <div className="text-[11px] text-[#9FADC2]">
                Coordinates: 30.0668° N, 79.0193° E · WGS84
              </div>
            </div>
          </div>
        </div>

        {/* Right Side Panel: Layers & Live Devices */}
        <div className="lg:col-span-4 xl:col-span-3 space-y-6">
          {/* Map Layers Card */}
          <Card>
            <div className="flex items-center gap-2 mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
              <Layers size={18} className="text-[#8A5A00] dark:text-[#FFD21F]" />
              <h3 className="text-sm font-bold text-[#16202D] dark:text-white">
                Map Layers
              </h3>
            </div>

            <div className="space-y-2.5">
              {Object.entries(activeLayers).map(([key, val]) => (
                <div
                  key={key}
                  onClick={() => toggleLayer(key as keyof typeof activeLayers)}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-black/5 dark:hover:bg-[#0E1627] cursor-pointer transition-colors"
                >
                  <span className="text-xs font-semibold text-[#16202D] dark:text-[#EEF2F8] capitalize">
                    {key.replace(/([A-Z])/g, ' $1')}
                  </span>
                  <button className="text-[#8A5A00] dark:text-[#FFD21F]">
                    {val ? <Eye size={16} /> : <EyeOff size={16} className="text-[#566070]" />}
                  </button>
                </div>
              ))}
            </div>
          </Card>

          {/* Live Devices Card */}
          <Card>
            <div className="flex items-center justify-between mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
              <div className="flex items-center gap-2">
                <Radio size={18} className="text-[#0E8A94] dark:text-[#3CC6D0]" />
                <h3 className="text-sm font-bold text-[#16202D] dark:text-white">
                  Live Devices (326)
                </h3>
              </div>
              <span className="text-[11px] font-bold text-[#8A5A00] dark:text-[#FFD21F] cursor-pointer hover:underline">
                View All
              </span>
            </div>

            <div className="space-y-2">
              {devices.map((d) => (
                <div
                  key={d.id}
                  className="p-2.5 rounded-lg bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex items-center justify-between text-xs"
                >
                  <div>
                    <span className="font-mono font-bold text-[#16202D] dark:text-white block">
                      {d.id}
                    </span>
                    <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                      {d.location} · {d.role}
                    </span>
                  </div>
                  <Badge
                    variant="status"
                    label={d.status}
                    className={
                      d.status === 'Online'
                        ? 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/40'
                        : d.status === 'Relay'
                        ? 'text-cyan-600 bg-cyan-50 dark:bg-cyan-950/40'
                        : 'text-gray-500'
                    }
                  />
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default LiveMapPage;

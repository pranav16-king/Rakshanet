import React, { useState } from 'react';
import {
  Radio,
  Search,
  Battery,
  Smartphone,
  Tablet,
  Share2,
  WifiOff,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';

export const DevicesPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('Device List');
  const [search, setSearch] = useState('');

  const metrics = [
    { label: 'Total Devices', value: '326', sub: 'All registered', color: 'gray' },
    { label: 'Online', value: '248', sub: '76% reachable', color: 'green' },
    { label: 'Relay Devices', value: '68', sub: '21% active mules', color: 'teal' },
    { label: 'Offline', value: '10', sub: '3% unreachable', color: 'red' },
  ];

  const devices = [
    {
      id: 'SR-8F42',
      userName: 'Amit Kumar',
      type: 'Phone',
      location: 'Uttarakhand',
      battery: 65,
      status: 'Online',
    },
    {
      id: 'SR-9A1C',
      userName: 'Priya Sharma',
      type: 'Phone',
      location: 'Uttarakhand',
      battery: 42,
      status: 'Relay',
    },
    {
      id: 'SR-3D7B',
      userName: 'Rahul Mehta',
      type: 'Phone',
      location: 'Himachal',
      battery: 78,
      status: 'Online',
    },
    {
      id: 'SR-4E2F',
      userName: 'Sneha Patel',
      type: 'Phone',
      location: 'Delhi',
      battery: 23,
      status: 'Offline',
    },
    {
      id: 'SR-7G9H',
      userName: 'Vikram Singh',
      type: 'Tablet',
      location: 'Uttarakhand',
      battery: 89,
      status: 'Online',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1
          className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
          style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
        >
          Devices & Network
        </h1>
        <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
          Connected Android handsets, opportunistic data mules, and edge topology
        </p>
      </div>

      {/* Metrics Row matching media_1791015140209.jpg */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {metrics.map((m, i) => (
          <Card key={i} className="p-4 flex flex-col justify-between">
            <span className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
              {m.label}
            </span>
            <span
              className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white my-1"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              {m.value}
            </span>
            <span
              className={`text-[11px] font-bold ${
                m.color === 'green'
                  ? 'text-emerald-600 dark:text-emerald-400'
                  : m.color === 'teal'
                  ? 'text-cyan-600 dark:text-cyan-400'
                  : m.color === 'red'
                  ? 'text-rose-600 dark:text-rose-400'
                  : 'text-gray-500'
              }`}
            >
              {m.sub}
            </span>
          </Card>
        ))}
      </div>

      {/* Tabs and Search */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          {['Device List', 'Network Topology', 'Connection Logs'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                activeTab === tab
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                  : 'bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2]'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-64">
          <Search
            size={15}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search device ID, owner..."
            className="w-full h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>
      </div>

      {/* Table */}
      <Card className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#FFFCEB] dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] uppercase tracking-wider font-semibold border-b border-[#E6DCA8] dark:border-[#26344F]">
              <tr>
                <th className="py-3.5 px-4">Device ID</th>
                <th className="py-3.5 px-4">User Name</th>
                <th className="py-3.5 px-4">Type</th>
                <th className="py-3.5 px-4">Location</th>
                <th className="py-3.5 px-4">Battery</th>
                <th className="py-3.5 px-4 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E6DCA8]/50 dark:divide-[#26344F]/50">
              {devices.map((d) => (
                <tr
                  key={d.id}
                  className="hover:bg-[#FFFCEB]/40 dark:hover:bg-[#0E1627]/40 transition-colors"
                >
                  <td className="py-3.5 px-4 font-mono font-bold text-[#8A5A00] dark:text-[#FFD21F]">
                    {d.id}
                  </td>
                  <td className="py-3.5 px-4 font-semibold text-[#16202D] dark:text-white">
                    {d.userName}
                  </td>
                  <td className="py-3.5 px-4 text-[#566070] dark:text-[#9FADC2]">
                    <span className="inline-flex items-center gap-1">
                      {d.type === 'Tablet' ? <Tablet size={14} /> : <Smartphone size={14} />}
                      {d.type}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-[#566070] dark:text-[#9FADC2]">{d.location}</td>
                  <td className="py-3.5 px-4">
                    <div className="flex items-center gap-2">
                      <div className="w-16 h-2 rounded-full bg-gray-200 dark:bg-gray-700 overflow-hidden">
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
                      <span className="font-mono text-[11px] font-bold text-[#16202D] dark:text-white">
                        {d.battery}%
                      </span>
                    </div>
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full font-bold text-[11px] ${
                        d.status === 'Online'
                          ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30'
                          : d.status === 'Relay'
                          ? 'bg-cyan-50 dark:bg-cyan-950/40 text-cyan-600 dark:text-cyan-400 border border-cyan-500/30'
                          : 'bg-gray-100 dark:bg-gray-800 text-gray-500 border border-gray-400/30'
                      }`}
                    >
                      {d.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

export default DevicesPage;

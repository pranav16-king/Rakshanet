import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  AlertOctagon,
  Radio,
  Share2,
  TrendingUp,
  ArrowUpRight,
  Clock,
  MapPin,
  ChevronRight,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();

  const kpis = [
    {
      title: 'Total Active Users',
      value: '1,248',
      change: '+12% from yesterday',
      icon: Users,
      color: 'teal',
      trend: 'up',
    },
    {
      title: 'Active Incidents',
      value: '18',
      change: '3 critical',
      icon: AlertOctagon,
      color: 'red',
      trend: 'critical',
    },
    {
      title: 'Connected Devices',
      value: '326',
      change: '+20% from yesterday',
      icon: Radio,
      color: 'yellow',
      trend: 'up',
    },
    {
      title: 'Messages Relayed',
      value: '12,842',
      change: '+45% from yesterday',
      icon: Share2,
      color: 'green',
      trend: 'up',
    },
  ];

  const recentIncidents = [
    {
      id: 'INC-2026-001',
      title: 'Flood in River Area',
      location: 'Uttarakhand',
      time: '12 min ago',
      severity: 'CRITICAL' as const,
      people: 142,
    },
    {
      id: 'INC-2026-002',
      title: 'Landslide on NH-7',
      location: 'Himachal Pradesh',
      time: '26 min ago',
      severity: 'HIGH' as const,
      people: 38,
    },
    {
      id: 'INC-2026-003',
      title: 'Building Collapse',
      location: 'Delhi',
      time: '1 hour ago',
      severity: 'HIGH' as const,
      people: 15,
    },
    {
      id: 'INC-2026-004',
      title: 'Cyclone Alert',
      location: 'Odisha',
      time: '2 hours ago',
      severity: 'MEDIUM' as const,
      people: 520,
    },
  ];

  const incidentTypes = [
    { name: 'Flood', count: 6, color: '#0E8A94' },
    { name: 'Earthquake', count: 4, color: '#D92D20' },
    { name: 'Landslide', count: 3, color: '#E07B00' },
    { name: 'Cyclone', count: 2, color: '#7A4DD8' },
    { name: 'Fire', count: 2, color: '#E0463B' },
    { name: 'Others', count: 1, color: '#566070' },
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
            Dashboard
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            Real-time overview of disaster communication network
          </p>
        </div>

        <div className="flex items-center gap-3">
          <select className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-semibold text-[#16202D] dark:text-[#EEF2F8] focus:outline-none focus:ring-2 focus:ring-[#FFC400]">
            <option>Last 24 hours</option>
            <option>Last 7 days</option>
            <option>All-Time Disaster Event</option>
          </select>
        </div>
      </div>

      {/* KPI Cards (4 columns matching mockup) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map((kpi, idx) => {
          const Icon = kpi.icon;
          return (
            <Card key={idx} className="flex flex-col justify-between">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
                  {kpi.title}
                </span>
                <div
                  className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                    kpi.color === 'red'
                      ? 'bg-[#FDE2DF] dark:bg-[#3A1512] text-[#D92D20] dark:text-[#FF5A4E]'
                      : kpi.color === 'yellow'
                      ? 'bg-[#FFEFA6] dark:bg-[#3A3010] text-[#8A5A00] dark:text-[#FFD21F]'
                      : kpi.color === 'teal'
                      ? 'bg-[#D6F1F3] dark:bg-[#0F3037] text-[#0E8A94] dark:text-[#3CC6D0]'
                      : 'bg-[#D9F2E3] dark:bg-[#0F3322] text-[#1E8E4E] dark:text-[#4CD08A]'
                  }`}
                >
                  <Icon size={18} />
                </div>
              </div>

              <div>
                <span
                  className="text-3xl font-black text-[#16202D] dark:text-white"
                  style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                >
                  {kpi.value}
                </span>
              </div>

              <div className="mt-2 flex items-center gap-1.5 text-[11px] font-bold">
                {kpi.trend === 'critical' ? (
                  <span className="text-[#D92D20] dark:text-[#FF5A4E] flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#D92D20] dark:bg-[#FF5A4E] animate-ping" />
                    {kpi.change}
                  </span>
                ) : (
                  <span className="text-[#1E8E4E] dark:text-[#4CD08A] flex items-center gap-1">
                    <TrendingUp size={12} />
                    {kpi.change}
                  </span>
                )}
              </div>
            </Card>
          );
        })}
      </div>

      {/* Main Grid: Distribution & Recent Incidents */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Incident Distribution (Donut style overview) */}
        <div className="lg:col-span-5">
          <Card className="h-full flex flex-col justify-between">
            <div>
              <h3
                className="text-base font-bold text-[#16202D] dark:text-white mb-1"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                Incident Distribution
              </h3>
              <p className="text-xs text-[#566070] dark:text-[#9FADC2] mb-6">
                Active alerts classified by disaster taxonomy
              </p>

              {/* Visual Donut representation */}
              <div className="flex items-center justify-center my-6">
                <div className="relative w-44 h-44 rounded-full border-8 border-[#FFC400] dark:border-[#FFD21F] flex items-center justify-center shadow-inner">
                  <div className="flex flex-col items-center">
                    <span className="text-4xl font-black text-[#16202D] dark:text-white">
                      18
                    </span>
                    <span className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
                      Total Active
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Breakdown legend */}
            <div className="grid grid-cols-2 gap-2 pt-4 border-t border-[#E6DCA8] dark:border-[#26344F]">
              {incidentTypes.map((t, idx) => (
                <div key={idx} className="flex items-center justify-between text-xs py-1">
                  <div className="flex items-center gap-2">
                    <span
                      className="w-2.5 h-2.5 rounded-full"
                      style={{ backgroundColor: t.color }}
                    />
                    <span className="text-[#566070] dark:text-[#9FADC2]">{t.name}</span>
                  </div>
                  <span className="font-bold text-[#16202D] dark:text-white">{t.count}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Recent Incidents List */}
        <div className="lg:col-span-7">
          <Card className="h-full flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3
                    className="text-base font-bold text-[#16202D] dark:text-white mb-0.5"
                    style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                  >
                    Recent Incidents
                  </h3>
                  <p className="text-xs text-[#566070] dark:text-[#9FADC2]">
                    High-priority cluster notifications
                  </p>
                </div>
                <button
                  onClick={() => navigate('/app/incidents')}
                  className="text-xs font-bold text-[#8A5A00] dark:text-[#FFD21F] hover:underline flex items-center gap-1 cursor-pointer"
                >
                  View All <ChevronRight size={14} />
                </button>
              </div>

              {/* Incidents Table Rows */}
              <div className="space-y-3">
                {recentIncidents.map((inc) => (
                  <div
                    key={inc.id}
                    onClick={() => navigate(`/app/incidents/${inc.id}`)}
                    className="p-3.5 rounded-xl bg-[#FFFCEB]/60 dark:bg-[#0E1627] border border-[#E6DCA8]/70 dark:border-[#26344F] hover:border-[#FFC400] dark:hover:border-[#FFD21F] transition-all cursor-pointer flex items-center justify-between group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-red-500/10 text-red-500 flex items-center justify-center flex-shrink-0 group-hover:scale-105 transition-transform">
                        <AlertOctagon size={20} />
                      </div>
                      <div>
                        <h4 className="text-sm font-bold text-[#16202D] dark:text-white group-hover:text-[#8A5A00] dark:group-hover:text-[#FFD21F] transition-colors">
                          {inc.title}
                        </h4>
                        <div className="flex items-center gap-3 text-xs text-[#566070] dark:text-[#9FADC2] mt-0.5">
                          <span className="flex items-center gap-1">
                            <MapPin size={12} /> {inc.location}
                          </span>
                          <span>•</span>
                          <span className="flex items-center gap-1">
                            <Clock size={12} /> {inc.time}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <Badge severity={inc.severity} label={inc.severity} />
                      <ArrowUpRight
                        size={16}
                        className="text-[#9FADC2] group-hover:text-white transition-colors"
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick Actions Footer */}
            <div className="mt-6 pt-4 border-t border-[#E6DCA8] dark:border-[#26344F] flex items-center justify-between">
              <span className="text-xs text-[#566070] dark:text-[#9FADC2]">
                DBSCAN cluster engine running every 30s
              </span>
              <button
                onClick={() => navigate('/app/map')}
                className="text-xs font-bold px-3 py-1.5 rounded-lg bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] hover:brightness-105 transition-all cursor-pointer"
              >
                Open Live Map
              </button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AlertTriangle,
  Search,
  Filter,
  Users,
  MapPin,
  Clock,
  ArrowRight,
  RefreshCw,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';

export const IncidentsPage: React.FC = () => {
  const navigate = useNavigate();
  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [search, setSearch] = useState('');

  const incidents = [
    {
      id: 'INC-2026-001',
      title: 'Flood in River Area',
      type: 'Flood',
      severity: 'CRITICAL' as const,
      location: 'Uttarakhand, India',
      time: '12 min ago',
      people: 142,
      devices: 28,
      status: 'ACTIVE',
      description: 'Heavy flooding reported in the river area. Multiple users stranded on rooftops.',
    },
    {
      id: 'INC-2026-002',
      title: 'Landslide on NH-7',
      type: 'Landslide',
      severity: 'HIGH' as const,
      location: 'Himachal Pradesh, India',
      time: '26 min ago',
      people: 38,
      devices: 12,
      status: 'ASSIGNED',
      description: 'Major rockfall blocking highway. 8 vehicles trapped in vulnerable zone.',
    },
    {
      id: 'INC-2026-003',
      title: 'Structural Building Collapse',
      type: 'Building Collapse',
      severity: 'HIGH' as const,
      location: 'Delhi NCR, India',
      time: '1 hour ago',
      people: 15,
      devices: 9,
      status: 'IN_PROGRESS',
      description: 'Commercial structure collapsed after tremor. Rescue dogs dispatched.',
    },
    {
      id: 'INC-2026-004',
      title: 'Coastal Cyclone Alert',
      type: 'Cyclone',
      severity: 'MEDIUM' as const,
      location: 'Odisha Coast, India',
      time: '2 hours ago',
      people: 520,
      devices: 64,
      status: 'ACTIVE',
      description: 'Category 3 storm surge approaching coastal fishing settlements.',
    },
    {
      id: 'INC-2026-005',
      title: 'Forest Wildfire Spread',
      type: 'Fire',
      severity: 'MEDIUM' as const,
      location: 'Nainital Forest Reserve',
      time: '4 hours ago',
      people: 22,
      devices: 5,
      status: 'CONTAINED',
      description: 'Dry brush fire nearing village perimeter. Containment line formed.',
    },
  ];

  const filtered = incidents.filter((inc) => {
    const matchesSev = filterSeverity === 'ALL' || inc.severity === filterSeverity;
    const matchesSearch =
      inc.title.toLowerCase().includes(search.toLowerCase()) ||
      inc.location.toLowerCase().includes(search.toLowerCase());
    return matchesSev && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Incidents & Distress Clusters
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            DBSCAN-aggregated master emergencies with live casualty estimation
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Button
            variant="secondary"
            size="md"
            leftIcon={<RefreshCw size={16} />}
            onClick={() => alert('DBSCAN cluster recalculation triggered across edge nodes.')}
          >
            Recalculate Clusters
          </Button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F]">
        <div className="relative w-full sm:w-72">
          <Search
            size={16}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search incident name, location..."
            className="w-full h-10 pl-10 pr-4 text-xs rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto">
          {['ALL', 'CRITICAL', 'HIGH', 'MEDIUM'].map((sev) => (
            <button
              key={sev}
              onClick={() => setFilterSeverity(sev)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                filterSeverity === sev
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                  : 'text-[#566070] dark:text-[#9FADC2] hover:bg-black/5 dark:hover:bg-white/5'
              }`}
            >
              {sev}
            </button>
          ))}
        </div>
      </div>

      {/* Incidents Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.map((inc) => (
          <Card
            key={inc.id}
            variant="alert"
            alertColor={inc.severity === 'CRITICAL' ? 'red' : inc.severity === 'HIGH' ? 'yellow' : 'teal'}
            className="cursor-pointer hover:shadow-md transition-all flex flex-col justify-between"
            onClick={() => navigate(`/app/incidents/${inc.id}`)}
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="font-mono text-xs font-bold text-[#8A5A00] dark:text-[#FFD21F]">
                  {inc.id}
                </span>
                <Badge severity={inc.severity} label={inc.severity} />
              </div>

              <h3
                className="text-lg font-bold text-[#16202D] dark:text-white leading-tight mb-2"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                {inc.title}
              </h3>

              <p className="text-xs text-[#566070] dark:text-[#9FADC2] line-clamp-2 mb-4 leading-relaxed">
                {inc.description}
              </p>
            </div>

            <div className="pt-3 border-t border-[#E6DCA8]/60 dark:border-[#26344F]/60 flex items-center justify-between text-xs text-[#566070] dark:text-[#9FADC2]">
              <div className="flex items-center gap-3">
                <span className="flex items-center gap-1 font-semibold text-[#16202D] dark:text-white">
                  <Users size={14} className="text-[#0E8A94]" /> {inc.people} affected
                </span>
                <span>•</span>
                <span className="flex items-center gap-1">
                  <Clock size={14} /> {inc.time}
                </span>
              </div>

              <span className="font-bold text-[#8A5A00] dark:text-[#FFD21F] flex items-center gap-1">
                Details <ArrowRight size={14} />
              </span>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default IncidentsPage;
